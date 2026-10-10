# ============================================================
# MEJORA: cache de hashes (Resultado\HashCache.tsv).
#
# Calcular el hash de miles de ROMs es lo que mas tarda; la cache
# reutiliza el de los archivos que no han cambiado (mismo tamano y
# fecha de modificacion).
#
# Comprueba:
# - Un archivo hasheado dos veces: la segunda sale de la cache.
# - Persiste en disco y se reutiliza tras "reiniciar" (Reset).
# - Si el archivo cambia de contenido (y de tamano/fecha), se
#   recalcula y el hash nuevo es el correcto.
# - Si cambia solo la fecha o solo el tamano, tambien se recalcula.
# - Cambiar de algoritmo descarta la cache.
# - Una cache corrupta se ignora sin error.
# - HashCache = $false no lee ni escribe nada.
# - Los archivos que ya no existen se quitan al guardar.
# - Group-RomsByHash no hashea los archivos de tamano unico.
# ============================================================

$tempRoot = New-TestTempFolder
$cacheFile = Join-Path $tempRoot "cache.tsv"

$saved = @{
    Path      = $Global:HashCachePath
    Enabled   = $Global:Settings.HashCache
    Algorithm = $Global:Settings.HashAlgorithm
}

$Global:HashCachePath = $cacheFile
$Global:Settings.HashCache = $true
$Global:Settings.HashAlgorithm = "MD5"

Reset-HashCache

function New-TestRomFile
{
    param([string]$Name, [string]$Content)

    $path = Join-Path $tempRoot $Name
    [System.IO.File]::WriteAllText($path, $Content)
    return $path
}

