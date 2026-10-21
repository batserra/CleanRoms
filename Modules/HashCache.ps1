# ============================================================
# CleanROMs
#
# HashCache.ps1
#
# Cache de hashes. Calcular el hash de cientos o miles de ROMs es lo
# que mas tarda de toda la limpieza, y en cada ejecucion se volvian a
# leer y hashear los mismos archivos que no han cambiado.
#
# La cache guarda, para cada archivo, su hash junto con su TAMANO y su
# FECHA DE MODIFICACION en el momento de calcularlo. Al pedir el hash
# de un archivo se reutiliza solo si el tamano y la fecha siguen
# siendo exactamente los mismos; si cambia cualquiera de los dos, se
# recalcula. Un archivo que cambia de contenido sin cambiar de tamano
# ni de fecha seria la unica forma de que la cache diera un hash
# viejo; para ese caso extremo basta con borrar
# Resultado\HashCache.tsv o poner HashCache = $false en Settings.ps1.
#
# Formato: texto con una linea por archivo (ruta, tamano, fecha, hash
# separados por tabuladores) y una cabecera con la version y el
# algoritmo. Si el algoritmo configurado (MD5, SHA256...) no coincide
# con el de la cache, se descarta entera.
#
# Es solo un acelerador: si falta, esta corrupta o no se puede
# escribir, el programa funciona igual (mas lento).
# ============================================================

# Ruta alternativa (tests); vacia = Resultado\HashCache.tsv junto al programa
$Global:HashCachePath = ""

$Global:HashCacheData = $null
$Global:HashCacheLoadedFrom = ""
$Global:HashCacheAlgorithm = ""
$Global:HashCacheDirty = $false
$Global:HashCacheStats = @{ Hits = 0; Misses = 0 }

function Get-HashCachePath {

    if(-not [string]::IsNullOrWhiteSpace($Global:HashCachePath))
    {
        return $Global:HashCachePath
    }

    return Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) "Resultado") "HashCache.tsv"
}

function Test-HashCacheEnabled {

    return -not (
        $Global:Settings.ContainsKey("HashCache") -and
        ($Global:Settings.HashCache -eq $false)
    )
}

#--------------------------------------------------------------
# Olvida lo cargado en memoria (los tests, o al cambiar de ruta)
#--------------------------------------------------------------

function Reset-HashCache {

    $Global:HashCacheData = $null
    $Global:HashCacheLoadedFrom = ""
    $Global:HashCacheAlgorithm = ""
    $Global:HashCacheDirty = $false
    $Global:HashCacheStats = @{ Hits = 0; Misses = 0 }
}

#--------------------------------------------------------------
# Carga la cache del disco la primera vez que se necesita
#--------------------------------------------------------------

function Initialize-HashCache {

    param([Parameter(Mandatory)][string]$Algorithm)

    $path = Get-HashCachePath

    if($null -ne $Global:HashCacheData -and
       $Global:HashCacheLoadedFrom -eq $path -and
       $Global:HashCacheAlgorithm -eq $Algorithm)
    {
        return
    }

    $data = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::OrdinalIgnoreCase)

    if([System.IO.File]::Exists($path))
    {
        try
        {
            $first = $true
            $valid = $false

            # ReadAllLines (no ReadLines): lee todo y CIERRA el archivo siempre. Con ReadLines,
            # salir del bucle antes de tiempo dejaba el archivo abierto (y bloqueado en Windows).
            foreach($line in [System.IO.File]::ReadAllLines($path))
            {
                if($first)
                {
                    $first = $false

                    # Cabecera: CleanROMs-HashCache<TAB>1<TAB>ALGORITMO
                    $header = $line -split "`t"
                    $valid = ($header.Count -ge 3 -and $header[0] -eq "CleanROMs-HashCache" -and
                              $header[1] -eq "1" -and $header[2] -ieq $Algorithm)

                    if(-not $valid)
                    {
                        break
                    }

                    continue
                }

                $parts = $line -split "`t"

                if($parts.Count -ne 4)
                {
                    continue
                }

                $size = 0L
                $ticks = 0L

                if([long]::TryParse($parts[1], [ref]$size) -and [long]::TryParse($parts[2], [ref]$ticks) -and $parts[3] -ne "")
                {
                    $data[$parts[0]] = [PSCustomObject]@{ Size = $size; Ticks = $ticks; Hash = $parts[3] }
                }
            }
        }
        catch
        {
            # Cache ilegible: se empieza de cero, sin molestar
            $data.Clear()
        }
    }

    $Global:HashCacheData = $data
    $Global:HashCacheLoadedFrom = $path
    $Global:HashCacheAlgorithm = $Algorithm
    $Global:HashCacheDirty = $false
}

