# ============================================================
# Beta CleanROMs v2.5
#
# HackOrganizer.ps1
#
# Mueve las ROMs marcadas como Hack (NamedHack, ver Grouper.ps1)
# que están sueltas en la carpeta principal de un sistema a su
# propia subcarpeta "# Hacks #" — la misma convención que ya
# reconoce RomParser.ps1 para detectar hacks por carpeta. Una vez
# movidas allí, quedan organizadas y separadas de las ROMs
# normales, pero el programa las sigue reconociendo (nunca se
# comparan ni se mueven a _duplicates entre sí).
#
# No se borra ni se pierde nada: es solo una reorganización, con
# su propia previsualización y confirmación S/N.
# ============================================================

function Get-LooseHackRoms {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Roms
    )

    return @(
        $Roms | Where-Object {
            $_.NamedHack -and
            ((Split-Path $_.FullPath -Parent) -notmatch "Hack")
        }
    )

}

function Invoke-HackOrganizer {

    param(
        [Parameter(Mandatory)]
        [string[]]$SystemFolders
    )

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackorg.header")
    Write-Host "==========================================" -ForegroundColor Cyan

    $allLoose = @()

    foreach($folder in $SystemFolders)
    {
        if(!(Test-Path -LiteralPath $folder))
        {
            continue
        }

        $roms = @(Get-RomsFromFolder $folder)

        $loose = Get-LooseHackRoms -Roms $roms

        if($loose.Count -gt 0)
        {
            Write-Host (T "hackorg.foundInSystem" @((Split-Path $folder -Leaf), $loose.Count))
        }

        $allLoose += $loose
    }

    Write-Host ""

    if($allLoose.Count -eq 0)
    {
        Write-Host (T "hackorg.noneFound") -ForegroundColor Green
        return
    }

    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackorg.previewTitle")
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    foreach($rom in $allLoose)
    {
        $systemFolder = Split-Path $rom.FullPath -Parent
        $target = Join-Path $systemFolder "# Hacks #"

        Write-Host "[MOVE] $($rom.FullPath)"
        Write-Host (T "hackorg.destination" $target)
        Write-Host ""
    }

    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackorg.totalFound" $allLoose.Count)
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    $answer = Read-Host (T "hackorg.confirm")

    if($answer -notmatch (T "confirm.yesPattern"))
    {
        Write-Host ""
        Write-Host (T "plan.operationCancelled")
        return
    }

    Write-Host ""

    $movedCount = 0
    $skippedCount = 0

    foreach($rom in $allLoose)
    {
        $systemFolder = Split-Path $rom.FullPath -Parent
        $target = Join-Path $systemFolder "# Hacks #"

        if(!(Test-Path -LiteralPath $target))
        {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        if(!(Test-Path -LiteralPath $rom.FullPath))
        {
            $skippedCount++
            continue
        }

        $destination = Join-Path $target (Split-Path $rom.FullPath -Leaf)

        if(Test-Path -LiteralPath $destination)
        {
            Write-Host (T "media.alreadyBackedUp" $destination) -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        Move-Item -LiteralPath $rom.FullPath -Destination $destination

        Write-Host (T "hackorg.moved" $rom.FullPath) -ForegroundColor Yellow

        #
        # Mover también los archivos asociados (partida guardada,
        # configuración de mando...), igual que al mover un
        # duplicado normal
        #

        if($Global:Settings.MoveAssets)
        {
            $assets = Get-AssociatedFiles $rom

            foreach($asset in $assets)
            {
                try
                {
                    Move-Asset -Asset $asset -TargetFolder $target
                    Write-Host (T "exec.moveAsset" $asset.Name) -ForegroundColor DarkYellow
                }
                catch
                {
                    Write-Warning (T "exec.assetMoveFailed" $asset.FullName)
                }
            }
        }

        $movedCount++
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackorg.movedCount" $movedCount)
    Write-Host (T "hackorg.skippedCount" $skippedCount)
    Write-Host "==========================================" -ForegroundColor Cyan
}
