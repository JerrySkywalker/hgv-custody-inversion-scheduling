param(
    [switch]$IncludeChapter5,
    [switch]$IncludeLegacy
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$core = Join-Path $scriptDir "pack_project_snapshot.ps1"

& $core `
    -SnapshotName "project_snapshot_head_code" `
    -Scope "head" `
    -CodeOnly `
    -IncludeChapter5:$IncludeChapter5 `
    -IncludeLegacy:$IncludeLegacy
