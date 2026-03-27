param(
    [switch]$Execute,
    [switch]$RemoveEmptyDirs,
    [string[]]$Targets = @("all"),
    [string]$Matlab = "matlab"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
Set-Location $repoRoot

$targetList = ($Targets | ForEach-Object { "'" + $_ + "'" }) -join ", "
$executeLiteral = if ($Execute) { "true" } else { "false" }
$removeEmptyLiteral = if ($RemoveEmptyDirs) { "true" } else { "false" }

$cmd = @"
try
    startup;
catch ME
    fprintf(2, '[clean_outputs.ps1] startup failed: %s\n', ME.message);
end
clean_outputs('execute', $executeLiteral, 'targets', {$targetList}, 'remove_empty_dirs', $removeEmptyLiteral);
exit;
"@

Write-Host "[clean_outputs.ps1] repoRoot = $repoRoot"
Write-Host "[clean_outputs.ps1] targets  = $($Targets -join ', ')"
Write-Host "[clean_outputs.ps1] execute  = $Execute"

& $Matlab -batch $cmd
