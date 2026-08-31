# ============================================================
# MEJORA: "Deshacer la última limpieza" ahora también restaura
# los archivos asociados (partida guardada, configuración de
# mando...) que se hubieran movido junto con la ROM, no solo la
# ROM en sí.
#
# Este test fabrica a mano un CleanPlan.json con una acción MOVE
# que incluye AssociatedFiles, coloca los archivos "ya movidos"
# en la carpeta destino (simulando una limpieza ya ejecutada), y
# comprueba que Invoke-UndoLastPlan devuelve tanto la ROM como su
# archivo asociado a la carpeta original.
# ============================================================

$tempRoot = New-TestTempFolder

$originalFolder = Join-Path $tempRoot "snes"
$targetFolder = Join-Path $tempRoot "_duplicates\snes"

New-Item -ItemType Directory -Path $originalFolder -Force | Out-Null
New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null

$romOriginalPath = Join-Path $originalFolder "Game.smc"
$assetOriginalPath = Join-Path $originalFolder "Game.sav"

# Los archivos "ya movidos" viven ahora mismo en la carpeta
# destino, tal como quedarían tras una limpieza real ya ejecutada.
Set-Content -LiteralPath (Join-Path $targetFolder "Game.smc") -Value "fake rom bytes"
Set-Content -LiteralPath (Join-Path $targetFolder "Game.sav") -Value "fake save bytes"

$planAction = [PSCustomObject]@{
    Action = "MOVE"
    Source = $romOriginalPath
    Target = $targetFolder
    Reason = "Test"
    Hash = "TEST-HASH"
    TimeStamp = Get-Date
    AssociatedFiles = @("Game.sav")
}

$resultadoFolder = Join-Path $tempRoot "Resultado"
New-Item -ItemType Directory -Path $resultadoFolder -Force | Out-Null

@($planAction) |
    ConvertTo-Json -Depth 10 |
    Set-Content (Join-Path $resultadoFolder "CleanPlan.json") -Encoding UTF8

try
{
    Invoke-UndoLastPlan -Root $tempRoot

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $romOriginalPath) `
        "Deshacer: la ROM debe volver a su carpeta original"

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $assetOriginalPath) `
        "Deshacer: el archivo asociado (Game.sav) también debe volver a su carpeta original"

    Assert-Equal `
        $false `
        (Test-Path -LiteralPath (Join-Path $targetFolder "Game.smc")) `
        "Deshacer: la ROM ya no debe estar en la carpeta de duplicados"

    Assert-Equal `
        $false `
        (Test-Path -LiteralPath (Join-Path $targetFolder "Game.sav")) `
        "Deshacer: el archivo asociado ya no debe estar en la carpeta de duplicados"
}
finally
{
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
