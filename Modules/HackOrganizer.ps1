# ============================================================
# Beta CleanROMs v2.6
#
# HackOrganizer.ps1
#
# Mueve las ROMs marcadas como Hack, Traducción, Beta, Prototype,
# Demo, Homebrew, Pirate, Sample, Preview o Kiosk (ver Grouper.ps1)
# que están sueltas en la carpeta principal de un sistema a su
# propia subcarpeta "# Hacks y Otros #" — la misma convención que
# ya reconoce RomParser.ps1 para detectar hacks por carpeta. Una
# vez movidas allí, quedan organizadas y separadas de las ROMs
# normales (no se ven directamente desde RetroBat), pero el
# programa las sigue reconociendo y nunca las compara con la
# versión original.
#
# Además, dentro de esa carpeta se hace una segunda pasada que
# deduplica por HASH (no por título): los hacks de fans cambian de
# nombre con total libertad (abreviaturas, apodos, siglas...), así
# que el título no sirve para encontrar sus duplicados, pero el
# hash demuestra sin lugar a dudas que es el mismo archivo.
#
# No se llama desde un menú aparte: se ejecuta automáticamente
# como parte de "Limpiar ROMs duplicadas" y de "TODO", con su
# propia previsualización y confirmación S/N cada vez.
# ============================================================
 
function Get-LooseHackRoms {
 
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Roms
    )
 
    #
    # Cualquier ROM de las categorías que Grouper.ps1 excluye de la
    # comparación, y que todavía esté suelta en la carpeta
    # principal del sistema (no dentro de una carpeta que ya
    # contenga "Hack" en el nombre).
    #
 
    return @(
        $Roms | Where-Object {
            (
                $_.NamedHack -or
                $_.Translation -or
                $_.Beta -or
                $_.Prototype -or
                $_.Demo -or
                $_.Homebrew -or
                $_.Pirate -or
                $_.Sample -or
                $_.Preview -or
                $_.Kiosk
            ) -and
            ((Split-Path $_.FullPath -Parent) -notmatch "Hack")
        }
    )
 
}
 
