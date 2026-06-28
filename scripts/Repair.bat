@echo off
setlocal
echo FA506IV fTPM Fix - Firmware Flash Repair v1.2
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_FirmwareFlash.ps1" -ReinstallDriver
set ERR=%errorLevel%
popd
if not "%ERR%"=="0" (
    echo.
    echo REPAIR FAILED. See messages above.
    pause
    exit /b %ERR%
)
echo.
echo Repair OK. Reboot fully, then run verify_flash_status.ps1
pause