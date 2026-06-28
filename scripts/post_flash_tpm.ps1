#Requires -RunAsAdministrator
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

$tpm = Get-Tpm
Write-Host "TpmPresent:       $($tpm.TpmPresent)"
Write-Host "TpmReady:         $($tpm.TpmReady)"
Write-Host "RestartPending:   $($tpm.RestartPending)"
Write-Host "ManufacturerVer:  $($tpm.ManufacturerVersion)"

if (-not $tpm.TpmPresent) {
    throw 'TPM not detected. Enable AMD fTPM in BIOS (F2), then rerun this script.'
}

Write-Host ''
Write-Host 'Clearing TPM so the new fTPM trustlet version is picked up...'
Clear-Tpm

Write-Host ''
Write-Host 'TPM cleared. A reboot is required.'
$answer = Read-Host 'Reboot now? (Y/N)'
if ($answer -match '^[Yy]') {
    shutdown.exe /r /t 15 /c 'FA506IV fTPM fix: completing TPM re-provision after BIOS flash.'
} else {
    Write-Host 'Reboot manually, then rerun Call of Duty Secure Attestation Wizard.'
}