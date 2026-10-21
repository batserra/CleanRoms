# Calcular-MD5-Excel.ps1
# PowerShell 7 - Windows 11
# Columnas: A = Nombre, B = Ruta, D = MD5
# Para ZIP con un único archivo interno, calcula el MD5 del contenido interno,
# no el MD5 del archivo ZIP. No extrae archivos al disco.

$ErrorActionPreference = 'Stop'

# Instalar ImportExcel si todavía no está instalado
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module ImportExcel -Scope CurrentUser -Force
}
Import-Module ImportExcel

# Necesario para leer el contenido de los ZIP
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-MD5ArchivoZip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RutaZip
    )

    $Zip = $null
    $MD5Algoritmo = $null

    try {
        $Zip = [System.IO.Compression.ZipFile]::OpenRead($RutaZip)

        # Ignorar directorios y entradas vacías que solo representan carpetas.
        $Entradas = @(
            $Zip.Entries | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_.Name)
            }
        )

        if ($Entradas.Count -eq 0) {
            throw "El ZIP no contiene archivos."
        }

        # Una fila del Excel solo puede guardar un MD5. Si hay varios archivos
        # internos, no elegir uno arbitrariamente: podría comparar la ROM equivocada.
        if ($Entradas.Count -gt 1) {
            $Nombres = ($Entradas | ForEach-Object { $_.FullName }) -join '; '
            return [PSCustomObject]@{
                MD5 = 'ZIP CON VARIOS ARCHIVOS'
                Detalle = "No se calculó un único MD5. Contenido: $Nombres"
            }
        }

        $Entrada = $Entradas[0]
        Write-Host "    Dentro del ZIP: $($Entrada.FullName)" -ForegroundColor DarkCyan

        $Flujo = $Entrada.Open()
        try {
            $MD5Algoritmo = [System.Security.Cryptography.MD5]::Create()
            $BytesHash = $MD5Algoritmo.ComputeHash($Flujo)
            $Hash = [System.BitConverter]::ToString($BytesHash).Replace('-', '')
        }
        finally {
            if ($Flujo) { $Flujo.Dispose() }
        }

        return [PSCustomObject]@{
            MD5 = $Hash
            Detalle = "MD5 del archivo interno: $($Entrada.FullName)"
        }
    }
    finally {
        if ($MD5Algoritmo) { $MD5Algoritmo.Dispose() }
        if ($Zip) { $Zip.Dispose() }
    }
}

# Seleccionar el archivo Excel
$Excel = Read-Host "Introduce la ruta completa del archivo Excel"

if (-not (Test-Path -LiteralPath $Excel -PathType Leaf)) {
    Write-Host "ERROR: No existe el archivo Excel indicado." -ForegroundColor Red
    exit 1
}

# Crear una copia de seguridad antes de modificarlo
$Carpeta = Split-Path -Parent $Excel
$NombreExcel = [System.IO.Path]::GetFileNameWithoutExtension($Excel)
$Extension = [System.IO.Path]::GetExtension($Excel)
$Backup = Join-Path $Carpeta "$NombreExcel.backup$(Get-Date -Format 'yyyyMMdd_HHmmss')$Extension"

Copy-Item -LiteralPath $Excel -Destination $Backup
Write-Host "Copia de seguridad: $Backup" -ForegroundColor Cyan

# Importar datos conservando el orden de las filas
$Datos = @(Import-Excel -Path $Excel)

if ($Datos.Count -eq 0) {
    Write-Host "El Excel no contiene filas de datos." -ForegroundColor Yellow
    exit 0
}

# Comprobar que existen las columnas necesarias
if (-not ($Datos[0].PSObject.Properties.Name -contains 'Nombre') -or
    -not ($Datos[0].PSObject.Properties.Name -contains 'Ruta')) {
    Write-Host "ERROR: No se encuentran las columnas Nombre y Ruta." -ForegroundColor Red
    exit 1
}

$Total = $Datos.Count
$Procesados = 0
$Correctos = 0
$NoEncontrados = 0
$Errores = 0
$ZipMultiples = 0

