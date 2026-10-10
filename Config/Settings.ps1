# ============================================================
#
# CleanROMs
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
# Version del programa
#
# Se lee del archivo VERSION (junto a main.ps1): es el UNICO sitio
# donde hay que cambiarla al publicar una version nueva. Aparece en
# el banner del menu, en el log y en los planes; el flujo de
# publicacion (.github\workflows\release.yml) comprueba que la
# etiqueta de GitHub coincida con este numero.
#--------------------------------------------------------------

$Global:AppVersion = "dev"

try
{
    $versionFile = Join-Path (Split-Path $PSScriptRoot -Parent) "VERSION"

    if(Test-Path -LiteralPath $versionFile)
    {
        $versionText = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()

        if($versionText -ne "")
        {
            $Global:AppVersion = $versionText
        }
    }
}
catch
{
    # sin VERSION se queda en "dev"
}

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
        RomPriorityLanguage = $null
    }

    if(Test-Path -LiteralPath $configFile)
    {
        try
        {
            $loaded = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json

            foreach($propName in @("Language", "RetroBatRoot", "RomPriorityLanguage"))
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

#--------------------------------------------------------------
# Elegir que tabla de Config\DecisionWeights.ps1 esta activa
#--------------------------------------------------------------

function Set-ActiveDecisionWeights {

    param(
        [Parameter(Mandatory)]
        [string]$Priority
    )

    if($Priority -eq "en")
    {
        $Global:DecisionWeights = $Global:DecisionWeights_EN
    }
    else
    {
        $Global:DecisionWeights = $Global:DecisionWeights_ES
    }

}

#--------------------------------------------------------------
# Primer arranque: elegir prioridad de ROMs (español/inglés)
#
# No es lo mismo que Initialize-Language: eso elige el idioma de
# los menús y mensajes; esto elige qué tabla de puntuación de
# región/idioma se usa para decidir qué copia se conserva cuando
# compiten dos ROMs (ver Config\DecisionWeights.ps1). Se pregunta
# por separado porque alguien podría querer los menús en inglés
# pero seguir prefiriendo quedarse con las ROMs en español, o
# viceversa.
#--------------------------------------------------------------

function Initialize-RomPriorityLanguage {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [switch]$Force
    )

    $userConfig = Get-UserSettings -Root $Root

    if((-not $Force) -and (-not [string]::IsNullOrWhiteSpace($userConfig.RomPriorityLanguage)))
    {
        $Global:Settings.RomPriorityLanguage = $userConfig.RomPriorityLanguage
        Set-ActiveDecisionWeights -Priority $Global:Settings.RomPriorityLanguage
        return
    }

    #
    # Primer arranque (o reconfiguración forzada desde el menú):
    # no hay prioridad guardada todavía.
    #

    if($Global:AutoConfirm)
    {
        #
        # Modo no interactivo (-Yes): se usa español por defecto,
        # sin preguntar, igual que Initialize-Language.
        #

        $Global:Settings.RomPriorityLanguage = "es"

        $userConfig | Add-Member -NotePropertyName "RomPriorityLanguage" -NotePropertyValue "es" -Force
        Save-UserSettings -Root $Root -Settings $userConfig

        Set-ActiveDecisionWeights -Priority "es"

        return
    }

    #
    # A diferencia del selector de idioma de interfaz, aquí ya
    # sabemos qué idioma prefiere (Initialize-Language se llama
    # antes que esta función), así que el mensaje se muestra ya
    # traducido con T, no en los dos idiomas a la vez.
    #

    Write-Host ""
    Write-Host (T "priority.askTitle") -ForegroundColor Cyan
    Write-Host (T "priority.opt1")
    Write-Host (T "priority.opt2")
    Write-Host ""

    do
    {
        $typed = Read-Host (T "priority.prompt")
    }
    until($typed -match '^[12]$')

    $Global:Settings.RomPriorityLanguage = if($typed -eq "2") { "en" } else { "es" }

    $userConfig | Add-Member -NotePropertyName "RomPriorityLanguage" -NotePropertyValue $Global:Settings.RomPriorityLanguage -Force
    Save-UserSettings -Root $Root -Settings $userConfig

    Set-ActiveDecisionWeights -Priority $Global:Settings.RomPriorityLanguage

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

    #
    # Idioma de la INTERFAZ (menús, mensajes en pantalla). No
    # confundir con RomPriorityLanguage de abajo, que es un ajuste
    # totalmente distinto.
    #

    Language         = "es"

    #
    # Idioma de PRIORIDAD DE ROMS: cuál de las dos tablas de
    # Config\DecisionWeights.ps1 se usa para puntuar región e
    # idioma ($Global:DecisionWeights_ES o _EN). No afecta a los
    # menús ni a los mensajes — solo a qué copia gana cuando dos
    # ROMs compiten por región/idioma. Ver Set-ActiveDecisionWeights
    # más abajo, e Initialize-RomPriorityLanguage.
    #

    RomPriorityLanguage = "es"

    PreviewOnly      = $false

    MoveAssets       = $true

    #
    # Al mover una ROM duplicada, pasa sus datos de usuario del
    # gamelist.xml de RetroBat (favorito, veces jugada, ultima
    # partida, nota; y descripcion/genero/etc. si faltan) a la
    # entrada de la ROM que se conserva. No borra ninguna entrada y
    # guarda antes una copia en Resultado\GamelistBackups\. Ver
    # Modules\GamelistManager.ps1. Poner a $false para desactivarlo.
    #

    MergeGamelistMetadata = $true

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

    #
    # Cache de hashes (Resultado\HashCache.tsv). Guarda el hash de
    # cada archivo junto con su tamano y fecha de modificacion y lo
    # reutiliza mientras no cambien, asi las siguientes limpiezas no
    # vuelven a leer y hashear los mismos archivos. Ver
    # Modules\HashCache.ps1. Poner a $false para desactivarla (o
    # borrar Resultado\HashCache.tsv para empezar de cero).
    #

    HashCache = $true

    #
    # Purga de _duplicates (opcion 6 del menu, o -Action Purge): cuantos
    # dias deben llevar las copias en _duplicates, desde que se
    # movieron, para que la purga las borre. Es lo unico que el
    # programa borra de verdad; antes de borrar siempre ensena la
    # lista y pide confirmacion (con -Yes, no). Puedes indicar otro
    # valor en cada ejecucion con la opcion de menu o -OlderThanDays.
    #

    PurgeDuplicatesAfterDays = 90

}

#--------------------------------------------------------------
# Sistemas, extensiones y carpetas ignoradas: Config\*.json
#
# Estos datos antes eran listas dentro de este mismo archivo, mezcladas
# con codigo. Ahora viven en archivos JSON que se pueden editar sin
# miedo a romper el programa:
#
#   Config\Systems.json      sistemas soportados: "Nombre": "carpeta",
#                            agrupados por categorias (o sueltos)
#   Config\Extensions.json   "RomExtensions" (extensiones que se
#                            consideran ROMs) y "IgnoredFolders"
#                            (carpetas que nunca se escanean)
#
# Opcionalmente, para anadir cosas tuyas SIN tocar los archivos
# anteriores (asi una actualizacion del programa no te las pisa):
#
#   Config\Systems.custom.json      mismo formato que Systems.json; se
#                                   suma, y si repite un nombre manda
#   Config\Extensions.custom.json   mismo formato que Extensions.json;
#                                   sus listas se SUMAN a las de arriba
#
# Si un archivo no se puede leer, el programa se detiene con un
# mensaje claro que indica el archivo y el error. Una entrada concreta
# no valida se avisa y se ignora, sin tumbar el resto.
#--------------------------------------------------------------

function Read-ConfigJson {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Optional
    )

    if(!(Test-Path -LiteralPath $Path))
    {
        if($Optional)
        {
            return $null
        }

        throw "Falta el archivo de configuracion / Missing configuration file: $Path"
    }

    try
    {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

        if([string]::IsNullOrWhiteSpace($raw))
        {
            return $null
        }

        return ($raw | ConvertFrom-Json)
    }
    catch
    {
        throw "No se pudo leer $Path (JSON no valido) / Could not read $Path (invalid JSON): $($_.Exception.Message)"
    }
}

