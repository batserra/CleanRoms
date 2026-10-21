# ============================================================
# BUG corregido (visto en Windows): al guardar la cache de hashes, a veces
# salia en pantalla
#
#   Move-Item: ...\HashCache.ps1:257
#   The process cannot access the file because it is being used by another process.
#
# Pasa cuando el antivirus o el indexador de busqueda de Windows tienen el
# archivo abierto un instante justo despues de escribirlo. Era un error
# "no terminante" de Move-Item (se imprimia en vez de llegar al catch).
#
# Ahora Save-HashCache reintenta unas veces con una espera corta y, si no
# lo consigue, lo deja para el siguiente guardado sin imprimir nada ni
# lanzar excepciones (la cache es solo un acelerador).
#
# El bloqueo se simula sustituyendo Move-Item por una funcion que falla.
# ============================================================

$tempRoot = New-TestTempFolder
$cacheFile = Join-Path $tempRoot "cache.tsv"
$romFile = Join-Path $tempRoot "game.sfc"
Set-Content -LiteralPath $romFile -Value "contenido"

$saved = @{
    Path      = $Global:HashCachePath
    Enabled   = $Global:Settings.HashCache
    Algorithm = $Global:Settings.HashAlgorithm
}

$Global:HashCachePath = $cacheFile
$Global:Settings.HashCache = $true
$Global:Settings.HashAlgorithm = "MD5"

$global:mvCalls = 0
$global:mvFailFirst = 0

function global:Move-Item
{
    param([string]$LiteralPath, [string]$Destination, [switch]$Force, $ErrorAction)

    $global:mvCalls++

    if($global:mvCalls -le $global:mvFailFirst)
    {
        throw "The process cannot access the file because it is being used by another process. (simulado)"
    }

    Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination -Force
}

try
{
    #
    # Bloqueo pasajero: falla 2 veces y a la tercera se guarda
    #

    Reset-HashCache
    $null = Get-RomHash -Path $romFile

    $global:mvCalls = 0
    $global:mvFailFirst = 2

    $threw = $false
    $output = @()

    try { $output = @(Save-HashCache 2>&1 3>&1 6>&1) } catch { $threw = $true }

    Assert-Equal $false $threw "Bloqueo pasajero: no lanza excepcion"
    Assert-Equal 0 $output.Count "Bloqueo pasajero: no imprime nada en pantalla (antes salia el error de Move-Item)"
    Assert-Equal 3 $global:mvCalls "Bloqueo pasajero: reintenta (2 fallos + 1 exito)"
    Assert-Equal $true (Test-Path -LiteralPath $cacheFile) "Bloqueo pasajero: la cache se guarda"
    Assert-Equal $false $Global:HashCacheDirty "Bloqueo pasajero: tras guardar ya no esta pendiente"
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $tempRoot -Filter "*.tmp").Count "Bloqueo pasajero: no queda ningun temporal"

    #
    # Bloqueo permanente: se rinde sin ruido y queda pendiente
    #

    Remove-Item -LiteralPath $cacheFile -Force
    Reset-HashCache
    $null = Get-RomHash -Path $romFile

    $global:mvCalls = 0
    $global:mvFailFirst = 1000

    $threw = $false
    $output = @()

    try { $output = @(Save-HashCache 2>&1 3>&1 6>&1) } catch { $threw = $true }

    Assert-Equal $false $threw "Bloqueo permanente: no lanza excepcion"
    Assert-Equal 0 $output.Count "Bloqueo permanente: no imprime nada en pantalla"
    Assert-Equal 6 $global:mvCalls "Bloqueo permanente: se rinde tras 6 intentos"
    Assert-Equal $false (Test-Path -LiteralPath $cacheFile) "Bloqueo permanente: no se crea una cache a medias"
    Assert-Equal $true $Global:HashCacheDirty "Bloqueo permanente: queda pendiente para el siguiente guardado"
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $tempRoot -Filter "*.tmp").Count "Bloqueo permanente: se limpia el temporal"

    # ... y cuando el bloqueo se va, el siguiente guardado funciona
    $global:mvCalls = 0
    $global:mvFailFirst = 0

    Save-HashCache

    Assert-Equal $true (Test-Path -LiteralPath $cacheFile) "Tras el bloqueo: el siguiente guardado funciona"
}
finally
{
    Remove-Item Function:\Move-Item -ErrorAction SilentlyContinue

    $Global:HashCachePath = $saved.Path
    $Global:Settings.HashCache = $saved.Enabled
    $Global:Settings.HashAlgorithm = $saved.Algorithm
    Reset-HashCache

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
