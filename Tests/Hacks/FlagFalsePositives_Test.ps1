# ============================================================
# BUG corregido: los flags Beta, Prototype, Demo, Homebrew,
# Pirate, Sample, Preview y Kiosk no tenian NINGUN limite de
# palabra -- coincidian con la subcadena en cualquier sitio del
# nombre. Comprobado con una coleccion real (~94.000 archivos):
# esto organizaba en "# Hacks y Otros #" juegos legitimos como
# "Demon's Crest" (contiene "Demo"), "Pirates of the Caribbean"
# (contiene "Pirate"), o "Team Protoman" (contiene "Proto"),
# sin ser ni demos, ni copias pirateadas, ni prototipos.
#
# Este test comprueba que esos juegos reales ya NO se detectan
# como ninguno de esos flags, y que los casos genuinos (incluido
# "Prototipo" en espanol) se siguen detectando igual que antes.
# ============================================================

# -------------------------------------------------------
# Falsos positivos reales encontrados en una coleccion real:
# NINGUNO de estos debe activar ningun flag.
# -------------------------------------------------------

$falsosPositivos = @(
    "Demon's Crest (ESP) (PAL)",
    "Demon Attack (Europe) (Unl)",
    "Clash at Demonhead (ESP)",
    "Laplace's Demon (Laplace No Ma) (ESP) (NTSC)",
    "Demolition Man (ESP) (NTSC)",
    "Desert Demolition",
    "Pirates Of The Caribbean - Dead Man's Chest [E]",
    "Pirates of the Caribbean - The Curse of the Black Pearl (USA)",
    "The Pirates of Dark Water (ESP) (NTSC)",
    "The Jetsons - Invasion of the Planet Pirates (ESP) (NTSC)",
    "Megaman Battle Network 5 - Team Protoman (E)",
    "4th Protocol, The (UK) (1986)",
    "Dokodemo Mahjong (Japan)"
)

foreach($titulo in $falsosPositivos)
{
    $flags = Get-RomFlags $titulo

    $activado = $flags.Beta -or $flags.Prototype -or $flags.Demo -or `
                $flags.Homebrew -or $flags.Pirate -or $flags.Sample -or `
                $flags.Preview -or $flags.Kiosk

    Assert-Equal `
        $false `
        $activado `
        "Get-RomFlags: '$titulo' es un juego legitimo, no debe activar ningun flag de exclusion"
}

# -------------------------------------------------------
# Casos genuinos: deben seguir detectandose igual que antes
# -------------------------------------------------------

Assert-Equal $true (Get-RomFlags "GP-1 Racing (U) (Beta)").Beta `
    "Get-RomFlags: '(Beta)' como etiqueta real debe seguir detectandose"

Assert-Equal $true (Get-RomFlags "Star Fox 2 (Proto) (ESP)").Prototype `
    "Get-RomFlags: '(Proto)' como etiqueta real debe seguir detectandose"

Assert-Equal $true (Get-RomFlags "Batman - Revenge of the Joker (Prototipo)").Prototype `
    "Get-RomFlags: '(Prototipo)' en espanol debe detectarse igual que '(Proto)'"

Assert-Equal $true (Get-RomFlags "Interlace Demo 1 (PD)").Demo `
    "Get-RomFlags: '(PD) Demo' real debe seguir detectandose"

Assert-Equal $true (Get-RomFlags "Celeste Classic (v1.0) (homebrew)").Homebrew `
    "Get-RomFlags: '(homebrew)' real debe seguir detectandose"

Assert-Equal $true (Get-RomFlags "Pirate (Europe) (Unl)").Pirate `
    "Get-RomFlags: '(Pirate)' como etiqueta real debe seguir detectandose"

Assert-Equal $true (Get-RomFlags "NESA Audio Player - Little Nemo Sample (PD)").Sample `
    "Get-RomFlags: 'Sample' como etiqueta real debe seguir detectandose"
