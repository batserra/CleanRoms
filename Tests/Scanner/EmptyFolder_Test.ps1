# ============================================================
# Carpeta vacía
# Escanear una carpeta sin ninguna ROM no debe lanzar error
# ============================================================

$tempFolder = New-TestTempFolder

try
{
    $roms = @(Get-RomsFromFolder $tempFolder)

    Assert-Equal `
        0 `
        $roms.Count `
        "Carpeta vacía: no lanza error y devuelve 0 ROMs"
}
finally
{
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
