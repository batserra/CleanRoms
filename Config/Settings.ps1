# ============================================================
#
# Beta CleanROMs v2.5 RC
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
# Configurar la ruta de RetroBat sin tener que editar el código
#--------------------------------------------------------------

function Get-UserSettings {

    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $configFile = Join-Path $Root "Config\UserSettings.json"

    if(Test-Path -LiteralPath $configFile)
    {
        try
        {
            return Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
        }
        catch
        {
            # Archivo de configuración dañado: se ignora
        }
    }

    return [PSCustomObject]@{}

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
        [string]$Root
    )

    $userConfig = Get-UserSettings -Root $Root

    if(-not [string]::IsNullOrWhiteSpace($userConfig.Language))
    {
        $Global:Settings.Language = $userConfig.Language
        return
    }

    #
    # Primer arranque: no hay idioma guardado todavía. Este mensaje
    # se muestra siempre en los dos idiomas a la vez, porque
    # todavía no sabemos cuál prefiere la persona que lo está viendo.
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

    Write-Host ""
    Write-Host (T "lang.saved" "Config\UserSettings.json") -ForegroundColor Green
    Write-Host ""

}

function Initialize-RetroBatRoot {

    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $userConfig = Get-UserSettings -Root $Root

    if((-not [string]::IsNullOrWhiteSpace($userConfig.RetroBatRoot)) -and (Test-Path -LiteralPath $userConfig.RetroBatRoot))
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

    CreateLog        = $true

    AskConfirmation  = $true

    KeepBestRomOnly  = $true

    RemoveDuplicates = $false

}

#--------------------------------------------------------------
# Sistemas soportados
#--------------------------------------------------------------

$Global:SystemPaths = @{

    # Consolas de Sobremesa

    "Nintendo Entertainment System (NES)" = "nes"
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