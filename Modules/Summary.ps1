# ============================================================
# Beta CleanROMs v2.6
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
    Write-Host (T "summary.title") -ForegroundColor Yellow
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
    # Cada acción lleva ya el sistema real en .System (ver
    # New-CleanAction). Como red de seguridad, si alguna acción no
    # lo trajera (planes antiguos, por ejemplo), se recurre al
    # cálculo a partir de la ruta — con la salvedad de que ese
    # cálculo asume que la ROM vive justo dentro de la carpeta del
    # sistema, y se equivocaría si viviera en una subcarpeta.
    #

    $actionsWithSystem = $Plan.Actions |
        ForEach-Object {
            $systemName = $_.System

            if([string]::IsNullOrWhiteSpace($systemName))
            {
                $systemName = Split-Path (Split-Path $_.Source -Parent) -Leaf
            }

            [PSCustomObject]@{
                System = $systemName
                Action = $_.Action
            }
        }

    $systems = $actionsWithSystem |
        ForEach-Object { $_.System } |
        Sort-Object -Unique

    Write-Host ""
    Write-Host (T "summary.systems") -ForegroundColor Yellow

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
    Write-Host (T "summary.stats") -ForegroundColor Yellow
    Write-Host "------------------------------------------"

    Write-Host (T "summary.totalActions" $Plan.TotalActions)
    Write-Host ("KEEP           : {0}" -f $Plan.TotalKeep)
    Write-Host ("MOVE           : {0}" -f $Plan.TotalMove)
    Write-Host ("DELETE         : {0}" -f $Plan.TotalDelete)
    Write-Host ("RENAME         : {0}" -f $Plan.TotalRename)

    if($Plan.PSObject.Properties.Match("BuildDate").Count -gt 0)
    {
        Write-Host (T "summary.date" $Plan.BuildDate)
    }

    if($Plan.PSObject.Properties.Match("Version").Count -gt 0)
    {
        Write-Host (T "summary.version" $Plan.Version)
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
        $warnings += (T "summary.noDuplicates").TrimStart(' ', '-')
    }

    if($Plan.TotalActions -eq 0)
    {
        $warnings += (T "summary.emptyPlan").TrimStart(' ', '-')
    }

    if($warnings.Count -eq 0)
    {
        Write-Host (T "summary.noWarnings") -ForegroundColor Green
        return
    }

    Write-Host (T "summary.warnings") -ForegroundColor Yellow
    Write-Host "------------------------------------------"

    foreach($warning in $warnings)
    {
        Write-Host (" - {0}" -f $warning) -ForegroundColor Yellow
    }

    Write-Host ""

    if($Global:AutoConfirm)
    {
        Write-Host (T "summary.importantNotice")
        Write-Host (T "confirm.autoConfirmed") -ForegroundColor DarkGray
    }
    else
    {
        Read-Host (T "summary.importantNotice")
    }

}

