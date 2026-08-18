# ============================================================
# Beta CleanROMs v2.6
#
# Executor.ps1
#
# Ejecuta el plan de limpieza
# ============================================================

function Invoke-CleanExecute {

    param(

        [Parameter(Mandatory)]
        $Plan

    )
	
	$keepCount = 0

$moveCount = 0

$deleteCount = 0

$renameCount = 0

$movedOkCount = 0

$previewCount = 0

$skippedMissingCount = 0

$skippedExistsCount = 0

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "exec.executing")
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

$total = $Plan.Actions.Count

$index = 0

foreach($action in $Plan.Actions)
{
    $index++
	
	switch($action.Action)
{
    "KEEP"   {$keepCount++}
    "MOVE"   {$moveCount++}
    "DELETE" {$deleteCount++}
    "RENAME" {$renameCount++}
}

    Write-Progress `
        -Activity "Ejecutando plan" `
        -Status "$index de $total" `
        -PercentComplete (($index / $total) * 100)

     try
    {
        $result = Invoke-CleanAction $action

        if($action.Action -eq "MOVE")
        {
            switch($result)
            {
                "MOVED"            { $movedOkCount++ }
                "PREVIEW"          { $previewCount++ }
                "SKIPPED_MISSING"  { $skippedMissingCount++ }
                "SKIPPED_EXISTS"   { $skippedExistsCount++ }
            }
        }
    }
    catch
    {
        Write-Warning $_

        Write-Log "ERROR: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host ("KEEP    : {0}" -f $keepCount) `
    -ForegroundColor Green

Write-Host ("MOVE    : {0}" -f $moveCount) `
    -ForegroundColor Yellow

if($movedOkCount -gt 0)
{
    Write-Host (T "exec.movedOk" $movedOkCount) `
        -ForegroundColor Yellow
}

if($previewCount -gt 0)
{
    Write-Host (T "exec.previewOnly" $previewCount) `
        -ForegroundColor DarkYellow
}

if($skippedExistsCount -gt 0)
{
    Write-Host (T "exec.skippedExists" $skippedExistsCount) `
        -ForegroundColor Red
}

if($skippedMissingCount -gt 0)
{
    Write-Host (T "exec.skippedMissing" $skippedMissingCount) `
        -ForegroundColor Red
}

Write-Host ("DELETE  : {0}" -f $deleteCount) `
    -ForegroundColor Red

Write-Host ("RENAME  : {0}" -f $renameCount) `
    -ForegroundColor Cyan

Write-Host "==========================================" -ForegroundColor Cyan


Write-Progress `
    -Activity "Ejecutando plan" `
    -Completed

    Write-Host ""
    Write-Host (T "exec.planCompleted")
}

function Invoke-CleanAction {

    param(

        [Parameter(Mandatory)]
        $Action

    )

    switch($Action.Action)
    {

        "KEEP"
        {
            Invoke-KeepAction $Action
            return "KEPT"
        }

        "MOVE"
        {
            return Invoke-MoveAction $Action
        }

        "DELETE"
        {
            Invoke-DeleteAction $Action
            return "DELETED"
        }

        "RENAME"
        {
            Invoke-RenameAction $Action
            return "RENAMED"
        }

        default
        {
            throw "Acción desconocida: $($Action.Action)"
        }

    }

}

function Invoke-KeepAction {

    param($Action)

    Write-Host "[KEEP ] $($Action.Source)" -ForegroundColor Green

}

# ============================================================
# Ejecutar acción MOVE
# ============================================================

function Invoke-MoveAction {

    param(
        [Parameter(Mandatory)]
        $Action
    )

    #
    # Comprobaciones
    #

    if(!(Test-Path -LiteralPath $Action.Source))
    {
        Write-Warning (T "exec.fileNotFound")
        Write-Warning $Action.Source
        return "SKIPPED_MISSING"
    }

    #
    # Crear carpeta destino
    #

    if(!(Test-Path -LiteralPath $Action.Target))
    {
        New-Item `
            -ItemType Directory `
            -Path $Action.Target `
            -Force | Out-Null
    }

    #
    # Destino completo
    #

    $destination = Join-Path `
        $Action.Target `
        (Split-Path $Action.Source -Leaf)

    #
    # Evitar sobrescribir
    #

    if(Test-Path -LiteralPath $destination)
    {
        Write-Warning (T "exec.alreadyExists")
        Write-Warning $destination
        return "SKIPPED_EXISTS"
    }

    #
    # Movimiento
    #
	
	#
# Modo simulación
#

if($Global:Settings.PreviewOnly)
{
    Write-Host (T "exec.previewMove" $Action.Source) -ForegroundColor DarkYellow
    return "PREVIEW"
}



    Move-Item `
        -LiteralPath $Action.Source `
        -Destination $destination

    Write-Host "[MOVE ] $($Action.Source)" -ForegroundColor Yellow

    #
    # Mover también los archivos asociados a esta ROM (guardado,
    # configuración de mando, etc. con el mismo nombre): sin esto
    # se quedan huérfanos en la carpeta original, apuntando a una
    # ROM que ya no está ahí.
    #

    if($Global:Settings.MoveAssets)
    {
        $assets = Get-AssociatedFiles $Action.Rom

        foreach($asset in $assets)
        {
            try
            {
                Move-Asset -Asset $asset -TargetFolder $Action.Target
                Write-Host "[MOVE ]   + $($asset.Name)" -ForegroundColor DarkYellow
            }
            catch
            {
                Write-Warning (T "exec.assetMoveFailed" $asset.FullName)
            }
        }
    }

    return "MOVED"

}

function Invoke-DeleteAction {

    param(
        [Parameter(Mandatory)]
        $Action
    )

    Write-Host "[DELETE] $($Action.Source)" -ForegroundColor Red
if($Global:Settings.PreviewOnly)
{
    Write-Host (T "exec.previewDelete" $Action.Source) -ForegroundColor DarkRed
    return
}


    Remove-Item `
        -LiteralPath $Action.Source `
        -Force

    if($Global:Settings.MoveAssets)
    {
        $assets = Get-AssociatedFiles $Action.Rom

        foreach($asset in $assets)
        {
            try
            {
                Remove-Item -LiteralPath $asset.FullName -Force
                Write-Host "[DELETE]   + $($asset.Name)" -ForegroundColor DarkRed
            }
            catch
            {
                Write-Warning (T "exec.assetDeleteFailed" $asset.FullName)
            }
        }
    }
}

function Invoke-RenameAction {

    param(
        [Parameter(Mandatory)]
        $Action
    )

    Write-Host "[RENAME] $($Action.Source)" -ForegroundColor Cyan

if($Global:Settings.PreviewOnly)
{
    Write-Host (T "exec.previewRename" $Action.Source) -ForegroundColor Cyan
    return
}

    Rename-Item `
        -LiteralPath $Action.Source `
        -NewName $Action.Target

}




