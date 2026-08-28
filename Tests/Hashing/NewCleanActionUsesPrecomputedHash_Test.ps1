# ============================================================
# MEJORA: New-CleanAction acepta un -Hash ya calculado (de
# Get-RomHashesParallel) para no volver a leer y hashear el
# mismo archivo por segunda vez al construir el plan.
# ============================================================

$tempFolder = New-TestTempFolder

$realFile = Join-Path $tempFolder "Game.smc"
Set-Content -LiteralPath $realFile -Value "contenido de prueba"

$rom = New-TestRom -Title $realFile -NormalizedTitle "game"

try
{
    #
    # Sin -Hash: debe calcularlo el mismo (comportamiento de
    # siempre).
    #

    $actionSinHash = New-CleanAction -Action "KEEP" -Rom $rom -Reason "Test"

    $hashReal = Get-RomHash -Path $realFile

    Assert-Equal `
        $hashReal `
        $actionSinHash.Hash `
        "New-CleanAction sin -Hash: debe calcular el hash del archivo real"

    #
    # Con -Hash: debe usar exactamente el valor recibido, aunque
    # no coincida con el hash real del archivo (para comprobar
    # sin ambigüedad que no lo está recalculando por su cuenta).
    #

    $actionConHash = New-CleanAction -Action "KEEP" -Rom $rom -Reason "Test" -Hash "HASH-DE-PRUEBA-FALSO"

    Assert-Equal `
        "HASH-DE-PRUEBA-FALSO" `
        $actionConHash.Hash `
        "New-CleanAction con -Hash: debe usar el hash recibido tal cual, sin recalcularlo"
}
finally
{
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
