# ============================================================
# Traducción detectada por la carpeta contenedora
# Aunque el nombre del archivo no lo diga, si está dentro de
# una carpeta como "Traducciones" debe marcarse igualmente
# ============================================================

$tempFolder = New-TestTempFolder

$translationFolder = Join-Path $tempFolder "Traducciones"

New-Item -ItemType Directory -Path $translationFolder -Force | Out-Null

try
{
    $filePath = Join-Path $translationFolder "Some Game (NTSC).zip"

    "contenido de prueba" | Set-Content $filePath

    $rom = Parse-Rom $filePath

    Assert-Equal `
        $true `
        $rom.Translation `
        "ROM dentro de una carpeta 'Traducciones': se marca como Translation aunque el nombre del archivo no lo diga"
}
finally
{
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
