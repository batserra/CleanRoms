# ============================================================
# BUG corregido: al organizar los hacks sueltos en
# "# Hacks y Otros #", su entrada del gamelist.xml se quedaba con la
# ruta ANTIGUA. RetroBat dejaba de asociar el juego con su entrada y
# se perdian los favoritos, las veces jugada, etc. de esos hacks.
#
# Ahora la <path> de cada entrada sigue al archivo:
# - Organizar: "./Juego (Hack).smc" -> "./# Hacks y Otros #/Juego (Hack).smc"
#   (con copia de seguridad del gamelist.xml).
# - Deshacer la ultima limpieza: la ruta vuelve a la original.
# - Si luego se deduplican copias exactas dentro de "# Hacks y Otros #",
#   ya se encuentran las entradas y se fusionan sus datos (antes era
#   un "limite conocido": no coincidian las rutas).
# - Sin entrada, con PreviewOnly o con MergeGamelistMetadata = $false:
#   el gamelist.xml no se toca.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$saved = @{
    PreviewOnly = $Global:Settings.PreviewOnly
    Language    = $Global:Settings.Language
    Merge       = $Global:Settings.MergeGamelistMetadata
    Assets      = $Global:Settings.MoveAssets
    AutoConfirm = $Global:AutoConfirm
    Root        = $Global:RetroBatRoot
    Dup         = $Global:DuplicatesFolder
}

$Global:Settings.PreviewOnly = $false
$Global:Settings.Language = "es"
$Global:Settings.MergeGamelistMetadata = $true
$Global:Settings.MoveAssets = $true
$Global:AutoConfirm = $true
$Global:DuplicatesFolder = "_duplicates"

$tempRoots = @()

function New-Fixture
{
    $root = New-TestTempFolder
    $script:tempRoots += $root
    $sys = Join-Path $root "snes"
    New-Item -ItemType Directory -Path $sys -Force | Out-Null
    $Global:RetroBatRoot = $root
    return [PSCustomObject]@{ Root = $root; System = $sys; Gamelist = (Join-Path $sys "gamelist.xml"); Hacks = (Join-Path $sys "# Hacks y Otros #") }
}

function Get-EntryByName
{
    param([string]$Gamelist, [string]$Name)

    [xml]$doc = Get-Content -LiteralPath $Gamelist -Raw
    return @($doc.gameList.game | Where-Object { $_.name -eq $Name })[0]
}

function Get-BackupCount
{
    param($Fixture)

    return @(Get-ChildItem -LiteralPath (Join-Path (Join-Path $Fixture.Root "Resultado") "GamelistBackups") -Filter "gamelist_snes_*.xml" -ErrorAction SilentlyContinue).Count
}

try
{
    #
    # A) Un hack con entrada: la ruta lo sigue y Deshacer la devuelve
    #

    $f = New-Fixture

    Set-Content -LiteralPath (Join-Path $f.System "Super Game (Hack).smc") -Value "hack rom"
    Set-Content -LiteralPath (Join-Path $f.System "Normal (USA).sfc") -Value "normal rom"

    Set-Content -LiteralPath $f.Gamelist -Value @'
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./Super Game (Hack).smc</path>
		<name>Super Game</name>
		<favorite>true</favorite>
		<playcount>4</playcount>
	</game>
	<game>
		<path>./Normal (USA).sfc</path>
		<name>Normal</name>
		<playcount>1</playcount>
	</game>
</gameList>
'@

    $null = Invoke-HackOrganizer -Root $f.Root -SystemFolders @($f.System) 6>$null

    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $f.Hacks "Super Game (Hack).smc")) "A) el hack se mueve a '# Hacks y Otros #'"

    $hackEntry = Get-EntryByName $f.Gamelist "Super Game"
    $normalEntry = Get-EntryByName $f.Gamelist "Normal"

    Assert-Equal "./# Hacks y Otros #/Super Game (Hack).smc" $hackEntry.path "A) la entrada del hack sigue al archivo (nueva ruta)"
    Assert-Equal "true" $hackEntry.favorite "A) el favorito del hack se conserva"
    Assert-Equal "4" $hackEntry.playcount "A) las veces jugado del hack se conservan"
    Assert-Equal "./Normal (USA).sfc" $normalEntry.path "A) la entrada de la ROM normal no se toca"
    Assert-Equal 2 ([xml](Get-Content -LiteralPath $f.Gamelist -Raw)).gameList.game.Count "A) no se crean ni se pierden entradas"
    Assert-Equal 1 (Get-BackupCount $f) "A) se hace copia de seguridad del gamelist.xml"

    $plan = @(Get-Content -LiteralPath (Join-Path (Join-Path $f.Root "Resultado") "CleanPlan.json") -Raw | ConvertFrom-Json)
    $move = @($plan | Where-Object { $_.Action -eq "MOVE" })[0]

    Assert-Equal $true $move.GamelistUpdated "A) el plan anota que se actualizo la entrada del gamelist.xml"

    $null = Invoke-UndoLastPlan -Root $f.Root 6>$null

    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $f.System "Super Game (Hack).smc")) "A) Deshacer: el hack vuelve a su carpeta"
    Assert-Equal "./Super Game (Hack).smc" (Get-EntryByName $f.Gamelist "Super Game").path "A) Deshacer: la entrada recupera su ruta original"
    Assert-Equal "true" (Get-EntryByName $f.Gamelist "Super Game").favorite "A) Deshacer: el favorito sigue ahi"
    Assert-Equal "./Normal (USA).sfc" (Get-EntryByName $f.Gamelist "Normal").path "A) Deshacer: la otra entrada sigue igual"

    #
    # B) Hack sin entrada: el gamelist.xml no se toca
    #

    $f = New-Fixture

    Set-Content -LiteralPath (Join-Path $f.System "Orphan (Hack).smc") -Value "hack rom"

    Set-Content -LiteralPath $f.Gamelist -Value @'
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./Something Else.sfc</path>
		<name>Something</name>
	</game>