function Group-RomsByHash {
 
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Roms,

        #
        # Igual que en Group-Roms: el nombre real del sistema, para
        # que luego Get-DuplicateTargetFolder no tenga que
        # adivinarlo a partir de la carpeta del archivo (que aquí
        # sería "# Hacks y Otros #", no el sistema).
        #

        [string]$SystemName = $null
    )
 
    #
    # A diferencia de Group-Roms (que agrupa por título normalizado),
    # esto agrupa por contenido real (hash). Los hacks de fans
    # cambian de nombre con más libertad que las ROMs originales,
    # así que el título no sirve para encontrar sus duplicados —
    # pero el hash demuestra sin duda que es el mismo archivo.
    #
 
    if($null -eq $Roms -or $Roms.Count -eq 0)
    {
        return @()
    }
 
    $withHash = foreach($rom in $Roms)
    {
        $hash = Get-RomHash -Path $rom.FullPath
 
        if($hash)
        {
            [PSCustomObject]@{
                Rom  = $rom
                Hash = $hash
            }
        }
    }
 
    $groups = $withHash |
        Group-Object Hash |
        Where-Object { $_.Count -gt 1 }
 
    $result = foreach($group in $groups)
    {
        #
        # De cada grupo de archivos idénticos, se conserva el de
        # nombre más corto (normalmente el más "limpio"), y en
        # caso de empate el primero por orden alfabético — mismo
        # criterio que ya se usa como desempate en DecisionEngine.
        #
 
        $sorted = $group.Group.Rom | Sort-Object `
            @{Expression = { $_.Title.Length }}, `
            @{Expression = { $_.Title }}
 
        [PSCustomObject]@{
            Hash   = $group.Name
            System = $SystemName
            Keep   = $sorted[0]
            Remove = @($sorted | Select-Object -Skip 1)
        }
    }
 
    return @($result)
 
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
 
        $systemName = Split-Path $folder -Leaf
 
        $roms = @(Get-RomsFromFolder -Path $folder -SystemName $systemName)
 
        $loose = @(Get-LooseHackRoms -Roms $roms)
 
        if($loose.Count -gt 0)
        {
            Write-Host (T "hackorg.foundInSystem" @($systemName, $loose.Count))
        }
 
        $allLoose += $loose
    }
 
    Write-Host ""
 
    if($allLoose.Count -eq 0)
    {
        Write-Host (T "hackorg.noneFound") -ForegroundColor Green
    }
    else
    {
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host (T "hackorg.previewTitle")
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""
 
        foreach($rom in $allLoose)
        {
            $systemFolder = Split-Path $rom.FullPath -Parent
            $target = Join-Path $systemFolder "# Hacks y Otros #"
 
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
        }
        else
        {
            Write-Host ""
 
            $movedCount = 0
            $skippedCount = 0
 
            foreach($rom in $allLoose)
            {
                $systemFolder = Split-Path $rom.FullPath -Parent
                $target = Join-Path $systemFolder "# Hacks y Otros #"
 
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
    }
 
    #
    # Segunda pasada: deduplicar por hash DENTRO de cada carpeta
    # "# Hacks y Otros #" (incluye lo recién movido y lo que ya
    # hubiera antes).
    #
 
    $hacksFolders = @(
        $SystemFolders |
            ForEach-Object { Join-Path $_ "# Hacks y Otros #" } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Select-Object -Unique
    )
 
    Invoke-HackDeduplication -HacksFolders $hacksFolders
}
 
function Invoke-HackDeduplication {
 
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$HacksFolders
    )
 
    if($HacksFolders.Count -eq 0)
    {
        return
    }
 
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackdedup.header")
    Write-Host "==========================================" -ForegroundColor Cyan
 
    $allDupeGroups = @()
 
    foreach($folder in $HacksFolders)
    {
        $systemName = Split-Path (Split-Path $folder -Parent) -Leaf

        $roms = @(Get-RomsFromFolder -Path $folder -SystemName $systemName)
 
        $dupeGroups = @(Group-RomsByHash -Roms $roms -SystemName $systemName)
 
        if($dupeGroups.Count -gt 0)
        {
            Write-Host (T "hackdedup.foundInSystem" @($systemName, $dupeGroups.Count))
        }
 
        $allDupeGroups += $dupeGroups
    }
 
    Write-Host ""
 
    if($allDupeGroups.Count -eq 0)
    {
        Write-Host (T "hackdedup.noneFound") -ForegroundColor Green
        return
    }
 
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackorg.previewTitle")
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
 
    $totalToMove = 0
 
    foreach($group in $allDupeGroups)
    {
        Write-Host "[KEEP] $($group.Keep.FullPath)"
        Write-Host (T "hackdedup.hash" @($Global:Settings.HashAlgorithm, $group.Hash))
        Write-Host ""
 
        foreach($rom in $group.Remove)
        {
            $target = Get-DuplicateTargetFolder -SystemName $group.System
 
            Write-Host "[MOVE] $($rom.FullPath)"
            Write-Host (T "hackorg.destination" $target)
            Write-Host ""
 
            $totalToMove++
        }
    }
 
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackdedup.totalFound" $totalToMove)
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
 
    Write-Host (T "hackdedup.confirmNote" $Global:Settings.HashAlgorithm) -ForegroundColor Yellow
    Write-Host ""
 
    $answer = Read-Host (T "hackdedup.confirmMove")
 
    if($answer -notmatch (T "confirm.yesPattern"))
    {
        Write-Host ""
        Write-Host (T "plan.operationCancelled")
        return
    }
 
    Write-Host ""
 
    $movedCount = 0
    $skippedCount = 0
 
    foreach($group in $allDupeGroups)
    {
        foreach($rom in $group.Remove)
        {
            $target = Get-DuplicateTargetFolder -SystemName $group.System
 
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
 
            Write-Host (T "exec.move" $rom.FullPath) -ForegroundColor Yellow
 
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
    }
 
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "hackorg.movedCount" $movedCount)
    Write-Host (T "hackorg.skippedCount" $skippedCount)
    Write-Host "==========================================" -ForegroundColor Cyan
}