# ============================================================
# Beta CleanROMs v2.6
#
# Main.ps1
# ============================================================
param(

    #
    # Carpeta del sistema a procesar (el nombre de carpeta tal
    # cual, p.ej. "snes", "gba", "megadrive"), o "ALL"/vacío para
    # todos los sistemas configurados. Si no se indica, el
    # programa muestra el menú interactivo de siempre.
    #

    [string]$System = $null,

    #
    # Qué hacer, sin pasar por el menú interactivo:
    #   Clean   -> igual que la opción 1 (limpiar ROMs duplicadas
    #              + organizar hacks)
    #   Orphans -> igual que la opción 3 (huérfanos)
    #   All     -> igual que la opción 4 (todo)
    #   Undo    -> igual que la opción 2 (deshacer la última
    #              limpieza; -System se ignora en este caso)
    #
    # Si no se indica ningún valor, se ignoran también -System,
    # -Yes y -PreviewOnly, y el programa arranca exactamente igual
    # que siempre (menú interactivo).
    #

    [ValidateSet("Clean", "Orphans", "All", "Undo")]
    [string]$Action = $null,

    #
    # Confirma automáticamente todas las preguntas S/N (pensado
    # para tareas programadas, donde no hay nadie delante para
    # responder). Sin esto, aunque uses -Action, el programa
    # seguiría preguntando igual que siempre.
    #

    [switch]$Yes,

    #
    # Fuerza el modo simulación para esta ejecución concreta, sin
    # tener que editar Config\Settings.ps1. Útil para probar una
    # tarea programada nueva antes de dejar que mueva archivos de
    # verdad.
    #

    [switch]$PreviewOnly

)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

#=========================================================
# Configuración
#=========================================================

. "$Root\Config\Settings.ps1"
. "$Root\Config\Strings.ps1"
. "$Root\Config\DecisionWeights.ps1"

#
# Se fija ANTES de Initialize-Language / Initialize-RetroBatRoot
# (que vienen justo debajo) para que, si es la primera vez que se
# ejecuta el programa con -Yes y todavía no hay nada configurado,
# esas dos funciones sepan que no deben quedarse esperando una
# respuesta que nadie va a dar.
#

$Global:AutoConfirm = [bool]$Yes

Initialize-Language -Root $Root
Initialize-RetroBatRoot -Root $Root

if($PreviewOnly)
{
    $Global:Settings.PreviewOnly = $true
}

if($Global:AutoConfirm -and [string]::IsNullOrWhiteSpace($Global:RetroBatRoot))
{
    #
    # Modo no interactivo y no se pudo resolver ninguna ruta de
    # RetroBat válida (primera ejecución, sin Config\UserSettings.json,
    # y la carpeta sugerida por defecto tampoco existe). No hay
    # ninguna respuesta segura que adivinar aquí, así que se para
    # con un error claro en vez de quedarse esperando para siempre.
    #

    Write-Host (T "cli.rootNotConfigured") -ForegroundColor Red
    Write-Host (T "cli.usageHint")
    exit 1
}

#=========================================================
# Módulos
#=========================================================

. "$Root\Modules\Menu.ps1"
. "$Root\Modules\Logger.ps1"
. "$Root\Modules\RomParser.ps1"
. "$Root\Modules\RomScanner.ps1"
. "$Root\Modules\TitleNormalizer.ps1"
. "$Root\Modules\Grouper.ps1"
. "$Root\Modules\DecisionEngine.ps1"
. "$Root\Modules\Cleaner.ps1"
. "$Root\Modules\Summary.ps1"
. "$Root\Modules\Executor.ps1"
. "$Root\Modules\AssetMover.ps1"
. "$Root\Modules\UndoManager.ps1"
. "$Root\Modules\MediaCleaner.ps1"
. "$Root\Modules\HackOrganizer.ps1"



#--------------------------------------------------------------
# Inicio
#--------------------------------------------------------------

Start-Log $Root

