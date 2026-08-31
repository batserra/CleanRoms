# ============================================================
# BUG corregido: NamedHack, Translation, la region ESP/Spain, y
# la deteccion de version/revision usaban limites de palabra \b,
# que en .NET NO consideran el guion bajo como separador (es un
# caracter de "palabra" como una letra). Esto hacia que un nombre
# de archivo con guiones bajos en vez de espacios/parentesis
# (frecuente en sets de SNES, ver seccion 6 del manual) nunca
# coincidiera con estos patrones.
#
# Caso real reportado: "Street_Fighter_5_Hack_.smc" nunca se
# detectaba como hack, asi que nunca se organizaba en
# "# Hacks y Otros #" ni se comparaba por hash con su copia ya
# organizada alli -- quedaba duplicada sin que el programa lo
# notara.
# ============================================================

# -------------------------------------------------------
# NamedHack con guion bajo
# -------------------------------------------------------

$flagsGuionBajo = Get-RomFlags "Street_Fighter_5_Hack_"

Assert-Equal `
    $true `
    $flagsGuionBajo.NamedHack `
    "Get-RomFlags: 'Street_Fighter_5_Hack_' debe detectarse como hack (nombrado con guiones bajos)"

$flagsNormal = Get-RomFlags "Street Fighter 5 (Hack)"

Assert-Equal `
    $true `
    $flagsNormal.NamedHack `
    "Get-RomFlags: 'Street Fighter 5 (Hack)' debe seguir detectandose como hack (con parentesis, como antes)"

# No debe haber falsos positivos con palabras reales que contienen "hack"
$flagsFalsoPositivo = Get-RomFlags "Hackathon Simulator"

Assert-Equal `
    $false `
    $flagsFalsoPositivo.NamedHack `
    "Get-RomFlags: 'Hackathon Simulator' NO debe detectarse como hack (falso positivo)"

# -------------------------------------------------------
# Translation con guion bajo
# -------------------------------------------------------

$flagsTraduccion = Get-RomFlags "Juego_Translation_ESP_"

Assert-Equal `
    $true `
    $flagsTraduccion.Translation `
    "Get-RomFlags: traduccion con guiones bajos debe seguir detectandose"

# -------------------------------------------------------
# Region ESP/Spain con guion bajo
# -------------------------------------------------------

$regionGuionBajo = Get-RomRegion "Game_ESP_"

Assert-Equal `
    "ESP" `
    $regionGuionBajo `
    "Get-RomRegion: 'Game_ESP_' debe detectar la region ESP (con guiones bajos)"

# -------------------------------------------------------
# Version y revision con guion bajo
# -------------------------------------------------------

$versionGuionBajo = Get-RomVersion "Game_V1.1_"

Assert-Equal `
    "1.1" `
    $versionGuionBajo `
    "Get-RomVersion: 'Game_V1.1_' debe detectar la version 1.1 (con guiones bajos)"

$revisionGuionBajo = Get-RomRevision "Game_Rev2_"

Assert-Equal `
    "2" `
    $revisionGuionBajo `
    "Get-RomRevision: 'Game_Rev2_' debe detectar la revision 2 (con guiones bajos)"

# No debe haber falsos positivos con palabras reales tipo "Revenge"
$revisionFalsoPositivo = Get-RomRevision "Revenge_Game"

Assert-Equal `
    $null `
    $revisionFalsoPositivo `
    "Get-RomRevision: 'Revenge_Game' NO debe detectarse como revision (falso positivo)"
