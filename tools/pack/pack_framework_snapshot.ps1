param(
    [Parameter(Mandatory = $true)]
    [string]$SnapshotName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('head','all')]
    [string]$Scope,

    [switch]$CodeOnly,
    [switch]$IncludeOutputs,
    [switch]$IncludeChapter5,
    [switch]$IncludeLegacy
)

$ErrorActionPreference = 'Stop'

$ThisScript = $MyInvocation.MyCommand.Path
$ToolsPackRoot = Split-Path -Parent $ThisScript
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ToolsPackRoot)

$SettingsPath = Join-Path $ToolsPackRoot 'pack_framework_snapshot_settings.json'
$Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

$SnapshotRoot = Join-Path $RepoRoot ('snapshots\' + $SnapshotName)
$StagingDir = Join-Path $SnapshotRoot ($SnapshotName + '_staging_' + $Timestamp)
$ZipPath = Join-Path $SnapshotRoot ($SnapshotName + '_' + $Timestamp + '.zip')

New-Item -ItemType Directory -Force $SnapshotRoot | Out-Null
New-Item -ItemType Directory -Force $StagingDir | Out-Null

function Copy-FileIfExists {
    param([string]$Src, [string]$Dst)
    if (Test-Path $Src -PathType Leaf) {
        $DstDir = Split-Path -Parent $Dst
        New-Item -ItemType Directory -Force $DstDir | Out-Null
        Copy-Item $Src $Dst -Force
    }
}

function Should-SkipDir {
    param([string]$Name)
    return $Settings.skip_dirs -contains $Name
}

function Should-CopyFile {
    param([string]$Name)
    $Ext = [System.IO.Path]::GetExtension($Name)
    if ($Settings.blocked_names -contains $Name) { return $false }
    if ($Settings.blocked_ext -contains $Ext) { return $false }
    return $Settings.allowed_ext -contains $Ext
}

function Copy-TreeFiltered {
    param([string]$SrcRoot, [string]$DstRoot)

    if (-not (Test-Path $SrcRoot -PathType Container)) { return }

    Get-ChildItem $SrcRoot -Force | ForEach-Object {
        if ($_.PSIsContainer) {
            if (Should-SkipDir $_.Name) { return }
            $Dst = Join-Path $DstRoot $_.Name
            New-Item -ItemType Directory -Force $Dst | Out-Null
            Copy-TreeFiltered $_.FullName $Dst
        }
        else {
            if (Should-CopyFile $_.Name) {
                $Dst = Join-Path $DstRoot $_.Name
                $DstDir = Split-Path -Parent $Dst
                New-Item -ItemType Directory -Force $DstDir | Out-Null
                Copy-Item $_.FullName $Dst -Force
            }
        }
    }
}

function Copy-LatestOutputTree {
    param([string]$SrcRoot, [string]$DstRoot)

    if (-not (Test-Path $SrcRoot -PathType Container)) { return }

    Get-ChildItem $SrcRoot -Force | ForEach-Object {
        if ($_.PSIsContainer) {
            Copy-LatestOutputTree $_.FullName (Join-Path $DstRoot $_.Name)
        }
        else {
            if ($_.Name -like ('*' + $Settings.latest_pattern + '*')) {
                $Dst = Join-Path $DstRoot $_.Name
                $DstDir = Split-Path -Parent $Dst
                New-Item -ItemType Directory -Force $DstDir | Out-Null
                Copy-Item $_.FullName $Dst -Force
            }
        }
    }
}

Copy-FileIfExists (Join-Path $RepoRoot 'startup.m') (Join-Path $StagingDir 'startup.m')
Copy-FileIfExists (Join-Path $RepoRoot 'README.md') (Join-Path $StagingDir 'README.md')
Copy-FileIfExists (Join-Path $RepoRoot 'CHANGELOG.md') (Join-Path $StagingDir 'CHANGELOG.md')

Copy-TreeFiltered (Join-Path $RepoRoot 'tools\pack') (Join-Path $StagingDir 'tools\pack')
Copy-TreeFiltered (Join-Path $RepoRoot 'framework') (Join-Path $StagingDir 'framework')
Copy-TreeFiltered (Join-Path $RepoRoot 'experiments\common') (Join-Path $StagingDir 'experiments\common')
Copy-TreeFiltered (Join-Path $RepoRoot 'experiments\chapter4') (Join-Path $StagingDir 'experiments\chapter4')
Copy-TreeFiltered (Join-Path $RepoRoot 'tests\smoke') (Join-Path $StagingDir 'tests\smoke')

if ($IncludeChapter5) {
    Copy-TreeFiltered (Join-Path $RepoRoot 'experiments\chapter5') (Join-Path $StagingDir 'experiments\chapter5')
}

if ($IncludeLegacy) {
    Copy-TreeFiltered (Join-Path $RepoRoot 'legacy') (Join-Path $StagingDir 'legacy')
}

if ($IncludeOutputs -and -not $CodeOnly) {
    if ($Scope -eq 'head') {
        Copy-LatestOutputTree (Join-Path $RepoRoot 'outputs\experiments\chapter4') (Join-Path $StagingDir 'outputs\experiments\chapter4')
    }
    else {
        Copy-LatestOutputTree (Join-Path $RepoRoot 'outputs\experiments') (Join-Path $StagingDir 'outputs\experiments')
    }
}

Compress-Archive -Path (Join-Path $StagingDir '*') -DestinationPath $ZipPath -Force
Remove-Item $StagingDir -Recurse -Force

Write-Host "[pack-ps] Created snapshot: $ZipPath"
