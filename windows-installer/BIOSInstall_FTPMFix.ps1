#Requires -RunAsAdministrator
param(
    [switch]$NonInteractive,
    [switch]$SkipReboot
)
<#
ASUS FA506IV fTPM fix — Windows staging helper v1.3.

IMPORTANT: Windows /fw ESRT flash cannot apply the patched ROM on FA506IV.
The signed catalog (oem96.cat) only covers the stock ASUS image. Flash via EZ Flash USB.
This script only stages files for diagnostics; use Prepare_EZFlash_USB.ps1 for real flashing.
#>

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'FirmwareFlashCommon.ps1')

if (-not (Test-Administrator)) {
    throw 'Administrator rights are required. Re-run Install.bat as Administrator.'
}

$root = $PSScriptRoot
$patchedSource = Join-Path $root 'FA506IV.320.PATCHED'
$stockSource = Join-Path $root 'FA506IV.320.STOCK'
$infFile = Get-ChildItem -Path (Join-Path $root 'Cabfile\*.inf') | Select-Object -First 1

if (-not $infFile) { throw 'Cabfile\*.inf not found next to installer.' }
if (-not (Test-Path $patchedSource)) { throw 'FA506IV.320.PATCHED not found next to installer.' }
if (-not (Test-Path $stockSource)) { throw 'FA506IV.320.STOCK not found next to installer.' }

$model = (Get-CimInstance Win32_ComputerSystem).Model
$biosVer = (Get-CimInstance Win32_BIOS).SMBIOSBIOSVersion
Write-Host ''
Write-Host 'ASUS FA506IV fTPM Fix — staging helper v1.3 (use EZ Flash USB to apply)'
Write-Host '=============================================='
Write-Host "Model: $model"
Write-Host "BIOS:  $biosVer"

if ($model -notmatch 'FA506IV') {
    throw "This installer is only for ASUS FA506IV. Detected model: $model"
}
if ($biosVer -notmatch '320') {
    Write-Warning "Expected BIOS FA506IV.320. Detected: $biosVer. Continue only if intentional."
}

$patchedBytes = [IO.File]::ReadAllBytes($patchedSource)
$stockBytes = [IO.File]::ReadAllBytes($stockSource)
if ((Get-Sha256Hex $patchedBytes) -ne $PatchedSha) {
    throw 'Patched ROM SHA-256 mismatch. Package may be corrupt.'
}
if ((Get-Sha256Hex $stockBytes) -ne $StockSha) {
    throw 'Stock ROM SHA-256 mismatch. Package may be corrupt.'
}

Write-Host ''
Write-Host 'Current flash status (before install):'
Get-FirmwareFlashStatus | Format-List *

$SystemFirmware = Get-SystemFirmwareInfName
if (-not $SystemFirmware) {
    throw 'System firmware driver not found. Is this a UEFI Windows install?'
}

$instanceId = (Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.CompatID -eq 'UEFI\CC_00010001' } | Select-Object -First 1).DeviceID
Write-Host "Firmware INF: $SystemFirmware"
Write-Host "InstanceId:   $instanceId"

$paths = Get-FirmwareRomPaths
if (Test-Path $paths.FirmwareRom) {
    $backupPath = Join-Path (Split-Path $paths.FirmwareRom -Parent) 'FA506IV.320.backup'
    Copy-Item -Path $paths.FirmwareRom -Destination $backupPath -Force
    Write-Host "Backed up staged ROM to $backupPath"
}

Write-Host ''
Write-Host 'Step 1/4: Removing current firmware driver package...'
cmd.exe /c "pnputil.exe /delete-driver $SystemFirmware /uninstall /force" 2>&1 | ForEach-Object { Write-Host $_ }

Write-Host ''
Write-Host 'Step 2/4: Installing signed ASUS firmware driver (stock ROM in catalog)...'
$install = cmd.exe /c "pnputil.exe /add-driver `"$($infFile.FullName)`" /install" 2>&1
$install | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    throw "pnputil install failed with exit code $LASTEXITCODE"
}

Write-Host ''
Write-Host 'Step 3/4: Staging patched ROM in Firmware folder AND DriverStore...'
$staged = Set-PatchedRomEverywhere -PatchedSource $patchedSource
if (-not $staged.DriverStoreRom) {
    Write-Warning 'DriverStore ROM path not found. Flash may still fail; report this in an issue.'
}

Write-Host ''
Write-Host 'Step 4/4: Marking firmware update pending (offered version 0x321)...'
$installedInf = Get-SystemFirmwareInfName
$catalog = if ($installedInf) { [IO.Path]::ChangeExtension($installedInf, '.cat') } else { 'oem96.cat' }
Set-FirmwareUpdatePending -OfferedVersion $OfferedFirmwareVersion -Catalog $catalog

$device = Get-PnpDevice -PresentOnly |
    Where-Object { $_.InstanceId -eq $instanceId } |
    Select-Object -First 1
if ($device) {
    Write-Host "Firmware device status: $($device.Status) (problem $($device.Problem))"
    if ($device.Problem -ne 'CM_PROB_NEED_RESTART') {
        Write-Warning 'Device is not reporting CM_PROB_NEED_RESTART yet. Registry was still updated; reboot is required.'
    }
}

Write-Host ''
Write-Host 'Flash status (after install):'
Get-FirmwareFlashStatus | Format-List *

Write-Host ''
Write-Host 'SUCCESS: Patched ROM staged locally (diagnostics only).'
Write-Host ''
Write-Host 'DO NOT reboot with /fw — Windows will reject the patched ROM at flash time.'
Write-Host (Test-WindowsEsrtFlashViable).Reason
Write-Host ''
Write-Host 'Apply the patch:'
Write-Host '  1. Run Prepare_EZFlash_USB.ps1 (or use the GUI "Prepare EZ Flash USB")'
Write-Host '  2. Reboot -> F2 -> Advanced -> ASUS EZ Flash 3 -> select FA506IV.320'
Write-Host '  3. After flash: verify TPM version, Clear TPM, run COD attestation wizard'
Write-Host ''
Write-Host 'Recovery: EZ Flash FA506IV.320.STOCK from USB, or Rollback_Stock.bat.'
Write-Host ''

if ($NonInteractive -and -not $SkipReboot) {
    Write-Warning 'NonInteractive no longer schedules /fw reboot. Use EZ Flash USB instead.'
} elseif (-not $NonInteractive) {
    Write-Host 'No firmware reboot scheduled. Use EZ Flash USB to apply the patch.'
}