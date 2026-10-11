@echo off
setlocal EnableExtensions

rem ================================================================
rem  CleanROMs launcher / Lanzador de CleanROMs
rem
rem  [EN] Double-click this file instead of main.ps1 the first time.
rem       Windows marks every file inside a downloaded/unzipped
rem       folder as "blocked" (Internet zone), and PowerShell's
rem       default policy then refuses to run main.ps1 with:
rem         "File ... is not digitally signed. You cannot run this
rem          script on the current system."
rem       This launcher removes that block from every file in this
rem       folder (Unblock-File) and starts main.ps1 with
rem       -ExecutionPolicy Bypass, so it works on the very first run
rem       with no extra steps.
rem
rem  [ES] Haz doble clic en este archivo en vez de en main.ps1 la
rem       primera vez. Windows marca como "bloqueado" (zona de
rem       Internet) cada archivo dentro de una carpeta descargada o
rem       descomprimida, y la politica por defecto de PowerShell
rem       entonces se niega a ejecutar main.ps1 con el error:
rem         "El archivo ... no esta firmado digitalmente. No se
rem          puede ejecutar el script en el sistema actual."
rem       Este lanzador quita ese bloqueo de todos los archivos de
rem       esta carpeta (Unblock-File) y arranca main.ps1 con
rem       -ExecutionPolicy Bypass, asi que funciona a la primera sin
rem       pasos extra.
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

"%PWSH_EXE%" -NoLogo -ExecutionPolicy Bypass -File "%ROOT%main.ps1"

echo.
pause
