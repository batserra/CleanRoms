# ============================================================
# Las tablas de Excel (CleanROMs_Sistemas_y_formatos.xlsx y su version
# en ingles CleanROMs_Systems_and_Formats.xlsx) deben estar al dia con
# Config\Systems.json y Config\Extensions.json: si alguien anade un
# sistema o una extension y no regenera las tablas, este test avisa.
#
# Se comprueba, sin necesitar Excel, abriendo el .xlsx como ZIP y
# contando las filas de las hojas "Sistemas" y "Extensiones" (+1 de la
# cabecera), y que las dos versiones (ES/EN) tienen las mismas.
# ============================================================

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-SheetRowCount
{
    param([string]$Workbook, [string]$SheetFile)

    $zip = [System.IO.Compression.ZipFile]::OpenRead($Workbook)

    try
    {
        $entry = $zip.GetEntry("xl/worksheets/$SheetFile")
        $reader = New-Object System.IO.StreamReader($entry.Open())

        try { $xml = $reader.ReadToEnd() }
        finally { $reader.Dispose() }

        return ([regex]::Matches($xml, '<row ')).Count
    }
    finally
    {
        $zip.Dispose()
    }
}

$systemsCount = 0

foreach($category in (Get-Content -LiteralPath (Join-Path $Root "Config/Systems.json") -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties)
{
    $systemsCount += @($category.Value.PSObject.Properties).Count
}

$extensionsCount = @((Get-Content -LiteralPath (Join-Path $Root "Config/Extensions.json") -Raw -Encoding UTF8 | ConvertFrom-Json).RomExtensions).Count

foreach($file in "CleanROMs_Sistemas_y_formatos.xlsx", "CleanROMs_Systems_and_Formats.xlsx")
{
    $path = Join-Path $Root $file

    Assert-Equal $true (Test-Path -LiteralPath $path) "Excel: existe $file"

    if(Test-Path -LiteralPath $path)
    {
        # hoja 2 = sistemas, hoja 3 = extensiones (la 1 es el resumen)
        Assert-Equal ($systemsCount + 1) (Get-SheetRowCount $path "sheet2.xml") "Excel: $file lista los $systemsCount sistemas de Systems.json (mas la cabecera)"
        Assert-Equal ($extensionsCount + 1) (Get-SheetRowCount $path "sheet3.xml") "Excel: $file lista las $extensionsCount extensiones de Extensions.json (mas la cabecera)"
    }
}
