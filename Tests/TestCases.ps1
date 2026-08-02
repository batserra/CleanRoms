# ============================================================
# Beta CleanROMs v2.5
#
# TestCases.ps1
#
# Casos de prueba conocidos, la mayoría sacados directamente de
# bugs reales encontrados y corregidos durante las pruebas sobre
# colecciones reales (ver el manual, sección 21 "Pruebas
# realizadas"). Sirven para comprobar en segundos que un cambio
# en TitleNormalizer.ps1, RomParser.ps1, MediaCleaner.ps1 o
# Config\TitleAliases.json no rompe algo que ya funcionaba.
#
# Cómo añadir un caso nuevo: copia el bloque más parecido a lo
# que quieres probar y cambia los datos. No hace falta tocar
# Test-Normalization.ps1 para nada.
#
# Tipos de caso:
#
#   Match        - Todos los "Files" deben normalizar (con alias)
#                  al MISMO título. Para duplicados reales.
#
#   Distinct     - Todos los "Files" deben normalizar a títulos
#                  DISTINTOS entre sí. Para evitar que una regla
#                  demasiado agresiva fusione juegos que no
#                  tienen nada que ver (como pasó con "rev").
#
#   Flag         - Un solo "File" + "ExpectedFlags" (hashtable
#                  con Hack/Translation/Beta/Prototype/Demo/
#                  Homebrew/Pirate/Sample/Preview/Kiosk = $true
#                  o $false). Comprueba Get-RomFlags.
#
#   MediaSuffix  - Un solo "File" (nombre de imagen/vídeo/manual)
#                  + "ExpectedBase" (nombre de la ROM sin sufijo).
#                  Comprueba Get-MediaRomBaseName.
#
#   Region       - Un solo "File" + "ExpectedRegion" (ESP/EUR/USA/
#                  JPN/WORLD/UNK). Comprueba Get-RomRegion.
#
#   Contains     - Un solo "File" + "ExpectedSubstring" que debe
#                  seguir presente en el título normalizado (para
#                  detectar cuando una regla se come contenido
#                  real del título, como pasó con "Revolver").
#
# ============================================================

