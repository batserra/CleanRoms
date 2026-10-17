# ============================================================
# MEJORA: en un empate (misma puntuacion, contenido DISTINTO), ademas de
# "1" y "2" ahora se puede elegir "3" = conservar TODAS las copias sin
# mover ninguna.
#
# Caso real que lo motivo: dos discos CHD de arcade Naomi 2,
#   naomi2\initdv2e\gds-0027.chd   (Initial D Arcade Stage Ver. 2, Export)
#   naomi2\initdv2j\gds-0027.chd   (Initial D Arcade Stage Ver. 2, Japan)
# con el mismo nombre (el del disco GD-ROM) en carpetas de revisiones
# distintas y hash distinto: NO son duplicados, son juegos distintos.
#
# Ademas, en modo no interactivo (-Yes) un empate con contenido distinto
# ya NO conserva la 1 y mueve la otra: se conservan todas (con la duda,
# no se mueve nada). Con contenido IDENTICO se sigue eligiendo una sin
# preguntar.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    PreviewOnly   = $Global:Settings.PreviewOnly
    AutoConfirm   = $Global:AutoConfirm
    Root          = $Global:RetroBatRoot
    Dup           = $Global:DuplicatesFolder
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

function Set-Answers
{
    param([string[]]$Answers, [bool]$Interactive = $true)

    $global:tkAnswers = $Answers
    $global:tkAsked = 0
    $Global:AutoConfirm = (-not $Interactive)
}

try
{
    $initD = @{
        "initdv2e/gds-0027.chd" = "contenido exportacion"
        "initdv2j/gds-0027.chd" = "contenido japon distinto"
    }

    #
    # 1) Interactivo: 3 = conservar todas, sin recordar
    #

    $f = New-Fixture $initD
    Set-Answers @("3", "N")

    $r = Get-Actions $f

    Assert-Equal 1 $r.Groups.Count "Initial D: las dos CHD forman un grupo (mismo nombre de disco)"
    Assert-Equal 2 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Opcion 3: se conservan las DOS copias"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Opcion 3: no se mueve ninguna"
    Assert-Equal 2 $global:tkAsked "Opcion 3: se pregunta cual conservar y despues si recordarlo (nada mas)"
    Assert-Equal $false (Test-Path -LiteralPath $Global:OverridesPath) "Opcion 3 + N: no se guarda nada en Overrides.json"
    Assert-Equal $true (@($r.Actions | Where-Object { $_.Reason -match "contenido distinto" }).Count -ge 1) "Opcion 3: el motivo del plan explica por que se conservan"
    Assert-Equal $false $Global:TieKeepAll "Opcion 3: la bandera interna se limpia al terminar el grupo"

    #
    # 2) Interactivo: 3 y recordar -> se guarda como Ignore y ya no se vuelve a tocar
    #

    $f = New-Fixture $initD
    Set-Answers @("3", "S")

    $r = Get-Actions $f
    $o = Get-Overrides

    Assert-Equal 1 @($o.Ignore).Count "Opcion 3 + S: se guarda un 'Ignore' en Overrides.json"
    Assert-Equal "naomi2" $o.Ignore[0].System "Opcion 3 + S: el Ignore lleva el sistema (naomi2)"
    Assert-Equal $r.Groups[0].Name $o.Ignore[0].Title "Opcion 3 + S: el Ignore lleva el titulo del grupo"

    Set-Answers @() $false   # sin interaccion

    $r2 = Get-Actions $f

    Assert-Equal 0 $r2.Actions.Count "Despues de recordarlo: el grupo se ignora (ni conserva ni mueve nada)"
    Assert-Equal 0 $global:tkAsked "Despues de recordarlo: ya no se pregunta nada"

    #
    # 3) Modo no interactivo con contenido distinto: se conservan todas
    #

    $f = New-Fixture $initD
    Set-Answers @() $false

    $r = Get-Actions $f

    Assert-Equal 0 $global:tkAsked "-Yes con contenido distinto: no se pregunta"
    Assert-Equal 2 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "-Yes con contenido distinto: se conservan las DOS copias"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "-Yes con contenido distinto: NO se mueve ninguna (antes se movia la 2)"

    #
    # 4) Modo no interactivo con contenido IDENTICO: se sigue eligiendo una
    #

    $f = New-Fixture @{ "initdv2e/gds-0027.chd" = "mismo contenido"; "initdv2j/gds-0027.chd" = "mismo contenido" }
    Set-Answers @() $false

    $r = Get-Actions $f

    Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "-Yes con contenido identico: se conserva una"
    Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "-Yes con contenido identico: se mueve la copia exacta"

    #
    # 5) Interactivo: 1 y 2 funcionan como siempre
    #

    foreach($answer in "1", "2")
    {
        $f = New-Fixture $initD
        Set-Answers @($answer, "N")

        $r = Get-Actions $f

        Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Opcion ${answer}: se conserva una"
        Assert-Equal 1 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Opcion ${answer}: se mueve la otra"
    }

    #
    # 6) "Conservar todas" en un grupo no se contagia al siguiente
    #

    $f = New-Fixture @{
        "initdv2e/gds-0027.chd" = "exportacion"
        "initdv2j/gds-0027.chd" = "japon"
        "Alpha (USA).chd"        = "alpha usa"
        "Alpha (Europe).chd"     = "alpha europe"
    }
    Set-Answers @("3", "N")

    $r = Get-Actions $f

    Assert-Equal 2 $r.Groups.Count "Dos grupos: el de Initial D y el de Alpha"
    Assert-Equal 2 @($r.Actions | Where-Object { (Split-Path $_.Source -Leaf) -eq "gds-0027.chd" -and $_.Action -eq "KEEP" }).Count "Dos grupos: Initial D conserva las dos"
    Assert-Equal 1 @($r.Actions | Where-Object { (Split-Path $_.Source -Leaf) -like "Alpha*" -and $_.Action -eq "MOVE" }).Count "Dos grupos: Alpha SI mueve una copia (la bandera no se contagia)"

    #
    # 7) Tres copias empatadas: se pregunta una sola vez
    #

    $f = New-Fixture @{ "a/gds-0100.chd" = "uno"; "b/gds-0100.chd" = "dos"; "c/gds-0100.chd" = "tres" }
    Set-Answers @("3", "N", "9", "9")

    $r = Get-Actions $f

    Assert-Equal 3 @($r.Actions | Where-Object { $_.Action -eq "KEEP" }).Count "Tres copias: se conservan las tres"
    Assert-Equal 0 @($r.Actions | Where-Object { $_.Action -eq "MOVE" }).Count "Tres copias: no se mueve ninguna"
    Assert-Equal 2 $global:tkAsked "Tres copias: se pregunta una sola vez (mas la pregunta de recordar), no por cada pareja"
}
finally
{
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

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
