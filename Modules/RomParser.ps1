# ============================================================
#
# Beta CleanROMs v2.6
#
# RomParser.ps1
#
# Parte 1/4
#
# ============================================================

# ============================================================
# Patrones de regiones
# ============================================================

$Global:RegionPatterns = @{

    ESP = @(
        '\(ESP\)',
        '\[ESP\]',
        '(?<![A-Za-z])ESP(?![A-Za-z])',
        'Spanish',
        'Español',
        '(?<![A-Za-z])Spain(?![A-Za-z])'
    )

    EUR = @(
        '\(E\)',
        '\[E\]',
        '\(EU\)',
        '\(EUR\)',
        '\(UE\)',
        'Europe'
    )

    USA = @(
        '\(U\)',
        '\[U\]',
        '\(USA\)',
        '\[USA\]',
        'USA'
    )

    JPN = @(
        '\(J\)',
        '\[J\]',
        '\(Japan\)',
        '\(JPN\)',
        'Japan'
    )

    WORLD = @(
        '\(World\)',
        '\[World\]',
        'World'
    )

}

# ============================================================
# Patrones de idiomas
# ============================================================

$Global:LanguagePatterns = @{

	Spanish = @(

    'Spanish',

    'Español',

    'Espanol',

    '\(ESP\)',

    '\[ESP\]',

    '(?<![A-Za-z])ESP(?![A-Za-z])'

)

    MultiSpanish = @(

    'En,Fr,De,Es',

    'En,Fr,De,Es,It',

    'En-Fr-De-Es',

    'Multi5',

    'Multi 5',

    'M5',

    '\(M5\)',

    '\[M5\]'

)
English = @(

    'English',

    '\(U\)',

    '\[U\]',

    'USA'

)
}

# ============================================================
# Flags soportados
# ============================================================

# ============================================================
# Patrones de flags
# ============================================================

$Global:FlagPatterns = @{

    Verified   = '\[\!\]'

    #
    # Codigo GoodTools de "bad dump": "[b]" o "[b1]", "[b2]"...
    # (solo digitos tras la "b"). Antes era '\[b.*?\]', que al ser
    # -match insensible a mayusculas tambien encajaba con etiquetas
    # legitimas como "[BIOS]" o "[Bonus]", marcandolas como mal
    # volcadas y penalizandolas -500 puntos sin motivo.
    #

    BadDump    = '\[b[0-9]*\]'

    Hack       = '\[h.*?\]|Hack'

    #
    # Version mas estricta: solo la palabra "Hack" en si (p.ej.
    # "(Hack)", "(SMW1 Hack)"), NO los codigos de dump tipo GoodTools
    # "[h1]"/"[hI]"/"[h1C]" que casi siempre son solo una modificacion
    # tecnica de cabecera y no un hack de juego real. Se usa para
    # decidir si una ROM se EXCLUYE de la agrupacion (Grouper.ps1);
    # el patron "Hack" de arriba se sigue usando para la puntuacion.
    #
    # BUG corregido en la v2.6: antes era '\bHack\b'. El limite de
    # palabra \b de .NET NO considera el guion bajo como separador
    # (es un caracter de "palabra" como una letra), así que un
    # nombre de archivo con guiones bajos en vez de espacios/paréntesis
    # (p.ej. "Street_Fighter_5_Hack_.smc", un estilo de renombrado
    # frecuente en sets de SNES — ver sección 6 del manual) nunca
    # coincidía con \bHack\b, y esa ROM se trataba como si no fuera
    # un hack: nunca se organizaba en "# Hacks y Otros #", y por
    # tanto nunca se comparaba por hash con su copia ya organizada
    # allí, quedando duplicada sin que el programa lo detectara.
    # El patrón nuevo trata cualquier caracter que NO sea una letra
    # (guion bajo incluido) como límite válido.
    #

    NamedHack  = '(?<![A-Za-z])Hack(?![A-Za-z])'

    #
    # Mismo arreglo que en NamedHack: se usan límites basados en
    # "no es una letra" en vez de \b, para que un nombre con
    # guiones bajos (p.ej. "Juego_Translation_ESP_.smc") también
    # se reconozca.
    #

    Translation = '\[T[\+\-].*?\]|T\([A-Za-z]{2,3}\)|Traducci[oó]n|(?<![A-Za-z])Translation(?![A-Za-z])|(?<![A-Za-z])Trans(?![A-Za-z])'

    #
    # BUG corregido en la v2.6: estos ocho patrones no tenían
    # NINGÚN límite de palabra (coincidían con la subcadena en
    # cualquier sitio del nombre). Comprobado con una colección
    # real: "Demo" coincidía dentro de "Demon" (Demon's Crest,
    # Demon Attack, Laplace's Demon...) y "Demolition" (Demolition
    # Man...); "Proto" dentro de "Protoman"/"Protocol"; "Pirate"
    # dentro de "Pirates" en juegos legítimos con piratas en la
    # trama (Pirates of the Caribbean, Pirates of Dark Water...).
    # Estos juegos acababan organizados en "# Hacks y Otros #"
    # sin ser ni hacks, ni demos, ni prototipos, ni copias
    # pirateadas. Mismo arreglo que en NamedHack/Translation: se
    # usan límites basados en "no es una letra" en vez de
    # coincidencia de subcadena libre.
    #

    Beta       = '(?<![A-Za-z])Beta(?![A-Za-z])'

    Prototype  = '(?<![A-Za-z])(Prototype|Prototipo|Proto)(?![A-Za-z])'

    Demo       = '(?<![A-Za-z])Demo(?![A-Za-z])'

    Homebrew   = '(?<![A-Za-z])Homebrew(?![A-Za-z])'

    Pirate     = '(?<![A-Za-z])Pirate(?![A-Za-z])'

    Sample     = '(?<![A-Za-z])Sample(?![A-Za-z])'

    Preview    = '(?<![A-Za-z])Preview(?![A-Za-z])'

    Kiosk      = '(?<![A-Za-z])Kiosk(?![A-Za-z])'

}

