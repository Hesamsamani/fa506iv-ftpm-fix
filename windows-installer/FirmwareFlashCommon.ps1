# Shared helpers for FA506IV Windows firmware staging/flash
$ErrorActionPreference = 'Stop'

$script:FirmwareGuid = '{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}'
$script:FirmwareGuidUpper = '{1DDCFE17-12C6-5C0A-81A0-DD30045CE6AA}'
$script:OfferedFirmwareVersion = 0x321
$script:StockSha = 'DC7E5984FB4A39DE84204F54F6D8A95B04DFECDF3AA32D45D0AA904272AD3273'
$script:PatchedSha = '37ED09073A01F2C6892603231BC9AB72164734ADD9D1D78A4D58E60E2049C316'
$script:LastAttemptStatusUnsuccessful = 0xC0000001
$script:PayloadVersion = '1.3.1'

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

function Unlock-ProtectedFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    cmd.exe /c "takeown.exe /f `"$Path`" /a" 2>&1 | Out-Null
    cmd.exe /c "icacls.exe `"$Path`" /grant Administrators:F" 2>&1 | Out-Null
    cmd.exe /c "icacls.exe `"$Path`" /grant `"$env:USERNAME`:(F)`"" 2>&1 | Out-Null
    attrib.exe -r -s -h $Path 2>&1 | Out-Null
}

