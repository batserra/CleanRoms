# ============================================================
# Hack detectado por la carpeta contenedora
# Aunque el nombre del archivo no diga "Hack", si está dentro
# de una carpeta como "# Hacks #" debe marcarse igualmente
# ============================================================

$tempFolder = New-TestTempFolder

$hackFolder = Join-Path $tempFolder "# Hacks #"

New-Item -ItemType Directory -Path $hackFolder -Force | Out-Null

try
{
    $filePath = Join-Path $hackFolder "ISSD-Version 2013 (V1) (ENG) (NTSC).zip"

    "contenido de prueba" | Set-Content $filePath

    $rom = Parse-Rom $filePath

    Assert-Equal `
        $true `
        $rom.Hack `
        "ROM dentro de una carpeta '# Hacks #': se marca como Hack aunque el nombre del archivo no lo diga"
}
finally
{
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
