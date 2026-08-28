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

#
# NOTA: aquí existía una función Move-RomAssets que envolvía
# Get-AssociatedFiles + Move-Asset, pero nunca llegaba a usarse
# desde ningún sitio del programa (Executor.ps1 y HackOrganizer.ps1
# llaman a Get-AssociatedFiles y Move-Asset directamente, cada uno
# con su propio manejo de errores por archivo). Se quitó en la
# misma limpieza de código muerto de la v2.6.
#

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

    if(Test-Path -LiteralPath $destination)
    {
        #
        # BUG corregido en la v2.6: antes se llegaba directamente
        # a Move-Item -Force, que si el destino ya existía (p.ej.
        # una partida guardada de una limpieza anterior con el
        # mismo nombre) lo SOBREESCRIBÍA SIN AVISAR — la única
        # operación de todo el programa que no comprobaba esto
        # antes de mover, a diferencia de la ROM principal, los
        # huérfanos, y los duplicados de hacks, que siempre
        # avisan y se saltan el archivo en vez de sobrescribir.
        #
        # Se lanza como excepción porque los tres sitios que
        # llaman a Move-Asset (Executor.ps1, HackOrganizer.ps1)
        # ya envuelven la llamada en un try/catch que avisa con
        # Write-Warning sin detener el resto de la limpieza.
        #

        throw (T "asset.destinationExists" $destination)
    }

    #
    # -Force se conserva aquí solo para poder mover partidas
    # guardadas marcadas como solo-lectura/ocultas — nunca para
    # sobrescribir el destino, que ya se ha descartado arriba.
    #

    Move-Item `
        -LiteralPath $Asset.FullName `
        -Destination $destination `
        -Force

}

