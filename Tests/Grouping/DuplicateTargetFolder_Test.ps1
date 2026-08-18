# ============================================================
# BUG corregido: Get-DuplicateTargetFolder calculaba el nombre
# del "sistema" haciendo Split-Path dos veces sobre la ruta de
# la ROM, asumiendo que ésta vivía siempre justo dentro de la
# carpeta del sistema (p.ej. "SNES\Game.sfc" -> "SNES").
#
# Eso se rompía en cuanto la ROM vivía un nivel más adentro,
# como ocurre con la deduplicación interna de
# "# Hacks y Otros #" (Invoke-HackDeduplication en
# HackOrganizer.ps1): la ROM "Keep" usada para calcular el
# destino vive en "SNES\# Hacks y Otros #\Game.sfc", así que el
# "sistema" calculado terminaba siendo "# Hacks y Otros #", y
# los duplicados de hacks acababan movidos a
# "_duplicates\# Hacks y Otros #\" en vez de
# "_duplicates\SNES\" (o, mejor aún, quedarse dentro de la
# propia carpeta de hacks del sistema).
#
# Ahora Get-DuplicateTargetFolder recibe el nombre del sistema
# explícito en vez de adivinarlo a partir de la ruta.
# ============================================================

$Global:RetroBatRoot = "C:\RetroBat\roms"
$Global:DuplicatesFolder = "_duplicates"

#
# Caso simple: pasando el sistema correcto, el destino es el
# esperado.
#

$target = Get-DuplicateTargetFolder -SystemName "SNES"

Assert-Equal `
    (Join-Path $Global:RetroBatRoot (Join-Path $Global:DuplicatesFolder "SNES")) `
    $target `
    "Get-DuplicateTargetFolder: 'SNES' -> _duplicates\SNES"

#
# Caso del bug real: una ROM "Keep" que vive dentro de
# "# Hacks y Otros #". El nombre de sistema que le llega a
# Get-DuplicateTargetFolder debe seguir siendo el sistema real
# (calculado por quien conoce la estructura de carpetas, como
# hace Invoke-HackDeduplication), nunca el nombre de la
# subcarpeta de hacks.
#

$hacksFolder = "C:\RetroBat\roms\SNES\# Hacks y Otros #"

$systemNameComoLoCalculaHackOrganizer = Split-Path (Split-Path $hacksFolder -Parent) -Leaf

Assert-Equal `
    "SNES" `
    $systemNameComoLoCalculaHackOrganizer `
    "El nombre de sistema derivado de la carpeta de hacks debe ser 'SNES', no '# Hacks y Otros #'"

$target = Get-DuplicateTargetFolder -SystemName $systemNameComoLoCalculaHackOrganizer

Assert-Equal `
    (Join-Path $Global:RetroBatRoot (Join-Path $Global:DuplicatesFolder "SNES")) `
    $target `
    "BUG: los duplicados de '# Hacks y Otros #' deben ir a _duplicates\SNES, no a _duplicates\# Hacks y Otros #"
