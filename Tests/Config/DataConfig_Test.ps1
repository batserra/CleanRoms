# ============================================================
# MEJORA: los sistemas, las extensiones de ROM y las carpetas
# ignoradas viven ahora en JSON (Config\Systems.json y
# Config\Extensions.json), en vez de listas dentro de Settings.ps1.
# Se pueden ampliar sin tocar esos archivos con
# Systems.custom.json y Extensions.custom.json.
#
# Comprueba:
# - Los JSON que se entregan dan los mismos datos que tenia
#   Settings.ps1 (63 sistemas, 113 extensiones, 12 carpetas).
# - Lectura de varias formas (por categorias o suelto).
# - Los .custom.json se suman y, en sistemas, mandan sobre los
#   de fabrica; las extensiones se normalizan (".GBA" / "gba").
# - Entradas no validas: se avisan y se ignoran, sin tumbar nada.
# - Errores graves (falta el archivo, JSON roto, sin sistemas):
#   mensaje claro con el nombre del archivo.
# ============================================================

$tempRoot = New-TestTempFolder

$saved = @{
    Systems    = $Global:SystemPaths
    Extensions = $Global:RomExtensions
    Ignored    = $Global:IgnoredFolders
}

function New-ConfigFolder
{
    param([string]$Name, [hashtable]$Files)

    $folder = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    foreach($file in $Files.Keys)
    {
        Set-Content -LiteralPath (Join-Path $folder $file) -Value $Files[$file] -Encoding UTF8
    }

    return $folder
}

function Get-ConfigError
{
    param([string]$Folder)

    try
    {
        Import-DataConfig -ConfigFolder $Folder 3>$null
        return ""
    }
    catch
    {
        return $_.Exception.Message
    }
}

