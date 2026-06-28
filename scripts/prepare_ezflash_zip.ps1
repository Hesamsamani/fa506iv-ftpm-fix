# Create EZ Flash zip from patch output
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$pkg = Join-Path $repo 'output\ezflash_package'
$zip = Join-Path $repo 'output\FA506IV_fTPM_fix_EZFlash_v2.zip'

if (-not (Test-Path $pkg)) {
    throw "Run patch_ftpm_bios_v2.py first."
}
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path @(
    "$pkg\Cabfile\FA506IV.320",
    "$pkg\Cabfile\FA506IV.320.STOCK",
    "$pkg\FLASH_README.txt",
    "$pkg\SHA256.txt"
) -DestinationPath $zip -Force
Write-Host "Created: $zip"