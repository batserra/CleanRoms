# ============================================================
# Traducción de fans detectada por el nombre del archivo
# No debe agruparse (ni compararse, ni moverse) con el original
# ============================================================

$original = New-TestRom `
    -Title "Football Game (USA).zip" `
    -NormalizedTitle "football game" `
    -Region "USA" `
    -Language "English"

$translation = New-TestRom `
    -Title "Football Game T(ESP) (NTSC).zip" `
    -NormalizedTitle "football game" `
    -Region "USA" `
    -Language "English" `
    -Translation $true

$groups = @(Group-Roms @($original, $translation))

Assert-Equal `
    0 `
    $groups.Count `
    "Traducción por nombre: no se agrupa con el original aunque coincida el título normalizado"
