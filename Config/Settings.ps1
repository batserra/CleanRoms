# ============================================================
#
# Beta CleanROMs v2.6
#
# Settings.ps1
#
# Configuración global
#
# ============================================================

#--------------------------------------------------------------
# Ruta base de RetroBat
#
# Este valor es solo el predeterminado de fábrica. La ruta real
# se pregunta la primera vez que se ejecuta el programa (o se
# lee de Config\UserSettings.json si ya se configuró antes) —
# ver Initialize-RetroBatRoot más abajo.
#--------------------------------------------------------------

$Global:RetroBatRoot = "C:\RetroBat\roms"

#--------------------------------------------------------------
# Modo no interactivo (-Yes en main.ps1)
#
# BUG corregido en la v2.6: esta variable solo se asignaba dentro
# de main.ps1 (según se indicara o no -Yes), así que en cualquier
# otro contexto que cargue los módulos sin pasar por main.ps1
# (por ejemplo, la suite de tests) leerla bajo
# Set-StrictMode -Version Latest (activo desde que se carga
# DecisionEngine.ps1) lanzaba "la variable no se ha establecido"
# en vez de tratarla como $false. Se inicializa aquí, junto al
# resto de valores globales por defecto, para que siempre exista
# de entrada — main.ps1 la sigue pudiendo cambiar a $true con -Yes
# igual que hasta ahora.
#--------------------------------------------------------------

$Global:AutoConfirm = $false

#--------------------------------------------------------------
# Configurar la ruta de RetroBat sin tener que editar el código
#--------------------------------------------------------------

function Get-UserSettings {

    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $configFile = Join-Path $Root "Config\UserSettings.json"

    #
    # BUG corregido en la v2.6: antes, si el archivo no existía
    # todavía (primer arranque) o estaba dañado, se devolvía un
    # [PSCustomObject]@{} completamente vacío -- sin ninguna
    # propiedad definida, ni siquiera a $null. Como
    # DecisionEngine.ps1 activa Set-StrictMode -Version Latest
    # para todo el programa, leer $userConfig.Language o
    # $userConfig.RetroBatRoot sobre ese objeto vacío lanzaba
    # "La propiedad 'Language' no se encuentra en este objeto" en
    # vez de devolver $null -- por ejemplo, al reconfigurar desde
    # la opción 5 del menú si el archivo guardado no tuviera
    # ambas claves. Ahora se garantiza que las dos propiedades
    # existen siempre (aunque sea a $null), venga o no el archivo,
    # y tenga o no ambas claves.
    #

    $result = [PSCustomObject]@{
        Language     = $null
        RetroBatRoot = $null
    }

    if(Test-Path -LiteralPath $configFile)
    {
        try
        {
            $loaded = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json

            foreach($propName in @("Language", "RetroBatRoot"))
            {
                if($loaded.PSObject.Properties.Name -contains $propName)
                {
                    $result.$propName = $loaded.$propName
                }
            }
        }
        catch
        {
            # Archivo de configuración dañado: se ignora, y se
            # devuelve $result con sus valores $null de partida.
        }
    }

    return $result

}

function Save-UserSettings {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        $Settings
    )

    $configFile = Join-Path $Root "Config\UserSettings.json"
    $configFolder = Split-Path $configFile -Parent

    if(!(Test-Path -LiteralPath $configFolder))
    {
        New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
    }

    $Settings | ConvertTo-Json | Set-Content $configFile

}

