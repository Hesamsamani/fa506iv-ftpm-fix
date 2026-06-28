# Populate windows-installer/ with patched ROM + ASUS signed cab files
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$wi = Join-Path $repo 'windows-installer'
$patched = Join-Path $repo 'output\FA506IV.320'
$stock = Join-Path $repo 'input\stock\FA506IV.320'
$asusCab = Join-Path $repo 'input\asus-extract\Cabfile'

if (-not (Test-Path $patched)) {
    throw "Run patch_ftpm_bios_v2.py first. Missing: $patched"
}
if (-not (Test-Path $stock)) {
    throw "Missing stock ROM: $stock"
}
if (-not (Test-Path (Join-Path $asusCab 'FA506IV_320.cat'))) {
    throw "Missing ASUS catalog. Extract official updater to input/asus-extract/Cabfile/"
}

Copy-Item $patched (Join-Path $wi 'FA506IV.320.PATCHED') -Force
Copy-Item $stock (Join-Path $wi 'FA506IV.320.STOCK') -Force
Copy-Item (Join-Path $asusCab 'FA506IV.320') (Join-Path $wi 'Cabfile_FA506IV.320') -Force
Copy-Item (Join-Path $asusCab 'FA506IV_320.cat') (Join-Path $wi 'Cabfile_FA506IV_320.cat') -Force
Copy-Item (Join-Path $asusCab 'FA506IV_320.inf') (Join-Path $wi 'Cabfile_FA506IV_320.inf') -Force
Write-Host "Windows installer package ready in $wi"