function Copy-ProtectedRom {
    param(
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Source
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source ROM not found: $Source"
    }

    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if (Test-Path -LiteralPath $Destination) {
        Unlock-ProtectedFile -Path $Destination
        Remove-Item -LiteralPath $Destination -Force
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Get-FirmwareRomPaths {
    $firmwareRom = Join-Path $env:windir "Firmware\$($script:FirmwareGuid)\FA506IV.320"
    $driverStoreRom = Get-ChildItem -Path (Join-Path $env:windir 'System32\DriverStore\FileRepository') `
        -Recurse -Filter 'FA506IV.320' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match 'fa506iv_320\.inf_amd64_' } |
        Select-Object -First 1

    [PSCustomObject]@{
        FirmwareRom = $firmwareRom
        DriverStoreRom = if ($driverStoreRom) { $driverStoreRom.FullName } else { $null }
    }
}

function Set-PatchedRomEverywhere {
    param(
        [Parameter(Mandatory)][string]$PatchedSource,
        [string]$ExpectedSha = $script:PatchedSha
    )

    $paths = Get-FirmwareRomPaths
    $targets = @($paths.FirmwareRom)
    if ($paths.DriverStoreRom) {
        $targets += $paths.DriverStoreRom
    }

    foreach ($target in $targets) {
        Write-Host "Staging patched ROM -> $target"
        Copy-ProtectedRom -Destination $target -Source $PatchedSource
        $sha = Get-Sha256Hex ([IO.File]::ReadAllBytes($target))
        if ($sha -ne $ExpectedSha) {
            throw "Patched ROM verification failed for $target (SHA=$sha)"
        }
    }

    return $paths
}

function Set-FirmwareUpdatePending {
    param(
        [int]$OfferedVersion = $script:OfferedFirmwareVersion,
        [string]$Catalog = 'oem96.cat'
    )

    $deviceParams = "HKLM:\SYSTEM\CurrentControlSet\Enum\UEFI\RES_$($script:FirmwareGuidUpper)\0\Device Parameters"
    $firmwareResources = "HKLM:\SYSTEM\CurrentControlSet\Control\FirmwareResources\$($script:FirmwareGuid)"

    if (-not (Test-Path $deviceParams)) {
        throw "Firmware device parameters registry key not found."
    }
    if (-not (Test-Path $firmwareResources)) {
        New-Item -Path $firmwareResources -Force | Out-Null
    }

    New-ItemProperty -Path $deviceParams -Name 'FirmwareVersion' -PropertyType DWord `
        -Value $OfferedVersion -Force | Out-Null
    New-ItemProperty -Path $deviceParams -Name 'FirmwareFilename' -PropertyType String `
        -Value "$($script:FirmwareGuid)\FA506IV.320" -Force | Out-Null
    New-ItemProperty -Path $deviceParams -Name 'FirmwareStatus' -PropertyType DWord `
        -Value 0 -Force | Out-Null

    New-ItemProperty -Path $firmwareResources -Name 'Version' -PropertyType DWord `
        -Value $OfferedVersion -Force | Out-Null
    New-ItemProperty -Path $firmwareResources -Name 'Filename' -PropertyType String `
        -Value "$($script:FirmwareGuid)\FA506IV.320" -Force | Out-Null
    New-ItemProperty -Path $firmwareResources -Name 'Catalog' -PropertyType String `
        -Value $Catalog -Force | Out-Null
    New-ItemProperty -Path $firmwareResources -Name 'Phase' -PropertyType DWord `
        -Value 1 -Force | Out-Null
    New-ItemProperty -Path $firmwareResources -Name 'LastAttemptVersion' -PropertyType DWord `
        -Value 0x320 -Force | Out-Null
    New-ItemProperty -Path $firmwareResources -Name 'LastAttemptStatus' -PropertyType DWord `
        -Value 0 -Force | Out-Null

    Write-Host "Marked firmware update pending: offered version 0x$('{0:X}' -f $OfferedVersion)"
}

function Get-FirmwareResourcesState {
    $resourcesPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FirmwareResources\$($script:FirmwareGuid)"
    $resources = Get-ItemProperty -Path $resourcesPath -ErrorAction SilentlyContinue
    if (-not $resources) {
        return $null
    }

    $lastStatus = if ($null -ne $resources.LastAttemptStatus) { [uint32]$resources.LastAttemptStatus } else { 0 }
    return [PSCustomObject]@{
        Phase = if ($null -ne $resources.Phase) { [int]$resources.Phase } else { $null }
        Version = if ($null -ne $resources.Version) { '0x{0:X}' -f [int]$resources.Version } else { $null }
        LastAttemptVersion = if ($null -ne $resources.LastAttemptVersion) { '0x{0:X}' -f [int]$resources.LastAttemptVersion } else { $null }
        LastAttemptStatus = '0x{0:X}' -f $lastStatus
        LastAttemptFailed = ($lastStatus -eq $script:LastAttemptStatusUnsuccessful)
        Catalog = $resources.Catalog
        Filename = $resources.Filename
    }
}

function Clear-FirmwareUpdateState {
    param(
        [switch]$RestoreStockRom,
        [string]$StockSource
    )

    $resourcesPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FirmwareResources\$($script:FirmwareGuid)"
    $deviceParams = "HKLM:\SYSTEM\CurrentControlSet\Enum\UEFI\RES_$($script:FirmwareGuidUpper)\0\Device Parameters"

    if (Test-Path $resourcesPath) {
        Remove-ItemProperty -Path $resourcesPath -Name 'Phase' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $resourcesPath -Name 'Version' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $resourcesPath -Name 'Filename' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $resourcesPath -Name 'Catalog' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $resourcesPath -Name 'LastAttemptVersion' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $resourcesPath -Name 'LastAttemptStatus' -ErrorAction SilentlyContinue
        Write-Host 'Cleared pending Windows firmware update state.'
    }

    if (Test-Path $deviceParams) {
        New-ItemProperty -Path $deviceParams -Name 'FirmwareVersion' -PropertyType DWord `
            -Value 0x320 -Force | Out-Null
        New-ItemProperty -Path $deviceParams -Name 'FirmwareStatus' -PropertyType DWord `
            -Value 0 -Force | Out-Null
        Write-Host 'Reset offered firmware version to 0x320.'
    }

    if ($RestoreStockRom) {
        if (-not $StockSource -or -not (Test-Path -LiteralPath $StockSource)) {
            throw "Stock ROM source not found: $StockSource"
        }
        $paths = Get-FirmwareRomPaths
        $targets = @($paths.FirmwareRom)
        if ($paths.DriverStoreRom) {
            $targets += $paths.DriverStoreRom
        }
        foreach ($target in $targets) {
            Write-Host "Restoring stock ROM -> $target"
            Copy-ProtectedRom -Destination $target -Source $StockSource
            $sha = Get-Sha256Hex ([IO.File]::ReadAllBytes($target))
            if ($sha -ne $script:StockSha) {
                throw "Stock ROM verification failed for $target (SHA=$sha)"
            }
        }
    }
}

function Test-WindowsEsrtFlashViable {
    [PSCustomObject]@{
        Supported = $false
        Reason = 'Windows ESRT flash validates the ROM against oem96.cat, which only covers the stock ASUS image. Patched ROMs fail at flash time (LastAttemptStatus 0xC0000001). Use EZ Flash USB instead.'
    }
}

function Get-FirmwareFlashStatus {
    param([string]$PatchedSha = $script:PatchedSha)

    $paths = Get-FirmwareRomPaths
    $resources = Get-FirmwareResourcesState
    $status = [ordered]@{
        FirmwareRomPath = $paths.FirmwareRom
        DriverStoreRomPath = $paths.DriverStoreRom
        FirmwareRomSha = $null
        DriverStoreRomSha = $null
        FirmwareRomIsPatched = $false
        DriverStoreRomIsPatched = $false
        DeviceFirmwareVersion = $null
        ResourcesPhase = $null
        ResourcesVersion = $null
        LastAttemptStatus = $null
        LastAttemptFailed = $false
        WindowsFlashFailed = $false
        DeviceProblem = $null
        TpmManufacturerVersion = $null
        RestartPending = $null
        RecommendedFlashMethod = 'EZFlashUSB'
    }

    if ($paths.FirmwareRom -and (Test-Path -LiteralPath $paths.FirmwareRom)) {
        $status.FirmwareRomSha = Get-Sha256Hex ([IO.File]::ReadAllBytes($paths.FirmwareRom))
        $status.FirmwareRomIsPatched = ($status.FirmwareRomSha -eq $PatchedSha)
    }
    if ($paths.DriverStoreRom -and (Test-Path -LiteralPath $paths.DriverStoreRom)) {
        $status.DriverStoreRomSha = Get-Sha256Hex ([IO.File]::ReadAllBytes($paths.DriverStoreRom))
        $status.DriverStoreRomIsPatched = ($status.DriverStoreRomSha -eq $PatchedSha)
    }

    $deviceParams = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\UEFI\RES_$($script:FirmwareGuidUpper)\0\Device Parameters" -ErrorAction SilentlyContinue
    if ($deviceParams) {
        $status.DeviceFirmwareVersion = '0x{0:X}' -f [int]$deviceParams.FirmwareVersion
    }

    if ($resources) {
        $status.ResourcesPhase = $resources.Phase
        $status.ResourcesVersion = $resources.Version
        $status.LastAttemptStatus = $resources.LastAttemptStatus
        $status.LastAttemptFailed = $resources.LastAttemptFailed
        $status.WindowsFlashFailed = (
            $resources.LastAttemptFailed -or
            ($resources.Phase -eq 2 -and -not $status.FirmwareRomIsPatched)
        )
    }

    $dev = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like "*$($script:FirmwareGuidUpper)*" } | Select-Object -First 1
    if ($dev) {
        $status.DeviceProblem = $dev.Problem
    }

    try {
        $tpm = Get-Tpm -ErrorAction Stop
        $status.TpmManufacturerVersion = $tpm.ManufacturerVersion
        $status.RestartPending = $tpm.RestartPending
    } catch {
        $status.TpmManufacturerVersion = '(admin required)'
    }

    return [PSCustomObject]$status
}

function Get-SystemFirmwareInfName {
    foreach ($driver in Get-CimInstance Win32_PnPSignedDriver) {
        if ($driver.CompatID -eq 'UEFI\CC_00010001') {
            return $driver.InfName
        }
    }
    return $null
}