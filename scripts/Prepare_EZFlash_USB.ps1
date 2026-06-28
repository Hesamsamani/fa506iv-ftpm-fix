#Requires -RunAsAdministrator
<#
Copies patched + stock ROMs to a FAT32 USB drive for ASUS EZ Flash 3.
#>

param(
    [Parameter(Mandatory)]
    [string]$DriveLetter
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

$drive = $DriveLetter.TrimEnd(':').ToUpperInvariant()
$root = "${drive}:\"
if (-not (Test-Path $root)) {
    throw "Drive not found: $root"
}

$vol = Get-Volume -DriveLetter $drive -ErrorAction Stop
if ($vol.FileSystem -ne 'FAT32') {
    Write-Warning "Drive ${drive}: is $($vol.FileSystem). ASUS EZ Flash works best with FAT32."
}

$patchedSource = Join-Path $wi 'FA506IV.320.PATCHED'
if (-not (Test-Path $patchedSource)) {
    $patchedSource = Join-Path $repo 'output\FA506IV.320'
}
$stockSource = Join-Path $wi 'FA506IV.320.STOCK'
if (-not (Test-Path $patchedSource)) { throw "Patched ROM not found: $patchedSource" }
if (-not (Test-Path $stockSource)) { throw "Stock ROM not found: $stockSource" }

$patchedDest = Join-Path $root 'FA506IV.320'
$stockDest = Join-Path $root 'FA506IV.320.STOCK'
$readmeDest = Join-Path $root 'FA506IV_FTPM_EZFLASH_README.txt'

Copy-Item -LiteralPath $patchedSource -Destination $patchedDest -Force
Copy-Item -LiteralPath $stockSource -Destination $stockDest -Force

$patchedSha = Get-Sha256Hex ([IO.File]::ReadAllBytes($patchedDest))
$stockSha = Get-Sha256Hex ([IO.File]::ReadAllBytes($stockDest))
if ($patchedSha -ne $PatchedSha) {
    throw "Patched ROM SHA mismatch on USB ($patchedSha)"
}
if ($stockSha -ne $StockSha) {
    throw "Stock ROM SHA mismatch on USB ($stockSha)"
}

@(
    'ASUS FA506IV fTPM Fix - EZ Flash package'
    '========================================'
    ''
    'Files on this USB:'
    '  FA506IV.320       - patched BIOS (v3 trustlet)'
    '  FA506IV.320.STOCK - official rollback image'
    ''
    'Flash steps:'
    '  1. Keep AC power connected.'
    '  2. Reboot -> press F2 for BIOS Setup.'
    '  3. Advanced -> ASUS EZ Flash 3 Utility.'
    '  4. Select FA506IV.320 from this USB.'
    '  5. Wait for flash to complete. Do not power off.'
    ''
    'If EZ Flash says "not a proper BIOS driver":'
    '  - Your USB setup is probably fine; ASUS validates modified ROMs.'
    '  - Try the GUI "Open COD Wizard" / pre-check — attestation may pass without BIOS flash.'
    '  - For rollback, EZ Flash FA506IV.320.STOCK instead.'
    ''
    "Patched SHA-256: $patchedSha"
    "Stock SHA-256:   $stockSha"
) | Set-Content -Path $readmeDest -Encoding UTF8

Write-Host "Prepared EZ Flash USB on $root"
Write-Host "  $patchedDest"
Write-Host "  $stockDest"
Write-Host "  $readmeDest"
Write-Host ''
Write-Host 'Safely eject the USB, reboot to BIOS (F2), and run ASUS EZ Flash 3.'