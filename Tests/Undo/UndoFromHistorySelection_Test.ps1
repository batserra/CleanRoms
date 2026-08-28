# ============================================================
# MEJORA: "Deshacer la última limpieza" ahora puede deshacer una
# sesión anterior del historial (Resultado\History\), no solo la
# más reciente (Resultado\CleanPlan.json).
#
# Este test monta dos "sesiones" (la actual y una del historial),
# cada una con su propia ROM ya movida a su carpeta destino, pide
# deshacer la del historial (respondiendo "1" a la pregunta), y
# comprueba que SOLO esa se restaura -- la sesión actual se queda
# tal cual, sin tocar.
# ============================================================

$tempRoot = New-TestTempFolder

$oldFolder = Join-Path $tempRoot "old_session"
$currentFolder = Join-Path $tempRoot "current_session"
$targetFolder = Join-Path $tempRoot "_duplicates"

New-Item -ItemType Directory -Path $oldFolder -Force | Out-Null
New-Item -ItemType Directory -Path $currentFolder -Force | Out-Null
New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null

$oldRomOriginal = Join-Path $oldFolder "OldGame.smc"
$currentRomOriginal = Join-Path $currentFolder "CurrentGame.smc"

Set-Content -LiteralPath (Join-Path $targetFolder "OldGame.smc") -Value "old rom bytes"
Set-Content -LiteralPath (Join-Path $targetFolder "CurrentGame.smc") -Value "current rom bytes"

$resultadoFolder = Join-Path $tempRoot "Resultado"
$historyFolder = Join-Path $resultadoFolder "History"
New-Item -ItemType Directory -Path $historyFolder -Force | Out-Null

$oldAction = [PSCustomObject]@{
    Action = "MOVE"; Source = $oldRomOriginal; Target = $targetFolder
    Reason = "Test"; Hash = "OLD"; TimeStamp = Get-Date; AssociatedFiles = @()
}

$currentAction = [PSCustomObject]@{
    Action = "MOVE"; Source = $currentRomOriginal; Target = $targetFolder
    Reason = "Test"; Hash = "CURRENT"; TimeStamp = Get-Date; AssociatedFiles = @()
}

@($oldAction) | ConvertTo-Json -Depth 10 |
    Set-Content (Join-Path $historyFolder "CleanPlan_20200101_000000.json") -Encoding UTF8

@($currentAction) | ConvertTo-Json -Depth 10 |
    Set-Content (Join-Path $resultadoFolder "CleanPlan.json") -Encoding UTF8

function global:Read-Host
{
    param($Prompt)
    return "1"
}

try
{
    Invoke-UndoLastPlan -Root $tempRoot

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $oldRomOriginal) `
        "Deshacer del historial: la ROM de la sesion antigua debe restaurarse"

    Assert-Equal `
        $false `
        (Test-Path -LiteralPath $currentRomOriginal) `
        "Deshacer del historial: la ROM de la sesion actual NO debe tocarse (se eligio deshacer la antigua)"
}
finally
{
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
