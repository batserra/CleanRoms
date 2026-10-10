# ============================================================
# CleanROMs
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
    #   Purge   -> igual que la opción 6: BORRA de _duplicates las
    #              copias que llevan -OlderThanDays días o más (lo
    #              único que el programa borra de verdad; sin
    #              -Yes pregunta antes; -System se ignora)
    #
    # Si no se indica ningún valor, se ignoran también -System,
    # -Yes y -PreviewOnly, y el programa arranca exactamente igual
    # que siempre (menú interactivo).
    #

    [ValidateSet("Clean", "Orphans", "All", "Undo", "Purge")]
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

    [switch]$PreviewOnly,

    #
    # Solo para -Action Purge: se borran las copias de _duplicates
    # que llevan este número de días o más desde que se movieron.
    # Si no se indica, se usa PurgeDuplicatesAfterDays de
    # Config\Settings.ps1 (90 por defecto).
    #

    [ValidateRange(1, 3650)]
    [int]$OlderThanDays = 0

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

#
# Cuenta las acciones que fallaron durante la ejecucion (un MOVE que
# lanzo una excepcion, un archivo asociado que no se pudo mover...).
# En modo no interactivo, si es mayor que 0 el programa termina con
# codigo de salida 2 para que el Programador de tareas lo vea.
#
# Codigos de salida en modo no interactivo (-Action):
#   0 = todo correcto
#   1 = error inesperado (ver crash_log.txt) o argumentos no validos
#   2 = terminó, pero alguna accion fallo (ver el log)
#

$Global:ActionErrorCount = 0

Initialize-Language -Root $Root
Initialize-RomPriorityLanguage -Root $Root
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
. "$Root\Modules\logger.ps1"
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
. "$Root\Modules\GamelistManager.ps1"
. "$Root\Modules\Overrides.ps1"
. "$Root\Modules\RomSets.ps1"
. "$Root\Modules\HashCache.ps1"
. "$Root\Modules\DuplicatesPurger.ps1"



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

    if($Action -ne "Undo" -and $Action -ne "Purge")
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
            Invoke-OrphanedMediaCleanup -Root $Root -SystemFolders $systemFolders
        }

        "All"
        {
            Invoke-RomCleaning -Root $Root -SystemFolders $systemFolders
            Invoke-OrphanedMediaCleanup -Root $Root -SystemFolders $systemFolders
            Invoke-HackOrganizer -Root $Root -SystemFolders $systemFolders
        }

        "Undo"
        {
            Invoke-UndoLastPlan -Root $Root
        }

        "Purge"
        {
            $null = Invoke-DuplicatesPurge -Root $Root -Days $OlderThanDays
        }
    }

    $exitCode = 0

    if($Global:ActionErrorCount -gt 0)
    {
        $exitCode = 2
    }

    Stop-Log
    exit $exitCode
}

:mainLoop
while($true)
{

Show-Banner

$mainAction = Select-MainAction

if($mainAction -eq 7)
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

        Invoke-OrphanedMediaCleanup -Root $Root -SystemFolders $systemFolders
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

        Invoke-OrphanedMediaCleanup -Root $Root -SystemFolders $systemFolders

        Invoke-HackOrganizer -Root $Root -SystemFolders $systemFolders
    }

    5
    {
        Show-ConfigMenu -Root $Root
        continue mainLoop
    }

    6
    {
        $purgeDays = Read-PurgeDays

        $null = Invoke-DuplicatesPurge -Root $Root -Days $purgeDays
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
    Write-Host (T "main.crash") -ForegroundColor Red
    Write-Host (T "main.crashDetails" $crashLog) -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red

    #
    # En modo no interactivo el fallo debe ser visible para quien
    # lanzo el programa (Programador de tareas, scripts...): se sale
    # con codigo 1 en vez de seguir y terminar "con exito".
    #

    if($Global:AutoConfirm)
    {
        Stop-Log
        exit 1
    }
}
finally
{
    #
    # Pase lo que pase (salida normal, Ctrl+C, o un error
    # inesperado), la transcripción del log se cierra siempre
    # aquí, para que el archivo nunca se quede abierto/bloqueado.
    #

    Save-HashCache

    Stop-Log
}

#--------------------------------------------------------------
# Fin
#--------------------------------------------------------------

Pause-End