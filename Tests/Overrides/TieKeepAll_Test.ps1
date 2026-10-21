# ============================================================
# EMPATES (misma puntuacion, ningun criterio las diferencia):
#
# - Contenido DISTINTO (hash distinto): no son copias de un mismo juego
#   sino juegos distintos que se parecen. Se conservan TODAS, sin mover
#   ninguna y SIN preguntar (ni en modo interactivo ni con -Yes).
#   Caso real que lo motivo: dos discos CHD de arcade Naomi 2,
#     naomi2\initdv2e\gds-0027.chd   (Initial D Arcade Stage Ver. 2, Export)
#     naomi2\initdv2j\gds-0027.chd   (Initial D Arcade Stage Ver. 2, Japan)
#   con el mismo nombre de disco en carpetas de revisiones distintas.
# - Contenido IDENTICO: se elige una sola sin preguntar (como siempre).
# - NO se pudo comparar el contenido (archivo bloqueado o ilegible): ahi
#   si hay una duda real. Se pregunta 1 / 2 / 3 (3 = conservar todas) y
#   con -Yes se conservan todas.
#
# La comparacion fallida se simula con un algoritmo de hash invalido.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    PreviewOnly   = $Global:Settings.PreviewOnly
    AutoConfirm   = $Global:AutoConfirm
    Root          = $Global:RetroBatRoot
    Dup           = $Global:DuplicatesFolder
    Hash          = $Global:Settings.HashAlgorithm
}

$Global:Settings.Language = "es"
$Global:Settings.PreviewOnly = $false
$Global:DuplicatesFolder = "_duplicates"

$global:tkAnswers = @()
$global:tkAsked = 0

function global:Read-Host
{
    param($Prompt)
    $a = $global:tkAnswers[$global:tkAsked]
    $global:tkAsked++
    return $a
}

$tempRoots = @()

function New-Fixture
{
    param([hashtable]$Files)   # ruta relativa a naomi2 -> contenido

    $root = New-TestTempFolder
    $script:tempRoots += $root
    $sys = Join-Path $root "naomi2"

    foreach($rel in $Files.Keys)
    {
        $path = Join-Path $sys $rel
        New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
        Set-Content -LiteralPath $path -Value $Files[$rel]
    }

    $Global:RetroBatRoot = $root
    $Global:OverridesPath = (Join-Path $root "Overrides.json")

    return [PSCustomObject]@{ Root = $root; System = $sys }
}

function Get-Actions
{
    param($Fixture)

    $roms = @(Get-RomsFromFolder -Path $Fixture.System -SystemName "naomi2" 6>$null)
    $roms = @(Update-NormalizedTitles $roms)
    $groups = @(Group-Roms -Roms $roms -SystemName "naomi2")

    return [PSCustomObject]@{
        Groups  = $groups
        Actions = @(Invoke-CleanPreview -Groups $groups -Root $Fixture.Root 6>$null 3>$null)
    }
}

function Set-Mode
{
    param([bool]$Interactive, [string]$Compare, [string[]]$Answers = @())

    $global:tkAnswers = $Answers
    $global:tkAsked = 0
    $Global:AutoConfirm = (-not $Interactive)

    # "unknown" = no se puede comparar el contenido (algoritmo de hash invalido)
    $Global:Settings.HashAlgorithm = if($Compare -eq "unknown") { "NOSUCH" } else { $saved.Hash }
}

