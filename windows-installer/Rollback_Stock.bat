@echo off
setlocal
echo ASUS FA506IV fTPM Fix - Rollback to stock BIOS
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

pushd "%~dp0"
if not exist Cabfile mkdir Cabfile
if exist "%~dp0Cabfile_FA506IV.320" copy /Y "%~dp0Cabfile_FA506IV.320" "%~dp0Cabfile\FA506IV.320" >nul
if exist "%~dp0Cabfile_FA506IV_320.cat" copy /Y "%~dp0Cabfile_FA506IV_320.cat" "%~dp0Cabfile\FA506IV_320.cat" >nul
if exist "%~dp0Cabfile_FA506IV_320.inf" copy /Y "%~dp0Cabfile_FA506IV_320.inf" "%~dp0Cabfile\FA506IV_320.inf" >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rollback_Stock.ps1"
popd
pause