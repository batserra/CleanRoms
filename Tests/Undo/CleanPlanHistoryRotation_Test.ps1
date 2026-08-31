# ============================================================
# MEJORA: "Deshacer la última limpieza" ahora puede ofrecer más
# de una sesión anterior, no solo la más reciente.
#
# Este test comprueba la pieza base: Export-CleanPlan -Rotate
# debe archivar el CleanPlan.json que ya hubiera (si lo hay) en
# Resultado\History\ antes de escribir el nuevo, y recortar el
# historial al límite configurado en
# $Global:Settings.UndoHistoryLimit.
# ============================================================

$tempRoot = New-TestTempFolder
$resultadoFolder = Join-Path $tempRoot "Resultado"

$originalLimit = $Global:Settings.UndoHistoryLimit

$rom = New-TestRom -Title "Game (Europe).smc" -NormalizedTitle "game"

try
{
    #
    # Primera "sesion": no hay nada previo que archivar todavia.
    #
    $planV1 = @{ Actions = @(New-CleanAction -Action "KEEP" -Rom $rom -Reason "v1") }
    Export-CleanPlan -Plan $planV1 -OutputFolder $resultadoFolder -Rotate | Out-Null

    $historyFolder = Join-Path $resultadoFolder "History"

    Assert-Equal `
        $false `
        (Test-Path -LiteralPath $historyFolder) `
        "Primera sesion: todavia no debe existir carpeta History (nada que archivar)"

    #
    # Segunda "sesion": ahora si habia un CleanPlan.json previo
    # (el de la v1), asi que -Rotate debe archivarlo.
    #
    Start-Sleep -Milliseconds 50

    $planV2 = @{ Actions = @(New-CleanAction -Action "KEEP" -Rom $rom -Reason "v2") }
    Export-CleanPlan -Plan $planV2 -OutputFolder $resultadoFolder -Rotate | Out-Null

    $historyCount = @(Get-ChildItem -LiteralPath $historyFolder -Filter "CleanPlan_*.json" -ErrorAction SilentlyContinue).Count

    Assert-Equal `
        1 `
        $historyCount `
        "Segunda sesion: la sesion anterior (v1) debe haberse archivado en History"

    #
    # Comprobar el recorte: con el limite puesto a 1, una tercera
    # rotacion no debe dejar mas de 1 archivo en History.
    #
    $Global:Settings.UndoHistoryLimit = 1

    Start-Sleep -Milliseconds 50

    $planV3 = @{ Actions = @(New-CleanAction -Action "KEEP" -Rom $rom -Reason "v3") }
    Export-CleanPlan -Plan $planV3 -OutputFolder $resultadoFolder -Rotate | Out-Null

    $historyCountAfterTrim = @(Get-ChildItem -LiteralPath $historyFolder -Filter "CleanPlan_*.json" -ErrorAction SilentlyContinue).Count

    Assert-Equal `
        1 `
        $historyCountAfterTrim `
        "Con UndoHistoryLimit=1, History no debe acumular mas de 1 archivo"
}
finally
{
    $Global:Settings.UndoHistoryLimit = $originalLimit

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