# Mezcla en $Target (hashtable nombre -> carpeta) los sistemas de un
# JSON, tanto si estan agrupados por categorias como sueltos.
function Add-SystemsFromJson {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        $Target,

        [Parameter(Mandatory)]
        $Json,

        [Parameter(Mandatory)]
        [string]$FileName
    )

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()

    $pairs = @()

    foreach($property in $Json.PSObject.Properties)
    {
        if($property.Value -is [string])
        {
            $pairs += ,@($property.Name, $property.Value)
        }
        elseif($null -ne $property.Value -and $property.Value.PSObject.Properties)
        {
            foreach($inner in $property.Value.PSObject.Properties)
            {
                $pairs += ,@($inner.Name, $inner.Value)
            }
        }
    }

    foreach($pair in $pairs)
    {
        $name = [string]$pair[0]
        $folder = $pair[1]

        if([string]::IsNullOrWhiteSpace($name) -or $folder -isnot [string] -or
           [string]::IsNullOrWhiteSpace($folder) -or $folder.IndexOfAny($invalidChars) -ge 0)
        {
            Write-Warning "$FileName`: sistema no valido, se ignora / invalid system, ignored: '$name'"
            continue
        }

        $Target[$name] = $folder.Trim()
    }
}

# Anade a $Target (lista) los textos validos de un array de un JSON.
function Add-StringsFromJson {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Target,

        $Values,

        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter(Mandatory)]
        [string]$ListName,

        [switch]$IsExtension
    )

    foreach($value in @($Values))
    {
        if($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value))
        {
            Write-Warning "$FileName`: valor no valido en $ListName, se ignora / invalid value in $ListName, ignored"
            continue
        }

        $text = $value.Trim()

        if($IsExtension)
        {
            $text = $text.ToLowerInvariant()

            if(-not $text.StartsWith("."))
            {
                $text = "." + $text
            }
        }

        if(-not $Target.Contains($text))
        {
            $Target.Add($text)
        }
    }
}

