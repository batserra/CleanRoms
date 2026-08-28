# ============================================================
#
# Beta CleanROMs v2.6
#
# Grouper.ps1
#
# Agrupa ROMs por nombre normalizado
#
# Las ROMs marcadas como Hack, Traducción, Beta, Prototype, Demo,
# Homebrew, Pirate, Sample, Preview o Kiosk quedan excluidas de la
# agrupación: nunca se comparan con otras copias, nunca entran en
# el motor de decisión, y por tanto nunca se mueven ni se renombran.
#
# Para Hack se usa específicamente NamedHack (solo la palabra
# "Hack" en sí, p.ej. "(Hack)", "(SMW1 Hack)") y no el flag Hack
# genérico, que también incluye códigos de dump estilo GoodTools
# como "[h1]"/"[hI]"/"[h1C]" — esos casi siempre son solo una
# modificación técnica de cabecera (no un hack de juego real) y sí
# deben poder agruparse y compararse con la copia limpia. El flag
# Hack genérico se sigue usando para la puntuación (sección 2 del
# manual), penalizando levemente esas copias sin excluirlas del
# todo.
#
# Las ROMs marcadas como Beta, Prototype, Demo, Homebrew, Pirate,
# Sample, Preview o Kiosk representan contenido genuinamente
# distinto de la versión final/retail (una beta o un prototipo no
# son "la misma ROM con peor nombre", son una versión distinta que
# un coleccionista puede querer conservar aparte), así que nunca se
# tratan como duplicado de la versión normal, aunque compartan
# título.
#
# ============================================================

function Group-Roms {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Roms,

        #
        # Nombre real del sistema/consola (p.ej. "SNES"), tal cual
        # está en $Global:Settings.SystemFolders. Se guarda en cada
        # grupo para que, más adelante, Get-DuplicateTargetFolder
        # pueda construir "_duplicates\<sistema>\" sin tener que
        # adivinarlo a partir de la carpeta del propio archivo (eso
        # fallaba cuando la ROM "perdedora" vivía en una subcarpeta,
        # como "# Hacks y Otros #" o una de discos múltiples: el
        # nombre de esa subcarpeta se colaba como si fuera el
        # sistema). Opcional para no romper los tests existentes que
        # llaman a Group-Roms sin este dato.
        #

        [string]$SystemName = $null
    )

    if($null -eq $Roms -or $Roms.Count -eq 0)
    {
        return @()
    }

    $groups = $Roms |
        Where-Object {
            (-not [string]::IsNullOrWhiteSpace($_.NormalizedTitle)) -and
            (-not $_.NamedHack) -and
            (-not $_.Translation) -and
            (-not $_.Beta) -and
            (-not $_.Prototype) -and
            (-not $_.Demo) -and
            (-not $_.Homebrew) -and
            (-not $_.Pirate) -and
            (-not $_.Sample) -and
            (-not $_.Preview) -and
            (-not $_.Kiosk)
        } |
        Group-Object NormalizedTitle |
        Sort-Object Name

    $result = foreach($group in $groups)
    {
        if($group.Count -gt 1)
        {
            [PSCustomObject]@{

                Name = $group.Name

                System = $SystemName

                Count = $group.Count

                Roms = @($group.Group)

                TotalScore = 0

                Winner = $null

            }
        }
    }

    return @($result)

}

#
# NOTA: aquí existían Find-RomGroup, Get-GroupCount,
# Get-DuplicateCount y Show-GroupStatistics — cuatro funciones
# auxiliares para trabajar con los grupos devueltos por
# Group-Roms, pero ninguna llegaba a usarse desde ningún otro
# sitio del programa (el resumen real en pantalla lo genera
# Summary.ps1, con sus propios cálculos). Se quitaron en la
# misma limpieza de código muerto de la v2.6 que ya afectó a
# Test-RomEligibility (DecisionEngine.ps1) y a Normalize-RomTitle
# / Get-CleanTitle (RomParser.ps1).
#