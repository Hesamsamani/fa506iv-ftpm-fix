#Requires -RunAsAdministrator
<#
One-shot repair for systems that already ran v1.1 installer:
- patch DriverStore ROM
- mark firmware update pending at version 0x321
Does not reinstall pnputil unless -ReinstallDriver is passed.
#>

param(
    [switch]$ReinstallDriver,
    [switch]$NonInteractive,
    [switch]$SkipReboot
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

$patchedSource = Join-Path $wi 'FA506IV.320.PATCHED'
if (-not (Test-Path $patchedSource)) {
    $patchedSource = Join-Path $repo 'output\FA506IV.320'
}
if (-not (Test-Path $patchedSource)) {
    throw 'Patched ROM not found.'
}

Write-Host 'FA506IV fTPM fix — firmware flash repair (v1.2)'
Write-Host '================================================'
Write-Host 'Before:'
Get-FirmwareFlashStatus | Format-List *

if ($ReinstallDriver) {
    $cabDir = Join-Path $wi 'Cabfile'
    if (-not (Test-Path $cabDir)) {
        New-Item -ItemType Directory -Path $cabDir -Force | Out-Null
        Copy-Item (Join-Path $wi 'Cabfile_FA506IV.320') (Join-Path $cabDir 'FA506IV.320') -Force
        Copy-Item (Join-Path $wi 'Cabfile_FA506IV_320.cat') (Join-Path $cabDir 'FA506IV_320.cat') -Force
        Copy-Item (Join-Path $wi 'Cabfile_FA506IV_320.inf') (Join-Path $cabDir 'FA506IV_320.inf') -Force
    }
    $infFile = Get-ChildItem -Path (Join-Path $cabDir '*.inf') -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $infFile) {
        $infFile = Get-Item (Join-Path $wi 'Cabfile_FA506IV_320.inf')
    }
    $systemFirmware = Get-SystemFirmwareInfName
    if ($systemFirmware) {
        Write-Host "Reinstalling firmware driver via $($infFile.FullName)..."
        cmd.exe /c "pnputil.exe /delete-driver $systemFirmware /uninstall /force" 2>&1 | ForEach-Object { Write-Host $_ }
        cmd.exe /c "pnputil.exe /add-driver `"$($infFile.FullName)`" /install" 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            throw "pnputil install failed with exit code $LASTEXITCODE"
        }
    }
}

Set-PatchedRomEverywhere -PatchedSource $patchedSource | Out-Null
$installedInf = Get-SystemFirmwareInfName
$catalog = if ($installedInf) { [IO.Path]::ChangeExtension($installedInf, '.cat') } else { 'oem96.cat' }
Set-FirmwareUpdatePending -OfferedVersion $OfferedFirmwareVersion -Catalog $catalog

Write-Host ''
Write-Host 'After:'
Get-FirmwareFlashStatus | Format-List *

Write-Host 'Repair complete (staging only).'
Write-Host 'Do NOT use /fw — use EZ Flash USB to apply the patched ROM.'
Write-Host (Test-WindowsEsrtFlashViable).Reason