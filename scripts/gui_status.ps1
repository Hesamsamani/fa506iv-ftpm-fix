#Requires -RunAsAdministrator
<# Outputs machine-readable JSON for the GUI dashboard. #>
param()

$ErrorActionPreference = 'Stop'

$localCommon = Join-Path $PSScriptRoot '..\windows-installer\FirmwareFlashCommon.ps1'
$standaloneCommon = Join-Path $PSScriptRoot 'FirmwareFlashCommon.ps1'
$common = if (Test-Path $standaloneCommon) { $standaloneCommon } else { $localCommon }
. $common

$model = (Get-CimInstance Win32_ComputerSystem).Model
$bios = (Get-CimInstance Win32_BIOS).SMBIOSBIOSVersion
$flash = Get-FirmwareFlashStatus

$tpm = $null
try {
    Import-Module TrustedPlatformModule -ErrorAction Stop
    $t = Get-Tpm
    $tpm = [ordered]@{
        Present = $t.TpmPresent
        Ready = $t.TpmReady
        RestartPending = $t.RestartPending
        ManufacturerVersion = [string]$t.ManufacturerVersion
        ManufacturerId = [string]$t.ManufacturerIdTxt
    }
} catch {
    $tpm = @{ Error = $_.Exception.Message }
}

$payload = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    IsAdmin = Test-Administrator
    Model = $model
    BiosVersion = $bios
    ModelSupported = ($model -match 'FA506IV')
    BiosSupported = ($bios -match '320')
    Tpm = $tpm
    Flash = [ordered]@{
        FirmwareRomIsPatched = $flash.FirmwareRomIsPatched
        DriverStoreRomIsPatched = $flash.DriverStoreRomIsPatched
        DeviceFirmwareVersion = $flash.DeviceFirmwareVersion
        ResourcesPhase = $flash.ResourcesPhase
        ResourcesVersion = $flash.ResourcesVersion
        LastAttemptStatus = $flash.LastAttemptStatus
        LastAttemptFailed = $flash.LastAttemptFailed
        WindowsFlashFailed = $flash.WindowsFlashFailed
        DeviceProblem = $flash.DeviceProblem
        RecommendedFlashMethod = $flash.RecommendedFlashMethod
        WindowsEsrtViable = (Test-WindowsEsrtFlashViable).Supported
        TpmStillBad = ($tpm.ManufacturerVersion -eq '3.42.0.5')
        ReadyForEzFlash = ($tpm.ManufacturerVersion -eq '3.42.0.5')
        ReadyForPostFlash = (
            $tpm.ManufacturerVersion -and
            $tpm.ManufacturerVersion -ne '3.42.0.5'
        )
        NeedsCleanup = $flash.WindowsFlashFailed
    }
    PayloadVersion = $PayloadVersion
}

$payload | ConvertTo-Json -Depth 6 -Compress