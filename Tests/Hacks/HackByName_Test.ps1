# ============================================================
# Hack detectado por el nombre del archivo
# No debe agruparse (ni compararse, ni moverse) con el original
# ============================================================

$original = New-TestRom `
    -Title "Super Game (USA).smc" `
    -NormalizedTitle "super game" `
    -Region "USA" `
    -Language "English"

$hack = New-TestRom `
    -Title "Super Game Edition (Hack).smc" `
    -NormalizedTitle "super game" `
    -Region "USA" `
    -Language "English" `
    -Hack $true

$groups = @(Group-Roms @($original, $hack))

Assert-Equal `
    0 `
    $groups.Count `
    "Hack por nombre: no se agrupa con el original aunque coincida el título normalizado"
