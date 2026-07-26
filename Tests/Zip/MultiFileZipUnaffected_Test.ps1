# ============================================================
# ZIP con varios archivos dentro (set tipo MAME/arcade)
# No debe tratarse como "una sola ROM": se sigue detectando
# todo por el nombre del propio .zip, igual que antes
# ============================================================

$tempFolder = New-TestTempFolder

try
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    $zipPath = Join-Path $tempFolder "sf2 (ESP).zip"

    $file1 = Join-Path $tempFolder "a.bin"
    $file2 = Join-Path $tempFolder "b.bin"

    "x" | Set-Content $file1
    "y" | Set-Content $file2

    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")

    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file1, "a.bin") | Out-Null
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file2, "b.bin") | Out-Null

    $zip.Dispose()

    Remove-Item $file1, $file2 -ErrorAction SilentlyContinue

    $rom = Parse-Rom $zipPath

    Assert-Equal `
        "ESP" `
        $rom.Region `
        "ZIP con varios archivos dentro: sigue detectando solo por el nombre del propio .zip"
}
finally
{
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
