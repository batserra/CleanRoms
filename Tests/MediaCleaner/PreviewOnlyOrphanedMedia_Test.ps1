# ============================================================
# BUG corregido: Invoke-OrphanedMediaCleanup (MediaCleaner.ps1)
# no comprobaba en ningún punto $Global:Settings.PreviewOnly, así
# que con PreviewOnly=$true los archivos huérfanos se movían
# igualmente en cuanto se confirmaba con "S" — el modo simulación
# no protegía esta parte del programa.
#
# Este test monta un sistema de prueba con una imagen huérfana
# (sin ninguna ROM real que la reclame), activa PreviewOnly, y
# comprueba que el archivo NO se mueve de su sitio original.
# ============================================================

$tempSystem = New-TestTempFolder

$imagesFolder = Join-Path $tempSystem "images"
New-Item -ItemType Directory -Path $imagesFolder -Force | Out-Null

$orphanFile = Join-Path $imagesFolder "NoSuchGame-marquee.png"
Set-Content -LiteralPath $orphanFile -Value "fake image content"

# Guardamos el estado real para restaurarlo despues del test, y
# forzamos el idioma a "es" para que la confirmacion "S" siempre
# sea la respuesta afirmativa esperada, sea cual sea la config
# real del usuario que ejecute la suite.
$originalPreviewOnly = $Global:Settings.PreviewOnly
$originalLanguage = $Global:Settings.Language

$Global:Settings.PreviewOnly = $true
$Global:Settings.Language = "es"

# Read-Host es interactivo; lo sobreescribimos a nivel global para
# que Invoke-OrphanedMediaCleanup reciba automaticamente "S" sin
# bloquear la suite de tests esperando entrada por teclado.
function global:Read-Host
{
    param($Prompt)
    return "S"
}

try
{
    Invoke-OrphanedMediaCleanup -SystemFolders @($tempSystem)

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $orphanFile) `
        "BUG PreviewOnly: el huerfano debe seguir en su sitio original (no se mueve nada en modo simulacion)"
}
finally
{
    $Global:Settings.PreviewOnly = $originalPreviewOnly
    $Global:Settings.Language = $originalLanguage

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    Remove-Item -Path $tempSystem -Recurse -Force -ErrorAction SilentlyContinue
}
