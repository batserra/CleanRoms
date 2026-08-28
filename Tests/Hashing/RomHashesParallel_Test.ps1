# ============================================================
# MEJORA: cálculo de hash en paralelo (Get-RomHashesParallel)
# para acelerar colecciones grandes -- usado por el plan de
# limpieza normal (Invoke-CleanPreview) y por la deduplicación
# de "# Hacks y Otros #" (Group-RomsByHash).
#
# Este test comprueba que el resultado es correcto tanto cuando
# se queda por debajo del umbral (calcula en serie, camino de
# siempre) como cuando lo supera (calcula con
# ForEach-Object -Parallel) -- en ambos casos debe devolver el
# mismo hashtable RutaCompleta -> hash.
# ============================================================

$tempFolder = New-TestTempFolder

$fileA = Join-Path $tempFolder "GameA.smc"
$fileB = Join-Path $tempFolder "GameB_copia_identica.smc"
$fileC = Join-Path $tempFolder "GameC_distinto.smc"

Set-Content -LiteralPath $fileA -Value "contenido identico"
Set-Content -LiteralPath $fileB -Value "contenido identico"
Set-Content -LiteralPath $fileC -Value "contenido totalmente distinto"

$originalThreshold = $Global:Settings.HashParallelThreshold

try
{
    #
    # Camino en serie: con el umbral por defecto (20), 3 archivos
    # se quedan por debajo y se calculan uno a uno.
    #

    $resultSerial = Get-RomHashesParallel -Paths @($fileA, $fileB, $fileC)

    Assert-Equal `
        $resultSerial[$fileA] `
        $resultSerial[$fileB] `
        "Get-RomHashesParallel (serie): dos archivos con el mismo contenido deben tener el mismo hash"

    Assert-Equal `
        $false `
        ($resultSerial[$fileA] -eq $resultSerial[$fileC]) `
        "Get-RomHashesParallel (serie): un archivo con contenido distinto debe tener un hash distinto"

    #
    # Camino en paralelo: bajando el umbral a 1, los mismos 3
    # archivos deben pasar por ForEach-Object -Parallel esta vez,
    # y el resultado debe ser exactamente el mismo.
    #

    $Global:Settings.HashParallelThreshold = 1

    $resultParallel = Get-RomHashesParallel -Paths @($fileA, $fileB, $fileC)

    Assert-Equal `
        $resultSerial[$fileA] `
        $resultParallel[$fileA] `
        "Get-RomHashesParallel (paralelo): mismo hash que en serie para el mismo archivo"

    Assert-Equal `
        $resultParallel[$fileA] `
        $resultParallel[$fileB] `
        "Get-RomHashesParallel (paralelo): dos archivos con el mismo contenido deben tener el mismo hash"

    Assert-Equal `
        $false `
        ($resultParallel[$fileA] -eq $resultParallel[$fileC]) `
        "Get-RomHashesParallel (paralelo): un archivo con contenido distinto debe tener un hash distinto"
}
finally
{
    $Global:Settings.HashParallelThreshold = $originalThreshold
    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
