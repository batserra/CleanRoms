# ============================================================
# BUG corregido: Show-SystemSummary (Summary.ps1) y
# Get-CleanStatistics (Cleaner.ps1) calculaban el "sistema" de
# cada acción a partir de la ruta (Split-Path dos veces), el
# mismo patrón que ya fallaba en Get-DuplicateTargetFolder: si la
# ROM vive en una subcarpeta dentro del sistema (no directamente
# en su raíz), el "sistema" calculado terminaba siendo el nombre
# de esa subcarpeta en vez del sistema real.
#
# Ahora New-CleanAction guarda el sistema real en la propia
# acción (.System) cuando quien la crea lo conoce con certeza, y
# el resumen lo usa directamente en vez de adivinarlo por ruta.
# ============================================================

$rom = New-TestRom `
    -Title "C:\RetroBat\roms\snes\Subcarpeta\Game (Europe).smc" `
    -NormalizedTitle "game"

$action = New-CleanAction -Action "KEEP" -Rom $rom -Reason "Test" -System "snes"

Assert-Equal `
    "snes" `
    $action.System `
    "New-CleanAction: debe guardar el sistema real recibido, no calcularlo de la ruta"

$fakePlan = [PSCustomObject]@{
    Actions      = @($action)
    TotalActions = 1
    TotalKeep    = 1
    TotalMove    = 0
    TotalDelete  = 0
    TotalRename  = 0
    BuildDate    = Get-Date
    Version      = "test"
}

$stats = Get-CleanStatistics -Plan $fakePlan

Assert-Equal `
    1 `
    @($stats.Systems).Count `
    "Get-CleanStatistics: debe reconocer un solo sistema (snes), no confundirlo con 'Subcarpeta'"

Assert-Equal `
    $true `
    (@($stats.Systems) -contains "snes") `
    "Get-CleanStatistics: el sistema debe ser 'snes', no el nombre de la subcarpeta"