try
{
    $initD = @{
        "initdv2e/gds-0027.chd" = "contenido exportacion"
        "initdv2j/gds-0027.chd" = "contenido japon distinto"
    }

    #
    # 1) Contenido distinto, modo interactivo: NO se pregunta, se conservan todas
    #

    $f = New-Fixture $initD
    Set-Mode -Interactive $true -Compare "real"

    $r = Get-Actions $f

    Assert-Equal 1 $r.Groups.Count "Initial D: las dos CHD forman un grupo (mismo nombre de disco)"
    Assert-Equal 0 $global:tkAsked "Contenido distinto (interactivo): no se pregunta nada"
    Assert-Equal 2 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Contenido distinto (interactivo): se conservan las DOS copias"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Contenido distinto (interactivo): no se mueve ninguna"
    Assert-Equal $true (@($r.Actions | Where-Object { $_.Reason -match "contenido distinto" }).Count -ge 1) "Contenido distinto: el motivo del plan explica por que se conservan"
    Assert-Equal $false $Global:TieKeepAll "Contenido distinto: la bandera interna se limpia al terminar el grupo"

    #
    # 2) Contenido distinto, modo no interactivo: igual
    #

    $f = New-Fixture $initD
    Set-Mode -Interactive $false -Compare "real"

    $r = Get-Actions $f

    Assert-Equal 0 $global:tkAsked "Contenido distinto (-Yes): no se pregunta"
    Assert-Equal 2 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Contenido distinto (-Yes): se conservan las DOS copias"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Contenido distinto (-Yes): NO se mueve ninguna (antes se movia la 2)"

    #
    # 3) Contenido identico: se elige una sola, sin preguntar
    #

    $f = New-Fixture @{ "initdv2e/gds-0027.chd" = "mismo contenido"; "initdv2j/gds-0027.chd" = "mismo contenido" }

    foreach($interactive in $true, $false)
    {
        Set-Mode -Interactive $interactive -Compare "real"

        $r = Get-Actions $f
        $label = if($interactive) { "interactivo" } else { "-Yes" }

        Assert-Equal 0 $global:tkAsked "Contenido identico ($label): no se pregunta"
        Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Contenido identico ($label): se conserva una"
        Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Contenido identico ($label): se mueve la copia exacta"
    }

    #
    # 4) NO se puede comparar el contenido: si se pregunta (1 / 2 / 3)
    #

    $f = New-Fixture $initD
    Set-Mode -Interactive $true -Compare "unknown" -Answers @("3", "N")

    $r = Get-Actions $f

    Assert-Equal 2 $global:tkAsked "Sin poder comparar: se pregunta cual conservar y despues si recordarlo"
    Assert-Equal 2 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Opcion 3: se conservan las DOS copias"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Opcion 3: no se mueve ninguna"
    Assert-Equal $false (Test-Path -LiteralPath $Global:OverridesPath) "Opcion 3 + N: no se guarda nada en Overrides.json"

    # 3 y recordar: se guarda como Ignore y el grupo ya no se toca
    $f = New-Fixture $initD
    Set-Mode -Interactive $true -Compare "unknown" -Answers @("3", "S")

    $r = Get-Actions $f
    $o = Get-Overrides

    Assert-Equal 1 @($o.Ignore).Count "Opcion 3 + S: se guarda un 'Ignore' en Overrides.json"
    Assert-Equal "naomi2" $o.Ignore[0].System "Opcion 3 + S: el Ignore lleva el sistema (naomi2)"
    Assert-Equal $r.Groups[0].Name $o.Ignore[0].Title "Opcion 3 + S: el Ignore lleva el titulo del grupo"

    Set-Mode -Interactive $false -Compare "real"
    $r2 = Get-Actions $f

    Assert-Equal 0 $r2.Actions.Count "Despues de recordarlo: el grupo se ignora (ni conserva ni mueve nada)"

    # 1 y 2 funcionan como siempre
    foreach($answer in "1", "2")
    {
        $f = New-Fixture $initD
        Set-Mode -Interactive $true -Compare "unknown" -Answers @($answer, "N")

        $r = Get-Actions $f

        Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Opcion ${answer}: se conserva una"
        Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Opcion ${answer}: se mueve la otra"
    }

    # Sin poder comparar y sin nadie que responda (-Yes): se conservan todas
    $f = New-Fixture $initD
    Set-Mode -Interactive $false -Compare "unknown"

    $r = Get-Actions $f

    Assert-Equal 0 $global:tkAsked "Sin poder comparar (-Yes): no se pregunta"
    Assert-Equal 2 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Sin poder comparar (-Yes): se conservan las dos"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Sin poder comparar (-Yes): no se mueve ninguna"

    #
    # 5) "Conservar todas" en un grupo no se contagia al siguiente
    #

    $f = New-Fixture @{
        "initdv2e/gds-0027.chd" = "exportacion"
        "initdv2j/gds-0027.chd" = "japon"
        "Alpha (USA).chd"       = "alpha usa"
        "Alpha (Europe).chd"    = "alpha europe"
    }
    Set-Mode -Interactive $true -Compare "real"

    $r = Get-Actions $f

    Assert-Equal 2 $r.Groups.Count "Dos grupos: el de Initial D y el de Alpha"
    Assert-Equal 2 @($r.Actions | Where-Object { (Split-Path $_.Source -Leaf) -eq "gds-0027.chd" -and $_.Action -eq "KEEP" }).Count "Dos grupos: Initial D conserva las dos"
    Assert-Equal 1 @($r.Actions | Where-Object { (Split-Path $_.Source -Leaf) -like "Alpha*" -and $_.Action -eq "MOVE" }).Count "Dos grupos: Alpha SI mueve una copia (la bandera no se contagia)"

    #
    # 6) Tres copias con contenido distinto: se conservan las tres sin preguntar
    #

    $f = New-Fixture @{ "a/gds-0100.chd" = "uno"; "b/gds-0100.chd" = "dos"; "c/gds-0100.chd" = "tres" }
    Set-Mode -Interactive $true -Compare "real"

    $r = Get-Actions $f

    Assert-Equal 3 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Tres copias distintas: se conservan las tres"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Tres copias distintas: no se mueve ninguna"
    Assert-Equal 0 $global:tkAsked "Tres copias distintas: no se pregunta nada"

    # ... y si no se puede comparar, se pregunta UNA sola vez (no por cada pareja)
    $f = New-Fixture @{ "a/gds-0100.chd" = "uno"; "b/gds-0100.chd" = "dos"; "c/gds-0100.chd" = "tres" }
    Set-Mode -Interactive $true -Compare "unknown" -Answers @("3", "N", "9", "9")

    $r = Get-Actions $f

    Assert-Equal 3 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Tres copias sin comparar: opcion 3 conserva las tres"
    Assert-Equal 2 $global:tkAsked "Tres copias sin comparar: se pregunta una sola vez (mas la de recordar)"
}
finally
{
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    $Global:Settings.HashAlgorithm = $saved.Hash
    $Global:OverridesPath = $saved.OverridesPath
    $Global:Settings.Language = $saved.Language
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup
    $Global:OverrideContextSystem = ""
    $Global:OverrideContextTitle = ""
    $Global:TieKeepAll = $false

    foreach($r in $tempRoots) { Remove-Item -Path $r -Recurse -Force -ErrorAction SilentlyContinue }
}