function Import-DataConfig {

    param(
        # Carpeta de los JSON (los tests usan una temporal)
        [string]$ConfigFolder = $PSScriptRoot
    )

    $configFolder = $ConfigFolder

    # --- Sistemas

    $systems = @{}

    $systemsJson = Read-ConfigJson -Path (Join-Path $configFolder "Systems.json")

    if($null -ne $systemsJson)
    {
        Add-SystemsFromJson -Target $systems -Json $systemsJson -FileName "Systems.json"
    }

    $customSystems = Read-ConfigJson -Path (Join-Path $configFolder "Systems.custom.json") -Optional

    if($null -ne $customSystems)
    {
        Add-SystemsFromJson -Target $systems -Json $customSystems -FileName "Systems.custom.json"
    }

    if($systems.Count -eq 0)
    {
        throw "Config\Systems.json no define ningun sistema / defines no systems"
    }

    # --- Extensiones y carpetas ignoradas

    $extensions = New-Object 'System.Collections.Generic.List[string]'
    $ignored = New-Object 'System.Collections.Generic.List[string]'

    $extensionsJson = Read-ConfigJson -Path (Join-Path $configFolder "Extensions.json")

    if($null -ne $extensionsJson)
    {
        # (con PSObject.Properties: una clave que falte no debe dar error aunque haya Set-StrictMode)
        if($extensionsJson.PSObject.Properties["RomExtensions"])
        {
            Add-StringsFromJson -Target $extensions -Values $extensionsJson.RomExtensions -FileName "Extensions.json" -ListName "RomExtensions" -IsExtension
        }

        if($extensionsJson.PSObject.Properties["IgnoredFolders"])
        {
            Add-StringsFromJson -Target $ignored -Values $extensionsJson.IgnoredFolders -FileName "Extensions.json" -ListName "IgnoredFolders"
        }
    }

    $customExtensions = Read-ConfigJson -Path (Join-Path $configFolder "Extensions.custom.json") -Optional

    if($null -ne $customExtensions)
    {
        if($customExtensions.PSObject.Properties["RomExtensions"])
        {
            Add-StringsFromJson -Target $extensions -Values $customExtensions.RomExtensions -FileName "Extensions.custom.json" -ListName "RomExtensions" -IsExtension
        }

        if($customExtensions.PSObject.Properties["IgnoredFolders"])
        {
            Add-StringsFromJson -Target $ignored -Values $customExtensions.IgnoredFolders -FileName "Extensions.custom.json" -ListName "IgnoredFolders"
        }
    }

    if($extensions.Count -eq 0)
    {
        throw "Config\Extensions.json no define ninguna extension / defines no extensions"
    }

    $Global:SystemPaths = $systems
    $Global:RomExtensions = @($extensions)
    $Global:IgnoredFolders = @($ignored)
}

Import-DataConfig

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