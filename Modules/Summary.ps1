# ============================================================
# Beta CleanROMs v2.5
#
# Summary.ps1
#
# Muestra el resumen final antes de ejecutar
# ============================================================

function Show-CleanSummary {

    param(
        [Parameter(Mandatory)]
        $Plan
    )

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "           RESUMEN DE LIMPIEZA" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan

    Show-SystemSummary $Plan

    Show-ActionSummary $Plan

    Show-StatisticsSummary $Plan

    Show-WarningsSummary $Plan
	
	Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan

}

function Show-SystemSummary {

    param($Plan)

    #
    # Cada acción lleva la ruta completa de la ROM en Source, p.ej.
    # C:\RetroBat\roms\amstradcpc\juego.dsk -> el sistema es el
    # nombre de la carpeta que contiene el archivo.
    #

    $actionsWithSystem = $Plan.Actions |
        ForEach-Object {
            [PSCustomObject]@{
                System = Split-Path (Split-Path $_.Source -Parent) -Leaf
                Action = $_.Action
            }
        }

    $systems = $actionsWithSystem |
        ForEach-Object { $_.System } |
        Sort-Object -Unique

    Write-Host ""
    Write-Host "Sistema(s):" -ForegroundColor Yellow

    foreach($system in $systems)
    {
        $systemActions = @($actionsWithSystem | Where-Object System -eq $system)

        $keep   = @($systemActions | Where-Object Action -eq "KEEP").Count
        $move   = @($systemActions | Where-Object Action -eq "MOVE").Count
        $delete = @($systemActions | Where-Object Action -eq "DELETE").Count
        $rename = @($systemActions | Where-Object Action -eq "RENAME").Count

        Write-Host ("   - {0,-15} KEEP: {1,-5} MOVE: {2,-5} DELETE: {3,-5} RENAME: {4,-5}" -f `
            $system, $keep, $move, $delete, $rename)
    }

}

function Show-ActionSummary {

    param($Plan)

    Write-Host ""

    Write-Host ("KEEP    : {0}" -f $Plan.TotalKeep) `
        -ForegroundColor Green

    Write-Host ("MOVE    : {0}" -f $Plan.TotalMove) `
        -ForegroundColor Yellow

    Write-Host ("DELETE  : {0}" -f $Plan.TotalDelete) `
        -ForegroundColor Red

    Write-Host ("RENAME  : {0}" -f $Plan.TotalRename) `
        -ForegroundColor Cyan

}

# ============================================================
# Estadísticas generales
# ============================================================

function Show-StatisticsSummary {

    param($Plan)

    Write-Host ""
    Write-Host "Estadísticas" -ForegroundColor Yellow
    Write-Host "------------------------------------------"

    Write-Host ("Total acciones : {0}" -f $Plan.TotalActions)
    Write-Host ("KEEP           : {0}" -f $Plan.TotalKeep)
    Write-Host ("MOVE           : {0}" -f $Plan.TotalMove)
    Write-Host ("DELETE         : {0}" -f $Plan.TotalDelete)
    Write-Host ("RENAME         : {0}" -f $Plan.TotalRename)

    if($Plan.PSObject.Properties.Match("BuildDate").Count -gt 0)
    {
        Write-Host ("Fecha          : {0}" -f $Plan.BuildDate)
    }

    if($Plan.PSObject.Properties.Match("Version").Count -gt 0)
    {
        Write-Host ("Versión        : {0}" -f $Plan.Version)
    }

}

# ============================================================
# Advertencias
# ============================================================

function Show-WarningsSummary {

    param($Plan)

    Write-Host ""

    $warnings = @()

    if($Plan.TotalMove -eq 0)
    {
        $warnings += "No se han encontrado ROMs duplicadas."
    }

    if($Plan.TotalActions -eq 0)
    {
        $warnings += "El plan está vacío."
    }

    if($warnings.Count -eq 0)
    {
        Write-Host "No hay advertencias." -ForegroundColor Green
        return
    }

    Write-Host "Advertencias" -ForegroundColor Yellow
    Write-Host "------------------------------------------"

    foreach($warning in $warnings)
    {
        Write-Host (" - {0}" -f $warning) -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Aviso importante arriba en amarillo. Pulse ENTER para continuar"

}