#--------------------------------------------------------------
# Hash guardado de un archivo, o $null si no hay o ya no vale
#--------------------------------------------------------------

function Get-CachedHash {

    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Algorithm
    )

    Initialize-HashCache -Algorithm $Algorithm

    $entry = $null

    if(-not $Global:HashCacheData.TryGetValue($Path, [ref]$entry))
    {
        $Global:HashCacheStats.Misses++
        return $null
    }

    try
    {
        $info = New-Object System.IO.FileInfo $Path

        if($info.Exists -and $info.Length -eq $entry.Size -and $info.LastWriteTimeUtc.Ticks -eq $entry.Ticks)
        {
            $Global:HashCacheStats.Hits++
            return $entry.Hash
        }
    }
    catch
    {
        # cae en el recalculo
    }

    $Global:HashCacheStats.Misses++
    return $null
}

function Set-CachedHash {

    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Algorithm,
        [Parameter(Mandatory)][string]$Hash
    )

    Initialize-HashCache -Algorithm $Algorithm

    try
    {
        $info = New-Object System.IO.FileInfo $Path

        if(-not $info.Exists)
        {
            return
        }

        $Global:HashCacheData[$Path] = [PSCustomObject]@{
            Size  = $info.Length
            Ticks = $info.LastWriteTimeUtc.Ticks
            Hash  = $Hash
        }

        $Global:HashCacheDirty = $true
    }
    catch
    {
        # sin cache para este archivo; no pasa nada
    }
}

#--------------------------------------------------------------
# Guarda la cache en disco (solo si cambio), quitando antes las
# entradas de archivos que ya no existen. Nunca lanza excepcion.
#--------------------------------------------------------------

function Save-HashCache {

    if(-not (Test-HashCacheEnabled) -or -not $Global:HashCacheDirty -or $null -eq $Global:HashCacheData)
    {
        return
    }

    $path = Get-HashCachePath
    $temp = "$path.$PID.tmp"

    try
    {
        $folder = Split-Path $path -Parent

        if(-not [string]::IsNullOrWhiteSpace($folder) -and -not [System.IO.Directory]::Exists($folder))
        {
            [System.IO.Directory]::CreateDirectory($folder) | Out-Null
        }

        $lines = New-Object 'System.Collections.Generic.List[string]'
        $lines.Add("CleanROMs-HashCache`t1`t$($Global:HashCacheAlgorithm)")

        foreach($key in @($Global:HashCacheData.Keys))
        {
            if(-not [System.IO.File]::Exists($key))
            {
                [void]$Global:HashCacheData.Remove($key)
                continue
            }

            $e = $Global:HashCacheData[$key]
            $lines.Add("$key`t$($e.Size)`t$($e.Ticks)`t$($e.Hash)")
        }

        [System.IO.File]::WriteAllLines($temp, $lines, (New-Object System.Text.UTF8Encoding($false)))

        #
        # En Windows, el antivirus o el indexador de busqueda pueden tener
        # el archivo abierto un instante justo despues de escribirlo (se vio
        # al guardar la cache varias veces seguidas: "The process cannot
        # access the file because it is being used by another process").
        # Se reintenta unas veces con una espera corta. Y -ErrorAction Stop
        # hace que el fallo llegue al catch en vez de imprimirse en pantalla
        # (Move-Item sin eso solo lanza un error "no terminante").
        #

        $replaced = $false

        for($attempt = 1; $attempt -le 6 -and -not $replaced; $attempt++)
        {
            try
            {
                Move-Item -LiteralPath $temp -Destination $path -Force -ErrorAction Stop
                $replaced = $true
            }
            catch
            {
                Start-Sleep -Milliseconds (100 * $attempt)
            }
        }

        if($replaced)
        {
            $Global:HashCacheDirty = $false
        }
        else
        {
            # La cache es solo un acelerador: si no se puede guardar ahora, se
            # guardara en el siguiente intento. Se limpia el temporal.
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
    catch
    {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}
