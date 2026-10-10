# ============================================================
# CleanROMs
#
# RomSets.ps1
#
# ROMs de VARIOS ficheros (juegos de disco: PlayStation, Saturn,
# Dreamcast, Sega CD, PC Engine CD...).
#
# Hasta ahora cada fichero con extension de ROM se trataba como
# una ROM distinta, y eso rompia juegos enteros:
#
# - "Juego (USA).cue" + "Juego (USA).bin" se consideraban copias
#   uno del otro: se conservaba uno y se MOVIA el otro, dejando el
#   juego sin arrancar.
# - Un juego de varios discos ("(Disc 1)", "(Disc 2)"...) con su
#   .m3u se trataba como discos duplicados entre si: se conservaba
#   uno (a veces solo la lista .m3u) y se movian los demas.
#
# Merge-RomSets agrupa esos ficheros en UNA unidad por juego antes
# de buscar duplicados:
#
# 1) Un .cue, .gdi o .m3u ARRASTRA los ficheros a los que hace
#    referencia (los .bin/.raw de sus pistas; los discos de un
#    .m3u, y las pistas de cada disco). Esos ficheros dejan de ser
#    "ROMs" sueltas.
# 2) Los discos de un mismo juego sin .m3u ("(Disc 1)", "(Disc 2)",
#    "(Disk 1)", "(CD 1)", "(Disc 1 of 2)"...) forman un conjunto;
#    el disco de numero mas bajo lo representa.
#
# La ROM que representa la unidad lleva en SetMembers el resto de
# ficheros; Cleaner.ps1 los conserva o los mueve JUNTO con ella.
#
# Un fichero referenciado por MAS DE UN descriptor (p.ej. una pista
# compartida) es de todos y de nadie: no se trata como ROM y nunca
# se mueve, para no romper la copia que se conserva.
# ============================================================

#--------------------------------------------------------------
# Resto de ficheros de la unidad (siempre un array, vacio si la
# ROM no tiene ninguno o es una ROM sin la propiedad)
#--------------------------------------------------------------

function Get-RomSetMembers {

    param($Rom)

    $prop = $Rom.PSObject.Properties["SetMembers"]

    if($null -eq $prop -or $null -eq $prop.Value)
    {
        return @()
    }

    return @($prop.Value)
}

#--------------------------------------------------------------
# Ficheros que referencia un .cue / .gdi / .m3u (rutas completas,
# solo los que existen). Nunca lanza excepcion.
#--------------------------------------------------------------

function Get-DescriptorReferences {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $folder = Split-Path $Path -Parent

    try
    {
        $lines = @(Get-Content -LiteralPath $Path -ErrorAction Stop)
    }
    catch
    {
        return @()
    }

    $found = @()

    foreach($line in $lines)
    {
        $name = $null
        $text = [string]$line

        if($extension -eq ".cue")
        {
            if($text -match '^\s*FILE\s+(?:"([^"]+)"|(\S+))\s+\S+')
            {
                $name = if($Matches[1]) { $Matches[1] } else { $Matches[2] }
            }
        }
        elseif($extension -eq ".gdi")
        {
            if($text -match '^\s*\d+\s+\d+\s+\d+\s+\d+\s+(?:"([^"]+)"|(\S+))\s+\d+')
            {
                $name = if($Matches[1]) { $Matches[1] } else { $Matches[2] }
            }
        }
        elseif($extension -eq ".m3u")
        {
            $trimmed = $text.Trim()

            if($trimmed -ne "" -and -not $trimmed.StartsWith("#"))
            {
                $name = $trimmed
            }
        }

        if([string]::IsNullOrWhiteSpace($name))
        {
            continue
        }

        # Las rutas pueden venir con \ o / segun donde se hiciera el archivo
        $relative = $name.Trim() -replace '[\\/]', [string][System.IO.Path]::DirectorySeparatorChar

        try
        {
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $folder $relative))
        }
        catch
        {
            continue
        }

        if(Test-Path -LiteralPath $candidate -PathType Leaf)
        {
            $found += $candidate
            continue
        }

        #
        # Mayusculas/minusculas distintas entre el .cue y el nombre
        # real (en Windows da igual; en Linux es otro archivo)
        #

        $candidateFolder = Split-Path $candidate -Parent
        $candidateName = Split-Path $candidate -Leaf

        if(Test-Path -LiteralPath $candidateFolder -PathType Container)
        {
            $match = Get-ChildItem -LiteralPath $candidateFolder -File |
                Where-Object { $_.Name -ieq $candidateName } |
                Select-Object -First 1

            if($null -ne $match)
            {
                $found += $match.FullName
            }
        }
    }

    return @($found | Select-Object -Unique)
}

