# ============================================================
# MEJORA: la purga de _duplicates (opcion 6 / -Action Purge) puede borrar
# TODO lo que haya, sin importar cuando se movio (0 dias).
#
# Antes solo borraba lo que llevaba N dias o mas (90 por defecto, contados
# desde que se movio), asi que tras una limpieza reciente la opcion 6 "no
# borraba nada" y quedaban imagenes y videos huerfanos en _duplicates.
#
# - Dias = 0: todo es candidato (tambien lo reciente y lo que no tiene fecha).
# - Si ningun archivo llega a los dias pedidos pero HAY archivos, se explica
#   como borrarlos igualmente.
# - Es destructivo: PreviewOnly simula, responder N cancela, y el texto de
#   confirmacion deja claro que se borra TODO.
# - Read-PurgeDays: Intro = valor por defecto (-1), 0 = todo, N = dias.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$dupSnes = Join-Path (Join-Path $tempRoot "_duplicates") "snes"
$systemFolder = Join-Path $tempRoot "snes"
$resultFolder = Join-Path $tempRoot "Resultado"

$saved = @{
    Language    = $Global:Settings.Language
    PreviewOnly = $Global:Settings.PreviewOnly
    AutoConfirm = $Global:AutoConfirm
    Root        = $Global:RetroBatRoot
    Dup         = $Global:DuplicatesFolder
}

$Global:Settings.Language = "es"
$Global:Settings.PreviewOnly = $false
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"

$global:paAnswers = @()
$global:paAsked = 0

function global:Read-Host
{
    param($Prompt)
    $a = $global:paAnswers[$global:paAsked]
    $global:paAsked++
    return $a
}

function New-DupFile
{
    param([string]$Relative)

    $path = Join-Path $dupSnes $Relative
    New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
    Set-Content -LiteralPath $path -Value "contenido de $Relative"
}

function New-Entry
{
    param([string]$SourceRelative, [string]$TargetRelative, [int]$DaysAgo)

    return [PSCustomObject]@{
        Action          = "MOVE"
        Source          = (Join-Path $systemFolder $SourceRelative)
        Target          = (Join-Path $dupSnes $TargetRelative)
        AssociatedFiles = @()
        TimeStamp       = (Get-Date).AddDays(-$DaysAgo).ToString("o")
    }
}

function Reset-Fixture
{
    Remove-Item -Path (Join-Path $tempRoot "_duplicates") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $resultFolder -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $resultFolder -Force | Out-Null

    # Lo del caso real: ROM de hace tiempo, y medios huerfanos movidos AYER
    New-DupFile "old.sfc"
    New-DupFile "images/Star Fox 2 (Beta)-image.png"
    New-DupFile "images/Star Fox 2 (Beta)-marquee.png"
    New-DupFile "videos/Star Fox 2 (Beta)-video.mp4"
    New-DupFile "undated.sfc"

    @(
        (New-Entry "old.sfc" "." 200),
        (New-Entry "images/Star Fox 2 (Beta)-image.png" "images" 1),
        (New-Entry "images/Star Fox 2 (Beta)-marquee.png" "images" 1),
        (New-Entry "videos/Star Fox 2 (Beta)-video.mp4" "videos" 1)
    ) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $resultFolder "CleanPlan.json") -Encoding UTF8
}

function Get-RemainingCount
{
    return @(Get-ChildItem -LiteralPath (Join-Path $tempRoot "_duplicates") -File -Recurse -ErrorAction SilentlyContinue).Count
}

