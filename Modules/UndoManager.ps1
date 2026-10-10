# ============================================================
# CleanROMs
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

    $resultadoFolder = Join-Path $Root "Resultado"

    $jsonFile = Join-Path $resultadoFolder "CleanPlan.json"

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

        if(-not $Global:AutoConfirm)
        {
            Read-Host (T "menu.pressEnterContinue")
        }

        return
    }

    #
    # Si hay sesiones anteriores archivadas en Resultado\History\,
    # se ofrece elegir cuál deshacer. Por defecto (Enter sin
    # escribir nada) se deshace la más reciente, igual que se ha
    # hecho siempre.
    #

    $historyFolder = Join-Path $resultadoFolder "History"

    $historyFiles = @()

    if(Test-Path -LiteralPath $historyFolder)
    {
        $historyFiles = @(
            Get-ChildItem -LiteralPath $historyFolder -Filter "CleanPlan_*.json" |
                Sort-Object LastWriteTime -Descending
        )
    }

    if($historyFiles.Count -gt 0)
    {
        Write-Host (T "undo.chooseTitle")
        Write-Host (T "undo.chooseCurrent")

        for($i = 0; $i -lt $historyFiles.Count; $i++)
        {
            $label = $historyFiles[$i].LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Write-Host (T "undo.chooseHistoryItem" @(($i + 1), $label))
        }

        Write-Host ""

        if($Global:AutoConfirm)
        {
            #
            # Modo no interactivo: no se pregunta nada, se deshace
            # siempre la más reciente ($jsonFile ya apunta ahí por
            # defecto, no hace falta tocar nada más).
            #

            Write-Host (T "undo.choosePrompt")
            Write-Host (T "confirm.autoConfirmed") -ForegroundColor DarkGray
            Write-Host ""
        }
        else
        {
            $choice = Read-Host (T "undo.choosePrompt")

            if(![string]::IsNullOrWhiteSpace($choice))
            {
                $index = 0

                if([int]::TryParse($choice.Trim(), [ref]$index) -and $index -ge 1 -and $index -le $historyFiles.Count)
                {
                    $jsonFile = $historyFiles[$index - 1].FullName
                }
            }

            Write-Host ""
        }
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
    $failed = 0
    $assetsRestored = 0

    #
    # Se deshace en ORDEN INVERSO al que se hizo. Un mismo archivo
    # puede tener dos movimientos encadenados en la misma sesion
    # (p.ej. Invoke-HackOrganizer lo mueve a "# Hacks y Otros #" y
    # Invoke-HackDeduplication despues lo manda a _duplicates):
    # solo yendo del ultimo al primero vuelve hasta su carpeta
    # original. En orden directo la primera entrada no lo
    # encontraba (ya no estaba donde ella lo dejo) y se saltaba, y
    # el archivo se quedaba en "# Hacks y Otros #".
    #

    $orderedActions = @($moveActions)
    [array]::Reverse($orderedActions)

    # Rutas del gamelist.xml que hay que devolver a su valor original
    # (ROMs que el organizador de hacks movio de carpeta), por sistema
    $gamelistReverts = @{}

    foreach($action in $orderedActions)
    {
        try
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

            #
            # Si al mover esta ROM se actualizo su entrada del
            # gamelist.xml (organizador de hacks), la ruta se devuelve a
            # la original. Se apunta aqui y se aplica por sistema al
            # final, para guardar (y hacer copia) una sola vez.
            #

            $gamelistFlag = $action.PSObject.Properties["GamelistUpdated"]
            $gamelistFolder = $action.PSObject.Properties["SystemFolder"]

            if($null -ne $gamelistFlag -and $gamelistFlag.Value -eq $true -and
               $null -ne $gamelistFolder -and $gamelistFolder.Value)
            {
                $systemKey = [string]$gamelistFolder.Value

                if(-not $gamelistReverts.ContainsKey($systemKey))
                {
                    $gamelistReverts[$systemKey] = @()
                }

                $gamelistReverts[$systemKey] += [PSCustomObject]@{ From = $currentPath; To = $action.Source }
            }

            #
            # Archivos asociados (partida guardada, configuración de
            # mando...) que se movieron junto con esta ROM. Si el plan
            # viene de una versión anterior sin este campo, o de un
            # paso que todavía no lo rellena, $action.AssociatedFiles
            # es $null y este bucle simplemente no hace nada — no
            # hace falta comprobarlo aparte.
            #

            foreach($assetName in $action.AssociatedFiles)
            {
                $assetCurrentPath = Join-Path $action.Target $assetName
                $assetOriginalPath = Join-Path $sourceFolder $assetName

                if(!(Test-Path -LiteralPath $assetCurrentPath))
                {
                    # Ya no está ahí (se movió/borró a mano, o ya se
                    # había deshecho antes). Se omite en silencio: el
                    # contador de la ROM en sí ya refleja el resultado
                    # principal de este deshacer.
                    continue
                }

                if(Test-Path -LiteralPath $assetOriginalPath)
                {
                    Write-Host (T "undo.occupiedSource") -ForegroundColor Yellow
                    Write-Host "             $assetOriginalPath"
                    continue
                }

                Move-Item -LiteralPath $assetCurrentPath -Destination $assetOriginalPath

                Write-Host (T "undo.restoredAsset" $assetName) -ForegroundColor Green

                $assetsRestored++
            }
        }
        catch
        {
            #
            # Un fallo puntual (archivo bloqueado por otro programa,
            # permisos, disco desconectado...) no debe abortar el
            # resto del deshacer: se avisa, se cuenta (codigo de
            # salida 2 en modo desatendido) y se sigue con el
            # siguiente movimiento.
            #

            $failed++
            $Global:ActionErrorCount = [int]$Global:ActionErrorCount + 1

            Write-Warning (T "undo.failed" @($action.Source, $_.Exception.Message))

            if(Get-Command Write-Log -ErrorAction SilentlyContinue)
            {
                Write-Log "ERROR: undo $($action.Source) : $($_.Exception.Message)"
            }
        }
    }

    foreach($systemKey in $gamelistReverts.Keys)
    {
        try
        {
            $null = Update-GamelistEntryPaths -SystemFolder $systemKey -Changes @($gamelistReverts[$systemKey]) -Root $Root
        }
        catch
        {
            $failed++
            $Global:ActionErrorCount = [int]$Global:ActionErrorCount + 1

            Write-Warning (T "gamelist.failed" @((Split-Path $systemKey -Leaf), $_.Exception.Message))
        }
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "undo.restoredCount" $restored)

    if($assetsRestored -gt 0)
    {
        Write-Host (T "undo.assetsRestoredCount" $assetsRestored)
    }

    Write-Host (T "undo.notMovedCount" $notMoved)
    Write-Host (T "undo.occupiedCount" $occupied)

    if($failed -gt 0)
    {
        Write-Host (T "undo.failedCount" $failed) -ForegroundColor Red
    }

    Write-Host "==========================================" -ForegroundColor Cyan
}
