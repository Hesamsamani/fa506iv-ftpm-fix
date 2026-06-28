#Requires -RunAsAdministrator
<#
Reads TPM / attestation signals used by Call of Duty Secure Attestation Wizard.
Outputs JSON for the GUI dashboard.
#>
param()

$ErrorActionPreference = 'Stop'

function Get-LatestTpmHealthEvent {
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Microsoft-Windows-TPM-WMI'
        Id = 1041
    } -MaxEvents 1 -ErrorAction SilentlyContinue
    if (-not $events) { return $null }
    $msg = $events[0].Message
    $jsonStart = $msg.IndexOf('{')
    if ($jsonStart -lt 0) { return @{ RawMessage = $msg } }
    try {
        return ($msg.Substring($jsonStart) | ConvertFrom-Json)
    } catch {
        return @{ RawMessage = $msg; ParseError = $_.Exception.Message }
    }
}

$tpm = $null
$secureBoot = $null
try {
    Import-Module TrustedPlatformModule -ErrorAction Stop
    $t = Get-Tpm
    $tpm = [ordered]@{
        Present = $t.TpmPresent
        Ready = $t.TpmReady
        Enabled = $t.TpmEnabled
        Activated = $t.TpmActivated
        Owned = $t.TpmOwned
        RestartPending = $t.RestartPending
        ManufacturerVersion = [string]$t.ManufacturerVersion
        ManufacturerId = [string]$t.ManufacturerIdTxt
        SpecVersion = [string]$t.SpecVersion
    }
} catch {
    $tpm = @{ Error = $_.Exception.Message }
}

try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    $secureBoot = [ordered]@{
        Enabled = ($sb -eq $true)
        State = [string]$sb
    }
} catch {
    $secureBoot = @{ Error = $_.Exception.Message }
}

$health = Get-LatestTpmHealthEvent
$badTpmPattern = ($tpm.ManufacturerVersion -match '^3\.\d+\.0\.')

$checks = [ordered]@{
    Tpm20Present = [bool]$tpm.Present
    TpmReady = [bool]$tpm.Ready
    SecureBootOn = [bool]$secureBoot.Enabled
    ManufacturerVersionOk = (-not $badTpmPattern -and [bool]$tpm.ManufacturerVersion)
    NotRestartPending = (-not [bool]$tpm.RestartPending)
}

$failures = @()
if (-not $checks.Tpm20Present) { $failures += 'TPM 2.0 not present' }
if (-not $checks.TpmReady) { $failures += 'TPM not ready' }
if (-not $checks.SecureBootOn) { $failures += 'Secure Boot disabled' }
if (-not $checks.ManufacturerVersionOk) {
    $failures += "AMD fTPM version $($tpm.ManufacturerVersion) matches bad 3.*.0.* pattern (PA-420)"
}
if (-not $checks.NotRestartPending) { $failures += 'TPM RestartPending is true — reboot required' }

$wizardLikelyPass = ($failures.Count -eq 0)
if ($health -and $health.HealthStatus) {
    $okHealth = @('Attestation passed', 'Healthy', 'Attestable')
    if ($okHealth -notcontains $health.HealthStatus) {
        $wizardLikelyPass = $false
        $failures += "Windows TPM health: $($health.HealthStatus)"
    }
}

$result = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    WizardVersion = '1.0.5'
    WizardDownloadUrl = 'https://storage.googleapis.com/atvi-support-psapi-prod/CODSecureAttestationWizard_1.0.5.zip'
    Tpm = $tpm
    SecureBoot = $secureBoot
    WindowsTpmHealthEvent = $health
    Checks = $checks
    Failures = $failures
    CodWizardLikelyPass = $wizardLikelyPass
    Summary = if ($wizardLikelyPass) {
        'System likely passes Call of Duty Secure Attestation Wizard checks.'
    } else {
        'System may fail Call of Duty attestation: ' + ($failures -join '; ')
    }
}

$result | ConvertTo-Json -Depth 8 -Compress