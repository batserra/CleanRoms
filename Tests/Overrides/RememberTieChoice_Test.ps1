# ============================================================
# MEJORA: al elegir a mano en un empate, el programa ofrece
# recordar la eleccion (se guarda como "Prefer" en
# Config\Overrides.json) para no volver a preguntar.
#
# - Respondiendo S: se guarda con el sistema del grupo.
# - Respondiendo N: no se crea nada.
# - En modo no interactivo (-Yes) no se pregunta ni se guarda.
# ============================================================

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null

$ovFile = Join-Path $tempRoot "Overrides.json"

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    AutoConfirm   = $Global:AutoConfirm
}

$Global:OverridesPath = $ovFile
$Global:Settings.Language = "es"
$Global:OverrideContextSystem = "snes"

# La pregunta del empate solo sale cuando NO se puede comparar el contenido
# (con contenido distinto se conservan todas sin preguntar, y con contenido
# identico se elige una sola). Un algoritmo de hash invalido hace que la
# comparacion falle, y asi se llega a la pregunta.
$savedHashAlgorithm = $Global:Settings.HashAlgorithm
$Global:Settings.HashAlgorithm = "NOSUCH"

$global:testAnswers = @()
$global:testAsked = 0

function global:Read-Host
{
    param($Prompt)

    $answer = $global:testAnswers[$global:testAsked]
    $global:testAsked++
    return $answer
}

try
{
    Set-Content -LiteralPath (Join-Path $systemFolder "Tie Game (USA).sfc") -Value "contenido uno"
    Set-Content -LiteralPath (Join-Path $systemFolder "Tie Game (Europe).sfc") -Value "contenido dos"

    $roms = @(Get-RomsFromFolder -Path $systemFolder -SystemName "snes")
    $a = $roms | Where-Object { $_.FullPath -like "*USA*" } | Select-Object -First 1
    $b = $roms | Where-Object { $_.FullPath -like "*Europe*" } | Select-Object -First 1

    $a.Score = 10
    $b.Score = 10

    #
    # Elige la 2 y recuerda
    #

    $Global:AutoConfirm = $false
    $global:testAnswers = @("2", "S")
    $global:testAsked = 0

    $winner = Resolve-RomTie -A $a -B $b 6>$null

    Assert-Equal $b.FullPath $winner.FullPath "Empate: se conserva la ROM elegida (la 2)"
    Assert-Equal 2 $global:testAsked "Empate: se pregunta cual conservar y despues si recordarlo"

    $o = Get-Overrides

    Assert-Equal 1 @($o.Prefer).Count "Empate: la eleccion se guarda como Prefer"
    Assert-Equal "Tie Game (Europe).sfc" $o.Prefer[0].File "Empate: se guarda el nombre del archivo elegido"
    Assert-Equal "snes" $o.Prefer[0].System "Empate: se guarda el sistema del grupo"

    #
    # Elige la 1 y NO recuerda
    #

    Remove-Item -LiteralPath $ovFile -Force

    $global:testAnswers = @("1", "N")
    $global:testAsked = 0

    $winner = Resolve-RomTie -A $a -B $b 6>$null

    Assert-Equal $a.FullPath $winner.FullPath "Empate: se conserva la ROM elegida (la 1)"
    Assert-Equal $false (Test-Path -LiteralPath $ovFile) "Empate: respondiendo N no se crea Overrides.json"

    #
    # Modo no interactivo: ni pregunta ni guarda
    #

    $Global:AutoConfirm = $true
    $global:testAsked = 0

    $winner = Resolve-RomTie -A $a -B $b 6>$null

    Assert-Equal 0 $global:testAsked "Empate con -Yes: no se pregunta nada"
    Assert-Equal $false (Test-Path -LiteralPath $ovFile) "Empate con -Yes: no se guarda nada"
}
finally
{
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    $Global:Settings.HashAlgorithm = $savedHashAlgorithm
    $Global:OverridesPath = $saved.OverridesPath
    $Global:Settings.Language = $saved.Language
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:OverrideContextSystem = ""

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
