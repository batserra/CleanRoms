# ============================================================
#
# Beta CleanROMs v2.6
#
# TitleNormalizer.ps1
#
# ============================================================

function Get-CoreNormalizedTitle {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    $t = $Title.ToLower()

    #----------------------------------------------------------
    # Quitar acentos
    #----------------------------------------------------------

    $t = $t.Replace("á","a")
    $t = $t.Replace("é","e")
    $t = $t.Replace("í","i")
    $t = $t.Replace("ó","o")
    $t = $t.Replace("ú","u")
    $t = $t.Replace("ü","u")
    $t = $t.Replace("ñ","n")

    #----------------------------------------------------------
    # Quitar número de catálogo al principio del nombre, p.ej.
    # "0263 - Advance Wars (E)(Arrogance).gba" -> algunos sets
    # de ROMs numeran cada archivo con un ID de 3-4 dígitos al
    # principio, seguido de " - ". Eso no es parte del título.
    #----------------------------------------------------------

    #
    # Fragmento residual de dominio pegado antes de la extensión
    # real, p.ej. "Jackie Chan's Action Kung Fu (U).net.nes"
    # (el archivo se descargó/renombró mal en algún momento y
    # quedó ".net" en medio del nombre y la extensión real)
    #

    $t = $t -replace "\.(net|com|org|info)$",""

    $t = $t -replace "^\d{3,4}\s*-\s*",""

    #----------------------------------------------------------
    # Quitar sufijo de fecha/hora al final del nombre, p.ej.
    # "...Circle of the Moon_20260709_034928" (lo añaden algunas
    # herramientas de copia/backup al renombrar duplicados)
    #----------------------------------------------------------

    $t = $t -replace "_\d{8}_\d{6}$",""

    #----------------------------------------------------------
    # Nombres con guion bajo en vez de espacios/paréntesis
    #
    # Algunos sets de ROMs (sobre todo SNES) usan un convenio
    # donde TODO, incluidos espacios, apóstrofes y paréntesis,
    # se sustituye por "_". Por ejemplo:
    #
    #   "Kirby_s_Fun_Pak_E_.smc"  =  "Kirby's Fun Pak (E).smc"
    #   "Super_Metroid_E_.smc"    =  "Super Metroid (E).smc"
    #
    # Sin este tratamiento, esas etiquetas (región, versión,
    # hack, crédito de traducción) se quedan pegadas al título
    # como palabras sueltas y rompen la agrupación.
    #----------------------------------------------------------

    #
    # Apóstrofe codificado como "_s_" -> se junta con la palabra
    # anterior en vez de quedar como palabra suelta "s"
    #

    $t = $t -replace "_s_","s "
    $t = $t -replace "_s$","s"

    #
    # Cadena de etiquetas finales unidas por "_": región, versión,
    # revisión de hack, crédito de traducción... Se van quitando
    # de derecha a izquierda mientras se reconozcan como metadato,
    # igual que se hace con "(...)"/"[...]"
    #

    for($i = 0; $i -lt 8; $i++)
    {
        $before = $t
        $t = $t -replace "_[uejw]_?$",""
        $t = $t -replace "_v\d+(_\d+)*_?$",""
        $t = $t -replace "_h\d+_?$",""
        $t = $t -replace "_hack_?$",""
        $t = $t -replace "_known_?$",""
        $t = $t -replace "_ng-dump_?$",""
        $t = $t -replace "_t_([a-z0-9]+_)+$",""
        $t = $t -replace "_!+$",""

        if($t -eq $before)
        {
            break
        }
    }

    #
    # Convertir los guiones bajos restantes a espacios YA, antes de
    # las limpiezas de palabras sueltas (the/a/an/el/la/and/y...).
    # El guion bajo cuenta como carácter de palabra en las
    # expresiones regulares, así que "\band\b" nunca encuentra el
    # límite correcto en "..._and_..." y esa palabra se queda sin
    # quitar. Convirtiendo ya a espacio, esas reglas funcionan igual
    # de bien en nombres con guion bajo que en nombres normales.
    #

    $t = $t -replace "_"," "

    #----------------------------------------------------------
    # Eliminar TODO el contenido entre paréntesis o corchetes.
    #
    # En el 99% de los sets de ROMs (No-Intro, TOSEC, GoodTools...)
    # todo lo que va entre () o [] después del título es metadato:
    # región, año, publisher/grupo de dump, idioma, revisión, flags
    # de calidad, etc. Antes solo se quitaban palabras conocidas de
    # una lista fija (usa, europe, japan...), así que cosas como
    # "(1986)", "(US Gold)", "(Elite Systems)" o "(UK)" NO se
    # reconocían y se quedaban como texto, rompiendo la agrupación
    # de copias que en realidad son el mismo juego.
    #
    # Se repite varias veces por si hay grupos consecutivos, p.ej.
    # "(1986)(US Gold)".
    #----------------------------------------------------------

    for($i = 0; $i -lt 5; $i++)
    {
        $before = $t
        $t = $t -replace "\([^\(\)]*\)"," "
        $t = $t -replace "\[[^\[\]]*\]"," "

        if($t -eq $before)
        {
            break
        }
    }

    #----------------------------------------------------------
    # Palabras sueltas que a veces aparecen SIN paréntesis/corchetes
    # (poco frecuente, pero se dejan como red de seguridad)
    #----------------------------------------------------------

    $words = @(

        "spanish",
        "español",
        "espanol",
        "english",
        "french",
        "german",
        "italian",
        "portuguese",
        "dutch",

        "multi",
        "multi5",
        "m5",
        "m4",

        "usa",
        "europe",
        "eur",
        "japan",
        "jpn",
        "world"

    )

    foreach($w in $words)
    {
        $t = $t -replace "\b$w\b"," "
    }

    #----------------------------------------------------------
    # Revisiones (por si aparecen fuera de paréntesis)
    #----------------------------------------------------------

    $t = $t -replace "\brev\s+[a-z0-9]{1,3}\b"," "
    $t = $t -replace "\bv[0-9]+\.[0-9]+\b"," "

    #----------------------------------------------------------
    # Números romanos
    #----------------------------------------------------------

    $t = $t -replace "\bviii\b","8"
    $t = $t -replace "\bvii\b","7"
    $t = $t -replace "\bvi\b","6"
    $t = $t -replace "\bv\b","5"
    $t = $t -replace "\biv\b","4"
    $t = $t -replace "\biii\b","3"
    $t = $t -replace "\bii\b","2"

    #----------------------------------------------------------
    # Casos especiales
    #----------------------------------------------------------

    $t = $t -replace "pokémon","pokemon"
    $t = $t -replace "mega-man","mega man"

    #----------------------------------------------------------
    # Eliminar artículos
    #----------------------------------------------------------

    $t = $t -replace "\bthe\b"," "
    $t = $t -replace "\ban\b"," "
    $t = $t -replace "\ba\b"," "

    #
    # Artículos en español (para que títulos traducidos como
    # "Los Sims 2" / "Sims 2, The" o "Golden Sun - La Edad
    # Perdida" / "...la edad perdida" se agrupen igual)
    #

    $t = $t -replace "\bel\b"," "
    $t = $t -replace "\bla\b"," "
    $t = $t -replace "\blos\b"," "
    $t = $t -replace "\blas\b"," "

    #----------------------------------------------------------
    # Apóstrofes y puntos: "Hoodlum's" vs "Hoodlums", "Jr." vs
    # "Jr" son la misma palabra a efectos de agrupar duplicados
    #----------------------------------------------------------

    $t = $t.Replace("'","").Replace("´","").Replace("'","")
    $t = $t.Replace(".","")
    $t = $t.Replace("!","").Replace("¡","")
    $t = $t.Replace("?","").Replace("¿","")

    #
    # "&" equivale a "and"/"y" (p.ej. "Tom & Jerry" vs "Tom and
    # Jerry", o "Rayman Advance & Rayman 3" vs "...+ Rayman 3").
    # Se convierte a "and" y luego se quita junto con "y", así
    # da igual qué forma use el archivo.
    #

    $t = $t.Replace("&"," and ")
    $t = $t -replace "\band\b"," "
    $t = $t -replace "\by\b"," "
    $t = $t.Replace("+"," ")

    #----------------------------------------------------------
    # Símbolos
    #----------------------------------------------------------

    $t = $t -replace "[-_:,]"," "
    $t = $t -replace "[\(\)\[\]\{\}]"," "

    #----------------------------------------------------------
    # Espacios
    #----------------------------------------------------------

    $t = $t -replace "\s+"," "
    $t = $t.Trim()

    return $t

}

