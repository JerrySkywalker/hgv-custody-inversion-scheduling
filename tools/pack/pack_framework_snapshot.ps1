param(
    [ValidateSet("working","head")]
    [string]$Mode = "working",

    [switch]$CodeOnly,
    [switch]$IncludeDeliverables,

    [string]$ArchiveLabel
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$repoRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
$snapshotsDir = Join-Path $repoRoot "snapshots"
New-Item -ItemType Directory -Force $snapshotsDir | Out-Null

if ([string]::IsNullOrWhiteSpace($ArchiveLabel)) {
    if ($Mode -eq "head" -and $CodeOnly) {
        $ArchiveLabel = "head_code"
    }
    elseif ($Mode -eq "head") {
        $ArchiveLabel = "head"
    }
    elseif ($CodeOnly) {
        $ArchiveLabel = "working_code"
    }
    else {
        $ArchiveLabel = "working"
    }
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$zipPath = Join-Path $snapshotsDir ("{0}_{1}.zip" -f $timestamp, $ArchiveLabel)

$stagingRoot = Join-Path $env:TEMP ("snapshot_stage_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $stagingRoot | Out-Null

function Copy-ItemSafe {
    param(
        [string]$SourcePath,
        [string]$DestRoot,
        [string]$RelativePath
    )

    if (-not (Test-Path $SourcePath)) {
        return
    }

    $destPath = Join-Path $DestRoot $RelativePath
    $destParent = Split-Path -Parent $destPath
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Force $destParent | Out-Null
    }

    if ((Get-Item $SourcePath) -is [System.IO.DirectoryInfo]) {
        Copy-Item -Path $SourcePath -Destination $destPath -Recurse -Force
        Write-Host "[pack_snapshot] copied dir : $RelativePath"
    }
    else {
        Copy-Item -Path $SourcePath -Destination $destPath -Force
        Write-Host "[pack_snapshot] copied file: $RelativePath"
    }
}

function Should-IncludeTrackedFile {
    param(
        [string]$RelativePath,
        [bool]$CodeOnly,
        [bool]$IncludeDeliverables
    )

    $norm = $RelativePath -replace "\\","/"

    if ($norm.StartsWith("outputs/")) { return $false }
    if ($norm.StartsWith("snapshots/")) { return $false }

    if (-not $IncludeDeliverables -and $norm.StartsWith("deliverables/")) {
        return $false
    }

    if ($CodeOnly) {
        return $true
    }

    return $true
}

function Collect-WorkingTree {
    param(
        [string]$RepoRoot,
        [string]$StagingRoot,
        [bool]$CodeOnly,
        [bool]$IncludeDeliverables
    )

    $includeList = @(
        "src",
        "run_stages",
        "milestones",
        "params",
        "tools",
        "tests",
        "startup.m",
        "README.md",
        "pack_snapshot_all.m",
        "pack_snapshot_all_code.m",
        "pack_snapshot_head.m",
        "pack_snapshot_head_code.m"
    )

    if ($IncludeDeliverables) {
        $includeList += "deliverables"
    }

    foreach ($rel in $includeList) {
        $src = Join-Path $RepoRoot $rel
        Copy-ItemSafe -SourcePath $src -DestRoot $StagingRoot -RelativePath $rel
    }
}

function Collect-GitHead {
    param(
        [string]$RepoRoot,
        [string]$StagingRoot,
        [bool]$CodeOnly,
        [bool]$IncludeDeliverables
    )

    Push-Location $RepoRoot
    try {
        $tracked = git ls-files
        if ($LASTEXITCODE -ne 0) {
            throw "git ls-files failed."
        }
    }
    finally {
        Pop-Location
    }

    foreach ($rel in $tracked) {
        if ([string]::IsNullOrWhiteSpace($rel)) {
            continue
        }

        if (-not (Should-IncludeTrackedFile -RelativePath $rel -CodeOnly $CodeOnly -IncludeDeliverables $IncludeDeliverables)) {
            continue
        }

        $src = Join-Path $RepoRoot $rel
        Copy-ItemSafe -SourcePath $src -DestRoot $StagingRoot -RelativePath $rel
    }
}

try {
    Write-Host "[pack_snapshot] repoRoot    = $repoRoot"
    Write-Host "[pack_snapshot] mode        = $Mode"
    Write-Host "[pack_snapshot] codeOnly    = $CodeOnly"
    Write-Host "[pack_snapshot] output      = $zipPath"

    switch ($Mode) {
        "working" {
            Collect-WorkingTree -RepoRoot $repoRoot -StagingRoot $stagingRoot -CodeOnly $CodeOnly -IncludeDeliverables $IncludeDeliverables
        }
        "head" {
            Collect-GitHead -RepoRoot $repoRoot -StagingRoot $stagingRoot -CodeOnly $CodeOnly -IncludeDeliverables $IncludeDeliverables
        }
        default {
            throw "Unknown mode: $Mode"
        }
    }

    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($stagingRoot, $zipPath)
    Write-Host "[pack_snapshot] created     = $zipPath"
}
finally {
    if (Test-Path $stagingRoot) {
        Remove-Item $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
