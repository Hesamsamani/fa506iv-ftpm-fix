# Build FA506IV_fTPM_Fix GUI single-file EXE with embedded payload
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$guiDir = Join-Path $repo 'gui'
$proj = Join-Path $guiDir 'FA506IV.FTPMFix.Gui\FA506IV.FTPMFix.Gui.csproj'
$payloadZip = Join-Path $repo 'gui-payload.zip'
$wizardCandidates = @(
    (Join-Path $repo 'tools\CODSecureAttestationWizard.exe'),
    'C:\Users\hesam\Downloads\bios-tpm-work\attestation-wizard\CODSecureAttestationWizard.exe'
)
$wizardSrc = $wizardCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
$staging = Join-Path $env:TEMP "fa506iv-gui-payload-$([Guid]::NewGuid().ToString('N'))"
$outDir = Join-Path $repo 'output'
$outExe = Join-Path $outDir 'FA506IV_fTPM_Fix_GUI.exe'

function Ensure-Cabfile([string]$InstallerDir) {
    $cab = Join-Path $InstallerDir 'Cabfile'
    if (-not (Test-Path $cab)) {
        New-Item -ItemType Directory -Path $cab -Force | Out-Null
        Copy-Item (Join-Path $InstallerDir 'Cabfile_FA506IV.320') (Join-Path $cab 'FA506IV.320') -Force
        Copy-Item (Join-Path $InstallerDir 'Cabfile_FA506IV_320.cat') (Join-Path $cab 'FA506IV_320.cat') -Force
        Copy-Item (Join-Path $InstallerDir 'Cabfile_FA506IV_320.inf') (Join-Path $cab 'FA506IV_320.inf') -Force
    }
}

Write-Host 'Staging GUI payload...'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

$wi = Join-Path $repo 'windows-installer'
Ensure-Cabfile $wi
Copy-Item $wi (Join-Path $staging 'windows-installer') -Recurse -Force

$scripts = Join-Path $staging 'scripts'
New-Item -ItemType Directory -Path $scripts -Force | Out-Null
$scriptFiles = @(
    'gui_status.ps1',
    'gui_attestation_check.ps1',
    'verify_flash_status.ps1',
    'post_flash_tpm.ps1',
    'Repair_FirmwareFlash.ps1',
    'Cleanup_FailedFirmwareFlash.ps1',
    'Prepare_EZFlash_USB.ps1',
    'FirmwareFlashCommon.ps1'
)
foreach ($f in $scriptFiles) {
    if ($f -eq 'FirmwareFlashCommon.ps1') {
        $src = Join-Path (Join-Path $repo 'windows-installer') $f
    } else {
        $src = Join-Path (Join-Path $repo 'scripts') $f
    }
    if (-not (Test-Path $src)) { throw "Missing $src" }
    Copy-Item $src (Join-Path $scripts $f) -Force
}

$tools = Join-Path $staging 'tools'
New-Item -ItemType Directory -Path $tools -Force | Out-Null
if ($wizardSrc) {
    Write-Host "Bundling COD Secure Attestation Wizard v1.0.5 from $wizardSrc ..."
    Copy-Item $wizardSrc (Join-Path $tools 'CODSecureAttestationWizard.exe') -Force
} else {
    Write-Warning 'COD wizard not found - GUI will link to Activision download page.'
}

if (Test-Path $payloadZip) { Remove-Item $payloadZip -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $payloadZip -CompressionLevel Optimal
Remove-Item $staging -Recurse -Force

$zipSize = (Get-Item $payloadZip).Length
Write-Host ('Payload zip: {0} ({1} bytes)' -f $payloadZip, $zipSize)

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'dotnet SDK not found. Install .NET 8 SDK.'
}

Write-Host 'Publishing GUI...'
dotnet publish $proj -c Release -o (Join-Path $guiDir 'publish') | Write-Host
if ($LASTEXITCODE -ne 0) { throw 'dotnet publish failed' }

$published = Join-Path $guiDir 'publish\FA506IV_fTPM_Fix.exe'
if (-not (Test-Path $published)) {
    throw "Published exe not found: $published"
}

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
Copy-Item $published $outExe -Force

$hash = (Get-FileHash $outExe -Algorithm SHA256).Hash
Write-Host ''
Write-Host "Built: $outExe"
Write-Host "SHA-256: $hash"
$exeSize = (Get-Item $outExe).Length
Write-Host ('Size: {0} bytes' -f $exeSize)