function Initialize-Language {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [switch]$Force
    )

    $userConfig = Get-UserSettings -Root $Root

    if((-not $Force) -and (-not [string]::IsNullOrWhiteSpace($userConfig.Language)))
    {
        $Global:Settings.Language = $userConfig.Language
        return
    }

    #
    # Primer arranque: no hay idioma guardado todavía.
    #

    if($Global:AutoConfirm)
    {
        #
        # Modo no interactivo (-Yes): no hay nadie para elegir
        # idioma. Se usa español por defecto y se guarda, para que
        # las próximas ejecuciones ya no tengan que decidir nada
        # aquí (interactivas o no).
        #

        $Global:Settings.Language = "es"

        $userConfig | Add-Member -NotePropertyName "Language" -NotePropertyValue "es" -Force
        Save-UserSettings -Root $Root -Settings $userConfig

        return
    }

    #
    # Este mensaje se muestra siempre en los dos idiomas a la vez,
    # porque todavía no sabemos cuál prefiere la persona que lo
    # está viendo.
    #

    Write-Host ""
    Write-Host "Selecciona idioma / Select language:" -ForegroundColor Cyan
    Write-Host " 1) Español"
    Write-Host " 2) English"
    Write-Host ""

    do
    {
        $typed = Read-Host "Opción / Option"
    }
    until($typed -match '^[12]$')

    $Global:Settings.Language = if($typed -eq "2") { "en" } else { "es" }

    $userConfig | Add-Member -NotePropertyName "Language" -NotePropertyValue $Global:Settings.Language -Force
    Save-UserSettings -Root $Root -Settings $userConfig

}

function Initialize-RetroBatRoot {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [switch]$Force
    )

    $userConfig = Get-UserSettings -Root $Root

    if((-not $Force) -and (-not [string]::IsNullOrWhiteSpace($userConfig.RetroBatRoot)) -and (Test-Path -LiteralPath $userConfig.RetroBatRoot))
    {
        $Global:RetroBatRoot = $userConfig.RetroBatRoot
        return
    }

    #
    # No hay configuración guardada (o no es válida): se pregunta,
    # sugiriendo como valor por defecto la carpeta que contiene a
    # CleanRoms (normalmente la carpeta "roms" de RetroBat)
    #

    $suggested = Split-Path $Root -Parent

    if($Global:AutoConfirm)
    {
        #
        # Modo no interactivo (-Yes): no hay nadie para escribir
        # una ruta. Si la carpeta sugerida por defecto existe de
        # verdad, se usa sin preguntar y se guarda. Si ni siquiera
        # esa existe, no hay ninguna respuesta segura que adivinar
        # — se deja $Global:RetroBatRoot vacío para que main.ps1
        # lo detecte y pare con un error claro, en vez de quedarse
        # aquí esperando una respuesta que nunca va a llegar.
        #

        if(Test-Path -LiteralPath $suggested)
        {
            $Global:RetroBatRoot = $suggested

            $userConfig | Add-Member -NotePropertyName "RetroBatRoot" -NotePropertyValue $suggested -Force
            Save-UserSettings -Root $Root -Settings $userConfig
        }
        else
        {
            $Global:RetroBatRoot = $null
        }

        return
    }

    Write-Host ""
    Write-Host (T "config.rootNotSet") -ForegroundColor Cyan

    do
    {
        $typed = Read-Host (T "config.rootPrompt" $suggested)

        if([string]::IsNullOrWhiteSpace($typed))
        {
            $candidate = $suggested
        }
        else
        {
            $candidate = $typed
        }

        if(!(Test-Path -LiteralPath $candidate))
        {
            Write-Host (T "config.folderNotExists") -ForegroundColor Yellow
            $candidate = $null
        }
    }
    until($null -ne $candidate)

    $Global:RetroBatRoot = $candidate

    #
    # Guardar para no volver a preguntar en próximas ejecuciones,
    # conservando cualquier otro ajuste ya guardado (p.ej. Language)
    #

    $userConfig | Add-Member -NotePropertyName "RetroBatRoot" -NotePropertyValue $candidate -Force
    Save-UserSettings -Root $Root -Settings $userConfig

    Write-Host (T "config.rootSaved") -ForegroundColor Green
    Write-Host ""
}

#--------------------------------------------------------------
# Carpeta donde se moverán los duplicados
#--------------------------------------------------------------

$Global:DuplicatesFolder = "_duplicates"

