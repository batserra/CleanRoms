# ============================================================
# BUG corregido: en modo no interactivo (-Yes), si era la
# primera vez que se ejecutaba el programa (sin
# Config\UserSettings.json todavía), Initialize-Language e
# Initialize-RetroBatRoot se quedaban esperando un Read-Host de
# todas formas -- el modo no interactivo no cubría el primer
# arranque, solo las confirmaciones S/N normales.
#
# Este test comprueba que, con AutoConfirm activo:
# - Initialize-Language elige español sin preguntar.
# - Initialize-RetroBatRoot usa la carpeta sugerida por defecto
#   sin preguntar, siempre que esa carpeta exista de verdad.
# ============================================================

$tempRoot = New-TestTempFolder

# Initialize-RetroBatRoot sugiere Split-Path $Root -Parent como
# valor por defecto -- se crea una subcarpeta "CleanRoms" para
# que el "Root" del programa sea ese hijo, y el "sugerido" sea
# $tempRoot mismo (que sabemos que existe).
$fakeProgramRoot = Join-Path $tempRoot "CleanRoms"
New-Item -ItemType Directory -Path $fakeProgramRoot -Force | Out-Null

$originalAutoConfirm = $Global:AutoConfirm
$originalRoot = $Global:RetroBatRoot
$originalLanguage = $Global:Settings.Language
$originalPriority = $Global:Settings.RomPriorityLanguage
$originalWeights = $Global:DecisionWeights

function global:Read-Host
{
    param($Prompt)
    throw "Read-Host no deberia llamarse con AutoConfirm activo"
}

try
{
    $Global:AutoConfirm = $true

    Initialize-Language -Root $fakeProgramRoot

    Assert-Equal `
        "es" `
        $Global:Settings.Language `
        "Initialize-Language con AutoConfirm: debe elegir español sin preguntar"

    Initialize-RomPriorityLanguage -Root $fakeProgramRoot

    Assert-Equal `
        "es" `
        $Global:Settings.RomPriorityLanguage `
        "Initialize-RomPriorityLanguage con AutoConfirm: debe elegir español sin preguntar"

    Assert-Equal `
        $Global:DecisionWeights_ES `
        $Global:DecisionWeights `
        "Initialize-RomPriorityLanguage con AutoConfirm: debe activar la tabla de prioridad español"

    Initialize-RetroBatRoot -Root $fakeProgramRoot

    Assert-Equal `
        $tempRoot `
        $Global:RetroBatRoot `
        "Initialize-RetroBatRoot con AutoConfirm: debe usar la carpeta sugerida sin preguntar"

    $saved = Get-UserSettings -Root $fakeProgramRoot

    Assert-Equal `
        "es" `
        $saved.Language `
        "Initialize-Language con AutoConfirm: la eleccion debe guardarse en UserSettings.json"

    Assert-Equal `
        "es" `
        $saved.RomPriorityLanguage `
        "Initialize-RomPriorityLanguage con AutoConfirm: la eleccion debe guardarse en UserSettings.json"
}
finally
{
    $Global:AutoConfirm = $originalAutoConfirm
    $Global:RetroBatRoot = $originalRoot
    $Global:Settings.Language = $originalLanguage
    $Global:Settings.RomPriorityLanguage = $originalPriority
    $Global:DecisionWeights = $originalWeights

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
