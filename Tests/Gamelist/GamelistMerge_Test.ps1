# ============================================================
# MEJORA: al mover una ROM duplicada, sus datos de usuario del
# gamelist.xml de RetroBat (favorito, veces jugada, ultima
# partida, nota...) se fusionan en la entrada de la ROM que se
# queda, en vez de perderse.
#
# Este test fabrica un sistema "snes" con un gamelist.xml real y
# comprueba:
# - Se fusionan favorito / playcount / lastplayed / rating, y los
#   campos descriptivos solo si faltaban.
# - NUNCA se copian rutas de imagen ni se borra la entrada de la
#   ROM movida.
# - Si la ROM que se queda no tenia entrada, se crea una nueva.
# - Se hace copia de seguridad antes de guardar.
# - Ejecutarlo dos veces no cambia nada mas (idempotente).
# - PreviewOnly, el interruptor MergeGamelistMetadata y un XML
#   corrupto no tocan ni rompen nada.
# - New-CleanAction guarda WinnerPath.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
$dupFolder = Join-Path $tempRoot "_duplicates\snes"

New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null
New-Item -ItemType Directory -Path $dupFolder -Force | Out-Null

$originalSettings = @{
    PreviewOnly = $Global:Settings.PreviewOnly
    Merge       = $Global:Settings.MergeGamelistMetadata
}

function New-TestGamelist
{
    param([string]$Path, [string]$Body)

    $xml = "<?xml version=`"1.0`"?>`n<gameList>`n$Body</gameList>`n"
    [System.IO.File]::WriteAllText($Path, $xml, (New-Object System.Text.UTF8Encoding($false)))
}

function New-TestMove
{
    param([string]$LoserName, [string]$WinnerName, [bool]$LoserMoved = $true)

    # Simula una ROM ya movida: no esta en el sistema y si en _duplicates
    if($LoserMoved)
    {
        Set-Content -LiteralPath (Join-Path $dupFolder $LoserName) -Value "x"
    }

    return [PSCustomObject]@{
        Action     = "MOVE"
        Source     = (Join-Path $systemFolder $LoserName)
        Target     = $dupFolder
        System     = "snes"
        WinnerPath = (Join-Path $systemFolder $WinnerName)
    }
}

$gamelist = Join-Path $systemFolder "gamelist.xml"

$body = @"
	<game>
		<path>./Game (USA).sfc</path>
		<name>Game</name>
		<playcount>2</playcount>
		<lastplayed>20230101T100000</lastplayed>
		<image>./images/Game (USA)-image.png</image>
	</game>
	<game>
		<path>./Game (Europe).sfc</path>
		<name>Game EU</name>
		<desc>Una descripcion &amp; mas</desc>
		<rating>0.8</rating>
		<favorite>true</favorite>
		<playcount>5</playcount>
		<lastplayed>20240315T200000</lastplayed>
		<image>./images/Game (Europe)-image.png</image>
	</game>
	<game>
		<path>./Other (Japan).sfc</path>
		<name>Other JP</name>
		<favorite>true</favorite>
		<playcount>3</playcount>
		<image>./images/Other (Japan)-image.png</image>
	</game>
"@