$Global:TestCases = @(

    # -------------------------------------------------------
    # MATCH: metadatos (año, publisher, región, idioma...)
    # -------------------------------------------------------

    @{
        Name = "Amstrad: año y publisher entre parentesis"
        Type = "Match"
        Files = @(
            "10th Frame (1986)(US Gold)[t].dsk",
            "10th Frame (Europe).dsk"
        )
    },

    @{
        Name = "Amstrad: año, publisher y region distintos"
        Type = "Match"
        Files = @(
            "1942 (1986)(Elite Systems)[t].dsk",
            "1942 (Europe).dsk",
            "1942 (UK) (1986).dsk"
        )
    },

    @{
        Name = "GBA: region/idioma con distintas etiquetas"
        Type = "Match"
        Files = @(
            "Advance Wars (Europe) (En,Fr,De,Es).gba",
            "Advance Wars (U) (V1.1) [!].gba",
            "Advance Wars [E].gba"
        )
    },

    # -------------------------------------------------------
    # MATCH: convencion de guion bajo (SNES)
    # -------------------------------------------------------

    @{
        Name = "Guion bajo: region como '_U_' al final"
        Type = "Match"
        Files = @(
            "Frogger (U) [!].smc",
            "Frogger_U_.smc"
        )
    },

    @{
        Name = "Guion bajo: apostrofe codificado como '_s_'"
        Type = "Match"
        Files = @(
            "Kirby's Fun Pak (E) [!].smc",
            "Kirby_s_Fun_Pak_E_.smc"
        )
    },

    @{
        Name = "Guion bajo: palabras sueltas 'and'/'the' pegadas"
        Type = "Match"
        Files = @(
            "Boogerman - A Pick and Flick Adventure (U).smc",
            "Boogerman_-_A_Pick_and_Flick_Adventure_U_.smc"
        )
    },

    # -------------------------------------------------------
    # MATCH: apostrofes, puntuacion, fragmentos residuales
    # -------------------------------------------------------

    @{
        Name = "Apostrofe + palabra suelta de idioma (Esp)"
        Type = "Match"
        Files = @(
            "Demon's Crest [Esp].smc",
            "Demon's Crest.smc"
        )
    },

    @{
        Name = "Fragmento residual '.net' antes de la extension real"
        Type = "Match"
        Files = @(
            "Jackie Chan's Action Kung Fu (U).nes",
            "Jackie Chan's Action Kung Fu (U).net.nes"
        )
    },

    @{
        Name = "Signo de exclamacion no deberia importar"
        Type = "Match"
        Files = @(
            "Mickey's Playtown Adventure - A Day of Discovery! (U).gba",
            "Mickey_s_Playtown_Adventure_A_Day_of_Discovery_U.gba"
        )
    },

    @{
        Name = "'&' equivale a 'and'/'the' se quita igual"
        Type = "Match"
        Files = @(
            "Kirby & The Amazing Mirror [E].gba",
            "Kirby - The Amazing Mirror.gba"
        )
    },

    @{
        Name = "Articulos en español ('the' <-> 'los/las')"
        Type = "Match"
        Files = @(
            "Los Sims 2 [E].gba",
            "Sims 2, The (UE) (M6).gba"
        )
    },

    # -------------------------------------------------------
    # MATCH: alias de titulo (Config\TitleAliases.json)
    # -------------------------------------------------------

    @{
        Name = "Alias: Narnia (traduccion oficial)"
        Type = "Match"
        Files = @(
            "Narnia - El leon la bruja y el armario [E].gba",
            "The Chronicles of Narnia - The Lion, the Witch and the Wardrobe (UE) (M8).gba"
        )
    },

    @{
        Name = "Alias: Piratas del Caribe (traduccion oficial)"
        Type = "Match"
        Files = @(
            "Piratas del Caribe - El cofre del hombre muerto [E].gba",
            "Pirates of the Caribbean - Dead Man's Chest (U) (M5).gba",
            "Pirates Of The Caribbean - Dead Man's Chest [E].gba"
        )
    },

    @{
        Name = "Alias: Cybernoid II (subtitulo distinto)"
        Type = "Match"
        Files = @(
            "Cybernoid 2 (UK) (1988).dsk",
            "Cybernoid II - The Revenge (Europe).dsk"
        )
    },

    @{
        Name = "Alias: Advance Wars 2 (nombre abreviado sin subtitulo)"
        Type = "Match"
        Files = @(
            "Advance Wars 2 - Black Hole Rising (Europe) (En,Fr,De,Es,It).gba",
            "Advance Wars 2 [E].gba"
        )
    },

    # -------------------------------------------------------
    # MATCH: codigos de dump GoodTools [hI]/[hIR00] no deben
    # excluirse de la agrupacion (no son hacks de juego reales,
    # BUG encontrado con Bomberman Max 2 / BMX Trick Racer / etc)
    # -------------------------------------------------------

    @{
        Name = "Codigo GoodTools [hI]: Bomberman Max 2 Blue"
        Type = "Match"
        Files = @(
            "Bomberman Max 2 - Blue (E) (M3).gba",
            "Bomberman Max 2 - Blue (U) [hI].gba"
        )
    },

    @{
        Name = "Codigo GoodTools [hI]: Bomberman Max 2 Red"
        Type = "Match"
        Files = @(
            "Bomberman Max 2 - Red (E) (M3).gba",
            "Bomberman Max 2 - Red (U) [hI].gba"
        )
    },

    @{
        Name = "Codigo GoodTools [hI] vs [hIR00]: BMX Trick Racer"
        Type = "Match"
        Files = @(
            "BMX Trick Racer (U) [hIR00].gba",
            "BMX Trick Racer (U) [hI].gba"
        )
    },

    @{
        Name = "Codigo GoodTools [hI]: Rugrats All Grown Up"
        Type = "Match"
        Files = @(
            "Rugrats - All Grown Up! - Express Yourself (E) (M2).gba",
            "Rugrats - All Grown Up! - Express Yourself (U) [hI].gba"
        )
    },

    # -------------------------------------------------------
    # DISTINCT: guardas anti-regresion (bugs ya corregidos)
    # -------------------------------------------------------

    @{
        Name = "BUG 'rev': Revolver/Revolution/Reveal NO son el mismo juego"
        Type = "Distinct"
        Files = @(
            "Revolver (Europe).dsk",
            "Revolution (Europe).dsk",
            "Reveal (Europe).dsk"
        )
    },

    @{
        Name = "BUG version suelta: 'V8' no es un numero de version"
        Type = "Distinct"
        Files = @(
            "Last V8, The (Europe).dsk",
            "Twin Turbo V8 (Europe).dsk"
        )
    },

    # -------------------------------------------------------
    # CONTAINS: el titulo no debe perder contenido real
    # -------------------------------------------------------

    @{
        Name = "No debe perder 'revenge' aunque haya una 'e' suelta antes (Wile E Coyote)"
        Type = "Contains"
        File = "Wile_E_Coyotes_Revenge_E_NG-Dump_Known_.smc"
        ExpectedSubstring = "revenge"
    },

    @{
        Name = "No debe perder 'v8' de un titulo real (no es una etiqueta de version)"
        Type = "Contains"
        File = "Last V8, The (Europe).dsk"
        ExpectedSubstring = "v8"
    },

    # -------------------------------------------------------
    # FLAG: proteccion de Hack/Beta/Demo/etc frente a agrupacion
    # -------------------------------------------------------

    @{
        Name = "Beta debe detectarse como Beta (no comparar con la version final)"
        Type = "Flag"
        File = "Battletoads in Battlemaniacs (Beta) [h1C].smc"
        ExpectedFlags = @{ Beta = $true }
    },

    @{
        Name = "Hack (etiqueta con texto) debe detectarse como Hack"
        Type = "Flag"
        File = "Super Mario's Quest (SMW1 Hack).smc"
        ExpectedFlags = @{ Hack = $true; NamedHack = $true }
    },

    @{
        Name = "Codigo de dump [hI] NO debe considerarse un hack de juego real (NamedHack=false)"
        Type = "Flag"
        File = "Bomberman Max 2 - Blue (U) [hI].gba"
        ExpectedFlags = @{ NamedHack = $false }
    },

    @{
        Name = "Codigo de dump [hIR00] NO debe considerarse un hack de juego real (NamedHack=false)"
        Type = "Flag"
        File = "BMX Trick Racer (U) [hIR00].gba"
        ExpectedFlags = @{ NamedHack = $false }
    },

    @{
        Name = "Una ROM normal no debe marcarse como Hack/Beta/Demo por error"
        Type = "Flag"
        File = "Advance Wars (Europe) (En,Fr,De,Es).gba"
        ExpectedFlags = @{ Hack = $false; Beta = $false; Demo = $false; Prototype = $false }
    },

    # -------------------------------------------------------
    # MEDIA SUFFIX: reconocimiento de imagenes/videos/manuales
    # -------------------------------------------------------

    @{
        Name = "Sufijo -bezel se reconoce (bug corregido, faltaba en la lista)"
        Type = "MediaSuffix"
        File = "Super Mario World-bezel"
        ExpectedBase = "Super Mario World"
    },

    @{
        Name = "Sufijo -map se reconoce (bug corregido, faltaba en la lista)"
        Type = "MediaSuffix"
        File = "Zelda Ocarina of Time-map"
        ExpectedBase = "Zelda Ocarina of Time"
    },

    @{
        Name = "El titulo puede llevar su propio guion, solo se recorta el sufijo exacto"
        Type = "MediaSuffix"
        File = "2 Game Pack! - Uno & Skip-Bo (Europe)-marquee"
        ExpectedBase = "2 Game Pack! - Uno & Skip-Bo (Europe)"
    },

    # -------------------------------------------------------
    # REGION: 'Spain' y '(UE)' no se reconocian (BUG: una ROM
    # española se quedaba con 0 puntos de region y perdia frente
    # a una copia peor con [hI])
    # -------------------------------------------------------

    @{
        Name = "'Spain' (palabra en ingles) debe reconocerse como region ESP"
        Type = "Region"
        File = "Scooby-Doo (Spain).gba"
        ExpectedRegion = "ESP"
    },

    @{
        Name = "'(UE)' (region combinada USA/Europa) debe reconocerse como EUR"
        Type = "Region"
        File = "Disney's Tarzan - Return to the Jungle (UE) [!].gba"
        ExpectedRegion = "EUR"
    }

)
