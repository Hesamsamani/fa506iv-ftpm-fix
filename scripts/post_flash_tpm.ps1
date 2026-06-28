#Requires -RunAsAdministrator
param(
    [switch]$NonInteractive,
    [switch]$ForceClear,
    [switch]$SkipReboot
)
<#
After flashing FA506IV fTPM fix v3:
1. Confirm TPM is present
2. Clear TPM so Windows reloads fTPM firmware version from BIOS
3. Reboot
#>
$ErrorActionPreference = 'Stop'

Write-Host 'FA506IV fTPM fix — post-flash TPM reset'
Write-Host '========================================'

try {
    Import-Module TrustedPlatformModule -ErrorAction Stop
} catch {
    Write-Warning 'TrustedPlatformModule module unavailable. Open tpm.msc manually.'
}

$localCommon = Join-Path $PSScriptRoot 'FirmwareFlashCommon.ps1'
$repoCommon = Join-Path (Split-Path $PSScriptRoot -Parent) 'windows-installer\FirmwareFlashCommon.ps1'
$common = if (Test-Path $localCommon) { $localCommon } elseif (Test-Path $repoCommon) { $repoCommon } else { $null }
if ($common) {
    . $common
    Write-Host 'Flash staging status:'
    Get-FirmwareFlashStatus | Format-List FirmwareRomIsPatched, DriverStoreRomIsPatched, DeviceFirmwareVersion, ResourcesPhase, DeviceProblem
    Write-Host ''
}

$tpm = Get-Tpm
Write-Host "TpmPresent:       $($tpm.TpmPresent)"
Write-Host "TpmReady:         $($tpm.TpmReady)"
Write-Host "RestartPending:   $($tpm.RestartPending)"
Write-Host "ManufacturerVer:  $($tpm.ManufacturerVersion)"

if (-not $tpm.TpmPresent) {
    throw 'TPM not detected. Enable AMD fTPM in BIOS (F2), then rerun this script.'
}

if ($tpm.ManufacturerVersion -eq '3.42.0.5' -and -not $ForceClear) {
    Write-Warning 'TPM still reports 3.42.0.5. The BIOS flash likely did not apply yet.'
    if ($NonInteractive) {
        throw 'TPM still 3.42.0.5. Run Repair + firmware reboot (/fw) before clearing TPM.'
    }
    Write-Warning 'Run scripts\Repair_FirmwareFlash.ps1, reboot fully, then rerun this script.'
    $continue = Read-Host 'Clear TPM anyway? (Y/N)'
    if ($continue -notmatch '^[Yy]') {
        throw 'Aborted. Fix firmware flash first (Install.bat v1.2 or Repair_FirmwareFlash.ps1).'
    }
}

Write-Host ''
Write-Host 'Clearing TPM so the new fTPM trustlet version is picked up...'
Clear-Tpm

Write-Host ''
Write-Host 'TPM cleared. A reboot is required.'
if ($NonInteractive -and -not $SkipReboot) {
    shutdown.exe /r /t 60 /c 'FA506IV fTPM fix: completing TPM re-provision after BIOS flash.'
    Write-Host 'Reboot scheduled in 60 seconds.'
} elseif (-not $NonInteractive) {
    $answer = Read-Host 'Reboot now? (Y/N)'
    if ($answer -match '^[Yy]') {
        shutdown.exe /r /t 15 /c 'FA506IV fTPM fix: completing TPM re-provision after BIOS flash.'
    } else {
        Write-Host 'Reboot manually, then rerun Call of Duty Secure Attestation Wizard.'
    }
}