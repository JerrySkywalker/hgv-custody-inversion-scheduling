param(
    [Parameter(Mandatory = $true)]
    [string]$SnapshotName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("all", "head")]
    [string]$Scope,

    [switch]$CodeOnly,
    [switch]$IncludeOutputs,
    [switch]$IncludeChapter5,
    [switch]$IncludeLegacy
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

function Test-AllowedFile {
    param(
        [string]$Name,
        $Settings
    )

    $ext = [System.IO.Path]::GetExtension($Name)

    $allowed = @($Settings.allowed_ext)
    $blocked = @($Settings.blocked_ext)
    $blockedNames = @($Settings.blocked_names)

    if ($blockedNames -contains $Name) {
        return $false
    }

    if ($ext -and ($blocked -contains $ext)) {
        return $false
    }

    if ([string]::IsNullOrEmpty($ext)) {
        return ($allowed -contains $Name)
    }

    return ($allowed -contains $ext)
}

function Copy-FileIfExists {
    param(
        [string]$SourcePath,
        [string]$DestPath
    )

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        return
    }

    $destParent = Split-Path -Parent $DestPath
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Force $destParent | Out-Null
    }

    Copy-Item -Path $SourcePath -Destination $DestPath -Force
}

function Copy-TreeFiltered {
    param(
        [string]$SourceRoot,
        [string]$DestRoot,
        $Settings
    )

    if (-not (Test-Path $SourceRoot -PathType Container)) {
        return
    }

    $skipDirs = @($Settings.skip_dirs)

    Get-ChildItem -Path $SourceRoot -Recurse -Force | ForEach-Object {
        $fullPath = $_.FullName
        $rel = Get-RelativePathSafe -BasePath $SourceRoot -FullPath $fullPath
        if ([string]::IsNullOrWhiteSpace($rel) -or $rel -eq ".") {
            return
        }

        $parts = (Normalize-PathForMatch $rel).Split("\")
        foreach ($part in $parts) {
            if ($skipDirs -contains $part) {
                return
            }
        }

        $destPath = Join-Path $DestRoot $rel

        if ($_.PSIsContainer) {
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Force $destPath | Out-Null
            }
        }
        else {
            if (Test-AllowedFile -Name $_.Name -Settings $Settings) {
                $destParent = Split-Path -Parent $destPath
                if (-not (Test-Path $destParent)) {
                    New-Item -ItemType Directory -Force $destParent | Out-Null
                }
                Copy-Item -Path $fullPath -Destination $destPath -Force
            }
        }
    }
}

function Copy-LatestOutputTree {
    param(
        [string]$SourceRoot,
        [string]$DestRoot,
        $Settings
    )

    if (-not (Test-Path $SourceRoot -PathType Container)) {
        return
    }

    $latestPattern = [string]$Settings.latest_pattern

    Get-ChildItem -Path $SourceRoot -Recurse -Force -File | ForEach-Object {
        if ($_.Name -like "*$latestPattern*") {
            $rel = Get-RelativePathSafe -BasePath $SourceRoot -FullPath $_.FullName
            $destPath = Join-Path $DestRoot $rel
            $destParent = Split-Path -Parent $destPath
            if (-not (Test-Path $destParent)) {
                New-Item -ItemType Directory -Force $destParent | Out-Null
            }
            Copy-Item -Path $_.FullName -Destination $destPath -Force
        }
    }
}

function Write-Manifest {
    param(
        [string]$ManifestPath
    )

    $lines = @(
        "snapshot_name: $SnapshotName",
        "scope: $Scope",
        "code_only: $([bool]$CodeOnly)",
        "include_outputs: $([bool]$IncludeOutputs)",
        "include_chapter5: $([bool]$IncludeChapter5)",
        "include_legacy: $([bool]$IncludeLegacy)",
        "created_at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "timestamp: $timestamp"
    )

    Set-Content -Path $ManifestPath -Encoding UTF8 -Value $lines
}

try {
    foreach ($rel in @($settings.root_files)) {
        $src = Join-Path $repoRoot $rel
        $dst = Join-Path $stagingDir $rel
        Copy-FileIfExists -SourcePath $src -DestPath $dst
    }

    foreach ($rel in @($settings.roots_common)) {
        $src = Join-Path $repoRoot $rel
        $dst = Join-Path $stagingDir $rel
        Copy-TreeFiltered -SourceRoot $src -DestRoot $dst -Settings $settings
    }

    foreach ($name in @($settings.chapter4_tex)) {
        Copy-FileIfExists -SourcePath (Join-Path $repoRoot $name) -DestPath (Join-Path $stagingDir $name)
    }

    if ($IncludeChapter5) {
        foreach ($name in @($settings.chapter5_tex)) {
            Copy-FileIfExists -SourcePath (Join-Path $repoRoot $name) -DestPath (Join-Path $stagingDir $name)
        }
    }

    if ($IncludeLegacy) {
        Copy-TreeFiltered -SourceRoot (Join-Path $repoRoot "legacy") -DestRoot (Join-Path $stagingDir "legacy") -Settings $settings
    }

    if ($IncludeOutputs -and (-not $CodeOnly)) {
        Copy-LatestOutputTree -SourceRoot (Join-Path $repoRoot "outputs\stage") -DestRoot (Join-Path $stagingDir "outputs\stage") -Settings $settings
        Copy-LatestOutputTree -SourceRoot (Join-Path $repoRoot "outputs\milestone") -DestRoot (Join-Path $stagingDir "outputs\milestone") -Settings $settings
        Copy-LatestOutputTree -SourceRoot (Join-Path $repoRoot "outputs\shared_scenarios") -DestRoot (Join-Path $stagingDir "outputs\shared_scenarios") -Settings $settings
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


