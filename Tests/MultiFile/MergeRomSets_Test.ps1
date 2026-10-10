# ============================================================
# BUG corregido: los juegos de VARIOS ficheros se rompian.
#
# Cada fichero con extension de ROM se trataba como una ROM
# distinta, asi que:
# - "Juego (USA).cue" y "Juego (USA).bin" se veian como copias uno
#   del otro y se movia uno de los dos.
# - Los discos de un juego ("(Disc 1)", "(Disc 2)") y su .m3u se
#   veian como duplicados entre si.
#
# Merge-RomSets agrupa cada juego en una unidad (la ROM principal
# lleva el resto en SetMembers). Este test comprueba como se forman
# esas unidades: .cue, .gdi, .m3u, discos por nombre, ficheros
# compartidos, mayusculas distintas, subcarpetas...
# ============================================================

$tempRoot = New-TestTempFolder

function New-SetFolder
{
    param([string]$Name)

    $folder = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    return $folder
}

function New-TestFile
{
    param([string]$Folder, [string]$Name, [string]$Content = "x")

    $path = Join-Path $Folder $Name
    $parent = Split-Path $path -Parent

    if(!(Test-Path -LiteralPath $parent))
    {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $path -Value $Content
    return $path
}

function Get-Units
{
    param([string]$Folder)

    $roms = @(Get-RomsFromFolder -Path $Folder -SystemName "psx" 6>$null)
    $roms = @(Update-NormalizedTitles $roms)

    return @(Merge-RomSets $roms)
}

function Get-MemberNames
{
    param($Rom)

    return @(Get-RomSetMembers $Rom | ForEach-Object { Split-Path $_.FullPath -Leaf } | Sort-Object)
}

try
{
    #
    # Numero de disco
    #

    Assert-Equal 1 (Get-RomDiscNumber "Game (USA) (Disc 1).chd") "Disco: '(Disc 1)'"
    Assert-Equal 2 (Get-RomDiscNumber "Game (USA) (Disk 2).cue") "Disco: '(Disk 2)'"
    Assert-Equal 3 (Get-RomDiscNumber "Game [CD 3].iso") "Disco: '[CD 3]'"
    Assert-Equal 2 (Get-RomDiscNumber "Game (Disc 2 of 4).chd") "Disco: '(Disc 2 of 4)'"
    Assert-Equal 0 (Get-RomDiscNumber "Game (USA).chd") "Disco: sin etiqueta de disco"
    Assert-Equal 0 (@(Get-RomSetMembers ([PSCustomObject]@{ FullPath = "x" })).Count) "Get-RomSetMembers: una ROM sin la propiedad no tiene miembros"

    #
    # .cue + .bin con el mismo nombre
    #

    $f = New-SetFolder "cuebin"
    New-TestFile $f "Crash (USA).bin" "data" | Out-Null
    New-TestFile $f "Crash (USA).cue" "FILE `"Crash (USA).bin`" BINARY`n  TRACK 01 MODE2/2352`n    INDEX 01 00:00:00" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 1 $u.Count ".cue + .bin: una sola unidad (antes eran dos ROMs 'duplicadas')"
    Assert-Equal "Crash (USA).cue" (Split-Path $u[0].FullPath -Leaf) ".cue + .bin: la unidad la representa el .cue"
    Assert-Equal "Crash (USA).bin" ((Get-MemberNames $u[0]) -join ",") ".cue + .bin: el .bin va como miembro"

    #
    # .cue con varias pistas, nombres con espacios y sin comillas
    #

    $f = New-SetFolder "tracks"
    New-TestFile $f "Game (USA).cue" "FILE `"Game (USA) (Track 1).bin`" BINARY`nFILE `"Game (USA) (Track 2).bin`" BINARY`nFILE Track3.bin BINARY" | Out-Null
    New-TestFile $f "Game (USA) (Track 1).bin" | Out-Null
    New-TestFile $f "Game (USA) (Track 2).bin" | Out-Null
    New-TestFile $f "Track3.bin" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 1 $u.Count ".cue con pistas: una sola unidad"
    Assert-Equal 3 @(Get-MemberNames $u[0]).Count ".cue con pistas: las 3 pistas son miembros"

    #
    # .cue que referencia un fichero que no existe: no absorbe nada
    #

    $f = New-SetFolder "missing"
    New-TestFile $f "Ghost (USA).cue" "FILE `"No Existe.bin`" BINARY" | Out-Null
    New-TestFile $f "Other (USA).bin" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 2 $u.Count ".cue con referencia rota: no absorbe ficheros que no son suyos"

    #
    # Mayusculas distintas y barras de Windows dentro del .cue
    #

    $f = New-SetFolder "casing"
    New-TestFile $f "Case (USA).cue" "FILE `"CASE (USA).BIN`" BINARY`nFILE `"extra\Case Track.bin`" BINARY" | Out-Null
    New-TestFile $f "Case (USA).bin" | Out-Null
    New-TestFile $f "extra/Case Track.bin" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 1 $u.Count "Referencias con otras mayusculas y subcarpeta: una sola unidad"
    Assert-Equal 2 @(Get-MemberNames $u[0]).Count "Referencias con otras mayusculas y subcarpeta: ambos ficheros son miembros"

    #
    # .gdi: pistas .bin y .raw (el .raw no es extension de ROM)
    #

    $f = New-SetFolder "gdi"
    New-TestFile $f "Dream (USA).gdi" "3`n1 0 4 2352 track01.bin 0`n2 756 0 2352 `"track02.raw`" 0`n3 45000 4 2352 track03.bin 0" | Out-Null
    New-TestFile $f "track01.bin" | Out-Null
    New-TestFile $f "track02.raw" | Out-Null
    New-TestFile $f "track03.bin" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 1 $u.Count ".gdi: una sola unidad"
    Assert-Equal "track01.bin,track02.raw,track03.bin" ((Get-MemberNames $u[0]) -join ",") ".gdi: incluye tambien la pista .raw que el escaneo no ve"

    #
    # .m3u con discos .chd
    #

    $f = New-SetFolder "m3u"
    New-TestFile $f "FF7 (USA).m3u" "#EXTM3U`nFF7 (USA) (Disc 1).chd`nFF7 (USA) (Disc 2).chd`n`nFF7 (USA) (Disc 3).chd" | Out-Null
    1..3 | ForEach-Object { New-TestFile $f "FF7 (USA) (Disc $_).chd" | Out-Null }

    $u = @(Get-Units $f)

    Assert-Equal 1 $u.Count ".m3u: una sola unidad (antes los 3 discos eran 'duplicados' del .m3u)"
    Assert-Equal "FF7 (USA).m3u" (Split-Path $u[0].FullPath -Leaf) ".m3u: lo representa el .m3u"
    Assert-Equal 3 @(Get-MemberNames $u[0]).Count ".m3u: los 3 discos son miembros"

    #
    # .m3u -> .cue -> .bin (cierre completo)
    #

    $f = New-SetFolder "m3ucue"
    New-TestFile $f "Spyro (USA).m3u" "Spyro (USA) (Disc 1).cue`nSpyro (USA) (Disc 2).cue" | Out-Null

    foreach($d in 1, 2)
    {
        New-TestFile $f "Spyro (USA) (Disc $d).cue" "FILE `"Spyro (USA) (Disc $d).bin`" BINARY" | Out-Null
        New-TestFile $f "Spyro (USA) (Disc $d).bin" | Out-Null
    }

    $u = @(Get-Units $f)

    Assert-Equal 1 $u.Count ".m3u -> .cue -> .bin: una sola unidad"
    Assert-Equal 4 @(Get-MemberNames $u[0]).Count ".m3u -> .cue -> .bin: 2 .cue + 2 .bin como miembros"

    #
    # Discos por nombre, sin .m3u
    #

    $f = New-SetFolder "discs"
    1..3 | ForEach-Object { New-TestFile $f "Final (USA) (Disc $_).chd" | Out-Null }
    New-TestFile $f "Lonely (USA) (Disc 1).chd" | Out-Null
    New-TestFile $f "Final (Europe) (Disc 1).chd" | Out-Null
    New-TestFile $f "Final (Europe) (Disc 2).chd" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 3 $u.Count "Discos por nombre: conjunto USA, conjunto Europe y un disco suelto"

    $usa = @($u | Where-Object { (Split-Path $_.FullPath -Leaf) -eq "Final (USA) (Disc 1).chd" })[0]
    $eur = @($u | Where-Object { (Split-Path $_.FullPath -Leaf) -eq "Final (Europe) (Disc 1).chd" })[0]
    $lonely = @($u | Where-Object { (Split-Path $_.FullPath -Leaf) -like "Lonely*" })[0]

    Assert-Equal "Final (USA) (Disc 2).chd,Final (USA) (Disc 3).chd" ((Get-MemberNames $usa) -join ",") "Discos por nombre: el Disc 1 representa y lleva el 2 y el 3"
    Assert-Equal "Final (Europe) (Disc 2).chd" ((Get-MemberNames $eur) -join ",") "Discos por nombre: el conjunto Europe va aparte"
    Assert-Equal 0 @(Get-MemberNames $lonely).Count "Discos por nombre: un unico '(Disc 1)' no se agrupa con nada"

    #
    # Fichero compartido por dos .cue: ni ROM ni miembro de nadie
    #

    $f = New-SetFolder "shared"
    New-TestFile $f "A (USA).cue" "FILE `"shared.bin`" BINARY" | Out-Null
    New-TestFile $f "A (Europe).cue" "FILE `"shared.bin`" BINARY" | Out-Null
    New-TestFile $f "shared.bin" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 2 $u.Count "Fichero compartido: no cuenta como ROM suelta (quedan los dos .cue)"
    Assert-Equal 0 (@($u | ForEach-Object { Get-MemberNames $_ }).Count) "Fichero compartido: no es miembro de ninguno (nunca se movera)"

    #
    # Sin descriptores: no cambia nada
    #

    $f = New-SetFolder "plain"
    New-TestFile $f "Plain (USA).sfc" | Out-Null
    New-TestFile $f "Plain (Europe).sfc" | Out-Null

    $u = @(Get-Units $f)

    Assert-Equal 2 $u.Count "ROMs de un solo fichero: no cambia nada"

    Assert-Equal 0 (@(Merge-RomSets @()).Count) "Merge-RomSets: lista vacia"
}
finally
{
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
