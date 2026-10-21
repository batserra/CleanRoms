# Eliminar-Duplicados-MD5.ps1
# PowerShell 7 - Windows 11
# Lee Nombre, Ruta y MD5 del Excel.
# ZIP y 7Z nunca se eliminan.
# Si hay un ZIP/7Z y otro fichero, se borra el otro fichero.
# Modo simulación activado por defecto.
# Se omiten las filas cuyo MD5 indique "ZIP CON VARIOS ARCHIVOS".

$ErrorActionPreference = 'Stop'

# CONFIGURACIÓN
$ModoSimulacion = $false   # Cambiar a $false solo después de revisar el informe
$ExtensionesProtegidas = @('.zip', '.7z')
$CarpetaInformes = Join-Path $PSScriptRoot 'Resultado\DuplicadosMD5'

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module ImportExcel -Scope CurrentUser -Force
}

Import-Module ImportExcel

$Excel = Read-Host "Introduce la ruta completa del Excel con Nombre, Ruta y MD5"

if (-not (Test-Path -LiteralPath $Excel -PathType Leaf)) {
    Write-Host "ERROR: No se encuentra el Excel." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $CarpetaInformes -Force | Out-Null

$Fecha = Get-Date -Format 'yyyyMMdd_HHmmss'
$Informe = Join-Path $CarpetaInformes "Informe_MD5_$Fecha.csv"
$Log = Join-Path $CarpetaInformes "Proceso_MD5_$Fecha.txt"

function Escribir-Log {
    param(
        [string]$Mensaje
    )

    $Linea = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Mensaje"

    Add-Content -LiteralPath $Log -Value $Linea -Encoding utf8
    Write-Host $Mensaje
}

try {
    $Datos = @(Import-Excel -Path $Excel)
}
catch {
    Write-Host "ERROR al leer el Excel: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Datos.Count -eq 0) {
    Write-Host "El Excel no contiene registros." -ForegroundColor Yellow
    exit 0
}

$Columnas = $Datos[0].PSObject.Properties.Name

foreach ($Columna in @('Nombre', 'Ruta', 'MD5')) {
    if ($Columnas -notcontains $Columna) {
        Write-Host "ERROR: falta la columna '$Columna'." -ForegroundColor Red
        exit 1
    }
}

# Preparar registros válidos
$ListaArchivos = [System.Collections.Generic.List[object]]::new()

$RutasVistas = New-Object 'System.Collections.Generic.HashSet[string]'(
    [System.StringComparer]::OrdinalIgnoreCase
)

$OmitidosZipVarios = 0

foreach ($Fila in $Datos) {

    $Nombre = [string]$Fila.Nombre
    $Ruta = ([string]$Fila.Ruta).Trim()
    $MD5Original = ([string]$Fila.MD5).Trim()
    $MD5 = $MD5Original.ToUpperInvariant()

    if ($MD5 -eq 'ZIP CON VARIOS ARCHIVOS') {
        $OmitidosZipVarios++

        Write-Host "  [OMITIDO] ZIP con varios archivos: Nombre: $Nombre | Ruta: $Ruta" `
            -ForegroundColor Yellow

        continue
    }

    if ($MD5 -notmatch '^[A-F0-9]{32}$' -or [string]::IsNullOrWhiteSpace($Ruta)) {
        continue
    }

    if (Test-Path -LiteralPath $Ruta -PathType Leaf) {
        $Archivo = $Ruta
    }
    elseif (
        -not [string]::IsNullOrWhiteSpace($Nombre) -and
        (Test-Path -LiteralPath (Join-Path $Ruta $Nombre) -PathType Leaf)
    ) {
        $Archivo = Join-Path $Ruta $Nombre
    }
    else {
        continue
    }

    try {
        $Info = Get-Item -LiteralPath $Archivo -ErrorAction Stop

        if ($Info.PSIsContainer) {
            continue
        }

        if (-not $RutasVistas.Add($Info.FullName)) {
            continue
        }

        $ListaArchivos.Add(
            [PSCustomObject]@{
                MD5    = $MD5
                Nombre = $Info.Name
                Ruta   = $Info.FullName
                Ext    = $Info.Extension.ToLowerInvariant()
            }
        )
    }
    catch {
        Write-Warning "No se puede acceder a '$Archivo': $($_.Exception.Message)"
    }
}

$Archivos = @($ListaArchivos.ToArray())

$Grupos = @(
    $Archivos |
    Group-Object -Property MD5 |
    Where-Object { $_.Count -gt 1 }
)

$Resultados = [System.Collections.Generic.List[object]]::new()

$Eliminados = 0
$Protegidos = 0
$Fallidos = 0
$BytesEliminados = 0

Escribir-Log "Inicio. Modo simulación: $ModoSimulacion"
Escribir-Log "Archivos válidos: $($Archivos.Count)"
Escribir-Log "Grupos con MD5 repetido: $($Grupos.Count)"
Escribir-Log "Filas omitidas por 'ZIP CON VARIOS ARCHIVOS': $OmitidosZipVarios"

foreach ($Grupo in $Grupos) {

    $Lista = @($Grupo.Group | Sort-Object Ruta)

    $Comprimidos = @(
        $Lista |
        Where-Object { $_.Ext -in $ExtensionesProtegidas }
    )

    $Candidatos = @(
        $Lista |
        Where-Object { $_.Ext -notin $ExtensionesProtegidas }
    )

    Escribir-Log "MD5 $($Grupo.Name): $($Lista.Count) archivos"

    foreach ($Archivo in $Comprimidos) {

        $Protegidos++

        $Resultados.Add(
            [PSCustomObject]@{
                MD5      = $Grupo.Name
                Archivo  = $Archivo.Ruta
                Accion   = 'PROTEGIDO_COMPRIMIDO'
                Detalle  = 'Archivo ZIP/7Z: no se elimina'
            }
        )

        Escribir-Log "  PROTEGIDO: $($Archivo.Ruta)"
    }

    if ($Comprimidos.Count -gt 0) {

        $ArchivosABorrar = $Candidatos

    }
    else {

        if ($Candidatos.Count -gt 0) {

            $Conservar = $Candidatos[0]

            Escribir-Log "  CONSERVAR: $($Conservar.Ruta)"

            $Resultados.Add(
                [PSCustomObject]@{
                    MD5      = $Grupo.Name
                    Archivo  = $Conservar.Ruta
                    Accion   = 'CONSERVAR'
                    Detalle  = 'Archivo elegido para conservar'
                }
            )

            $ArchivosABorrar = @(
                $Candidatos |
                Select-Object -Skip 1
            )
        }
        else {
            $ArchivosABorrar = @()
        }
    }

    foreach ($Archivo in $ArchivosABorrar) {
		# Obtener tamaño del archivo
    $TamanoArchivo = 0

    if (Test-Path -LiteralPath $Archivo.Ruta -PathType Leaf) {
        try {
            $TamanoArchivo = (Get-Item -LiteralPath $Archivo.Ruta).Length
        }
        catch {
            $TamanoArchivo = 0
        }
    }

        if ($ModoSimulacion) {

            $Accion = 'SIMULACION_BORRADO'
            $Detalle = 'No se ha borrado; simulación activa'
			$BytesEliminados += $TamanoArchivo

            Escribir-Log "  SIMULACIÓN: se borraría $($Archivo.Ruta)"

            Write-Host `
                "  [SIMULACIÓN] Se borraría -> Nombre: $($Archivo.Nombre) | Ruta: $($Archivo.Ruta)" `
                -ForegroundColor Cyan
        }
        else {

            try {

                if ($Archivo.Ext -in $ExtensionesProtegidas) {

                    $Accion = 'PROTEGIDO_COMPRIMIDO'
                    $Detalle = 'Archivo ZIP/7Z: no se elimina'

                }
                elseif (Test-Path -LiteralPath $Archivo.Ruta -PathType Leaf) {

                    Write-Host `
                        "  [ELIMINANDO] Nombre: $($Archivo.Nombre) | Ruta: $($Archivo.Ruta)" `
                        -ForegroundColor Red

                    Remove-Item -LiteralPath $Archivo.Ruta -Force -ErrorAction Stop

                    $Accion = 'ELIMINADO'
                    $Detalle = 'Borrado correctamente'

                    $Eliminados++
					$BytesEliminados += $TamanoArchivo
                    Escribir-Log "  ELIMINADO: $($Archivo.Ruta)"
                }
                else {

                    $Accion = 'NO_ENCONTRADO'
                    $Detalle = 'El archivo ya no existe'
                }
			}
        catch {

                $Accion = 'ERROR'
                $Detalle = $_.Exception.Message

                $Fallidos++

                Escribir-Log "  ERROR: $($Archivo.Ruta) - $Detalle"
            }
        }

        $Resultados.Add(
            [PSCustomObject]@{
                MD5      = $Grupo.Name
                Archivo  = $Archivo.Ruta
                Accion   = $Accion
                Detalle  = $Detalle
            }
        )
    }
}

$Resultados |
Export-Csv -LiteralPath $Informe -NoTypeInformation -Encoding utf8

$TotalMB = [Math]::Round($BytesEliminados / 1MB, 2)
$TotalGB = [Math]::Round($BytesEliminados / 1GB, 2)



Escribir-Log "===================================="
Escribir-Log "Grupos duplicados: $($Grupos.Count)"
Escribir-Log "Filas omitidas por 'ZIP CON VARIOS ARCHIVOS': $OmitidosZipVarios"
Escribir-Log "Archivos ZIP/7Z protegidos: $Protegidos"
Escribir-Log "Archivos eliminados: $Eliminados"
Escribir-Log "Errores de borrado: $Fallidos"
Escribir-Log "Informe CSV: $Informe"
Escribir-Log "Espacio liberado: $TotalMB MB ($TotalGB GB)" -ForegroundColor Green



if ($ModoSimulacion) {

    Write-Host "`nSIMULACIÓN FINALIZADA: no se ha borrado ningún archivo." `
        -ForegroundColor Yellow

    Write-Host "Revisa el CSV y el log antes de activar el borrado."
}
else {

    Write-Host "`nPROCESO DE BORRADO FINALIZADO." `
        -ForegroundColor Green
}
