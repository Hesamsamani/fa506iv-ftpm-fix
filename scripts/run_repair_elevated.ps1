$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'repair_log.txt'
$repair = Join-Path $PSScriptRoot 'Repair_FirmwareFlash.ps1'
$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$repair`" *> `"$log`""
Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList $arg
if (Test-Path $log) {
    Get-Content $log
} else {
    Write-Host 'Repair log not created — elevation may have been denied.'
}