#--------------------------------------------------------------
# Numero de disco de un nombre de archivo: "(Disc 2)", "(Disk 2)",
# "(CD 2)", "[Disc 2]", "(Disc 2 of 3)". 0 si no lleva.
#--------------------------------------------------------------

$Global:DiscTagPattern = '\s*[\(\[]\s*(?:Disc|Disk|CD)\s*(\d+)(?:\s*(?:of|de)\s*\d+)?\s*[\)\]]'

function Get-RomDiscNumber {

    param([string]$FileName)

    if($FileName -match $Global:DiscTagPattern)
    {
        return [int]$Matches[1]
    }

    return 0
}

#--------------------------------------------------------------
# Crea el objeto ROM de un fichero que el escaneo no incluyo
# (p.ej. una pista .raw o .wav, que no son extensiones de ROM)
#--------------------------------------------------------------

function New-RomSetMember {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $ByPath
    )

    if($ByPath.ContainsKey($Path))
    {
        return $ByPath[$Path]
    }

    $title = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    $member = New-RomObject -Title $title -NormalizedTitle "" -FullPath $Path

    Add-Member -InputObject $member -NotePropertyName SetMembers -NotePropertyValue ([object[]]@()) -Force

    return $member
}

#--------------------------------------------------------------
# Agrupa los ficheros de cada juego en una unidad. Devuelve la
# lista de ROMs "de primer nivel": cada una representa un juego
# completo y lleva sus otros ficheros en SetMembers.
#--------------------------------------------------------------