#--------------------------------------------------------------
# Opciones de funcionamiento
#--------------------------------------------------------------

$Global:Settings = @{

    Language         = "es"

    PreviewOnly      = $false

    MoveAssets       = $true

    #
    # Verificacion por hash (SHA256/MD5): compara el contenido real
    # de los archivos, no solo el nombre. Se usa siempre (barato,
    # solo 2 archivos) para resolver un empate total sin tener que
    # preguntar, y opcionalmente (VerifyHashOnMove) para anotar en
    # cada movimiento si el contenido es idéntico o no al que se
    # conserva. Activarlo para todos los movimientos puede ralentizar
    # colecciones muy grandes, porque hay que leer el archivo entero.
    #

    VerifyHashOnMove = $false

    HashAlgorithm    = "MD5"

    CreateLog        = $true

    AskConfirmation  = $true

    KeepBestRomOnly  = $true

    RemoveDuplicates = $false

    #
    # Cuántas limpiezas anteriores se conservan en
    # Resultado\History\ para poder deshacerlas con la opción
    # "Deshacer la última limpieza" del menú, además de la más
    # reciente (que siempre se puede deshacer, sin contar aquí).
    # Poner a 0 desactiva el historial (solo se podría deshacer la
    # más reciente, como en versiones anteriores).
    #

    UndoHistoryLimit = 10

    #
    # Con cuántos archivos a la vez merece la pena arrancar
    # cálculo de hash en paralelo (PowerShell 7 -Parallel), en vez
    # de calcularlos uno a uno como de siempre. Por debajo de este
    # número, el coste de arrancar los procesos en paralelo no
    # compensa.
    #

    HashParallelThreshold = 20

    #
    # Cuántos archivos se hashean a la vez como máximo cuando sí
    # compensa paralelizar. Súbelo si tienes un disco SSD rápido y
    # varios núcleos libres; bájalo (o pon 1) si notas que el
    # disco duro se satura y todo va más lento en vez de más
    # rápido.
    #

    HashParallelism = 4

}

#--------------------------------------------------------------
# Sistemas soportados
#--------------------------------------------------------------

$Global:SystemPaths = @{

    # Consolas de Sobremesa

    "Nintendo Entertainment System (NES)" = "nes"
    "Nintendo Entertainment System 3D (NES3D)" = "nes3d"
    "SNES" = "snes"
    "Nintendo 64 (N64)" = "n64"
    "Nintendo GameCube" = "gamecube"
    "Nintendo Wii" = "wii"
    "Nintendo Wii U" = "wiiu"
    "Nintendo Switch" = "switch"
    "Sony PlayStation 1 (PS1)" = "psx"
    "Sony PlayStation 2 (PS2)" = "ps2"
    "Sony PlayStation 3 (PS3)" = "ps3"
    "Master System" = "mastersystem"
    "Sega Mega Drive / Genesis" = "megadrive"
    "Sega CD / Mega CD" = "segacd"
    "Sega Saturn" = "saturn"
    "Sega Dreamcast" = "dreamcast"
    "Microsoft Xbox (Clásica)" = "xbox"
    "Microsoft Xbox 360" = "xbox360"
    "Atari 2600" = "atari2600"
    "Atari 7800" = "atari7800"
    "Atari Jaguar" = "atarijaguar"
    "TurboGrafx-16 / PC Engine" = "pcengine"
    "ColecoVision" = "coleco"
    "Mattel Intellivision" = "intellivision"
    "GCE Vectrex" = "vectrex"
    "Panasonic 3DO" = "3do"
    "Philips CD-i" = "cdi"

    # Consolas Portátiles

    "Nintendo Game Boy (GB)" = "gb"
    "Nintendo Game Boy Color (GBC)" = "gbc"
    "Nintendo Game Boy Advance (GBA)" = "gba"
    "Nintendo DS (NDS)" = "nds"
    "Nintendo 3DS" = "n3ds"
    "Sony PlayStation Portable (PSP)" = "psp"
    "Sony PS Vita" = "psvita"
    "Sega Game Gear" = "gamegear"
    "Atari Lynx" = "lynx"
    "SNK Neo Geo Pocket / Color" = "ngpc"
    "Bandai WonderSwan / Color" = "wonderswan"
    "Watara Supervision" = "supervision"

    # Microordenadores

    "Amstrad CPC" = "amstradcpc"
    "Amstrad GX4000" = "gx4000"
    "MSX / MSX2 / MSX2+" = "msx"
    "Sinclair ZX Spectrum" = "zxspectrum"
    "Commodore 64 (C64)" = "c64"
    "Commodore Amiga 500" = "amiga500"
    "Commodore Amiga 1200" = "amiga1200"
    "Atari ST" = "atarist"
    "Apple II" = "apple2"
    "PC DOS" = "dos"
    "Sharp X68000" = "x68000"
    "NEC PC-9801" = "pc98"
    "Thomson MO/TO" = "thomson"

    # Sistemas Arcade

    "Capcom Play System I (CPS1)" = "cps1"
    "Capcom Play System II (CPS2)" = "cps2"
    "Capcom Play System III (CPS3)" = "cps3"
    "SNK Neo-Geo AES / MVS" = "neogeo"
    "MAME (General Arcade)" = "mame"
    "FinalBurn Neo (FBNeo)" = "fbneo"
    "Sammy Atomiswave" = "atomiswave"
    "Sega Naomi / Naomi 2" = "naomi"
    "Sega Model 2" = "model2"
    "Sega Model 3" = "model3"
    "LaserDisc (Daphne / Singe)" = "daphne"
}