# ============================================================
# Crear objeto ROM
# ============================================================

function Get-RomHash {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Algorithm = $Global:Settings.HashAlgorithm
    )

    if([string]::IsNullOrWhiteSpace($Algorithm))
    {
        $Algorithm = "SHA256"
    }

    if(!(Test-Path -LiteralPath $Path))
    {
        return $null
    }

    try
    {
        return (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash
    }
    catch
    {
        # Archivo bloqueado, sin permisos, etc.: no se puede verificar
        return $null
    }

}

function Test-RomsIdenticalContent {

    param(
        [Parameter(Mandatory)]
        [string]$PathA,

        [Parameter(Mandatory)]
        [string]$PathB
    )

    $hashA = Get-RomHash -Path $PathA
    $hashB = Get-RomHash -Path $PathB

    if([string]::IsNullOrWhiteSpace($hashA) -or [string]::IsNullOrWhiteSpace($hashB))
    {
        # No se pudo calcular alguno de los dos: no afirmamos nada
        return $null
    }

    return ($hashA -eq $hashB)

}

# ============================================================
# Calcula el hash de muchos archivos a la vez, en paralelo
# cuando compensa hacerlo.
#
# Se usa en los dos sitios del programa que necesitan hashear
# muchos archivos de golpe (el plan de duplicados normal, y la
# deduplicación de "# Hacks y Otros #" por hash) — con
# colecciones grandes, leer y hashear cientos o miles de ROMs uno
# a uno es lo que más tarda de toda la limpieza.
#
# Devuelve un hashtable RutaCompleta -> hash (o $null si ese
# archivo en concreto no se pudo hashear, igual que haría
# Get-RomHash uno a uno).
#
# El hash se calcula directamente con Get-FileHash en cada hilo
# en paralelo (PowerShell 7 -Parallel), sin depender de cargar
# ninguna función externa dentro del runspace.
#
# Por debajo de $Global:Settings.HashParallelThreshold archivos,
# el coste de arrancar los runspaces no compensa frente a
# calcularlo todo en serie como se ha hecho siempre, así que se
# usa el camino de siempre directamente.
# ============================================================

