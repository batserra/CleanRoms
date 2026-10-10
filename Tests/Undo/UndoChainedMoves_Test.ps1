# ============================================================
# BUG: "Deshacer" no devolvia a su sitio original los hacks que
# habian sufrido DOS movimientos en la misma ejecucion.
#
# Invoke-HackOrganizer mueve los hacks sueltos a
# "# Hacks y Otros #" (movimiento 1) y, justo despues,
# Invoke-HackDeduplication mueve a _duplicates las copias exactas
# que haya dentro de esa carpeta (movimiento 2). Si una de esas
# copias es una ROM recien organizada, el mismo archivo tiene dos
# entradas encadenadas en CleanPlan.json:
#
#   1)  <sistema>\Juego (Hack).smc -> <sistema>\# Hacks y Otros #\
#   2)  <sistema>\# Hacks y Otros #\Juego (Hack).smc -> _duplicates\<sistema>\
#
# Invoke-UndoLastPlan las recorria en orden directo: la 1 no
# encontraba el archivo (ya estaba en _duplicates) y se saltaba, y
# la 2 lo devolvia a "# Hacks y Otros #", NO a su carpeta original.
# Ahora se recorren en orden inverso: la 2 y despues la 1.
#
# Este test hace la secuencia completa de verdad (sin PreviewOnly):
# organizar + deduplicar + deshacer, con archivos asociados.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
$hacksFolder = Join-Path $systemFolder "# Hacks y Otros #"
$duplicatesFolder = Join-Path (Join-Path $tempRoot "_duplicates") "snes"

New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null

$saved = @{
    PreviewOnly   = $Global:Settings.PreviewOnly
    Language      = $Global:Settings.Language
    MoveAssets    = $Global:Settings.MoveAssets
    AutoConfirm   = $Global:AutoConfirm
    RetroBatRoot  = $Global:RetroBatRoot
    DuplicatesDir = $Global:DuplicatesFolder
}

$Global:Settings.PreviewOnly = $false
$Global:Settings.Language = "es"
$Global:Settings.MoveAssets = $true
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"

try
{
    #
    # Dos hacks sueltos con el MISMO contenido (copias exactas),
    # cada uno con su partida guardada (contenido distinto).
    #

    $romA = Join-Path $systemFolder "Super Game (Hack).smc"
    $romB = Join-Path $systemFolder "Another Game (Hack).smc"
    $srmA = Join-Path $systemFolder "Super Game (Hack).srm"
    $srmB = Join-Path $systemFolder "Another Game (Hack).srm"

    Set-Content -LiteralPath $romA -Value "identical hack content"
    Set-Content -LiteralPath $romB -Value "identical hack content"
    Set-Content -LiteralPath $srmA -Value "save A"
    Set-Content -LiteralPath $srmB -Value "save B"

    $null = Invoke-HackOrganizer -Root $tempRoot -SystemFolders @($systemFolder) 6>$null

    #
    # Comprobaciones previas: la secuencia hizo lo esperado
    #

    $inHacks = @(Get-ChildItem -LiteralPath $hacksFolder -Filter *.smc)
    $inDuplicates = @(Get-ChildItem -LiteralPath $duplicatesFolder -Filter *.smc -ErrorAction SilentlyContinue)

    Assert-Equal 1 $inHacks.Count "Hacks: tras organizar y deduplicar queda una sola copia en '# Hacks y Otros #'"
    Assert-Equal 1 $inDuplicates.Count "Hacks: la copia exacta esta en _duplicates\snes"
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $systemFolder -File -Filter *.smc).Count "Hacks: no queda ningun hack suelto en la carpeta del sistema"

    $plan = @(Get-Content -LiteralPath (Join-Path (Join-Path $tempRoot "Resultado") "CleanPlan.json") -Raw | ConvertFrom-Json)

    Assert-Equal 3 @($plan | Where-Object { $_.Action -eq "MOVE" }).Count "Plan: 2 movimientos de organizar + 1 de deduplicar quedan registrados"

    #
    # Deshacer
    #

    $null = Invoke-UndoLastPlan -Root $tempRoot 6>$null

    Assert-Equal $true (Test-Path -LiteralPath $romA) "Deshacer: 'Super Game (Hack).smc' vuelve a la carpeta del sistema"
    Assert-Equal $true (Test-Path -LiteralPath $romB) "Deshacer: 'Another Game (Hack).smc' vuelve a la carpeta del sistema"
    Assert-Equal $true (Test-Path -LiteralPath $srmA) "Deshacer: la partida guardada A vuelve a su sitio"
    Assert-Equal $true (Test-Path -LiteralPath $srmB) "Deshacer: la partida guardada B vuelve a su sitio"

    Assert-Equal 0 @(Get-ChildItem -LiteralPath $hacksFolder -File -ErrorAction SilentlyContinue).Count "Deshacer: '# Hacks y Otros #' queda sin archivos"
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $duplicatesFolder -File -ErrorAction SilentlyContinue).Count "Deshacer: _duplicates\snes queda sin archivos"

    if(Test-Path -LiteralPath $romA)
    {
        Assert-Equal "identical hack content" ((Get-Content -LiteralPath $romA -Raw).Trim()) "Deshacer: el contenido de la ROM restaurada no cambia"
    }
}
finally
{
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:Settings.Language = $saved.Language
    $Global:Settings.MoveAssets = $saved.MoveAssets
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.RetroBatRoot
    $Global:DuplicatesFolder = $saved.DuplicatesDir

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
