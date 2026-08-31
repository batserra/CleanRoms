# ============================================================
# ZIP con una única ROM dentro
# El propio .zip no lleva ninguna etiqueta en su nombre, pero
# el archivo de dentro sí -> debe detectarse igualmente
# ============================================================

$tempFolder = New-TestTempFolder

try
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    $zipPath = Join-Path $tempFolder "SuperGame.zip"

    $innerFile = Join-Path $tempFolder "SuperGame (ESP).gba"

    "contenido de prueba" | Set-Content $innerFile

    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")

    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, $innerFile, "SuperGame (ESP).gba"
    ) | Out-Null

    $zip.Dispose()

    Remove-Item $innerFile -ErrorAction SilentlyContinue

    $rom = Parse-Rom $zipPath

    Assert-Equal `
        "ESP" `
        $rom.Region `
        "ZIP con una sola ROM dentro: detecta la región del nombre interno aunque el .zip no la lleve"
}
finally
{
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
