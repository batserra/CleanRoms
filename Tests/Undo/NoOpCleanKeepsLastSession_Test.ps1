# ============================================================
# BUG corregido: una limpieza que NO se ejecutaba desplazaba a la
# ultima limpieza real.
#
# El plan se exporta (y el CleanPlan.json anterior se archiva en
# History) ANTES de pedir confirmacion. Si despues no habia nada que
# mover, o el usuario contestaba "N", ese plan nuevo (vacio o sin
# ejecutar) pasaba a ser "la ultima limpieza": "Deshacer" proponia por
# defecto una limpieza que no habia hecho nada, y la real quedaba
# escondida como "1)" en el historial. Resultado: parecia que Deshacer
# no restauraba nada (ni ROMs, ni imagenes, ni videos, ni manuales).
#
# Ahora, si el plan no se ejecuta, se devuelve la sesion anterior a ser
# "la ultima limpieza".
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
$resultFolder = Join-Path $tempRoot "Resultado"
$historyFolder = Join-Path $resultFolder "History"
$planFile = Join-Path $resultFolder "CleanPlan.json"

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    PreviewOnly   = $Global:Settings.PreviewOnly
    AutoConfirm   = $Global:AutoConfirm
    Root          = $Global:RetroBatRoot
    Dup           = $Global:DuplicatesFolder
}

$Global:OverridesPath = (Join-Path $tempRoot "no-overrides.json")
$Global:Settings.Language = "es"
$Global:Settings.PreviewOnly = $false
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"

$global:npAnswer = "N"

function global:Read-Host
{
    param($Prompt)
    return $global:npAnswer
}

function New-Pair
{
    param([string]$Title)

    Set-Content -LiteralPath (Join-Path $systemFolder "$Title (USA).sfc") -Value "$Title usa"
    Set-Content -LiteralPath (Join-Path $systemFolder "$Title (Europe).sfc") -Value "$Title eur"
}

function Get-HistoryCount
{
    return @(Get-ChildItem -LiteralPath $historyFolder -Filter "CleanPlan_*.json" -ErrorAction SilentlyContinue).Count
}

try
{
    New-Item -ItemType Directory -Path (Join-Path $systemFolder "images") -Force | Out-Null

    #
    # 0) Primera limpieza del programa, contestando N: no debe dejar
    #    ningun "ultimo plan" sin ejecutar
    #

    New-Pair "Alpha"

    $Global:AutoConfirm = $false
    $global:npAnswer = "N"

    Invoke-RomCleaning -Root $tempRoot -SystemFolders @($systemFolder) 6>$null

    Assert-Equal 2 @(Get-ChildItem -LiteralPath $systemFolder -Filter *.sfc).Count "Primera limpieza cancelada: no se mueve nada"
    Assert-Equal $false (Test-Path -LiteralPath $planFile) "Primera limpieza cancelada: no queda un CleanPlan.json sin ejecutar como 'ultima limpieza'"

    #
    # 1) Limpieza real
    #

    $Global:AutoConfirm = $true
    Set-Content -LiteralPath (Join-Path $systemFolder "images/Alpha (USA).png") -Value "img usa"
    Set-Content -LiteralPath (Join-Path $systemFolder "images/Alpha (Europe).png") -Value "img eur"

    Invoke-RomCleaning -Root $tempRoot -SystemFolders @($systemFolder) 6>$null
    Invoke-OrphanedMediaCleanup -Root $tempRoot -SystemFolders @($systemFolder) 6>$null

    $realPlan = Get-Content -LiteralPath $planFile -Raw

    Assert-Equal 1 @(Get-ChildItem -LiteralPath $systemFolder -Filter *.sfc).Count "Limpieza real: queda una ROM"
    Assert-Equal 0 (Get-HistoryCount) "Limpieza real: aun no hay historial"

    #
    # 2) Otra limpieza SIN nada que hacer: la real sigue siendo la ultima
    #

    Invoke-RomCleaning -Root $tempRoot -SystemFolders @($systemFolder) 6>$null

    Assert-Equal $realPlan (Get-Content -LiteralPath $planFile -Raw) "Sin nada que hacer: CleanPlan.json sigue siendo el de la limpieza real"
    Assert-Equal 0 (Get-HistoryCount) "Sin nada que hacer: no se archiva nada en History"

    #
    # 3) Otra limpieza con duplicados nuevos contestando N
    #

    New-Pair "Beta"

    $Global:AutoConfirm = $false
    $global:npAnswer = "N"

    Invoke-RomCleaning -Root $tempRoot -SystemFolders @($systemFolder) 6>$null

    Assert-Equal 3 @(Get-ChildItem -LiteralPath $systemFolder -Filter *.sfc).Count "Cancelada: no se mueve nada (1 de Alpha + 2 de Beta)"
    Assert-Equal $realPlan (Get-Content -LiteralPath $planFile -Raw) "Cancelada: CleanPlan.json sigue siendo el de la limpieza real"
    Assert-Equal 0 (Get-HistoryCount) "Cancelada: no se archiva nada en History"

    #
    # 4) Deshacer despues de todo eso: devuelve la limpieza REAL, con sus
    #    imagenes
    #

    $Global:AutoConfirm = $true
    $null = Invoke-UndoLastPlan -Root $tempRoot 6>$null

    Assert-Equal 2 @(Get-ChildItem -LiteralPath $systemFolder -Filter "Alpha*.sfc").Count "Deshacer: vuelven las dos ROMs de Alpha"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $systemFolder "images/Alpha (USA).png")) "Deshacer: vuelve la imagen de la ROM movida (USA)"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $systemFolder "images/Alpha (Europe).png")) "Deshacer: la imagen de la otra ROM sigue en su sitio"

    #
    # 5) Una limpieza que SI se ejecuta archiva la anterior, como siempre
    #

    Invoke-RomCleaning -Root $tempRoot -SystemFolders @($systemFolder) 6>$null

    Assert-Equal 1 (Get-HistoryCount) "Limpieza ejecutada: la sesion anterior pasa a History (una)"
    Assert-Equal $true ((Get-Content -LiteralPath $planFile -Raw) -ne $realPlan) "Limpieza ejecutada: CleanPlan.json es el de la sesion nueva"
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

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
