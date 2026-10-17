# Calcular-MD5-Excel.ps1
# PowerShell 7 - Windows 11
# Columnas: A = Nombre, B = Ruta, D = MD5

$ErrorActionPreference = 'Stop'

# Instalar ImportExcel si todavía no está instalado
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module ImportExcel -Scope CurrentUser -Force
}

Import-Module ImportExcel

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

foreach ($Fila in $Datos) {
    $Procesados++
    $Nombre = [string]$Fila.Nombre
    $Ruta = [string]$Fila.Ruta

    Write-Progress -Activity "Calculando hashes MD5" `
        -Status "$Procesados de $Total : $Nombre" `
        -PercentComplete (($Procesados / $Total) * 100)

    try {
        if ([string]::IsNullOrWhiteSpace($Ruta)) {
            $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue 'RUTA VACIA' -Force
            $Errores++
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
            continue
        }

        $Hash = (Get-FileHash -LiteralPath $Archivo -Algorithm MD5).Hash
        $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue $Hash -Force
        $Correctos++
    }
    catch {
        $Fila | Add-Member -NotePropertyName MD5 -NotePropertyValue 'ERROR' -Force
        $Errores++
        Write-Warning "Error procesando '$Nombre': $($_.Exception.Message)"
    }
}

Write-Progress -Activity "Calculando hashes MD5" -Completed

# Exportar los datos a un archivo temporal y sustituir el original
# ImportExcel conserva los datos tabulares, pero puede no conservar
# todos los elementos visuales, macros o características avanzadas del libro.
$Temporal = Join-Path $Carpeta "$NombreExcel.tmp.xlsx"

try {
    $Datos | Export-Excel -Path $Temporal -WorksheetName 'Hoja1' `
        -ClearSheet -AutoFilter

    # Comprobar que el temporal se ha creado correctamente
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
Write-Host "MD5 calculados: $Correctos"
Write-Host "No encontrados: $NoEncontrados"
Write-Host "Errores o rutas vacías: $Errores"
Write-Host "Archivo actualizado: $Excel" -ForegroundColor Cyan