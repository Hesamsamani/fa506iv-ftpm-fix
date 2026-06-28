#Requires -RunAsAdministrator
<#
Clears a failed Windows ESRT firmware update attempt and restores stock ROM staging.
Use after /fw reboot when verify shows Phase 2 + LastAttemptStatus 0xC0000001.
#>

param(
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
$repo = Split-Path $scriptRoot -Parent
$standalone = Test-Path (Join-Path $scriptRoot 'FirmwareFlashCommon.ps1')
if ($standalone) {
    $wi = $scriptRoot
    . (Join-Path $wi 'FirmwareFlashCommon.ps1')
} else {
    $wi = Join-Path $repo 'windows-installer'
    . (Join-Path $wi 'FirmwareFlashCommon.ps1')
}

if (-not (Test-Administrator)) {
    throw 'Run as Administrator.'
}

$stockSource = Join-Path $wi 'FA506IV.320.STOCK'
if (-not (Test-Path $stockSource)) {
    $stockSource = Join-Path $repo 'input\stock\FA506IV.320'
}
if (-not (Test-Path $stockSource)) {
    throw 'Stock ROM not found.'
}

Write-Host 'FA506IV fTPM fix - cleanup failed Windows flash'
Write-Host '==============================================='
Write-Host 'Before:'
Get-FirmwareFlashStatus | Format-List *

Clear-FirmwareUpdateState -RestoreStockRom -StockSource $stockSource

Write-Host ''
Write-Host 'After:'
Get-FirmwareFlashStatus | Format-List *

Write-Host ''
Write-Host 'Cleanup complete.'
Write-Host 'Windows /fw flash cannot apply the patched ROM (catalog only signs stock).'
Write-Host 'Next: use "Prepare EZ Flash USB" in the GUI, then flash FA506IV.320 from BIOS.'
Write-Host 'Rollback file on USB: FA506IV.320.STOCK'

if (-not $NonInteractive) {
    Read-Host 'Press Enter to close'
}