function Get-RomHashesParallel {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Paths,

        [string]$Algorithm = $Global:Settings.HashAlgorithm
    )

    $result = @{}

    if($null -eq $Paths -or $Paths.Count -eq 0)
    {
        return $result
    }

    if([string]::IsNullOrWhiteSpace($Algorithm))
    {
        $Algorithm = "SHA256"
    }

    #
    # Rutas únicas: si el mismo archivo apareciera más de una vez
    # en la lista (no debería, pero por si acaso), no hace falta
    # hashearlo dos veces.
    #

    $uniquePaths = @($Paths | Select-Object -Unique)

    $threshold = $Global:Settings.HashParallelThreshold

    if($null -eq $threshold -or $threshold -lt 1)
    {
        $threshold = 20
    }

    if($uniquePaths.Count -lt $threshold)
    {
        foreach($path in $uniquePaths)
        {
            $result[$path] = Get-RomHash -Path $path -Algorithm $Algorithm
        }

        return $result
    }

    $throttle = [int]$Global:Settings.HashParallelism

    if($throttle -lt 1)
    {
        $throttle = 4
    }

    #
    # El hash se calcula aquí directamente con Get-FileHash (lo
    # mismo que hace Get-RomHash por dentro), en vez de depender
    # de que cada runspace en paralelo cargue Get-RomHash por su
    # cuenta -- así no hace falta volver a cargar RomParser.ps1
    # dentro de cada hilo (ni con -InitializationScript, cuyo
    # comportamiento con $using: dentro de una scriptblock
    # guardada en variable aparte puede variar según la versión
    # de PowerShell), y el resultado es exactamente el mismo que
    # daría Get-RomHash para el mismo archivo y algoritmo.
    #

    $parallelResults = $uniquePaths | ForEach-Object -Parallel {

        $hashValue = $null

        try
        {
            $hashValue = (Get-FileHash -LiteralPath $_ -Algorithm $using:Algorithm -ErrorAction Stop).Hash
        }
        catch
        {
            $hashValue = $null
        }

        [PSCustomObject]@{
            Path = $_
            Hash = $hashValue
        }

    } -ThrottleLimit $throttle

    foreach($item in $parallelResults)
    {
        $result[$item.Path] = $item.Hash
    }

    return $result

}

function New-RomObject {

    param(

        [string]$Title,

        [string]$NormalizedTitle,

        [string]$FullPath

    )
	

    return [PSCustomObject]@{

        # ------------------------
        # Información básica
        # ------------------------

        Title = $Title

        NormalizedTitle = $NormalizedTitle

        FullPath = $FullPath

        Region = "UNK"

        Language = "Unknown"

        # ------------------------
        # Calidad ROM
        # ------------------------

		Version = $null

		Revision = $null

        Verified = $false

        BadDump = $false

        Hack = $false

        NamedHack = $false

        Translation = $false

        Beta = $false

        Prototype = $false

        Demo = $false

        Homebrew = $false

        Pirate = $false

        Sample = $false

        Preview = $false

        Kiosk = $false

		FileName = [System.IO.Path]::GetFileName($FullPath)

		Extension = [System.IO.Path]::GetExtension($FullPath).ToLower()

        # ------------------------
        # Decision Engine
        # ------------------------

        Score = 0

        Keep = $false

        Decision = ""

        DuplicateGroup = ""

        Reasons = @()

    }

}

# ============================================================
# Obtener región de la ROM
# ============================================================

function Get-RomRegion {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    foreach($region in $Global:RegionPatterns.Keys)
    {
        foreach($pattern in $Global:RegionPatterns[$region])
        {
            if($Title -match $pattern)
            {
                return $region
            }
        }
    }

    return "UNK"

}

# ============================================================
# Obtener idioma de la ROM
# ============================================================

function Get-RomLanguage {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    #
    # Multi con español
    #

    foreach($pattern in $Global:LanguagePatterns.MultiSpanish)
    {
        if($Title -match $pattern)
        {
            return "Multi-Spanish"
        }
    }

    #
    # Español
    #

    foreach($pattern in $Global:LanguagePatterns.Spanish)
    {
        if($Title -match $pattern)
        {
            return "Spanish"
        }
    }

    #
    # Inglés
    #

    foreach($pattern in $Global:LanguagePatterns.English)
    {
        if($Title -match $pattern)
        {
            return "English"
        }
    }

    #
    # Europa normalmente implica multiidioma
    #

    if($Title -match '\(E\)|\[E\]|Europe|EUR')
    {
        return "Multi"
    }

    #
    # Japón
    #

    if($Title -match '\(J\)|\[J\]|Japan|JPN')
    {
        return "Japanese"
    }

    #
    # USA normalmente sólo inglés
    #

    if($Title -match '\(U\)|\[U\]|USA')
    {
        return "English"
    }

    return "Unknown"

}