function Merge-RomSets {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Roms
    )

    if($Roms.Count -eq 0)
    {
        return @()
    }

    $byPath = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach($rom in $Roms)
    {
        Add-Member -InputObject $rom -NotePropertyName SetMembers -NotePropertyValue ([object[]]@()) -Force
        $byPath[$rom.FullPath] = $rom
    }

    $descriptorExtensions = @(".cue", ".gdi", ".m3u")

    #
    # 1) Que ficheros referencia cada descriptor
    #

    $references = @{}
    $referenceCount = @{}

    foreach($rom in $Roms)
    {
        $extension = [System.IO.Path]::GetExtension($rom.FullPath).ToLowerInvariant()

        if($descriptorExtensions -notcontains $extension)
        {
            continue
        }

        $refs = @(Get-DescriptorReferences -Path $rom.FullPath |
            Where-Object { $_ -ine $rom.FullPath })

        if($refs.Count -eq 0)
        {
            continue
        }

        $references[$rom.FullPath.ToLowerInvariant()] = $refs

        foreach($ref in $refs)
        {
            $key = $ref.ToLowerInvariant()
            $referenceCount[$key] = 1 + [int]$(if($referenceCount.ContainsKey($key)) { $referenceCount[$key] } else { 0 })
        }
    }

    # Referenciados por mas de un descriptor: ni ROM ni miembro de nadie
    $shared = @{}

    foreach($key in $referenceCount.Keys)
    {
        if($referenceCount[$key] -gt 1)
        {
            $shared[$key] = $true
        }
    }

    #
    # Todos los ficheros que cuelgan de un descriptor, con los
    # descriptores que cuelgan de otros (un .m3u -> sus .cue -> sus .bin)
    #

    function Get-DescriptorClosure
    {
        param([string]$DescriptorPath, $Visited)

        $closure = @()

        $key = $DescriptorPath.ToLowerInvariant()

        if($Visited.ContainsKey($key) -or -not $references.ContainsKey($key))
        {
            return @()
        }

        $Visited[$key] = $true

        foreach($ref in $references[$key])
        {
            $refKey = $ref.ToLowerInvariant()

            if($shared.ContainsKey($refKey))
            {
                continue
            }

            $closure += $ref
            $closure += @(Get-DescriptorClosure -DescriptorPath $ref -Visited $Visited)
        }

        return @($closure)
    }

    $absorbed = @{}

    foreach($rom in $Roms)
    {
        $key = $rom.FullPath.ToLowerInvariant()

        if(-not $references.ContainsKey($key))
        {
            continue
        }

        $memberPaths = @(Get-DescriptorClosure -DescriptorPath $rom.FullPath -Visited @{}) |
            Where-Object { $_ -ine $rom.FullPath } |
            Select-Object -Unique

        $members = @()

        foreach($path in @($memberPaths))
        {
            $members += New-RomSetMember -Path $path -ByPath $byPath
            $absorbed[$path.ToLowerInvariant()] = $true
        }

        $rom.SetMembers = [object[]]@($members)
    }

    # Los compartidos tampoco son ROMs sueltas
    foreach($key in $shared.Keys)
    {
        $absorbed[$key] = $true
    }

    #
    # Un descriptor absorbido por otro (el .cue de un disco de un
    # .m3u) deja de ser unidad propia
    #

    $topLevel = @($Roms | Where-Object { -not $absorbed.ContainsKey($_.FullPath.ToLowerInvariant()) })

    #
    # 2) Discos de un mismo juego sin .m3u
    #

    $discGroups = @{}

    foreach($rom in $topLevel)
    {
        $fileName = Split-Path $rom.FullPath -Leaf
        $disc = Get-RomDiscNumber $fileName

        if($disc -eq 0)
        {
            continue
        }

        $baseName = ([regex]::Replace($fileName, $Global:DiscTagPattern, "")).Trim().ToLowerInvariant()
        $groupKey = (Split-Path $rom.FullPath -Parent).ToLowerInvariant() + "|" + $baseName

        if(-not $discGroups.ContainsKey($groupKey))
        {
            $discGroups[$groupKey] = @()
        }

        $discGroups[$groupKey] += [PSCustomObject]@{ Rom = $rom; Disc = $disc }
    }

    $collapsed = @{}

    foreach($groupKey in $discGroups.Keys)
    {
        $discs = @($discGroups[$groupKey] | Sort-Object Disc)

        if(@($discs | Select-Object -ExpandProperty Disc -Unique).Count -lt 2)
        {
            continue
        }

        $primary = $discs[0].Rom
        $members = @(Get-RomSetMembers $primary)

        foreach($other in ($discs | Select-Object -Skip 1))
        {
            $members += $other.Rom
            $members += @(Get-RomSetMembers $other.Rom)
            $collapsed[$other.Rom.FullPath.ToLowerInvariant()] = $true
        }

        $primary.SetMembers = [object[]]@($members)
    }

    return @($topLevel | Where-Object { -not $collapsed.ContainsKey($_.FullPath.ToLowerInvariant()) })
}

#--------------------------------------------------------------
# Ficheros de la unidad que hay que mover/conservar ADEMAS de la
# ROM principal. Excluye los que ya se mueven como "archivos
# asociados" (Get-AssociatedFiles: mismo nombre y extension que no
# es de ROM, como una pista .raw), para no moverlos dos veces.
#--------------------------------------------------------------

function Get-RomUnitMembers {

    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $members = @(Get-RomSetMembers $Rom)

    if($members.Count -eq 0)
    {
        return @()
    }

    $handledAsAssets = @{}

    foreach($file in (@($Rom) + $members))
    {
        foreach($asset in @(Get-AssociatedFiles $file))
        {
            $handledAsAssets[$asset.FullName.ToLowerInvariant()] = $true
        }
    }

    return @($members | Where-Object { -not $handledAsAssets.ContainsKey($_.FullPath.ToLowerInvariant()) })
}
