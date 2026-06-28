#Requires -RunAsAdministrator
<#
ASUS FA506IV fTPM fix — Windows installer (no EZ Flash menu required).
Uses stock-signed ASUS driver package for pnputil, then swaps in patched ROM
before reboot. Flash happens automatically during restart.
#>

$ErrorActionPreference = 'Stop'

$FirmwareGuid = '{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}'
$FirmwareDir = Join-Path $env:windir "Firmware\$FirmwareGuid"
$FirmwareRom = Join-Path $FirmwareDir 'FA506IV.320'
$StockSha = 'DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273'
$PatchedSha = '51CECB2BF48A58F224C55BB7210BABAED5B97DC72315BEA2CF1D0F26CD94759F'

function Get-Sha256Hex([byte[]]$Bytes) {
    [BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash($Bytes)
    ).Replace('-', '')
}

function Test-Administrator {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    throw 'Administrator rights are required. Re-run Install.bat as Administrator.'
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$patchedSource = Join-Path $root 'FA506IV.320.PATCHED'
$stockSource = Join-Path $root 'FA506IV.320.STOCK'
$infFile = Get-ChildItem -Path (Join-Path $root 'Cabfile\*.inf') | Select-Object -First 1

if (-not $infFile) { throw 'Cabfile\*.inf not found next to installer.' }
if (-not (Test-Path $patchedSource)) { throw 'FA506IV.320.PATCHED not found next to installer.' }
if (-not (Test-Path $stockSource)) { throw 'FA506IV.320.STOCK not found next to installer.' }

$model = (Get-CimInstance Win32_ComputerSystem).Model
$biosVer = (Get-CimInstance Win32_BIOS).SMBIOSBIOSVersion
Write-Host ''
Write-Host 'ASUS FA506IV fTPM Fix — Windows Installer'
Write-Host '========================================='
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

$SystemFirmware = $null
$instanceId = $null
foreach ($driver in Get-CimInstance Win32_PnPSignedDriver) {
    if ($driver.CompatID -eq 'UEFI\CC_00010001') {
        $SystemFirmware = $driver.InfName
        $instanceId = $driver.DeviceID
        break
    }
}
if (-not $SystemFirmware) {
    throw 'System firmware driver not found. Is this a UEFI Windows install?'
}

Write-Host "Firmware INF: $SystemFirmware"
Write-Host "InstanceId:   $instanceId"

$backupPath = Join-Path $FirmwareDir 'FA506IV.320.backup'
if (Test-Path $FirmwareRom) {
    Copy-Item -Path $FirmwareRom -Destination $backupPath -Force
    Write-Host "Backed up staged ROM to $backupPath"
}

$pnputilUn = "pnputil.exe /delete-driver $SystemFirmware /uninstall /force"
Write-Host ''
Write-Host 'Step 1/3: Removing current firmware driver package...'
$uninstall = cmd.exe /c $pnputilUn 2>&1
$uninstall | ForEach-Object { Write-Host $_ }

$pnputilIn = "pnputil.exe /add-driver `"$($infFile.FullName)`" /install"
Write-Host ''
Write-Host 'Step 2/3: Installing signed ASUS firmware driver (stock ROM for catalog check)...'
$install = cmd.exe /c $pnputilIn 2>&1
$install | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    throw "pnputil install failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path $FirmwareDir)) {
    New-Item -ItemType Directory -Path $FirmwareDir -Force | Out-Null
}

Write-Host ''
Write-Host 'Step 3/3: Staging patched ROM for flash on reboot...'
Copy-Item -Path $patchedSource -Destination $FirmwareRom -Force
$stagedSha = Get-Sha256Hex ([IO.File]::ReadAllBytes($FirmwareRom))
if ($stagedSha -ne $PatchedSha) {
    throw "Staged ROM verification failed. SHA=$stagedSha"
}
Write-Host "Staged ROM verified: $stagedSha"

$device = Get-PnpDevice -PresentOnly |
    Where-Object { $_.InstanceId -eq $instanceId } |
    Select-Object -First 1
if ($device) {
    Write-Host "Firmware device status: $($device.Status) (problem $($device.Problem))"
}

Write-Host ''
Write-Host 'SUCCESS: Patched BIOS is staged.'
Write-Host 'A full restart is required. Windows will flash BIOS during reboot.'
Write-Host 'Keep AC power connected. Do not interrupt the restart.'
Write-Host ''
Write-Host 'Recovery: run Rollback_Stock.bat from this folder, then reboot.'
Write-Host ''

$answer = Read-Host 'Reboot now? (Y/N)'
if ($answer -match '^[Yy]') {
    shutdown.exe /r /t 15 /c 'ASUS FA506IV fTPM fix: flashing BIOS on restart. Keep AC power connected.'
    Write-Host 'Rebooting in 15 seconds...'
} else {
    Write-Host 'Reboot manually when ready. Flash will not apply until restart.'
}