# ============================================================
# Obtener versión de la ROM, p.ej. "(V1.1)", "[v1.2]" -> "1.1"
#
# Sin esto, $Rom.Version se queda siempre a $null y todo el
# desempate por versión de DecisionEngine.ps1 (Get-VersionScore)
# no hacía nada en la práctica.
# ============================================================

function Get-RomVersion {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    #
    # BUG corregido en la v2.6: antes usaba \bv...\b. Igual que con
    # NamedHack, el guion bajo no es un límite de palabra válido
    # para \b, así que "Game_V1.1_.smc" (estilo de renombrado con
    # guiones bajos, ver sección 6 del manual) nunca detectaba la
    # versión. Se sustituye por límites basados en "no es una letra".
    #

    if($Title -match '(?<![A-Za-z])v\s*([0-9]+(?:\.[0-9]+)?)(?![A-Za-z])')
    {
        return $Matches[1]
    }

    return $null

}

# ============================================================
# Obtener revisión de la ROM, p.ej. "(Rev 1)", "[Rev A]" -> "1" / "A"
#
# Mismo caso que Get-RomVersion: $Rom.Revision nunca se rellenaba,
# así que Get-RevisionScore devolvía siempre 0.
# ============================================================

function Get-RomRevision {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    #
    # (?![a-z]) tras "Rev" evita que "Revenge", "Revolution" o
    # "Review" (palabras reales de título) se confundan con la
    # etiqueta "(Rev X)"/"(Rev.X)"/"(RevX)".
    #

    #
    # BUG corregido en la v2.6: antes usaba \bRev...\b. Mismo caso
    # que NamedHack y Get-RomVersion: el guion bajo no cuenta como
    # límite para \b, así que "Game_Rev2_.smc" nunca detectaba la
    # revisión. Se sustituye por límites basados en "no es una letra".
    #

    if($Title -match '(?<![A-Za-z])Rev(?![a-z])\.?\s*([0-9A-Za-z]{1,3})(?![A-Za-z])')
    {
        return $Matches[1]
    }

    return $null

}

# ============================================================
# Comprobar si existe un patrón
# ============================================================

function Test-RomPattern {

    param(

        [Parameter(Mandatory)]
        [string]$Title,

        [AllowEmptyString()]
        [string]$Pattern

    )

    if([string]::IsNullOrWhiteSpace($Pattern))
    {
        return $false
    }

    return ($Title -match $Pattern)

}

# ============================================================
# Obtener todos los flags de una ROM
# ============================================================

function Get-RomFlags {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    return [PSCustomObject]@{

        Verified   = Test-RomPattern $Title $Global:FlagPatterns.Verified
		
        BadDump    = Test-RomPattern $Title $Global:FlagPatterns.BadDump

        Hack       = Test-RomPattern $Title $Global:FlagPatterns.Hack

        NamedHack  = Test-RomPattern $Title $Global:FlagPatterns.NamedHack

        Translation = Test-RomPattern $Title $Global:FlagPatterns.Translation

        Beta       = Test-RomPattern $Title $Global:FlagPatterns.Beta

        Prototype  = Test-RomPattern $Title $Global:FlagPatterns.Prototype

        Demo       = Test-RomPattern $Title $Global:FlagPatterns.Demo

        Homebrew   = Test-RomPattern $Title $Global:FlagPatterns.Homebrew

        Pirate     = Test-RomPattern $Title $Global:FlagPatterns.Pirate

        Sample     = Test-RomPattern $Title $Global:FlagPatterns.Sample

        Preview    = Test-RomPattern $Title $Global:FlagPatterns.Preview

        Kiosk      = Test-RomPattern $Title $Global:FlagPatterns.Kiosk

    }

}

