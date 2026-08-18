# ============================================================
# Group-Roms debe guardar el nombre del sistema en cada grupo
# que devuelve (campo .System), para que después
# Get-DuplicateTargetFolder pueda usarlo directamente en vez de
# tener que adivinarlo a partir de la ruta de una ROM concreta.
# ============================================================

$romA = New-TestRom `
    -Title "Football Game (USA).zip" `
    -NormalizedTitle "football game" `
    -Region "USA" `
    -Language "English"

$romB = New-TestRom `
    -Title "Football Game (Europe).zip" `
    -NormalizedTitle "football game" `
    -Region "Europe" `
    -Language "English"

$groups = @(Group-Roms -Roms @($romA, $romB) -SystemName "SNES")

Assert-Equal `
    1 `
    $groups.Count `
    "Se forma un único grupo con las dos ROMs del mismo título normalizado"

if($groups.Count -eq 1)
{
    Assert-Equal `
        "SNES" `
        $groups[0].System `
        "Group-Roms: el grupo devuelto debe llevar el SystemName recibido"
}

#
# Sin indicar SystemName (uso existente en otros tests), el
# grupo se sigue formando con normalidad y System queda a $null
# en vez de romper nada.
#

$groupsSinSistema = @(Group-Roms -Roms @($romA, $romB))

Assert-Equal `
    1 `
    $groupsSinSistema.Count `
    "Group-Roms sin -SystemName sigue agrupando con normalidad (compatibilidad hacia atrás)"