#--------------------------------------------------------------
# Extensiones soportadas
#--------------------------------------------------------------

$Global:RomExtensions = @(

    ".2mg",
    ".3ds",
    ".7z",
    ".a26",
    ".a78",
    ".adf",
    ".bin",
    ".cas",
    ".cci",
    ".cdi",
    ".cdt",
    ".chd",
    ".ciso",
    ".col",
    ".cpc",
    ".cpr",
    ".crt",
    ".cso",
    ".cue",
    ".cxi",
    ".d64",
    ".d88",
    ".d98",
    ".dap",
    ".dim",
    ".dms",
    ".do",
    ".dosz",
    ".dsk",
    ".fba",
    ".fd",
    ".fdi",
    ".fds",
    ".fig",
    ".g64",
    ".gb",
    ".gba",
    ".gbc",
    ".gcm",
    ".gcz",
    ".gdi",
    ".gen",
    ".gg",
    ".gz",
    ".hdf",
    ".hdi",
    ".hds",
    ".hdv",
    ".img",
    ".int",
    ".ipf",
    ".iso",
    ".j64",
    ".jag",
    ".k7",
    ".lha",
    ".lnx",
    ".m3u",
    ".m5",
    ".m7",
    ".md",
    ".msa",
    ".mx1",
    ".mx2",
    ".n64",
    ".nca",
    ".nds",
    ".nes",
    ".ngc",
    ".ngp",
    ".nhd",
    ".nib",
    ".nsp",
    ".pbp",
    ".pce",
    ".po",
    ".prg",
    ".rar",
    ".rom",
    ".rpx",
    ".rvz",
    ".sap",
    ".scl",
    ".sfc",
    ".smc",
    ".smd",
    ".sms",
    ".sna",
    ".st",
    ".stx",
    ".sv",
    ".t64",
    ".tap",
    ".thd",
    ".trd",
    ".tzx",
    ".unf",
    ".v64",
    ".vec",
    ".voc",
    ".vpk",
    ".wav",
    ".wbfs",
    ".ws",
    ".wsc",
    ".wua",
    ".wux",
    ".xbe",
    ".xci",
    ".xex",
    ".z64",
    ".z80",
    ".zip"

)

