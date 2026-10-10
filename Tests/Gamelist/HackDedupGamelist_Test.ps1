# ============================================================
# MEJORA: la deduplicacion de hacks (copias exactas dentro de
# "# Hacks y Otros #") tambien pasa los datos del usuario del
# gamelist.xml (favorito, veces jugada...) a la copia que se
# queda, igual que la limpieza normal de ROMs.
#
# Antes esa ruta quedaba fuera de la fusion del gamelist.xml.
# El test no asume cual de las dos copias se conserva: comprueba
# que la que sobrevive tiene los datos de las dos.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
$hacksFolder = Join-Path $systemFolder "# Hacks y Otros #"
New-Item -ItemType Directory -Path $hacksFolder -Force | Out-Null

$saved = @{
    PreviewOnly = $Global:Settings.PreviewOnly
    Language    = $Global:Settings.Language
    Merge       = $Global:Settings.MergeGamelistMetadata
    AutoConfirm = $Global:AutoConfirm
    Root        = $Global:RetroBatRoot
    Dup         = $Global:DuplicatesFolder
}

$Global:Settings.PreviewOnly = $false
$Global:Settings.Language = "es"
$Global:Settings.MergeGamelistMetadata = $true
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"

try
{
    Set-Content -LiteralPath (Join-Path $hacksFolder "Hack Uno (Hack).smc") -Value "mismo contenido de hack"
    Set-Content -LiteralPath (Join-Path $hacksFolder "Hack Dos (Hack).smc") -Value "mismo contenido de hack"

    $gamelist = Join-Path $systemFolder "gamelist.xml"

    Set-Content -LiteralPath $gamelist -Value @'
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./# Hacks y Otros #/Hack Uno (Hack).smc</path>
		<name>Hack Uno</name>
		<favorite>true</favorite>
		<playcount>9</playcount>
	</game>
	<game>
		<path>./# Hacks y Otros #/Hack Dos (Hack).smc</path>
		<name>Hack Dos</name>
		<playcount>1</playcount>
		<rating>0.7</rating>
	</game>
</gameList>
'@

    $null = Invoke-HackDeduplication -Root $tempRoot -HacksFolders @($hacksFolder) 6>$null

    $remaining = @(Get-ChildItem -LiteralPath $hacksFolder -Filter *.smc)

    Assert-Equal 1 $remaining.Count "Hack dedup: queda una sola copia en '# Hacks y Otros #'"

    [xml]$doc = Get-Content -LiteralPath $gamelist -Raw

    $entry = @($doc.gameList.game | Where-Object { $_.path -eq ("./# Hacks y Otros #/" + $remaining[0].Name) })

    Assert-Equal 1 $entry.Count "Hack dedup: la copia que queda sigue teniendo su entrada en el gamelist.xml"
    Assert-Equal "true" $entry[0].favorite "Hack dedup: la copia que queda conserva el favorito"
    Assert-Equal "9" $entry[0].playcount "Hack dedup: la copia que queda conserva el mayor playcount"
    Assert-Equal "0.7" $entry[0].rating "Hack dedup: la copia que queda conserva la mejor nota"

    $plan = @(Get-Content -LiteralPath (Join-Path (Join-Path $tempRoot "Resultado") "CleanPlan.json") -Raw | ConvertFrom-Json)
    $move = @($plan | Where-Object { $_.Action -eq "MOVE" })

    Assert-Equal 1 $move.Count "Hack dedup: el movimiento queda registrado en el plan"
    Assert-Equal $remaining[0].FullName $move[0].WinnerPath "Hack dedup: el plan guarda cual es la copia que se queda (WinnerPath)"

    $backups = @(Get-ChildItem -LiteralPath (Join-Path (Join-Path $tempRoot "Resultado") "GamelistBackups") -Filter "gamelist_snes_*.xml" -ErrorAction SilentlyContinue)

    Assert-Equal 1 $backups.Count "Hack dedup: se hace copia de seguridad del gamelist.xml antes de guardarlo"
}
finally
{
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:Settings.Language = $saved.Language
    $Global:Settings.MergeGamelistMetadata = $saved.Merge
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
