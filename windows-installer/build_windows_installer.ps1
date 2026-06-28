# Build FA506IV_fTPM_fix_Windows.exe using 7-Zip SFX
$ErrorActionPreference = 'Stop'

$sevenZip = 'C:\Program Files\7-Zip\7z.exe'
$sfx = 'C:\Program Files\7-Zip\7z.sfx'
$repo = Split-Path -Parent $PSScriptRoot
$pkg = Join-Path $repo 'windows-installer'
$archive = Join-Path $repo 'output\FA506IV_fTPM_fix_Windows.7z'
$outExe = Join-Path $repo 'output\FA506IV_fTPM_fix_Windows.exe'
$config = Join-Path $pkg 'config.txt'

foreach ($path in @($sevenZip, $sfx, $pkg, $config)) {
    if (-not (Test-Path $path)) { throw "Missing required path: $path" }
}

if (Test-Path $archive) { Remove-Item $archive -Force }
if (Test-Path $outExe) { Remove-Item $outExe -Force }

& $sevenZip a -t7z -mx=5 $archive "$pkg\*" "-xr!Cabfile" "-xr!config.txt" | Out-Host
if ($LASTEXITCODE -ne 0) { throw '7z archive creation failed' }

$sfxBytes = [IO.File]::ReadAllBytes($sfx)
$configBytes = [Text.Encoding]::UTF8.GetBytes((Get-Content $config -Raw))
$archiveBytes = [IO.File]::ReadAllBytes($archive)

$outStream = [IO.File]::Open($outExe, [IO.FileMode]::CreateNew)
try {
    $outStream.Write($sfxBytes, 0, $sfxBytes.Length)
    $outStream.Write($configBytes, 0, $configBytes.Length)
    $outStream.Write($archiveBytes, 0, $archiveBytes.Length)
}
finally {
    $outStream.Close()
}

$hash = (Get-FileHash $outExe -Algorithm SHA256).Hash
Write-Host "Built: $outExe"
Write-Host "SHA-256: $hash"
Write-Host "Size: $((Get-Item $outExe).Length) bytes"