# ============================================================
# NOTA: aquí existían una función Normalize-RomTitle y un
# envoltorio Get-CleanTitle que hacían su propia normalización de
# título, en paralelo a la de Modules\TitleNormalizer.ps1. En la
# práctica, Cleaner.ps1 siempre llama a Update-NormalizedTitles
# (TitleNormalizer.ps1) justo después de escanear, así que ese
# resultado se sobreescribía siempre antes de llegar a usarse
# para nada — pura duplicación de lógica con riesgo de que las dos
# copias divergieran con el tiempo. Se quitaron en la limpieza de
# código muerto de la v2.6; Parse-Rom ahora deja NormalizedTitle
# con el nombre de archivo tal cual (ver más abajo), a la espera
# de que Update-NormalizedTitles lo normalice de verdad.
# ============================================================

# ============================================================
# Leer nombres de archivos dentro de un ZIP (sin descomprimir)
# ============================================================

function Get-ZipEntryNames {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try
    {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

        $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)

        $names = @(
            $zip.Entries |
                Where-Object { -not [string]::IsNullOrEmpty($_.Name) } |
                ForEach-Object { $_.Name }
        )

        $zip.Dispose()

        return $names
    }
    catch
    {
        #
        # ZIP dañado, protegido, o no se pudo leer: seguimos
        # tratándolo como un archivo normal (comportamiento anterior)
        #

        return @()
    }
}

# ============================================================
# Leer nombres de archivos dentro de un 7Z (sin descomprimir)
#
# Requiere 7z.exe en el PATH. Si no está disponible, el .7z
# se sigue tratando como un archivo único (comportamiento anterior).
# ============================================================

$Global:SevenZipPath = $null
$Global:SevenZipChecked = $false

function Initialize-SevenZipSupport {

    if($Global:SevenZipChecked)
    {
        return
    }

    $candidates = @()

    #
    # 1) PATH
    #

    $cmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue

    if($null -ne $cmd)
    {
        $candidates += $cmd.Source
    }

    #
    # 2) Rutas de instalación típicas (el instalador oficial de
    #    7-Zip no se añade al PATH por defecto)
    #

    if($env:ProgramFiles)
    {
        $candidates += (Join-Path $env:ProgramFiles "7-Zip\7z.exe")
    }

    if(${env:ProgramFiles(x86)})
    {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} "7-Zip\7z.exe")
    }

    #
    # 3) Registro de Windows (el instalador de 7-Zip guarda ahí
    #    la ruta real de instalación)
    #

    foreach($key in @("HKLM:\SOFTWARE\7-Zip", "HKLM:\SOFTWARE\WOW6432Node\7-Zip"))
    {
        try
        {
            $installPath = (Get-ItemProperty -Path $key -Name "Path" -ErrorAction Stop).Path

            if(-not [string]::IsNullOrWhiteSpace($installPath))
            {
                $candidates += (Join-Path $installPath "7z.exe")
            }
        }
        catch
        {
            # Esa clave de registro no existe, se ignora
        }
    }

    $found = $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } | Select-Object -First 1

    if($null -ne $found)
    {
        $Global:SevenZipPath = $found
        Write-Host (T "sevenzip.detected" $found) -ForegroundColor DarkGray
    }
    else
    {
        $Global:SevenZipPath = $null
        Write-Host (T "sevenzip.notDetected") -ForegroundColor DarkYellow
    }

    $Global:SevenZipChecked = $true
}

function Get-SevenZipEntryNames {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if([string]::IsNullOrWhiteSpace($Global:SevenZipPath))
    {
        return @()
    }

    try
    {
        $output = & $Global:SevenZipPath "l" "-slt" $Path 2>$null

        $names = @(
            $output |
                Where-Object { $_ -match '^Path = (.+)$' } |
                ForEach-Object { $Matches[1] } |
                Select-Object -Skip 1
        )

        return $names
    }
    catch
    {
        return @()
    }
}

# ============================================================
# Obtener el "texto de detección" de una ROM
#
# Para ZIP/7Z que contienen una única ROM real dentro, se añade
# el nombre interno al texto usado para detectar región, idioma
# y flags (la agrupación de duplicados sigue usando solo el
# nombre del archivo exterior, para no romper comparaciones con
# copias sueltas sin comprimir).
#
# Si el archivo contiene varios ficheros (sets de MAME/FBNeo/
# Neo Geo), se deja tal cual: el propio ZIP/7Z se trata como
# la ROM, igual que antes.
# ============================================================