foreach ($Fila in $Datos) {
    $Procesados++
    $Nombre = [string]$Fila.Nombre
    $Ruta = [string]$Fila.Ruta

    # Mostrar el fichero que se está tratando en la consola.
    Write-Host "`n[$Procesados/$Total] Procesando: $Nombre" -ForegroundColor Cyan
    Write-Progress -Activity "Calculando hashes MD5" `
        -Status "$Procesados de $Total : $Nombre" `
        -PercentComplete (($Procesados / $Total) * 100)

    try {
        if ([string]::IsNullOrWhiteSpace($Ruta)) {
            $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue 'RUTA VACIA' -Force
            $Errores++
            Write-Host "    ERROR: Ruta vacía" -ForegroundColor Red
            continue
        }

        # Si Ruta ya contiene el nombre del archivo, usarla directamente.
        # Si contiene solo la carpeta, combinarla con Nombre.
        if (Test-Path -LiteralPath $Ruta -PathType Leaf) {
            $Archivo = $Ruta
        }
        elseif (Test-Path -LiteralPath (Join-Path $Ruta $Nombre) -PathType Leaf) {
            $Archivo = Join-Path $Ruta $Nombre
        }
        else {
            $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue 'NO ENCONTRADO' -Force
            $NoEncontrados++
            Write-Host "    NO ENCONTRADO: $Ruta" -ForegroundColor Yellow
            continue
        }

        $ExtensionArchivo = [System.IO.Path]::GetExtension($Archivo).ToLowerInvariant()

        if ($ExtensionArchivo -eq '.zip') {
            Write-Host "    ZIP detectado; calculando MD5 del archivo que contiene..." -ForegroundColor Yellow
            $ResultadoZip = Get-MD5ArchivoZip -RutaZip $Archivo
            $Hash = $ResultadoZip.MD5

            if ($Hash -eq 'ZIP CON VARIOS ARCHIVOS') {
                $ZipMultiples++
                $Errores++
                Write-Host "    AVISO: contiene varios archivos; no se ha elegido uno arbitrariamente." -ForegroundColor Yellow
                Write-Host "    $($ResultadoZip.Detalle)" -ForegroundColor DarkYellow
            }
            else {
                $Correctos++
                Write-Host "    MD5 del contenido ZIP: $Hash" -ForegroundColor Green
            }

            $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue $Hash -Force
        }
        else {
            $Hash = (Get-FileHash -LiteralPath $Archivo -Algorithm MD5).Hash
            $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue $Hash -Force
            $Correctos++
            Write-Host "    MD5 del archivo: $Hash" -ForegroundColor Green
        }
    }
    catch {
        $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue 'ERROR' -Force
        $Errores++
        Write-Host "    ERROR procesando '$Nombre': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Progress -Activity "Calculando hashes MD5" -Completed

# Exportar los datos a un archivo temporal y sustituir el original.
# Nota: Export-Excel puede no conservar macros ni todos los elementos visuales
# o características avanzadas del libro.
$Temporal = Join-Path $Carpeta "$NombreExcel.tmp.xlsx"

try {
    $Datos | Export-Excel -Path $Temporal -WorksheetName 'Hoja1' `
        -ClearSheet -AutoFilter

    if (-not (Test-Path -LiteralPath $Temporal -PathType Leaf)) {
        throw "No se ha generado el archivo temporal."
    }

    Move-Item -LiteralPath $Temporal -Destination $Excel -Force
}
catch {
    Write-Host "ERROR al guardar: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "La copia original está disponible en: $Backup" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nPROCESO FINALIZADO" -ForegroundColor Green
Write-Host "Total de filas: $Total"
Write-Host "MD5 calculados correctamente: $Correctos"
Write-Host "ZIP con varios archivos (sin hash único): $ZipMultiples"
Write-Host "No encontrados: $NoEncontrados"
Write-Host "Errores o rutas vacías: $Errores"
Write-Host "Archivo actualizado: $Excel" -ForegroundColor Cyan