try
{

if(![string]::IsNullOrWhiteSpace($Action))
{
    #--------------------------------------------------------------
    # Modo no interactivo (-Action indicado por línea de comandos)
    #
    # Pensado para tareas programadas: hace exactamente lo mismo
    # que la opción de menú equivalente, pero sin mostrar el menú
    # ni quedarse esperando ninguna tecla al final.
    #--------------------------------------------------------------

    $systemFolders = @()

    if($Action -ne "Undo")
    {
        if([string]::IsNullOrWhiteSpace($System) -or $System -ieq "ALL")
        {
            $systemFolders = @(
                Get-SupportedSystems | ForEach-Object { Get-SystemFolder $_ }
            )
        }
        else
        {
            $resolved = Resolve-SystemFolderArgument -System $System

            if($null -eq $resolved)
            {
                Write-Host (T "cli.unknownSystem" $System) -ForegroundColor Red
                Write-Host (T "cli.usageHint")
                Stop-Log
                exit 1
            }

            $systemFolders = @($resolved)
        }
    }

    switch($Action)
    {
        "Clean"
        {
            Invoke-RomCleaning -Root $Root -SystemFolders $systemFolders
            Invoke-HackOrganizer -Root $Root -SystemFolders $systemFolders
        }

        "Orphans"
        {
            Invoke-OrphanedMediaCleanup -SystemFolders $systemFolders
        }

        "All"
        {
            Invoke-RomCleaning -Root $Root -SystemFolders $systemFolders
            Invoke-OrphanedMediaCleanup -SystemFolders $systemFolders
            Invoke-HackOrganizer -Root $Root -SystemFolders $systemFolders
        }

        "Undo"
        {
            Invoke-UndoLastPlan -Root $Root
        }
    }

    Stop-Log
    exit 0
}

:mainLoop
while($true)
{

Show-Banner

$mainAction = Select-MainAction

if($mainAction -eq 6)
{
    break mainLoop
}

switch($mainAction)
{

    1
    {
        $system = Select-System

        if($system -eq "__NONE__")
        {
            continue mainLoop
        }

        if($system -eq "__ALL__")
        {
            $systemFolders = @(
                Get-SupportedSystems | ForEach-Object { Get-SystemFolder $_ }
            )
        }
        else
        {
            $systemFolders = @(Get-SystemFolder $system)
        }

        Invoke-RomCleaning -Root $Root -SystemFolders $systemFolders

        Invoke-HackOrganizer -Root $Root -SystemFolders $systemFolders
    }

    2
    {
        Invoke-UndoLastPlan -Root $Root
    }

    3
    {
        Write-Host ""

        $system = Select-System

        if($system -eq "__NONE__")
        {
            continue mainLoop
        }

        if($system -eq "__ALL__")
        {
            $systemFolders = @(
                Get-SupportedSystems | ForEach-Object { Get-SystemFolder $_ }
            )
        }
        else
        {
            $systemFolders = @(Get-SystemFolder $system)
        }

        Invoke-OrphanedMediaCleanup -SystemFolders $systemFolders
    }

    4
    {
        $systemFolders = @(
            Get-SupportedSystems | ForEach-Object { Get-SystemFolder $_ }
        )

        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host (T "menu.totalCleanTitle")
        Write-Host (T "menu.totalCleanAllSystems")
        Write-Host "==========================================" -ForegroundColor Cyan

        Invoke-RomCleaning -Root $Root -SystemFolders $systemFolders

        Invoke-OrphanedMediaCleanup -SystemFolders $systemFolders

        Invoke-HackOrganizer -Root $Root -SystemFolders $systemFolders
    }

    5
    {
        Show-ConfigMenu -Root $Root
        continue mainLoop
    }

}

Write-Host ""
Read-Host (T "menu.pressEnterMainMenu")

}

}
catch
{
    #
    # DIAGNÓSTICO TEMPORAL: si algo revienta sin que se pueda ver
    # la línea exacta en consola, lo dejamos escrito en un archivo
    # aparte con el stack trace completo, para poder localizarlo
    # sin tener que reproducirlo interactivamente.
    #

    $crashLog = Join-Path $Root "crash_log.txt"

    $details = @"
========================================
FECHA: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
MENSAJE: $($_.Exception.Message)
----------------------------------------
POSICION:
$($_.InvocationInfo.PositionMessage)
----------------------------------------
SCRIPT STACK TRACE:
$($_.ScriptStackTrace)
========================================

"@

    Add-Content -LiteralPath $crashLog -Value $details -Encoding UTF8

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "Se ha producido un error inesperado." -ForegroundColor Red
    Write-Host "Detalles guardados en: $crashLog" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
}
finally
{
    #
    # Pase lo que pase (salida normal, Ctrl+C, o un error
    # inesperado), la transcripción del log se cierra siempre
    # aquí, para que el archivo nunca se quede abierto/bloqueado.
    #

    Stop-Log
}

#--------------------------------------------------------------
# Fin
#--------------------------------------------------------------

Pause-End