function Get-RomDetectionText {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter(Mandatory)]
        [string]$Extension
    )

    if($Extension -ne ".zip" -and $Extension -ne ".7z")
    {
        return $FileName
    }

    if($Extension -eq ".zip")
    {
        $entryNames = @(Get-ZipEntryNames $Path)
    }
    else
    {
        $entryNames = @(Get-SevenZipEntryNames $Path)
    }

    if($entryNames.Count -eq 0)
    {
        return $FileName
    }

    $realRomExtensions = @(
        $Global:RomExtensions | Where-Object { $_ -ne ".zip" -and $_ -ne ".7z" }
    )

    $romEntries = @(
        $entryNames | Where-Object {
            $realRomExtensions -contains [System.IO.Path]::GetExtension($_).ToLower()
        }
    )

    #
    # Solo una ROM real dentro -> no es un set de arcade,
    # añadimos su nombre interno a la detección
    #

    if($romEntries.Count -eq 1)
    {
        $innerName = [System.IO.Path]::GetFileNameWithoutExtension($romEntries[0])

        return "$FileName $innerName"
    }

    return $FileName

}

# ============================================================
# Parsear una ROM
# ============================================================

function Parse-Rom {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    #
    # Comprobaciones
    #

    if([string]::IsNullOrWhiteSpace($Path))
    {
        return $null
    }

    if(!(Test-Path -LiteralPath $Path))
    {
        return $null
    }

    #
    # Nombre del archivo
    #

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    $extension = [System.IO.Path]::GetExtension($Path).ToLower()

    #
    # Texto de detección (incluye el contenido del ZIP/7Z si aplica)
    #

    $detectionText = Get-RomDetectionText `
        -Path $Path `
        -FileName $fileName `
        -Extension $extension

    #
    # Título normalizado (agrupación de duplicados)
    #
    # Se deja aquí como el nombre de archivo sin más: la
    # normalización real la hace Update-NormalizedTitles
    # (TitleNormalizer.ps1), que Cleaner.ps1 llama justo después
    # de escanear y que SIEMPRE sobreescribe este valor antes de
    # que se use para agrupar nada. Ver la nota al principio de
    # este archivo.
    #

    $normalizedTitle = $fileName

    #
    # Crear objeto ROM
    #

    $rom = New-RomObject `
        -Title $fileName `
        -NormalizedTitle $normalizedTitle `
        -FullPath $Path

    #
    # Región
    #

    $rom.Region = Get-RomRegion $detectionText

    #
    # Idioma
    #

    $rom.Language = Get-RomLanguage $detectionText

    #
    # Versión / Revisión
    #

    $rom.Version  = Get-RomVersion $detectionText
    $rom.Revision = Get-RomRevision $detectionText

    #
    # Flags
    #

    $flags = Get-RomFlags $detectionText

    $rom.Verified  = $flags.Verified
    $rom.BadDump   = $flags.BadDump
    $rom.Hack      = $flags.Hack
    $rom.NamedHack = $flags.NamedHack
    $rom.Translation = $flags.Translation
    $rom.Beta      = $flags.Beta
    $rom.Prototype = $flags.Prototype
    $rom.Demo      = $flags.Demo
    $rom.Homebrew  = $flags.Homebrew
    $rom.Pirate    = $flags.Pirate
    $rom.Sample    = $flags.Sample
    $rom.Preview   = $flags.Preview
    $rom.Kiosk     = $flags.Kiosk

    #
    # También se considera Hack/Traducción si está dentro de una
    # carpeta cuyo nombre contenga "Hack" o "Traduc"/"Translation"
    # (p.ej. "# Hacks y Otros #", "Traducciones"), aunque el propio nombre
    # del archivo no lo indique
    #

    $folderPath = [System.IO.Path]::GetDirectoryName($Path)

    if($folderPath -match "Hack")
    {
        $rom.Hack = $true
        $rom.NamedHack = $true
    }

    if($folderPath -match "Traduc|Translation")
    {
        $rom.Translation = $true
    }

    #
    # Inicialización de propiedades internas
    #

    $rom.Score = 0
    $rom.Keep = $false
    $rom.Decision = ""
    $rom.DuplicateGroup = ""
    $rom.Reasons = @()

    return $rom

}

