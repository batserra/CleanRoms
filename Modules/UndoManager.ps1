# ============================================================
# Beta CleanROMs v2.5
#
# UndoManager.ps1
#
# Deshace la última limpieza ejecutada, leyendo el plan
# exportado (Resultado\CleanPlan.json) y devolviendo cada
# archivo movido a su carpeta original.
#
# Solo se restauran acciones MOVE que realmente se llegaron a
# ejecutar (se comprueba que el archivo esté físicamente en el
# destino); si el plan solo se previsualizó (PreviewOnly) o no
# se confirmó, no hay nada que deshacer.
# ============================================================

function Invoke-UndoLastPlan {

    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $jsonFile = Join-Path $Root "Resultado\CleanPlan.json"

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "undo.title")
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    if(!(Test-Path -LiteralPath $jsonFile))
    {
        Write-Host (T "undo.noPlanFoundFull") -ForegroundColor Yellow
        Write-Host "($jsonFile)"
        Write-Host ""
        Read-Host (T "menu.pressEnterContinue")
        return
    }

    try
    {
        $actions = @(Get-Content -LiteralPath $jsonFile -Raw | ConvertFrom-Json)
    }
    catch
    {
        Write-Host (T "undo.readError") -ForegroundColor Red
        return
    }

    $moveActions = @($actions | Where-Object { $_.Action -eq "MOVE" })

    if($moveActions.Count -eq 0)
    {
        Write-Host (T "undo.nothingToUndo") -ForegroundColor Green
        return
    }

    Write-Host (T "undo.checking" $moveActions.Count)
    Write-Host ""

    $restored = 0
    $notMoved = 0
    $occupied = 0

    foreach($action in $moveActions)
    {
        $fileName = Split-Path $action.Source -Leaf

        $currentPath = Join-Path $action.Target $fileName

        if(!(Test-Path -LiteralPath $currentPath))
        {
            #
            # No está en el destino: nunca se llegó a mover
            # (modo simulación, no se confirmó el plan, o ya
            # se había deshecho antes)
            #

            $notMoved++
            continue
        }

        if(Test-Path -LiteralPath $action.Source)
        {
            Write-Host (T "undo.occupiedSource") -ForegroundColor Yellow
            Write-Host "             $($action.Source)"
            $occupied++
            continue
        }

        $sourceFolder = Split-Path $action.Source -Parent

        if(!(Test-Path -LiteralPath $sourceFolder))
        {
            New-Item -ItemType Directory -Path $sourceFolder | Out-Null
        }

        Move-Item -LiteralPath $currentPath -Destination $action.Source

        Write-Host (T "undo.restored" $action.Source) -ForegroundColor Green

        $restored++
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "undo.restoredCount" $restored)
    Write-Host (T "undo.notMovedCount" $notMoved)
    Write-Host (T "undo.occupiedCount" $occupied)
    Write-Host "==========================================" -ForegroundColor Cyan
}
