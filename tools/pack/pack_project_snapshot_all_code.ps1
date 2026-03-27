$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$core = Join-Path $scriptDir "pack_project_snapshot.ps1"

& $core `
    -SnapshotName "project_snapshot_all_code" `
    -Source "working" `
    -Content "code"
