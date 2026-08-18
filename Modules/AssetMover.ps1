# ============================================================
# Beta CleanROMs v2.6
#
# AssetMover.ps1
#
# Movimiento de recursos asociados
# ============================================================

function Get-AssociatedFiles {

    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $directory = Split-Path $Rom.FullPath -Parent

    $romFileName = Split-Path $Rom.FullPath -Leaf
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Rom.FullPath)

    Get-ChildItem -LiteralPath $directory -File |
        Where-Object {

            #
            # Nunca tratar otra ROM como si fuera un archivo
            # asociado/secundario, aunque comparta el mismo nombre
            # base con distinta extensión (p.ej. "Juego.sfc" y
            # "Juego.smc" son dos ROMs independientes, cada una con
            # su propia acción en el plan — no un archivo secundario
            # de la otra). Sin esto, una ya se mueve como "asociada"
            # de la primera y luego su propia acción de MOVE falla
            # porque el archivo ya no está ahí.
            #

            (-not ($Global:RomExtensions -contains $_.Extension.ToLower())) -and

            (

                #
                # Coincidencia simple: mismo nombre sin extensión
                # (p.ej. "Juego.sav" para "Juego.gba")
                #

                ($_.BaseName -eq $baseName) -or

                #
                # Extensión compuesta: el archivo asociado empieza por
                # el nombre COMPLETO de la ROM (con su extensión) seguido
                # de más extensiones propias, p.ej.
                # "Barbarian (Europe).dsk.p2k.cfg" para "Barbarian (Europe).dsk"
                #

                ($_.Name -ne $romFileName -and $_.Name.StartsWith("$romFileName."))

            )

        }

}

function Move-RomAssets {

    param(
        [Parameter(Mandatory)]
        $Action
    )

    $assets = Get-AssociatedFiles $Action.Rom

    foreach($asset in $assets)
    {
        Move-Asset `
            -Asset $asset `
            -TargetFolder $Action.Target
    }

}

function Move-Asset {

    param(

        [Parameter(Mandatory)]
        $Asset,

        [Parameter(Mandatory)]
        [string]$TargetFolder

    )

    if(!(Test-Path -LiteralPath $TargetFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $TargetFolder `
            -Force | Out-Null
    }

    $destination = Join-Path `
        $TargetFolder `
        $Asset.Name

    Move-Item `
        -LiteralPath $Asset.FullName `
        -Destination $destination `
        -Force

}