try
{
    # 1) Con 90 dias solo cae lo antiguo; lo movido ayer se queda
    Reset-Fixture

    $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>$null

    Assert-Equal 1 $r.Deleted "90 dias: solo se borra la ROM de hace 200 dias"
    Assert-Equal 4 (Get-RemainingCount) "90 dias: los medios movidos ayer y el archivo sin fecha se quedan"

    # 2) Si no cae nada pero hay archivos: se explica como borrarlos
    $output = (@(Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>&1 3>&1) | ForEach-Object { [string]$_ }) -join "`n"

    Assert-Equal $true ($output -match "ninguno lleva 90 d") "Sin candidatos pero con archivos: avisa de que ninguno llega a los dias pedidos"
    Assert-Equal $true ($output -match "elige 0") "Sin candidatos pero con archivos: explica que 0 borra todo"
    Assert-Equal 4 (Get-RemainingCount) "Sin candidatos: no se borra nada"

    # 3) Todo (0 dias) en simulacion: informa, pero no borra
    Reset-Fixture
    $Global:Settings.PreviewOnly = $true

    $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 0 6>$null

    $Global:Settings.PreviewOnly = $false

    Assert-Equal 5 $r.Candidates "Todo + PreviewOnly: cuenta los 5 archivos"
    Assert-Equal 0 $r.Deleted "Todo + PreviewOnly: no borra nada"
    Assert-Equal 5 (Get-RemainingCount) "Todo + PreviewOnly: todo sigue en _duplicates"

    # 4) Todo, respondiendo N: se pregunta y no se borra
    $Global:AutoConfirm = $false
    $global:paAnswers = @("N")
    $global:paAsked = 0

    $output = (@(Invoke-DuplicatesPurge -Root $tempRoot -Days 0 6>&1 3>&1) | ForEach-Object { [string]$_ }) -join "`n"

    Assert-Equal 1 $global:paAsked "Todo + N: se pide confirmacion una vez"
    Assert-Equal 5 (Get-RemainingCount) "Todo + N: no se borra nada"
    Assert-Equal $true ($output -match "PURGA TOTAL") "Todo: la cabecera dice que es una purga TOTAL"

    # 5) Todo, confirmado: se vacia _duplicates (incluido lo reciente y lo sin fecha)
    $Global:AutoConfirm = $true

    $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 0 6>$null

    Assert-Equal 5 $r.Deleted "Todo: se borran los 5 archivos (los de ayer y el sin fecha tambien)"
    Assert-Equal 0 $r.Failed "Todo: sin fallos"
    Assert-Equal 0 (Get-RemainingCount) "Todo: no queda ningun archivo en _duplicates"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $dupSnes "images")) "Todo: las carpetas que quedan vacias se eliminan"

    $logs = @(Get-ChildItem -LiteralPath $resultFolder -Filter "PurgeLog_*.txt")
    Assert-Equal 1 $logs.Count "Todo: se anota lo borrado en PurgeLog"
    Assert-Equal 5 @(Get-Content -LiteralPath $logs[0].FullName).Count "Todo: el log lista los 5 archivos"

    # 6) La pregunta de los dias: Intro / 0 / N / valores invalidos
    $Global:AutoConfirm = $true
    Assert-Equal -1 (Read-PurgeDays) "Read-PurgeDays sin interaccion (-Yes): usa el valor por defecto (-1)"

    $Global:AutoConfirm = $false

    foreach($case in @(
        @{ Answers = @(""); Expected = -1; Name = "Intro = valor por defecto" },
        @{ Answers = @("0"); Expected = 0; Name = "0 = borrar TODO" },
        @{ Answers = @("45"); Expected = 45; Name = "45 = 45 dias" },
        @{ Answers = @("abc", "-3", "45"); Expected = 45; Name = "texto y negativos se rechazan y se vuelve a preguntar" },
        @{ Answers = @("3651", "0"); Expected = 0; Name = "mas de 3650 se rechaza" }
    ))
    {
        $global:paAnswers = $case.Answers
        $global:paAsked = 0

        $value = Read-PurgeDays 6>$null

        Assert-Equal $case.Expected $value "Read-PurgeDays: $($case.Name)"
    }
}
finally
{
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    $Global:Settings.Language = $saved.Language
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