try
{
    #
    # 1) Fusion normal + creacion de entrada para el ganador
    #

    New-TestGamelist -Path $gamelist -Body $body

    $plan = [PSCustomObject]@{
        MoveActions = @(
            (New-TestMove "Game (Europe).sfc" "Game (USA).sfc"),
            (New-TestMove "Other (Japan).sfc" "Other (USA).sfc")
        )
    }

    $Global:Settings.PreviewOnly = $false
    $Global:Settings.MergeGamelistMetadata = $true

    $r = Invoke-GamelistMerge -Plan $plan -SystemFolders @($systemFolder) -Root $tempRoot 6>$null

    Assert-Equal 1 $r.Updated "Gamelist: una entrada existente actualizada"
    Assert-Equal 1 $r.Created "Gamelist: una entrada nueva creada para el ganador sin entrada"

    [xml]$doc = Get-Content -LiteralPath $gamelist -Raw

    $win = @($doc.gameList.game | Where-Object { $_.path -eq "./Game (USA).sfc" })[0]

    Assert-Equal "true" $win.favorite "Gamelist: favorito se hereda"
    Assert-Equal "5" $win.playcount "Gamelist: playcount = el mayor (no se suma)"
    Assert-Equal "20240315T200000" $win.lastplayed "Gamelist: lastplayed = el mas reciente"
    Assert-Equal "0.8" $win.rating "Gamelist: rating = el mas alto"
    Assert-Equal "Una descripcion & mas" $win.desc "Gamelist: desc se copia si faltaba (y los & sobreviven)"
    Assert-Equal "Game" $win.name "Gamelist: name del ganador NO se pisa"
    Assert-Equal "./images/Game (USA)-image.png" $win.image "Gamelist: la imagen del ganador queda intacta"

    $created = @($doc.gameList.game | Where-Object { $_.path -eq "./Other (USA).sfc" })[0]

    Assert-Equal $true ($null -ne $created) "Gamelist: se crea la entrada del ganador sin entrada"
    Assert-Equal "true" $created.favorite "Gamelist: la entrada nueva hereda favorito"
    Assert-Equal "3" $created.playcount "Gamelist: la entrada nueva hereda playcount"
    Assert-Equal 0 @($created.ChildNodes | Where-Object { $_.Name -eq "image" }).Count "Gamelist: NUNCA se copian rutas de imagen a una entrada nueva"

    $loser = @($doc.gameList.game | Where-Object { $_.path -eq "./Game (Europe).sfc" })[0]

    Assert-Equal $true ($null -ne $loser) "Gamelist: la entrada de la ROM movida NO se borra"
    Assert-Equal 4 @($doc.gameList.game).Count "Gamelist: 3 entradas originales + 1 nueva"

    $backupFolder = Join-Path $tempRoot "Resultado\GamelistBackups"
    $backups = @(Get-ChildItem -LiteralPath $backupFolder -Filter "gamelist_snes_*.xml" -ErrorAction SilentlyContinue)

    Assert-Equal 1 $backups.Count "Gamelist: se crea una copia de seguridad antes de guardar"

    $backupText = Get-Content -LiteralPath $backups[0].FullName -Raw
    Assert-Equal $false ($backupText -match "Other \(USA\)") "Gamelist: la copia es la version ANTERIOR a la fusion"

    #
    # 2) Idempotencia: repetir no cambia nada ni crea otra copia
    #

    $r2 = Invoke-GamelistMerge -Plan $plan -SystemFolders @($systemFolder) -Root $tempRoot 6>$null

    Assert-Equal 0 ($r2.Updated + $r2.Created) "Gamelist: repetir la fusion no cambia nada (idempotente)"
    Assert-Equal 1 @(Get-ChildItem -LiteralPath $backupFolder -Filter "gamelist_snes_*.xml").Count "Gamelist: sin cambios no se hace otra copia"

    #
    # 3) PreviewOnly: informa pero no toca el archivo
    #

    New-TestGamelist -Path $gamelist -Body $body
    $before = Get-Content -LiteralPath $gamelist -Raw

    $Global:Settings.PreviewOnly = $true
    $r3 = Invoke-GamelistMerge -Plan $plan -SystemFolders @($systemFolder) -Root $tempRoot 6>$null

    Assert-Equal 2 ($r3.Updated + $r3.Created) "Gamelist PreviewOnly: cuenta lo que haria"
    Assert-Equal $before (Get-Content -LiteralPath $gamelist -Raw) "Gamelist PreviewOnly: el archivo no se modifica"

    #
    # 4) Interruptor desactivado
    #

    $Global:Settings.PreviewOnly = $false
    $Global:Settings.MergeGamelistMetadata = $false

    $r4 = Invoke-GamelistMerge -Plan $plan -SystemFolders @($systemFolder) -Root $tempRoot 6>$null

    Assert-Equal 0 ($r4.Updated + $r4.Created) "Gamelist: MergeGamelistMetadata = false no hace nada"
    Assert-Equal $before (Get-Content -LiteralPath $gamelist -Raw) "Gamelist: desactivado, el archivo no se modifica"

    $Global:Settings.MergeGamelistMetadata = $true

    #
    # 5) ROM que NO se llego a mover: no se fusiona
    #

    Remove-Item -LiteralPath (Join-Path $dupFolder "Game (Europe).sfc") -Force
    Set-Content -LiteralPath (Join-Path $systemFolder "Game (Europe).sfc") -Value "x"

    $planNotMoved = [PSCustomObject]@{
        MoveActions = @(
            [PSCustomObject]@{
                Action = "MOVE"; System = "snes"; Target = $dupFolder
                Source = (Join-Path $systemFolder "Game (Europe).sfc")
                WinnerPath = (Join-Path $systemFolder "Game (USA).sfc")
            }
        )
    }

    $r5 = Invoke-GamelistMerge -Plan $planNotMoved -SystemFolders @($systemFolder) -Root $tempRoot 6>$null

    Assert-Equal 0 ($r5.Updated + $r5.Created) "Gamelist: una ROM que no se movio no se fusiona"

    #
    # 6) XML corrupto: avisa, no revienta y no lo modifica
    #

    Set-Content -LiteralPath $gamelist -Value "<gameList><game>esto no cierra"
    $corrupt = Get-Content -LiteralPath $gamelist -Raw

    $threw = $false

    try
    {
        $null = Invoke-GamelistMerge -Plan $plan -SystemFolders @($systemFolder) -Root $tempRoot 6>$null 3>$null
    }
    catch
    {
        $threw = $true
    }

    Assert-Equal $false $threw "Gamelist: un XML corrupto no lanza excepcion"
    Assert-Equal $corrupt (Get-Content -LiteralPath $gamelist -Raw) "Gamelist: un XML corrupto no se modifica"

    #
    # 7) Sin gamelist.xml: no hace nada
    #

    Remove-Item -LiteralPath $gamelist -Force

    $r7 = Invoke-GamelistMerge -Plan $plan -SystemFolders @($systemFolder) -Root $tempRoot 6>$null

    Assert-Equal 0 ($r7.Updated + $r7.Created) "Gamelist: sin gamelist.xml no hay nada que fusionar"
    Assert-Equal $false (Test-Path -LiteralPath $gamelist) "Gamelist: no se crea un gamelist.xml que no existia"

    #
    # 8) New-CleanAction guarda WinnerPath
    #

    $fakeRom = New-TestRom -Title (Join-Path $systemFolder "Game (Europe).sfc") -NormalizedTitle "game"

    $action = New-CleanAction -Action "MOVE" -Rom $fakeRom -Target $dupFolder -Reason "t" -Hash "abc" -System "snes" -WinnerPath "C:\x\Game.sfc"

    Assert-Equal "C:\x\Game.sfc" $action.WinnerPath "New-CleanAction: guarda WinnerPath"

    $actionKeep = New-CleanAction -Action "KEEP" -Rom $fakeRom -Reason "t" -Hash "abc"

    Assert-Equal "" $actionKeep.WinnerPath "New-CleanAction: WinnerPath vacio por defecto"
}
finally
{
    $Global:Settings.PreviewOnly = $originalSettings.PreviewOnly
    $Global:Settings.MergeGamelistMetadata = $originalSettings.Merge

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