#--------------------------------------------------------------
# Carpetas que nunca deben escanearse
#--------------------------------------------------------------

$Global:IgnoredFolders = @(

    "_duplicates",

    "images",
    "videos",

    "manuals",

    "media",

    "boxart",

    "bezels",

    "overlays",

    "cheats",

    "saves",

    "states",

    "bios"

)

#--------------------------------------------------------------
# Obtener carpeta del sistema
#--------------------------------------------------------------

function Get-SystemFolder {

    param(
        [Parameter(Mandatory)]
        [string]$System
    )

    if(-not $Global:SystemPaths.ContainsKey($System))
    {
        throw "Sistema no soportado: $System"
    }

    return (Join-Path $Global:RetroBatRoot $Global:SystemPaths[$System])

}

#--------------------------------------------------------------
# Resolver el "-System" que se pasa por línea de comandos
#
# Get-SystemFolder exige el nombre largo y descriptivo tal cual
# aparece en el menú interactivo (p.ej. "Super Nintendo (SNES)"),
# que no es cómodo de escribir a mano en una tarea programada.
# Esta función acepta en su lugar el nombre de la CARPETA tal
# cual está en RetroBat\roms (p.ej. "snes"), que es lo que
# cualquiera que configure una tarea programada va a tener a
# mano — y, como red de seguridad, también acepta el nombre largo
# por si acaso. Sin distinguir mayúsculas/minúsculas.
#
# Devuelve la ruta completa si lo reconoce, o $null si no
# corresponde a ningún sistema soportado.
#--------------------------------------------------------------

function Resolve-SystemFolderArgument {

    param(
        [Parameter(Mandatory)]
        [string]$System
    )

    $match = $Global:SystemPaths.GetEnumerator() | Where-Object {
        $_.Value -ieq $System -or $_.Key -ieq $System
    } | Select-Object -First 1

    if($null -eq $match)
    {
        return $null
    }

    return (Join-Path $Global:RetroBatRoot $match.Value)

}

#--------------------------------------------------------------
# Obtener lista de sistemas
#--------------------------------------------------------------

function Get-SupportedSystems {

    return $Global:SystemPaths.Keys | Sort-Object

}

#--------------------------------------------------------------
# Comprobar si la carpeta de un sistema tiene alguna ROM
#
# Se detiene en cuanto encuentra la primera coincidencia (no
# hace falta contar todas), para que revisar los ~60 sistemas
# de golpe al abrir el menú sea rápido.
#--------------------------------------------------------------

function Test-SystemHasRoms {

    param(
        [Parameter(Mandatory)]
        [string]$SystemFolder
    )

    if(!(Test-Path -LiteralPath $SystemFolder))
    {
        return $false
    }

    $found = Get-ChildItem -LiteralPath $SystemFolder -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $Global:RomExtensions -contains $_.Extension.ToLower()
        } |
        Where-Object {
            $parts = $_.DirectoryName.Split('\')

            -not ($parts | Where-Object { $Global:IgnoredFolders -contains $_ })
        } |
        Select-Object -First 1

    return ($null -ne $found)

}

#--------------------------------------------------------------
# Pesos del Decision Engine
#--------------------------------------------------------------

$Global:DecisionWeights = @{

    # Idiomas
    Spanish         = 500
    MultiSpanish    = 400
    Multi           = 250
    English         = 100
    UnknownLanguage = 0

    # Regiones
    ESP             = 300
    EUR             = 200
    USA             = 100
    JPN             = 50
    WORLD           = 25
    UNK             = 0

    # Calidad
    Verified        = 100
    Translation     = 80

    # Revisiones
    Revision        = 20
    Version         = 10

    # Penalizaciones
    Hack            = -300
    Beta            = -200
    Prototype       = -300
    Demo            = -400
    BadDump         = -500
    Pirate          = -500
    Homebrew        = -100
    Sample          = -300
    Preview         = -250
    Kiosk           = -250
}