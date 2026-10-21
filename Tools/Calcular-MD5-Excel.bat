@echo off
setlocal EnableExtensions

rem ================================================================

rem ================================================================

set "ROOT=%~dp0"

echo Unblocking files / Desbloqueando archivos...
powershell -NoLogo -NoProfile -Command "Get-ChildItem -LiteralPath '%ROOT%' -Recurse -File | Unblock-File" >nul 2>nul

where pwsh >nul 2>nul
if %errorlevel%==0 (
    set "PWSH_EXE=pwsh"
) else if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
    set "PWSH_EXE=%ProgramFiles%\PowerShell\7\pwsh.exe"
) else (
    echo.
    echo [EN] PowerShell 7 was not found on this computer.
    echo      Download it from: https://github.com/PowerShell/PowerShell/releases
    echo.
    echo [ES] No se ha encontrado PowerShell 7 en este equipo.
    echo      Descargalo desde: https://github.com/PowerShell/PowerShell/releases
    echo.
    pause
    exit /b 1
)

"%PWSH_EXE%" -NoLogo -ExecutionPolicy Bypass -File "%ROOT%Calcular-MD5-Excel.ps1"
set "EXITCODE=%errorlevel%"


if not "%EXITCODE%"=="0" (
    echo.
    echo [EN] The program ended with an error ^(code %EXITCODE%^).
    echo [ES] El programa termino con un error ^(codigo %EXITCODE%^).
    echo.
    pause
)

exit /b %EXITCODE%
