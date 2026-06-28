#Requires -RunAsAdministrator
<#
Diagnose FA506IV fTPM BIOS patch status.
Exit 0 = clear next step (EZ Flash, COD wizard, or post-flash TPM).
Exit 1 = action required.
#>

$ErrorActionPreference = 'Stop'
$localCommon = Join-Path $PSScriptRoot 'FirmwareFlashCommon.ps1'
$repoCommon = Join-Path (Split-Path $PSScriptRoot -Parent) 'windows-installer\FirmwareFlashCommon.ps1'
$common = if (Test-Path $localCommon) { $localCommon } else { $repoCommon }
if (-not (Test-Path $common)) {
    throw "Missing FirmwareFlashCommon.ps1"
}
. $common

Write-Host 'FA506IV fTPM fix - flash status'
Write-Host '================================'
$status = Get-FirmwareFlashStatus
$status | Format-List *

$esrt = Test-WindowsEsrtFlashViable
$tpmStillStock = ($status.TpmManufacturerVersion -eq '3.42.0.5')
$tpmFlashed = (-not $tpmStillStock -and $status.TpmManufacturerVersion -and $status.TpmManufacturerVersion -ne '(admin required)')

if ($status.WindowsFlashFailed) {
    Write-Host ''
    Write-Host 'FAILED: Windows firmware update did not flash the patched ROM.'
    if ($status.LastAttemptStatus) {
        Write-Host "LastAttemptStatus: $($status.LastAttemptStatus) (0xC0000001 = catalog rejected patched image)"
    }
    if ($status.ResourcesPhase -eq 2) {
        Write-Host 'ResourcesPhase: 2 (flash attempt completed unsuccessfully)'
    }
    if (-not $status.FirmwareRomSha) {
        Write-Host 'Staged ROM was removed from C:\Windows\Firmware after the failed attempt.'
    }
    Write-Host ''
    Write-Host 'WHY: The signed catalog (oem96.cat) only covers the stock ASUS ROM.'
    Write-Host '     Patched ROMs cannot be applied via shutdown /r /fw on FA506IV.'
    Write-Host ''
    Write-Host 'FIX:'
    Write-Host '  1. Run Cleanup failed Windows flash (GUI or Cleanup_FailedFirmwareFlash.ps1)'
    Write-Host '  2. Prepare EZ Flash USB and flash FA506IV.320 from BIOS (F2 -> EZ Flash 3)'
    Write-Host '  3. If EZ Flash rejects the file, run COD attestation pre-check — it may already pass'
    exit 1
}

if ($tpmFlashed) {
    Write-Host ''
    Write-Host 'SUCCESS: TPM version changed to' $status.TpmManufacturerVersion
    Write-Host 'Next: Clear TPM in the GUI, reboot, then run COD attestation pre-check.'
    exit 0
}

if ($tpmStillStock) {
    Write-Host ''
    Write-Host 'TPM is still 3.42.0.5 — hardware BIOS has not been patched yet.'
    Write-Host "Recommended flash method: $($status.RecommendedFlashMethod)"
    Write-Host ''
    Write-Host 'Do NOT use Windows /fw reboot for this patch.'
    Write-Host $esrt.Reason
    Write-Host ''
    Write-Host 'Next: Prepare EZ Flash USB -> reboot F2 -> ASUS EZ Flash 3 -> FA506IV.320'
    exit 1
}

Write-Host ''
Write-Host 'Status unclear. Run Cleanup, prepare EZ Flash USB, or try COD attestation pre-check.'
exit 1