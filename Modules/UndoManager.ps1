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
    Write-Host "        DESHACER ÚLTIMA LIMPIEZA"
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    if(!(Test-Path -LiteralPath $jsonFile))
    {
        Write-Host "No se encontró ningún plan anterior." -ForegroundColor Yellow
        Write-Host "($jsonFile)"
        Write-Host ""
        Read-Host "Pulse ENTER para continuar"
        return
    }

    try
    {
        $actions = @(Get-Content -LiteralPath $jsonFile -Raw | ConvertFrom-Json)
    }
    catch
    {
        Write-Host "No se pudo leer el plan anterior (archivo dañado o vacío)." -ForegroundColor Red
        return
    }

    $moveActions = @($actions | Where-Object { $_.Action -eq "MOVE" })

    if($moveActions.Count -eq 0)
    {
        Write-Host "El último plan no contenía ningún movimiento que deshacer." -ForegroundColor Green
        return
    }

    Write-Host "Se van a comprobar $($moveActions.Count) movimientos del último plan..."
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
            Write-Host "[OMITIDO]    Ya existe algo en el origen:" -ForegroundColor Yellow
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

        Write-Host "[RESTAURADO] $($action.Source)" -ForegroundColor Green

        $restored++
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ("Restaurados     : {0}" -f $restored)
    Write-Host ("Sin cambios     : {0} (no se habían movido)" -f $notMoved)
    Write-Host ("Omitidos        : {0} (ya había algo en el origen)" -f $occupied)
    Write-Host "==========================================" -ForegroundColor Cyan
}
