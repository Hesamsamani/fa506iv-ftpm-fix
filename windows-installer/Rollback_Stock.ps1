#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$FirmwareGuid = '{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}'
$FirmwareRom = Join-Path $env:windir "Firmware\$FirmwareGuid\FA506IV.320"
$StockSource = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'FA506IV.320.STOCK'
$StockSha = 'DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273'

function Get-Sha256Hex([byte[]]$Bytes) {
    [BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash($Bytes)
    ).Replace('-', '')
}

if (-not (Test-Path $StockSource)) { throw 'FA506IV.320.STOCK not found.' }
$stockBytes = [IO.File]::ReadAllBytes($StockSource)
if ((Get-Sha256Hex $stockBytes) -ne $StockSha) { throw 'Stock ROM SHA mismatch.' }

$infFile = Get-ChildItem -Path (Join-Path (Split-Path $StockSource -Parent) 'Cabfile\*.inf') | Select-Object -First 1
$SystemFirmware = (Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.CompatID -eq 'UEFI\CC_00010001' } | Select-Object -First 1).InfName

Write-Host 'Reinstalling signed stock firmware package...'
cmd.exe /c "pnputil.exe /delete-driver $SystemFirmware /uninstall /force" | Write-Host
cmd.exe /c "pnputil.exe /add-driver `"$($infFile.FullName)`" /install" | Write-Host

Copy-Item -Path $StockSource -Destination $FirmwareRom -Force
Write-Host 'Stock ROM staged. Reboot to restore original BIOS.'
$answer = Read-Host 'Reboot now? (Y/N)'
if ($answer -match '^[Yy]') {
    shutdown.exe /r /t 15 /c 'Restoring stock ASUS FA506IV.320 BIOS on restart.'
}