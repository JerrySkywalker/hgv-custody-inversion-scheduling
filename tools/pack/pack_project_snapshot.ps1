param(
    [Parameter(Mandatory = $true)]
    [string]$SnapshotName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("working","head")]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [ValidateSet("all","code")]
    [string]$Content
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$packRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $packRoot)
$settingsPath = Join-Path $packRoot "pack_project_snapshot_settings.json"

if (-not (Test-Path $settingsPath)) {
    throw "Settings file not found: $settingsPath"
}

$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$snapshotRoot = Join-Path $repoRoot ("snapshots\" + $SnapshotName)
$stagingDir = Join-Path $snapshotRoot ($SnapshotName + "_staging_" + $timestamp)
$zipPath = Join-Path $snapshotRoot ($SnapshotName + "_" + $timestamp + ".zip")

New-Item -ItemType Directory -Force $snapshotRoot | Out-Null
New-Item -ItemType Directory -Force $stagingDir | Out-Null

function Normalize-PathForMatch {
    param([string]$PathText)
    return ($PathText -replace "/", "\")
}

function Get-RelativePathSafe {
    param(
        [string]$BasePath,
        [string]$FullPath
    )

    $base = [System.IO.Path]::GetFullPath($BasePath)
    $full = [System.IO.Path]::GetFullPath($FullPath)

    if (-not $base.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $base = $base + [System.IO.Path]::DirectorySeparatorChar
    }

    if ($full.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($base.Length)
    }

    throw "Cannot compute relative path. Base='$BasePath' Full='$FullPath'"
}

function Test-SkipByRelativePath {
    param(
        [string]$RelativePath,
        $Settings
    )

    $parts = (Normalize-PathForMatch $RelativePath).Split("\") | Where-Object { $_ -ne "" }
    $skipDirs = @($Settings.skip_dirs)

    foreach ($p in $parts) {
        if ($skipDirs -contains $p) {
            return $true
        }
    }
    return $false
}

function Test-CodeFile {
    param(
        [string]$Name,
        $Settings
    )

    $alwaysInclude = @($Settings.always_include_names)
    if ($alwaysInclude -contains $Name) {
        return $true
    }

    $ext = [System.IO.Path]::GetExtension($Name)
    $blocked = @($Settings.code_blocked_ext)
    $allowed = @($Settings.code_allowed_ext)

    if ($ext -and ($blocked -contains $ext)) {
        return $false
    }

    return ($allowed -contains $ext)
}

function Test-IncludeFile {
    param(
        [string]$RelativePath,
        [string]$Name,
        [string]$ContentMode,
        $Settings
    )

    if (Test-SkipByRelativePath -RelativePath $RelativePath -Settings $Settings) {
        return $false
    }

    switch ($ContentMode) {
        "all"  { return $true }
        "code" { return (Test-CodeFile -Name $Name -Settings $Settings) }
        default { throw "Unknown ContentMode: $ContentMode" }
    }
}

function Copy-FileToStaging {
    param(
        [string]$SourcePath,
        [string]$RelativePath,
        [string]$StagingRoot
    )

    $destPath = Join-Path $StagingRoot $RelativePath
    $destParent = Split-Path -Parent $destPath
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Force $destParent | Out-Null
    }
    Copy-Item -Path $SourcePath -Destination $destPath -Force
}

function Write-TextToStaging {
    param(
        [string]$Text,
        [string]$RelativePath,
        [string]$StagingRoot
    )

    $destPath = Join-Path $StagingRoot $RelativePath
    $destParent = Split-Path -Parent $destPath
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Force $destParent | Out-Null
    }

    [System.IO.File]::WriteAllText($destPath, $Text)
}

function Pack-FromWorkingTree {
    param(
        [string]$RepoRoot,
        [string]$StagingRoot,
        [string]$ContentMode,
        $Settings
    )

    Get-ChildItem -Path $RepoRoot -Recurse -Force -File | ForEach-Object {
        $fullPath = $_.FullName
        $rel = Get-RelativePathSafe -BasePath $RepoRoot -FullPath $fullPath

        if (Test-IncludeFile -RelativePath $rel -Name $_.Name -ContentMode $ContentMode -Settings $Settings) {
            Copy-FileToStaging -SourcePath $fullPath -RelativePath $rel -StagingRoot $StagingRoot
        }
    }
}

function Pack-FromHead {
    param(
        [string]$RepoRoot,
        [string]$StagingRoot,
        [string]$ContentMode,
        $Settings
    )

    $tmpId = [guid]::NewGuid().ToString("N")
    $tmpZip = Join-Path $env:TEMP ("pack_head_" + $tmpId + ".zip")
    $tmpExtract = Join-Path $env:TEMP ("pack_head_" + $tmpId)

    try {
        Push-Location $RepoRoot
        try {
            git archive --format=zip -o $tmpZip HEAD
            if ($LASTEXITCODE -ne 0) {
                throw "git archive failed."
            }
        }
        finally {
            Pop-Location
        }

        Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract -Force

        Get-ChildItem -Path $tmpExtract -Recurse -Force -File | ForEach-Object {
            $fullPath = $_.FullName
            $rel = Get-RelativePathSafe -BasePath $tmpExtract -FullPath $fullPath

            if (Test-IncludeFile -RelativePath $rel -Name $_.Name -ContentMode $ContentMode -Settings $Settings) {
                Copy-FileToStaging -SourcePath $fullPath -RelativePath $rel -StagingRoot $StagingRoot
            }
        }
    }
    finally {
        if (Test-Path $tmpZip) {
            Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $tmpExtract) {
            Remove-Item $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Write-Manifest {
    param(
        [string]$ManifestPath
    )

    $lines = @(
        "snapshot_name: $SnapshotName",
        "source: $Source",
        "content: $Content",
        "created_at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "timestamp: $timestamp"
    )

    Set-Content -Path $ManifestPath -Encoding UTF8 -Value $lines
}

try {
    switch ($Source) {
        "working" {
            Pack-FromWorkingTree -RepoRoot $repoRoot -StagingRoot $stagingDir -ContentMode $Content -Settings $settings
        }
        "head" {
            Pack-FromHead -RepoRoot $repoRoot -StagingRoot $stagingDir -ContentMode $Content -Settings $settings
        }
        default {
            throw "Unknown Source: $Source"
        }
    }

    Write-Manifest -ManifestPath (Join-Path $stagingDir "SNAPSHOT_MANIFEST.txt")

    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($stagingDir, $zipPath)
    Write-Host "[pack] Created snapshot: $zipPath"
}
finally {
    if (Test-Path $stagingDir) {
        Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
