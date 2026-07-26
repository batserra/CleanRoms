# ============================================================
# Beta CleanROMs v2.5
#
# Main.ps1
# ============================================================
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

#=========================================================
# Configuración
#=========================================================

. "$Root\Config\Settings.ps1"
. "$Root\Config\DecisionWeights.ps1"

Initialize-RetroBatRoot -Root $Root

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



#--------------------------------------------------------------
# Inicio
#--------------------------------------------------------------

Start-Log $Root

try
{

:mainLoop
while($true)
{

Show-Banner

$mainAction = Select-MainAction

if($mainAction -eq 5)
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
        Write-Host "   LIMPIEZA TOTAL: ROMs + imágenes/vídeos/manuales"
        Write-Host "   (TODOS los sistemas)"
        Write-Host "==========================================" -ForegroundColor Cyan

        Invoke-RomCleaning -Root $Root -SystemFolders $systemFolders

        Invoke-OrphanedMediaCleanup -SystemFolders $systemFolders
    }

}

Write-Host ""
Read-Host "Pulse ENTER para volver al menú principal"

}

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