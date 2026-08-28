# ============================================================
# BUG corregido: Get-VersionScore y Get-RevisionScore
# (DecisionEngine.ps1) calculaban la puntuación con una fórmula
# fija que daba una DÉCIMA PARTE de lo que indica la tabla de
# Config\DecisionWeights.ps1 y el manual de usuario (p.ej. V1.1
# daba 11 puntos en vez de los 110 documentados; Rev2 daba 2 en
# vez de 20).
#
# Como $Rom.Version / $Rom.Revision nunca se rellenaban antes de
# la v2.6 (ver el otro bug ya corregido en RomParser.ps1), este
# error nunca había llegado a manifestarse en la práctica -- al
# arreglar la detección, quedó al descubierto.
#
# Ahora Get-VersionScore/Get-RevisionScore buscan primero una
# clave exacta en Config\DecisionWeights.ps1 (p.ej. "Version_1_1",
# "Revision_2"), así que la tabla es de verdad editable como
# promete el manual, y solo recurren a una fórmula genérica (ya
# con la escala correcta) para valores que no estén listados ahí.
# ============================================================

# -------------------------------------------------------
# Valores exactos de la tabla (deben coincidir con
# Config\DecisionWeights.ps1 y con la sección 2 del manual)
# -------------------------------------------------------

$versionCases = @{
    "1.0" = 100
    "1.1" = 110
    "1.2" = 120
    "1.3" = 130
}

foreach($version in $versionCases.Keys)
{
    $rom = New-TestRom -Title "Game (V$version).smc" -NormalizedTitle "game" -Version $version

    $score = Get-VersionScore -Rom $rom

    Assert-Equal `
        $versionCases[$version] `
        $score `
        "Get-VersionScore: V$version debe dar $($versionCases[$version]) puntos (tabla documentada)"
}

$revisionCases = @{
    "0" = 0
    "1" = 10
    "2" = 20
    "3" = 30
    "4" = 40
}

foreach($revision in $revisionCases.Keys)
{
    $rom = New-TestRom -Title "Game (Rev $revision).smc" -NormalizedTitle "game" -Revision $revision

    $score = Get-RevisionScore -Rom $rom

    Assert-Equal `
        $revisionCases[$revision] `
        $score `
        "Get-RevisionScore: Rev$revision debe dar $($revisionCases[$revision]) puntos (tabla documentada)"
}

# -------------------------------------------------------
# Valores NO listados en la tabla: deben calcularse solos,
# con la misma escala (version x100, revision x10), no dar 0
# ni fallar.
# -------------------------------------------------------

$romVersionAlta = New-TestRom -Title "Game (V1.4).smc" -NormalizedTitle "game" -Version "1.4"

Assert-Equal `
    140 `
    (Get-VersionScore -Rom $romVersionAlta) `
    "Get-VersionScore: V1.4 (no listada) debe calcularse sola como 140, no dar 0"

$romRevisionAlta = New-TestRom -Title "Game (Rev 5).smc" -NormalizedTitle "game" -Revision "5"

Assert-Equal `
    50 `
    (Get-RevisionScore -Rom $romRevisionAlta) `
    "Get-RevisionScore: Rev5 (no listada) debe calcularse sola como 50, no dar 0"

# -------------------------------------------------------
# Sin version/revision: debe seguir dando 0, como siempre
# -------------------------------------------------------

$romSinVersion = New-TestRom -Title "Game.smc" -NormalizedTitle "game"

Assert-Equal `
    0 `
    (Get-VersionScore -Rom $romSinVersion) `
    "Get-VersionScore: sin version debe dar 0"

Assert-Equal `
    0 `
    (Get-RevisionScore -Rom $romSinVersion) `
    "Get-RevisionScore: sin revision debe dar 0"
