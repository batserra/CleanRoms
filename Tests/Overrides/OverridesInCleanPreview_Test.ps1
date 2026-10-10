# ============================================================
# MEJORA: los overrides se aplican de verdad en la limpieza.
#
# Con ROMs reales en disco y el flujo real (Scan-Roms ->
# Group-Roms -> Invoke-CleanPreview):
# - Sin Overrides.json decide el motor (se anota quien gana).
# - Un "Prefer" sobre la ROM que PERDIA la hace ganar, y la otra
#   se mueve. Los motivos mencionan la decision manual.
# - Un "Ignore" por titulo deja el grupo sin tocar (ni KEEP ni
#   MOVE), sin afectar a otros grupos.
# - Un "Prefer" que apunta a un archivo que no esta en el grupo
#   no cambia nada.
# ============================================================

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null

$ovFile = Join-Path $tempRoot "Overrides.json"

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    PreviewOnly   = $Global:Settings.PreviewOnly
    AutoConfirm   = $Global:AutoConfirm
    Root          = $Global:RetroBatRoot
    Dup           = $Global:DuplicatesFolder
}

$Global:OverridesPath = $ovFile
$Global:Settings.Language = "es"
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"

function Get-TestGroups
{
    $roms = @(Get-RomsFromFolder -Path $systemFolder -SystemName "snes")
    $roms = @(Update-NormalizedTitles $roms)

    return @(Group-Roms -Roms $roms -SystemName "snes")
}

try
{
    Set-Content -LiteralPath (Join-Path $systemFolder "Alpha Game (USA).sfc") -Value "alpha usa"
    Set-Content -LiteralPath (Join-Path $systemFolder "Alpha Game (Europe).sfc") -Value "alpha europe"
    Set-Content -LiteralPath (Join-Path $systemFolder "Gamma Game (USA).sfc") -Value "beta usa"
    Set-Content -LiteralPath (Join-Path $systemFolder "Gamma Game (Europe).sfc") -Value "beta europe"

    #
    # Sin overrides: decide el motor
    #

    $groups = Get-TestGroups
    Assert-Equal 2 $groups.Count "Preview: hay dos grupos de duplicados"

    $actions = @(Invoke-CleanPreview -Groups $groups -Root $tempRoot 6>$null)

    $alphaKeep = @($actions | Where-Object { $_.Action -eq "KEEP" -and (Split-Path $_.Source -Leaf) -like "Alpha*" })[0]
    $alphaMove = @($actions | Where-Object { $_.Action -eq "MOVE" -and (Split-Path $_.Source -Leaf) -like "Alpha*" })[0]

    Assert-Equal 4 $actions.Count "Preview sin overrides: 2 KEEP + 2 MOVE"

    $defaultWinner = Split-Path $alphaKeep.Source -Leaf
    $defaultLoser = Split-Path $alphaMove.Source -Leaf

    #
    # Prefer sobre la ROM que perdia
    #

    @{ Prefer = @(@{ System = "snes"; File = $defaultLoser }); Ignore = @() } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ovFile -Encoding UTF8

    $groups = Get-TestGroups
    $actions = @(Invoke-CleanPreview -Groups $groups -Root $tempRoot 6>$null)

    $alphaKeep2 = @($actions | Where-Object { $_.Action -eq "KEEP" -and (Split-Path $_.Source -Leaf) -like "Alpha*" })[0]
    $alphaMove2 = @($actions | Where-Object { $_.Action -eq "MOVE" -and (Split-Path $_.Source -Leaf) -like "Alpha*" })[0]

    Assert-Equal $defaultLoser (Split-Path $alphaKeep2.Source -Leaf) "Preview con Prefer: la ROM fijada pasa a ganar"
    Assert-Equal $defaultWinner (Split-Path $alphaMove2.Source -Leaf) "Preview con Prefer: la que ganaba por puntuacion ahora se mueve"
    Assert-Equal $true ($alphaKeep2.Reason -match "Overrides.json") "Preview con Prefer: el motivo del KEEP menciona la decision manual"
    Assert-Equal $true ($alphaMove2.Reason -match "Overrides.json") "Preview con Prefer: el motivo del MOVE menciona la decision manual"
    Assert-Equal (Join-Path $systemFolder $defaultLoser) $alphaMove2.WinnerPath "Preview con Prefer: WinnerPath apunta a la ROM fijada"
    Assert-Equal 4 $actions.Count "Preview con Prefer: el otro grupo sigue igual (2 KEEP + 2 MOVE)"

    #
    # Prefer que no esta en el grupo: no cambia nada
    #

    @{ Prefer = @(@{ System = "snes"; File = "No Existe (Japan).sfc" }); Ignore = @() } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ovFile -Encoding UTF8

    $groups = Get-TestGroups
    $actions = @(Invoke-CleanPreview -Groups $groups -Root $tempRoot 6>$null)

    $keepAgain = @($actions | Where-Object { $_.Action -eq "KEEP" -and (Split-Path $_.Source -Leaf) -like "Alpha*" })[0]

    Assert-Equal $defaultWinner (Split-Path $keepAgain.Source -Leaf) "Preview: un Prefer que no coincide con ninguna ROM no cambia la decision"

    #
    # Ignore por titulo
    #

    @{ Prefer = @(); Ignore = @(@{ System = "snes"; Title = "Alpha Game" }) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ovFile -Encoding UTF8

    $groups = Get-TestGroups
    $actions = @(Invoke-CleanPreview -Groups $groups -Root $tempRoot 6>$null)

    Assert-Equal 0 @($actions | Where-Object { (Split-Path $_.Source -Leaf) -like "Alpha*" }).Count "Preview con Ignore: el grupo ignorado no genera ninguna accion"
    Assert-Equal 2 @($actions | Where-Object { (Split-Path $_.Source -Leaf) -like "Gamma*" }).Count "Preview con Ignore: el otro grupo se procesa con normalidad"
}
finally
{
    $Global:OverridesPath = $saved.OverridesPath
    $Global:Settings.Language = $saved.Language
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup
    $Global:OverrideContextSystem = ""

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
