#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$rom = 'C:\Windows\Firmware\{1ddcfe17-12c6-5c0a-81a0-dd30045ce6aa}\FA506IV.320'
if (-not (Test-Path -LiteralPath $rom)) {
    Write-Host 'No staged ROM present — run Install.bat through step 2 first.'
    exit 0
}
$tmp = Join-Path $env:TEMP 'fa506iv_rom_acl_test.bin'
Copy-Item -LiteralPath $rom -Destination $tmp -Force
Write-Host 'Read backup OK'
cmd.exe /c "takeown.exe /f `"$rom`" /a"
cmd.exe /c "icacls.exe `"$rom`" /grant Administrators:F"
$bytes = [IO.File]::ReadAllBytes($tmp)
[IO.File]::WriteAllBytes($rom, $bytes)
Write-Host 'ACL fix test: WRITE OK'