try
{
    $a = New-TestRomFile "a.sfc" "contenido A"
    $expectedA = (Get-FileHash -LiteralPath $a -Algorithm MD5).Hash

    #
    # Miss y luego hit
    #

    $h1 = Get-RomHash -Path $a
    Assert-Equal $expectedA $h1 "Cache: el primer hash es el correcto"
    Assert-Equal 1 ([int]$Global:HashCacheStats.Misses) "Cache: la primera vez no esta en cache"

    $h2 = Get-RomHash -Path $a
    Assert-Equal $expectedA $h2 "Cache: el segundo hash es el correcto"
    Assert-Equal 1 ([int]$Global:HashCacheStats.Hits) "Cache: la segunda vez sale de la cache"

    #
    # Persistencia
    #

    Save-HashCache
    Assert-Equal $true (Test-Path -LiteralPath $cacheFile) "Cache: se guarda en disco"

    Reset-HashCache

    $h3 = Get-RomHash -Path $a
    Assert-Equal $expectedA $h3 "Cache: tras reiniciar, el hash sigue siendo correcto"
    Assert-Equal 1 ([int]$Global:HashCacheStats.Hits) "Cache: tras reiniciar, se reutiliza lo guardado en disco"

    #
    # Contenido que cambia (cambia tambien el tamano): se recalcula
    #

    [System.IO.File]::WriteAllText($a, "contenido A modificado y mas largo")
    $newExpected = (Get-FileHash -LiteralPath $a -Algorithm MD5).Hash

    Assert-Equal $newExpected (Get-RomHash -Path $a) "Cache: si el archivo cambia, el hash se recalcula"
    Assert-Equal $true ($newExpected -ne $expectedA) "Cache: (comprobacion del propio test) el hash nuevo es distinto"

    #
    # Solo cambia la fecha: se recalcula (y da el mismo hash)
    #

    Reset-HashCache
    $null = Get-RomHash -Path $a
    (Get-Item -LiteralPath $a).LastWriteTimeUtc = (Get-Date).AddDays(-30).ToUniversalTime()

    $misses = [int]$Global:HashCacheStats.Misses
    $null = Get-RomHash -Path $a

    Assert-Equal ($misses + 1) ([int]$Global:HashCacheStats.Misses) "Cache: si cambia la fecha de modificacion, no se fia y recalcula"

    #
    # Varios archivos a la vez (Get-RomHashesParallel)
    #

    $paths = @()
    1..30 | ForEach-Object { $paths += (New-TestRomFile "m$_.sfc" ("contenido $_")) }

    Reset-HashCache
    $first = Get-RomHashesParallel -Paths $paths 6>$null
    Save-HashCache

    Reset-HashCache
    $second = Get-RomHashesParallel -Paths $paths 6>$null

    Assert-Equal 30 ([int]$Global:HashCacheStats.Hits) "Cache en lote: la segunda pasada reutiliza los 30 hashes"

    $allEqual = $true
    foreach($p in $paths) { if($first[$p] -ne $second[$p] -or $first[$p] -ne (Get-FileHash -LiteralPath $p -Algorithm MD5).Hash) { $allEqual = $false } }

    Assert-Equal $true $allEqual "Cache en lote: los hashes de la cache coinciden con los reales"

    #
    # Un archivo cambia dentro del lote: solo ese se recalcula
    #

    [System.IO.File]::WriteAllText($paths[0], "otro contenido distinto del anterior")
    Reset-HashCache
    $third = Get-RomHashesParallel -Paths $paths 6>$null

    Assert-Equal 29 ([int]$Global:HashCacheStats.Hits) "Cache en lote: solo se recalcula el archivo que cambio"
    Assert-Equal (Get-FileHash -LiteralPath $paths[0] -Algorithm MD5).Hash $third[$paths[0]] "Cache en lote: el archivo que cambio tiene su hash nuevo"

    #
    # Archivos borrados se quitan al guardar
    #

    Save-HashCache
    Remove-Item -LiteralPath $paths[1] -Force
    $Global:HashCacheDirty = $true
    Save-HashCache

    $cacheText = Get-Content -LiteralPath $cacheFile -Raw
    Assert-Equal $false ($cacheText -like "*m2.sfc*") "Cache: las entradas de archivos borrados se eliminan al guardar"

    #
    # Cambio de algoritmo: la cache anterior no vale
    #

    Reset-HashCache
    $Global:Settings.HashAlgorithm = "SHA256"
    $sha = Get-RomHash -Path $a

    Assert-Equal (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash $sha "Cache: con otro algoritmo se calcula con el nuevo"
    Assert-Equal 0 ([int]$Global:HashCacheStats.Hits) "Cache: con otro algoritmo no se reutiliza nada de la cache MD5"

    $Global:Settings.HashAlgorithm = "MD5"

    #
    # La lectura de la cache NO deja el archivo abierto. (Fallo real en
    # Windows: al leer una cache de otro algoritmo se salia de la lectura
    # antes de tiempo y el archivo quedaba bloqueado, asi que no se podia
    # reescribir ni borrar. En Linux no se nota, por eso se comprueba
    # abriendolo en exclusiva, que falla si queda algun manejador abierto.)
    #

    Reset-HashCache
    $Global:Settings.HashAlgorithm = "SHA256"
    $null = Get-CachedHash -Path $a -Algorithm "SHA256"     # lee la cache MD5 y la descarta
    $Global:Settings.HashAlgorithm = "MD5"

    $locked = $false

    try
    {
        $stream = [System.IO.File]::Open($cacheFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Dispose()
    }
    catch
    {
        $locked = $true
    }

    Assert-Equal $false $locked "Cache: tras leerla (aunque no sirva) el archivo no queda abierto/bloqueado"

    #
    # Cache corrupta
    #

    Set-Content -LiteralPath $cacheFile -Value "esto no es una cache`nni de lejos`n1`t2`t3"
    Reset-HashCache

    $threw = $false
    $h = $null

    try { $h = Get-RomHash -Path $a } catch { $threw = $true }

    Assert-Equal $false $threw "Cache corrupta: no lanza excepcion"
    Assert-Equal (Get-FileHash -LiteralPath $a -Algorithm MD5).Hash $h "Cache corrupta: se ignora y el hash sale bien"

    #
    # Desactivada
    #

    Remove-Item -LiteralPath $cacheFile -Force
    Reset-HashCache
    $Global:Settings.HashCache = $false

    $null = Get-RomHash -Path $a
    $null = Get-RomHashesParallel -Paths $paths 6>$null
    Save-HashCache

    Assert-Equal $false (Test-Path -LiteralPath $cacheFile) "Cache desactivada: no se escribe ningun archivo"
    Assert-Equal 0 ([int]$Global:HashCacheStats.Hits + [int]$Global:HashCacheStats.Misses) "Cache desactivada: ni se consulta"

    $Global:Settings.HashCache = $true

    #
    # Group-RomsByHash: solo se hashean los archivos de tamano repetido
    #

    Reset-HashCache
    Remove-Item -LiteralPath $cacheFile -Force -ErrorAction SilentlyContinue

    $hackFolder = Join-Path $tempRoot "hacks"
    New-Item -ItemType Directory -Path $hackFolder -Force | Out-Null

    $same1 = Join-Path $hackFolder "Same One (Hack).smc"
    $same2 = Join-Path $hackFolder "Same Two (Hack).smc"
    $unique1 = Join-Path $hackFolder "Unique A (Hack).smc"
    $unique2 = Join-Path $hackFolder "Unique B (Hack).smc"

    [System.IO.File]::WriteAllText($same1, "identical hack bytes")
    [System.IO.File]::WriteAllText($same2, "identical hack bytes")
    [System.IO.File]::WriteAllText($unique1, "short")
    [System.IO.File]::WriteAllText($unique2, "a considerably longer unique file")

    $roms = @(Get-RomsFromFolder -Path $hackFolder -SystemName "snes" 6>$null)
    $groups = @(Group-RomsByHash -Roms $roms -SystemName "snes" 6>$null)

    Assert-Equal 1 $groups.Count "Group-RomsByHash: encuentra el unico grupo de copias exactas"
    Assert-Equal 1 @($groups[0].Remove).Count "Group-RomsByHash: una copia sobrante"

    $cacheAfter = [int]$Global:HashCacheData.Count

    Assert-Equal 2 $cacheAfter "Group-RomsByHash: solo se hashearon los 2 archivos del mismo tamano (los de tamano unico ni se leen)"

    #
    # Sin duplicados posibles: ni se hashea
    #

    Reset-HashCache
    $roms2 = @(Get-RomsFromFolder -Path $hackFolder -SystemName "snes" 6>$null | Where-Object { $_.FullPath -like "*Unique*" })
    $groups2 = @(Group-RomsByHash -Roms $roms2 -SystemName "snes" 6>$null)

    Assert-Equal 0 $groups2.Count "Group-RomsByHash: archivos de tamanos distintos no tienen duplicados"
    Assert-Equal 0 ([int]$Global:HashCacheStats.Hits + [int]$Global:HashCacheStats.Misses) "Group-RomsByHash: archivos de tamanos distintos no se hashean"
}
finally
{
    $Global:HashCachePath = $saved.Path
    $Global:Settings.HashCache = $saved.Enabled
    $Global:Settings.HashAlgorithm = $saved.Algorithm
    Reset-HashCache

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