function Normalize-Title {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    #----------------------------------------------------------
    # Alias de título (Config\TitleAliases.json)
    #
    # Para los casos que ya no son solo una etiqueta de región/
    # idioma/año sino un nombre distinto para el mismo juego
    # (traducciones, abreviaturas oficiales, títulos truncados):
    # "Los Sims 2" / "Sims 2, The", "Golden Sun 2" / "Golden Sun
    # - La Edad Perdida", "Zelda - The Minish Cap" / "Legend of
    # Zelda, The - The Minish Cap", etc. Estos no se pueden
    # resolver con una regla general sin arriesgar falsos
    # positivos, así que se mantienen en una lista editable.
    #----------------------------------------------------------

    $t = Get-CoreNormalizedTitle -Title $Title

    $aliases = Get-TitleAliasMap

    if($aliases.ContainsKey($t))
    {
        return $aliases[$t]
    }

    return $t

}

# ============================================================
# Alias de títulos: mapea variantes conocidas (nombre distinto
# para el mismo juego) a un nombre canónico, para que se agrupen
# como duplicados aunque la normalización estándar no pueda
# deducirlo solo con reglas.
#
# Se guardan en Config\TitleAliases.json como:
#   { "nombre normalizado variante": "nombre normalizado canónico" }
#
# Puedes añadir más entradas a mano según vayas encontrando casos.
# ============================================================

$Global:TitleAliasMap = $null

function Get-TitleAliasMap {

    if($null -ne $Global:TitleAliasMap)
    {
        return $Global:TitleAliasMap
    }

    $Global:TitleAliasMap = @{}

    $aliasFile = Join-Path (Split-Path $PSScriptRoot -Parent) "Config\TitleAliases.json"

    if(Test-Path -LiteralPath $aliasFile)
    {
        try
        {
            $raw = Get-Content -LiteralPath $aliasFile -Raw

            if(-not [string]::IsNullOrWhiteSpace($raw))
            {
                $json = $raw | ConvertFrom-Json

                foreach($prop in $json.PSObject.Properties)
                {
                    $Global:TitleAliasMap[$prop.Name] = $prop.Value
                }
            }
        }
        catch
        {
            Write-Host (T "alias.loadFailed") -ForegroundColor DarkYellow
        }
    }

    return $Global:TitleAliasMap

}

# ============================================================
# Actualizar todos los títulos
# ============================================================

function Update-NormalizedTitles {

    param(
        [array]$Roms
    )

    foreach($rom in $Roms)
    {
        $rom.NormalizedTitle = Normalize-Title $rom.Title
    }

    return $Roms

}