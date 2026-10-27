# ============================================================
# BUG corregido: Find-OrphanedMedia solo conocia ROMs que son
# ARCHIVOS. En PS3 los juegos son carpetas ("Rayman Origins.ps3"),
# asi que todos sus medios (images/videos/manuals) se marcaban como
# huerfanos y se movian a _duplicates aunque el juego existia.
# ============================================================

$tempSystem = New-TestTempFolder

try
{
    New-Item -ItemType Directory -Path (Join-Path $tempSystem "Rayman Origins.ps3\PS3_GAME") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempSystem "Game X.dec.ps3") -Force | Out-Null

    foreach($f in @("images","videos","manuals"))
    {
        New-Item -ItemType Directory -Path (Join-Path $tempSystem $f) -Force | Out-Null
    }

    Set-Content (Join-Path $tempSystem "images\Rayman Origins-image.jpg") "x"
    Set-Content (Join-Path $tempSystem "videos\Rayman Origins-video.mp4") "x"
    Set-Content (Join-Path $tempSystem "manuals\Rayman Origins-manual.pdf") "x"
    Set-Content (Join-Path $tempSystem "images\Game X.dec-thumb.png") "x"
    Set-Content (Join-Path $tempSystem "images\Gone Game-image.jpg") "x"

    # Lanzadores/acompanantes que el escaner no cuenta como ROM pero que
    # indican que el juego existe: sus medios tampoco son huerfanos
    Set-Content (Join-Path $tempSystem "Port Game.decomp") "x"
    Set-Content (Join-Path $tempSystem "Disc Game.mds") "x"
    Set-Content (Join-Path $tempSystem "images\Port Game-image.jpg") "x"
    Set-Content (Join-Path $tempSystem "images\Disc Game-thumb.png") "x"

    $orphans = @(Find-OrphanedMedia -SystemFolder $tempSystem)

    Assert-Equal 1 $orphans.Count "BUG ps3: solo el medio sin ROM/carpeta-ROM debe ser huerfano"
    Assert-Equal "Gone Game-image.jpg" $orphans[0].FileName "BUG ps3: el huerfano real debe detectarse"
}
finally
{
    Remove-Item -Path $tempSystem -Recurse -Force -ErrorAction SilentlyContinue
}
