# ============================================================
# BUG corregido: Invoke-HackDeduplication tampoco comprobaba
# $Global:Settings.PreviewOnly antes de mover los duplicados
# exactos (mismo hash) que encuentra dentro de "# Hacks y Otros #".
#
# Este test monta dos copias con el mismo contenido (mismo hash)
# ya organizadas dentro de "# Hacks y Otros #", activa PreviewOnly,
# y comprueba que ninguna de las dos se mueve a _duplicates.
# ============================================================

$tempSystem = New-TestTempFolder
$tempRoot = New-TestTempFolder

$hacksFolder = Join-Path $tempSystem "# Hacks y Otros #"
New-Item -ItemType Directory -Path $hacksFolder -Force | Out-Null

$fileA = Join-Path $hacksFolder "Same Hack.smc"
$fileB = Join-Path $hacksFolder "Same_Hack_.smc"

# Mismo contenido exacto -> mismo hash -> deben detectarse como
# duplicados exactos entre si.
Set-Content -LiteralPath $fileA -Value "identical rom bytes"
Set-Content -LiteralPath $fileB -Value "identical rom bytes"

$originalPreviewOnly = $Global:Settings.PreviewOnly
$originalLanguage = $Global:Settings.Language

$Global:Settings.PreviewOnly = $true
$Global:Settings.Language = "es"

# Ruta de RetroBat portable: el valor por defecto de Settings.ps1
# ("C:\RetroBat\roms") no existe fuera de Windows y Join-Path falla
# con "Cannot find drive".
$originalRoot = $Global:RetroBatRoot
$Global:RetroBatRoot = Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) "RetroBat_Fake") "roms"

function global:Read-Host
{
    param($Prompt)
    return "S"
}

try
{
    Invoke-HackDeduplication -Root $tempRoot -HacksFolders @($hacksFolder)

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $fileA) `
        "BUG PreviewOnly (hack dedup): la primera copia debe seguir en su sitio"

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $fileB) `
        "BUG PreviewOnly (hack dedup): la segunda copia (duplicado exacto) debe seguir en su sitio, no en _duplicates"
}
finally
{
    $Global:Settings.PreviewOnly = $originalPreviewOnly
    $Global:Settings.Language = $originalLanguage
    $Global:RetroBatRoot = $originalRoot

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    Remove-Item -Path $tempSystem -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
