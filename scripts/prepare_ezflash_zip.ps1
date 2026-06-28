# Create EZ Flash v3 zip from patch output / windows-installer ROMs
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $repo 'output'
$zip = Join-Path $outDir 'FA506IV_fTPM_fix_EZFlash_v3.zip'

$patched = Join-Path $repo 'windows-installer\FA506IV.320.PATCHED'
if (-not (Test-Path $patched)) {
    $patched = Join-Path $outDir 'FA506IV.320'
}
$stock = Join-Path $repo 'windows-installer\FA506IV.320.STOCK'
if (-not (Test-Path $stock)) {
    $stock = Join-Path $repo 'input\stock\FA506IV.320'
}
if (-not (Test-Path $patched)) { throw "Patched ROM missing. Run: python scripts/patch_ftpm_bios_v3.py" }
if (-not (Test-Path $stock)) { throw "Stock ROM missing at input/stock/FA506IV.320" }

$staging = Join-Path $env:TEMP "fa506iv-ezflash-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Copy-Item $patched (Join-Path $staging 'FA506IV.320') -Force
Copy-Item $stock (Join-Path $staging 'FA506IV.320.STOCK') -Force

$patchedSha = (Get-FileHash (Join-Path $staging 'FA506IV.320') -Algorithm SHA256).Hash
$stockSha = (Get-FileHash (Join-Path $staging 'FA506IV.320.STOCK') -Algorithm SHA256).Hash
@(
    "FA506IV.320.STOCK $stockSha"
    "FA506IV.320       $patchedSha"
) | Set-Content (Join-Path $staging 'SHA256.txt') -Encoding UTF8

@(
    'ASUS FA506IV fTPM Fix — EZ Flash v3 package'
    '==========================================='
    ''
    'Files:'
    '  FA506IV.320       Patched BIOS (v3 trustlet, TPM 3.42.2.5 class)'
    '  FA506IV.320.STOCK Official rollback image'
    ''
    'Steps:'
    '  1. Copy both files to FAT32 USB root.'
    '  2. Reboot -> F2 -> Advanced -> ASUS EZ Flash 3.'
    '  3. Select FA506IV.320. Keep AC power connected.'
    ''
    'If EZ Flash rejects the file, run FA506IV_fTPM_Fix_GUI.exe and try COD attestation pre-check.'
    'Rollback: flash FA506IV.320.STOCK from the same USB.'
    ''
    "Patched SHA-256: $patchedSha"
    "Stock SHA-256:   $stockSha"
) | Set-Content (Join-Path $staging 'FLASH_README.txt') -Encoding UTF8

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $staging -Recurse -Force
Write-Host "Created: $zip"
Write-Host "SHA-256: $((Get-FileHash $zip -Algorithm SHA256).Hash)"