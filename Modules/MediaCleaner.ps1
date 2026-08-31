# ============================================================
# Beta CleanROMs v2.6
#
# MediaCleaner.ps1
#
# Detecta imágenes y vídeos "huérfanos" dentro de las carpetas
# images/ y videos/ de cada sistema: archivos cuyo nombre no
# corresponde a ninguna ROM que exista actualmente (porque la
# ROM se borró, se renombró, o se movió).
#
# Nunca se borran de verdad: se mueven a _duplicates\<sistema>\
# (images o videos), la misma carpeta de respaldo que ya se usa
# para las ROMs duplicadas.
# ============================================================

$Global:OrphanedMediaFolders = @("images", "videos", "manuals")

#
# Sufijos que RetroBat/Skyscraper añaden al nombre de la ROM al
# descargar medios de ScreenScraper (p.ej. "Juego-marquee.png").
# Se comprueban de más largo a más corto para que un sufijo que
# contenga a otro (p.ej. "-boxfront" y "-box") no se corte mal.
#

$Global:MediaFileSuffixes = @(
    "-screenshottitle",
    "-screenshot",
    "-boxfront",
    "-boxback",
    "-box2dfront",
    "-box2dback",
    "-box3d",
    "-cartridge",
    "-bezel",
    "-map",
    "-fanart",
    "-marquee",
    "-thumb",
    "-title",
    "-wheel",
    "-manual",
    "-support",
    "-mix",
    "-image",
    "-video"
) | Sort-Object -Property Length -Descending

# ============================================================
# Quitar el sufijo de medio (si tiene) para obtener el nombre
# de ROM que debería corresponderle
# ============================================================

function Get-MediaRomBaseName {

    param(
        [Parameter(Mandatory)]
        [string]$FileBaseName
    )

    foreach($suffix in $Global:MediaFileSuffixes)
    {
        if($FileBaseName.ToLower().EndsWith($suffix.ToLower()))
        {
            return $FileBaseName.Substring(0, $FileBaseName.Length - $suffix.Length)
        }
    }

    return $FileBaseName

}

# ============================================================
# Buscar archivos huérfanos en la carpeta de un sistema
# ============================================================

function Find-OrphanedMedia {

    param(
        [Parameter(Mandatory)]
        [string]$SystemFolder
    )

    if(!(Test-Path -LiteralPath $SystemFolder))
    {
        return @()
    }

    #
    # Nombres (sin extensión) de todas las ROMs que existen
    # actualmente en este sistema, incluyendo subcarpetas como
    # "# Hacks y Otros #" (Get-RomFiles ya ignora images/videos/etc.)
    #

    $validBaseNames = @(
        Get-RomFiles $SystemFolder |
            ForEach-Object { $_.BaseName } |
            Sort-Object -Unique
    )

    $systemName = Split-Path $SystemFolder -Leaf

    $orphans = @()

    foreach($mediaFolderName in $Global:OrphanedMediaFolders)
    {
        $mediaFolder = Join-Path $SystemFolder $mediaFolderName

        if(!(Test-Path -LiteralPath $mediaFolder))
        {
            continue
        }

        $mediaFiles = @(Get-ChildItem -LiteralPath $mediaFolder -File -Recurse -ErrorAction SilentlyContinue)

        foreach($file in $mediaFiles)
        {
            $romName = Get-MediaRomBaseName $file.BaseName

            if($validBaseNames -notcontains $romName)
            {
                $orphans += [PSCustomObject]@{
                    Source    = $file.FullName
                    FileName  = $file.Name
                    MediaType = $mediaFolderName
                    System    = $systemName
                }
            }
        }
    }

    return $orphans

}

# ============================================================
# Carpeta de respaldo para un archivo huérfano
# ============================================================

function Get-OrphanedMediaTargetFolder {

    param(
        [Parameter(Mandatory)]
        $Orphan
    )

    return Join-Path `
        (Join-Path $Global:RetroBatRoot $Global:DuplicatesFolder) `
        (Join-Path $Orphan.System $Orphan.MediaType)

}

# ============================================================
# Previsualizar + confirmar + mover los huérfanos encontrados
# ============================================================

function Invoke-OrphanedMediaCleanup {

    param(
        [Parameter(Mandatory)]
        [string[]]$SystemFolders
    )

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "media.header")
    Write-Host "==========================================" -ForegroundColor Cyan

    $allOrphans = @()

    foreach($folder in $SystemFolders)
    {
        Write-Host ""
        Write-Host (T "media.scanning" $folder)

        $found = @(Find-OrphanedMedia -SystemFolder $folder)

        $foundText = T "media.found" $found.Count
        Write-Host "  $foundText"

        $allOrphans += $found
    }

    Write-Host ""

    if($allOrphans.Count -eq 0)
    {
        Write-Host (T "media.noneFound") -ForegroundColor Green
        return
    }

    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "media.previewTitle")
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    foreach($orphan in $allOrphans)
    {
        $target = Get-OrphanedMediaTargetFolder -Orphan $orphan

        Write-Host "[MOVE] $($orphan.Source)"
        Write-Host (T "media.system" @($orphan.System, $orphan.MediaType))
        Write-Host (T "media.destination" $target)
        Write-Host ""
    }

    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "media.totalFound" $allOrphans.Count)
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    if($Global:Settings.PreviewOnly)
    {
        Write-Host (T "plan.previewOnlyNotice") -ForegroundColor DarkYellow
        Write-Host ""
    }

    if(-not (Confirm-YesNo "media.confirmFolder" $Global:DuplicatesFolder))
    {
        Write-Host ""
        Write-Host (T "media.cancelled")
        return
    }

    Write-Host ""

    $movedCount = 0
    $skippedCount = 0
    $previewedCount = 0

    foreach($orphan in $allOrphans)
    {
        $target = Get-OrphanedMediaTargetFolder -Orphan $orphan

        if(!(Test-Path -LiteralPath $orphan.Source))
        {
            $skippedCount++
            continue
        }

        $destination = Join-Path $target $orphan.FileName

        if(Test-Path -LiteralPath $destination)
        {
            Write-Host (T "media.alreadyBackedUp" $destination) -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        if($Global:Settings.PreviewOnly)
        {
            Write-Host (T "exec.previewMove" $orphan.Source) -ForegroundColor DarkYellow
            $previewedCount++
            continue
        }

        if(!(Test-Path -LiteralPath $target))
        {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        Move-Item -LiteralPath $orphan.Source -Destination $destination

        Write-Host (T "media.moved" $orphan.Source) -ForegroundColor Yellow

        $movedCount++
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host (T "media.movedCount" $movedCount)

    if($Global:Settings.PreviewOnly)
    {
        Write-Host (T "exec.previewOnly" $previewedCount)
    }

    Write-Host (T "media.skippedCount" $skippedCount)
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host (T "media.nothingDeleted")
    Write-Host (T "media.nothingDeletedFull" $Global:DuplicatesFolder)
}
