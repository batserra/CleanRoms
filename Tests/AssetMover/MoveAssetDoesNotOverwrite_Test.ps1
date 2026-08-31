# ============================================================
# BUG corregido: Move-Asset (AssetMover.ps1) usaba
# Move-Item -Force directamente, que si ya existía un archivo con
# el mismo nombre en la carpeta destino (p.ej. una partida
# guardada de una limpieza anterior) lo SOBREESCRIBÍA SIN AVISAR
# -- la única operación de movimiento de todo el programa que no
# comprobaba esto antes, a diferencia de la ROM principal, los
# huérfanos y los duplicados de hacks.
#
# Este test comprueba que, si el destino ya tiene un archivo con
# ese nombre, Move-Asset lanza un error claro (que las tres
# llamadas reales ya capturan con try/catch) y NO toca el archivo
# que ya estaba ahí.
# ============================================================

$sourceFolder = New-TestTempFolder
$targetFolder = New-TestTempFolder

$sourceFile = Join-Path $sourceFolder "Game.sav"
$existingDestinationFile = Join-Path $targetFolder "Game.sav"

Set-Content -LiteralPath $sourceFile -Value "partida guardada nueva"
Set-Content -LiteralPath $existingDestinationFile -Value "partida guardada antigua, no se debe perder"

$asset = Get-Item -LiteralPath $sourceFile

try
{
    $threw = $false

    try
    {
        Move-Asset -Asset $asset -TargetFolder $targetFolder
    }
    catch
    {
        $threw = $true
    }

    Assert-Equal `
        $true `
        $threw `
        "Move-Asset: debe lanzar un error si ya existe un archivo con ese nombre en el destino"

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $sourceFile) `
        "Move-Asset: el archivo de origen debe seguir en su sitio (no se movio)"

    Assert-Equal `
        "partida guardada antigua, no se debe perder" `
        (Get-Content -LiteralPath $existingDestinationFile -Raw).Trim() `
        "Move-Asset: el archivo que ya habia en el destino NO debe sobrescribirse"
}
finally
{
    Remove-Item -Path $sourceFolder -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $targetFolder -Recurse -Force -ErrorAction SilentlyContinue
}