try
{
    #
    # Los JSON entregados
    #

    $realConfig = Join-Path (Join-Path $Root "Config") "."
    $realConfig = Split-Path (Get-Item -LiteralPath (Join-Path $Root "Config\Systems.json")).FullName -Parent

    Import-DataConfig -ConfigFolder $realConfig 3>$null

    Assert-Equal 105 $Global:SystemPaths.Count "Config entregada: 105 sistemas (63 + 41 de la tabla de RetroBat 8.2.1 + PS4 de RetroBat 8.3.1.1)"
    Assert-Equal 182 @($Global:RomExtensions).Count "Config entregada: 182 extensiones (113 + 63 de RetroBat 8.2.1 + 6 de RetroBat 8.3.1.1)"
    Assert-Equal 12 @($Global:IgnoredFolders).Count "Config entregada: 12 carpetas ignoradas"

    #
    # Sistemas de la tabla de RetroBat 8.2.1 ya incluidos
    #

    foreach($folder in "sega32x", "atari5200", "jaguar", "pcenginecd", "neogeocd", "vic20", "amigacd32", "naomi2", "scummvm", "pico8", "virtualboy", "n64dd")
    {
        Assert-Equal $true (@($Global:SystemPaths.Values) -contains $folder) "Config entregada: incluye el sistema '$folder'"
    }

    # Novedades de RetroBat 8.3.1.1: PS4 y sus extensiones seguras
    Assert-Equal $true (@($Global:SystemPaths.Values) -contains "ps4") "Config entregada: incluye el sistema 'ps4' (RetroBat 8.3.1.1)"

    foreach($ext in ".ps4", ".zar", ".xcp", ".xbox360", ".68k", ".sgd")
    {
        Assert-Equal $true (@($Global:RomExtensions) -contains $ext) "Config entregada: incluye la extension '$ext' (RetroBat 8.3.1.1)"
    }

    # Acompanantes/descriptores sin logica de agrupacion: nunca como ROM
    foreach($ext in ".mds", ".mdf", ".toc", ".cbn", ".decomp")
    {
        Assert-Equal $false (@($Global:RomExtensions) -contains $ext) "Config entregada: NO incluye '$ext' (acompanante o generica; sus medios se protegen en MediaCleaner)"
    }

    # Los nombres antiguos de carpeta siguen funcionando (quien tenga RetroBat anterior)
    foreach($folder in "atarijaguar", "coleco", "lynx", "n3ds", "gx4000", "ngpc")
    {
        Assert-Equal $true (@($Global:SystemPaths.Values) -contains $folder) "Config entregada: sigue incluyendo el nombre antiguo de carpeta '$folder'"
    }

    #
    # Lo que NO debe estar NUNCA (la tabla de RetroBat lo declara, pero aqui
    # seria peligroso: el programa mueve "duplicados" por titulo)
    #

    foreach($folder in "library", "screenshots", "retrobat", "pc", "ports", "cavestory")
    {
        Assert-Equal $false (@($Global:SystemPaths.Values) -contains $folder) "Config entregada: NO incluye la carpeta '$folder' (medios o ejecutables, no ROMs)"
    }

    $forbidden = @(
        ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".psd", ".tga", ".mp4", ".mkv", ".avi", ".pdf", ".cbz", ".cbr",
        ".exe", ".bat", ".cmd", ".lnk", ".sh", ".com", ".conf", ".json", ".lst", ".menu",
        ".dat", ".pak", ".wad", ".elf", ".o", ".p", ".app", ".game",
        ".ccd", ".rap"
    )

    $presentForbidden = @($forbidden | Where-Object { @($Global:RomExtensions) -contains $_ })

    Assert-Equal 0 $presentForbidden.Count "Config entregada: ninguna extension de imagen/video/documento/ejecutable/generica o acompanante ($($presentForbidden -join ', '))"

    $badFormat = @(@($Global:RomExtensions) | Where-Object { $_ -cnotmatch '^\.[a-z0-9_]+$' })

    Assert-Equal 0 $badFormat.Count "Config entregada: todas las extensiones empiezan por punto y estan en minusculas ($($badFormat -join ', '))"
    Assert-Equal @($Global:RomExtensions).Count @($Global:RomExtensions | Select-Object -Unique).Count "Config entregada: sin extensiones repetidas"
    Assert-Equal $Global:SystemPaths.Count @($Global:SystemPaths.Values | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique).Count "Config entregada: dos nombres de sistema no apuntan a la misma carpeta"

    #
    # El escaner reconoce un formato nuevo y sigue ignorando medios
    #

    $scanRoot = New-TestTempFolder

    try
    {
        $sys32x = Join-Path $scanRoot "sega32x"
        New-Item -ItemType Directory -Path $sys32x -Force | Out-Null

        foreach($n in "Game (USA).32x", "Game (Europe).32x", "Cover (USA).png", "Setup (USA).exe", "Notes.pdf")
        {
            Set-Content -LiteralPath (Join-Path $sys32x $n) -Value "x"
        }

        $recognized = @(Get-RomFiles -Folder $sys32x | ForEach-Object Name | Sort-Object)

        Assert-Equal "Game (Europe).32x,Game (USA).32x" ($recognized -join ",") "Escaner: reconoce .32x (formato nuevo) e ignora .png, .exe y .pdf"
    }
    finally
    {
        Remove-Item -Path $scanRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Assert-Equal "snes" $Global:SystemPaths["SNES"] "Config entregada: SNES -> snes"
    Assert-Equal "nes3d" $Global:SystemPaths["Nintendo Entertainment System 3D (NES3D)"] "Config entregada: NES3D -> nes3d (el caso que ya dio guerra)"
    Assert-Equal $true (@($Global:RomExtensions) -contains ".chd") "Config entregada: .chd es extension de ROM"
    Assert-Equal $true (@($Global:IgnoredFolders) -contains "_duplicates") "Config entregada: _duplicates nunca se escanea"

    #
    # Formatos: por categorias y suelto
    #

    $f = New-ConfigFolder "basic" @{
        "Systems.json"    = '{ "Consolas": { "SNES": "snes", "NES": "nes" }, "Arcade": { "MAME": "mame" }, "Suelto": "gb" }'
        "Extensions.json" = '{ "RomExtensions": [".SFC", "nes", ".nes"], "IgnoredFolders": ["images", "bios"] }'
    }

    Import-DataConfig -ConfigFolder $f 3>$null

    Assert-Equal 4 $Global:SystemPaths.Count "Formato: categorias y entradas sueltas se mezclan (4 sistemas)"
    Assert-Equal "gb" $Global:SystemPaths["Suelto"] "Formato: una entrada suelta (sin categoria) vale"
    Assert-Equal ".sfc,.nes" (@($Global:RomExtensions) -join ",") "Extensiones: se pasan a minusculas, se anade el punto y se quitan repetidas"
    Assert-Equal "images,bios" (@($Global:IgnoredFolders) -join ",") "Carpetas ignoradas: se leen tal cual"

    #
    # Archivos custom: suman y mandan
    #

    $f = New-ConfigFolder "custom" @{
        "Systems.json"           = '{ "A": { "SNES": "snes", "NES": "nes" } }'
        "Extensions.json"        = '{ "RomExtensions": [".sfc"], "IgnoredFolders": ["images"] }'
        "Systems.custom.json"    = '{ "Mios": { "Mi sistema": "mio", "NES": "nes_hacks" } }'
        "Extensions.custom.json" = '{ "RomExtensions": ["abc", ".sfc"], "IgnoredFolders": ["mis_cosas"] }'
    }

    Import-DataConfig -ConfigFolder $f 3>$null

    Assert-Equal 3 $Global:SystemPaths.Count "Custom: se suma el sistema nuevo (3 sistemas)"
    Assert-Equal "mio" $Global:SystemPaths["Mi sistema"] "Custom: el sistema anadido esta"
    Assert-Equal "nes_hacks" $Global:SystemPaths["NES"] "Custom: si repite un nombre, manda el custom"
    Assert-Equal "snes" $Global:SystemPaths["SNES"] "Custom: lo que no toca queda como estaba"
    Assert-Equal ".sfc,.abc" (@($Global:RomExtensions) -join ",") "Custom: se suman extensiones sin repetir"
    Assert-Equal "images,mis_cosas" (@($Global:IgnoredFolders) -join ",") "Custom: se suman carpetas ignoradas"

    #
    # Custom vacio o sin las claves: no pasa nada
    #

    $f = New-ConfigFolder "customempty" @{
        "Systems.json"           = '{ "A": { "SNES": "snes" } }'
        "Extensions.json"        = '{ "RomExtensions": [".sfc"], "IgnoredFolders": [] }'
        "Systems.custom.json"    = ''
        "Extensions.custom.json" = '{ }'
    }

    Import-DataConfig -ConfigFolder $f 3>$null

    Assert-Equal 1 $Global:SystemPaths.Count "Custom vacio o sin claves: no cambia nada"

    #
    # Entradas no validas: se ignoran con aviso
    #

    $f = New-ConfigFolder "invalid" @{
        "Systems.json"    = '{ "A": { "Bien": "ok", "Vacio": "", "ConRuta": "a/b", "Numero": 5, "   ": "x" } }'
        "Extensions.json" = '{ "RomExtensions": [".ok", 5, "", null], "IgnoredFolders": ["x", 7] }'
    }

    $output = @(Import-DataConfig -ConfigFolder $f 3>&1)
    $warnings = @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })

    Assert-Equal 1 $Global:SystemPaths.Count "No validas: solo queda el sistema correcto"
    Assert-Equal "ok" $Global:SystemPaths["Bien"] "No validas: el correcto se conserva"
    Assert-Equal ".ok" (@($Global:RomExtensions) -join ",") "No validas: solo queda la extension correcta"
    Assert-Equal "x" (@($Global:IgnoredFolders) -join ",") "No validas: solo queda la carpeta correcta"
    Assert-Equal $true ($warnings.Count -ge 6) "No validas: cada entrada rechazada genera un aviso"

    #
    # Errores graves: mensaje claro con el nombre del archivo
    #

    $msg = Get-ConfigError (New-ConfigFolder "nosystems" @{ "Extensions.json" = '{ "RomExtensions": [".a"] }' })
    Assert-Equal $true ($msg -like "*Systems.json*") "Falta Systems.json: el error nombra el archivo"

    $msg = Get-ConfigError (New-ConfigFolder "noext" @{ "Systems.json" = '{ "A": { "X": "x" } }' })
    Assert-Equal $true ($msg -like "*Extensions.json*") "Falta Extensions.json: el error nombra el archivo"

    $msg = Get-ConfigError (New-ConfigFolder "broken" @{ "Systems.json" = '{ "A": { "X": "x" '; "Extensions.json" = '{ "RomExtensions": [".a"] }' })
    Assert-Equal $true ($msg -like "*Systems.json*" -and $msg -like "*JSON*") "JSON roto: el error nombra el archivo y dice que el JSON no es valido"

    $msg = Get-ConfigError (New-ConfigFolder "brokencustom" @{ "Systems.json" = '{ "A": { "X": "x" } }'; "Extensions.json" = '{ "RomExtensions": [".a"] }'; "Systems.custom.json" = '[[[' })
    Assert-Equal $true ($msg -like "*Systems.custom.json*") "Custom roto: el error nombra el archivo custom"

    $msg = Get-ConfigError (New-ConfigFolder "empty" @{ "Systems.json" = '{ }'; "Extensions.json" = '{ "RomExtensions": [".a"] }' })
    Assert-Equal $true ($msg -like "*ningun sistema*") "Sin sistemas: error claro"

    $msg = Get-ConfigError (New-ConfigFolder "noextensions" @{ "Systems.json" = '{ "A": { "X": "x" } }'; "Extensions.json" = '{ "RomExtensions": [] }' })
    Assert-Equal $true ($msg -like "*ninguna extension*") "Sin extensiones: error claro"
}
finally
{
    $Global:SystemPaths = $saved.Systems
    $Global:RomExtensions = $saved.Extensions
    $Global:IgnoredFolders = $saved.Ignored

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