</gameList>
'@

    $before = Get-Content -LiteralPath $f.Gamelist -Raw

    $null = Invoke-HackOrganizer -Root $f.Root -SystemFolders @($f.System) 6>$null

    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $f.Hacks "Orphan (Hack).smc")) "B) el hack sin entrada se mueve igualmente"
    Assert-Equal $before (Get-Content -LiteralPath $f.Gamelist -Raw) "B) sin entrada, el gamelist.xml no se modifica"
    Assert-Equal 0 (Get-BackupCount $f) "B) sin cambios no se hace copia de seguridad"

    $plan = @(Get-Content -LiteralPath (Join-Path (Join-Path $f.Root "Resultado") "CleanPlan.json") -Raw | ConvertFrom-Json)
    Assert-Equal $null (@($plan | Where-Object { $_.Action -eq "MOVE" })[0].PSObject.Properties["GamelistUpdated"]) "B) sin entrada, el plan no marca nada"

    #
    # C) PreviewOnly y MergeGamelistMetadata = $false
    #

    foreach($mode in "preview", "disabled")
    {
        $f = New-Fixture

        Set-Content -LiteralPath (Join-Path $f.System "Mode (Hack).smc") -Value "hack rom"

        Set-Content -LiteralPath $f.Gamelist -Value @'
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./Mode (Hack).smc</path>
		<name>Mode</name>
	</game>
</gameList>
'@

        $before = Get-Content -LiteralPath $f.Gamelist -Raw

        if($mode -eq "preview") { $Global:Settings.PreviewOnly = $true } else { $Global:Settings.MergeGamelistMetadata = $false }

        $null = Invoke-HackOrganizer -Root $f.Root -SystemFolders @($f.System) 6>$null

        $Global:Settings.PreviewOnly = $false
        $Global:Settings.MergeGamelistMetadata = $true

        Assert-Equal $before (Get-Content -LiteralPath $f.Gamelist -Raw) "C) modo '$mode': el gamelist.xml no se toca"
    }

    #
    # D) Mayusculas distintas en la ruta de la entrada
    #

    $f = New-Fixture

    Set-Content -LiteralPath (Join-Path $f.System "Case Game (Hack).smc") -Value "hack rom"

    Set-Content -LiteralPath $f.Gamelist -Value @'
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./CASE GAME (HACK).SMC</path>
		<name>Case</name>
	</game>
</gameList>
'@

    $null = Invoke-HackOrganizer -Root $f.Root -SystemFolders @($f.System) 6>$null

    Assert-Equal "./# Hacks y Otros #/Case Game (Hack).smc" (Get-EntryByName $f.Gamelist "Case").path "D) la entrada se encuentra aunque cambien las mayusculas"

    #
    # E) Organizar + deduplicar copias exactas en la misma pasada:
    #    ahora SI se fusionan los datos, y Deshacer devuelve todo
    #

    $f = New-Fixture

    Set-Content -LiteralPath (Join-Path $f.System "Alpha (Hack).smc") -Value "identical hack content"
    Set-Content -LiteralPath (Join-Path $f.System "Beta (Hack).smc") -Value "identical hack content"

    Set-Content -LiteralPath $f.Gamelist -Value @'
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./Alpha (Hack).smc</path>
		<name>Alpha</name>
		<favorite>true</favorite>
		<playcount>9</playcount>
	</game>
	<game>
		<path>./Beta (Hack).smc</path>
		<name>Beta</name>
		<playcount>1</playcount>
		<rating>0.7</rating>
	</game>
</gameList>
'@

    $null = Invoke-HackOrganizer -Root $f.Root -SystemFolders @($f.System) 6>$null

    $survivor = @(Get-ChildItem -LiteralPath $f.Hacks -Filter *.smc)

    Assert-Equal 1 $survivor.Count "E) queda una sola copia en '# Hacks y Otros #'"

    [xml]$doc = Get-Content -LiteralPath $f.Gamelist -Raw
    $entry = @($doc.gameList.game | Where-Object { $_.path -eq ("./# Hacks y Otros #/" + $survivor[0].Name) })[0]

    Assert-Equal $true ($null -ne $entry) "E) la copia que queda tiene su entrada con la ruta nueva"
    Assert-Equal "true" $entry.favorite "E) hereda el favorito de la otra copia"
    Assert-Equal "9" $entry.playcount "E) hereda el mayor playcount"
    Assert-Equal "0.7" $entry.rating "E) hereda la mejor nota"

    $null = Invoke-UndoLastPlan -Root $f.Root 6>$null

    foreach($name in "Alpha (Hack).smc", "Beta (Hack).smc")
    {
        Assert-Equal $true (Test-Path -LiteralPath (Join-Path $f.System $name)) "E) Deshacer: $name vuelve a su carpeta"
    }

    [xml]$doc = Get-Content -LiteralPath $f.Gamelist -Raw
    $paths = @($doc.gameList.game | ForEach-Object { $_.path } | Sort-Object)

    Assert-Equal "./Alpha (Hack).smc,./Beta (Hack).smc" ($paths -join ",") "E) Deshacer: las dos entradas recuperan su ruta original"
}
finally
{
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:Settings.Language = $saved.Language
    $Global:Settings.MergeGamelistMetadata = $saved.Merge
    $Global:Settings.MoveAssets = $saved.Assets
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup

    foreach($r in $tempRoots) { Remove-Item -Path $r -Recurse -Force -ErrorAction SilentlyContinue }
}
