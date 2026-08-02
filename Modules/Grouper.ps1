# ============================================================
#
# Beta CleanROMs v2.5
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
        [array]$Roms
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

                Count = $group.Count

                Roms = @($group.Group)

                TotalScore = 0

                Winner = $null

            }
        }
    }

    return @($result)

}

# ============================================================
# Buscar grupo
# ============================================================

function Find-RomGroup {

    param(
        [array]$Groups,
        [string]$Name
    )

    return $Groups |
        Where-Object {
            $_.Name -eq $Name
        }

}

# ============================================================
# Número de grupos
# ============================================================

function Get-GroupCount {

    param(
        [array]$Groups
    )

    return @($Groups).Count

}

# ============================================================
# Número total de ROMs duplicadas
# ============================================================

function Get-DuplicateCount {

    param(
        [array]$Groups
    )

    $count = 0

    foreach($group in $Groups)
    {
        $count += $group.Count
    }

    return $count

}

# ============================================================
# Mostrar estadísticas
# ============================================================

function Show-GroupStatistics {

    param(
        [array]$Groups
    )

    Write-Host ""
    Write-Host "=============================="
    Write-Host " ESTADÍSTICAS"
    Write-Host "=============================="
    Write-Host ""

    Write-Host "Grupos duplicados : $(Get-GroupCount $Groups)"
    Write-Host "ROMs duplicadas   : $(Get-DuplicateCount $Groups)"
    Write-Host ""

}