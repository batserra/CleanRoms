# ============================================================
# Flujo completo con juegos de varios ficheros:
# escanear -> agrupar -> plan -> ejecutar -> deshacer.
#
# Una carpeta "psx" con:
# - Crash en USA y en Europe, cada uno .cue + .bin  (duplicados)
# - Solo (USA)  .cue + .bin                         (sin duplicado)
# - FF7 (USA)   .m3u + 3 discos .chd                (sin duplicado)
# - Spyro en USA y en Europe, 2 discos .chd cada uno (duplicados)
#
# Antes: un .cue y su .bin se trataban como duplicados entre si, el
# .m3u de FF7 'ganaba' a sus propios discos (que se movian) y los
# discos de Spyro se mezclaban. Ahora:
# - Solo y FF7 no se tocan.
# - De Crash y de Spyro se mueve UN juego completo (todos sus
#   ficheros) y se conserva el otro completo.
# - Deshacer devuelve todo a su sitio, con el mismo contenido.
# - Si algun fichero chocaria en el destino, el juego NO se parte:
#   se queda entero donde esta.
# ============================================================

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "psx"
$dupFolder = Join-Path (Join-Path $tempRoot "_duplicates") "psx"
New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    PreviewOnly   = $Global:Settings.PreviewOnly
    AutoConfirm   = $Global:AutoConfirm
    Root          = $Global:RetroBatRoot
    Dup           = $Global:DuplicatesFolder
}

$Global:OverridesPath = (Join-Path $tempRoot "no-overrides.json")
$Global:Settings.Language = "es"
$Global:Settings.PreviewOnly = $false
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"

function New-Game
{
    param([string]$Name, [string]$Content)

    Set-Content -LiteralPath (Join-Path $systemFolder "$Name.bin") -Value $Content
    Set-Content -LiteralPath (Join-Path $systemFolder "$Name.cue") -Value "FILE `"$Name.bin`" BINARY`n  TRACK 01 MODE2/2352`n    INDEX 01 00:00:00"
}

function Get-Actions
{
    $roms = @(Get-RomsFromFolder -Path $systemFolder -SystemName "psx" 6>$null)
    $roms = @(Update-NormalizedTitles $roms)
    $roms = @(Merge-RomSets $roms)
    $groups = @(Group-Roms -Roms $roms -SystemName "psx")

    return [PSCustomObject]@{
        Groups  = $groups
        Actions = @(Invoke-CleanPreview -Groups $groups -Root $tempRoot 6>$null 3>$null)
    }
}

function Get-Leaves
{
    param($Actions, [string]$Type, [string]$Like)

    return @($Actions | Where-Object { $_.Action -eq $Type -and (Split-Path $_.Source -Leaf) -like $Like } |
        ForEach-Object { Split-Path $_.Source -Leaf } | Sort-Object)
}

try
{
    New-Game "Crash (USA)" "crash usa data"
    New-Game "Crash (Europe)" "crash europe data"
    New-Game "Solo (USA)" "solo data"

    Set-Content -LiteralPath (Join-Path $systemFolder "FF7 (USA).m3u") -Value "FF7 (USA) (Disc 1).chd`nFF7 (USA) (Disc 2).chd`nFF7 (USA) (Disc 3).chd"
    1..3 | ForEach-Object { Set-Content -LiteralPath (Join-Path $systemFolder "FF7 (USA) (Disc $_).chd") -Value "ff7 disc $_" }

    foreach($region in "USA", "Europe")
    {
        1..2 | ForEach-Object { Set-Content -LiteralPath (Join-Path $systemFolder "Spyro ($region) (Disc $_).chd") -Value "spyro $region disc $_" }
    }

    $result = Get-Actions
    $actions = $result.Actions

    Assert-Equal 2 $result.Groups.Count "Plan: solo hay dos grupos de duplicados (Crash y Spyro)"

    Assert-Equal 0 @($actions | Where-Object { (Split-Path $_.Source -Leaf) -like "Solo*" }).Count "Plan: 'Solo (USA)' (.cue + .bin) no genera ninguna accion"
    Assert-Equal 0 @($actions | Where-Object { (Split-Path $_.Source -Leaf) -like "FF7*" }).Count "Plan: FF7 (.m3u + 3 discos) no genera ninguna accion"

    #
    # Crash: un juego entero se conserva y el otro entero se mueve
    #

    $crashKeep = @(Get-Leaves $actions "KEEP" "Crash*")
    $crashMove = @(Get-Leaves $actions "MOVE" "Crash*")

    Assert-Equal 2 $crashKeep.Count "Crash: se conservan 2 ficheros (.cue + .bin)"
    Assert-Equal 2 $crashMove.Count "Crash: se mueven 2 ficheros (.cue + .bin)"
    Assert-Equal 1 @($crashKeep | ForEach-Object { if($_ -like "*USA*") { "USA" } else { "Europe" } } | Select-Object -Unique).Count "Crash: los ficheros conservados son de UNA sola region"
    Assert-Equal 1 @($crashMove | ForEach-Object { if($_ -like "*USA*") { "USA" } else { "Europe" } } | Select-Object -Unique).Count "Crash: los ficheros movidos son de UNA sola region"
    Assert-Equal 2 @($crashKeep + $crashMove | ForEach-Object { [System.IO.Path]::GetExtension($_) } | Where-Object { $_ -eq ".cue" }).Count "Crash: cada juego aporta su .cue"

    #
    # Spyro: discos enteros
    #

    $spyroMove = @(Get-Leaves $actions "MOVE" "Spyro*")
    $spyroKeep = @(Get-Leaves $actions "KEEP" "Spyro*")

    Assert-Equal 2 $spyroMove.Count "Spyro: se mueven los 2 discos del juego perdedor"
    Assert-Equal 2 $spyroKeep.Count "Spyro: se conservan los 2 discos del juego ganador"
    Assert-Equal 1 @($spyroMove | ForEach-Object { if($_ -like "*USA*") { "USA" } else { "Europe" } } | Select-Object -Unique).Count "Spyro: los discos movidos son de UNA sola region (no se mezclan)"

    #
    # Ejecutar y deshacer
    #

    $before = @{}
    Get-ChildItem -LiteralPath $systemFolder -File | ForEach-Object { $before[$_.Name] = (Get-Content -LiteralPath $_.FullName -Raw) }

    $plan = Build-CleanPlan $actions

    $resultFolder = Join-Path $tempRoot "Resultado"
    New-Item -ItemType Directory -Path $resultFolder -Force | Out-Null
    $plan.Actions | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $resultFolder "CleanPlan.json") -Encoding UTF8

    Invoke-CleanExecute $plan 6>$null 3>$null

    $remaining = @(Get-ChildItem -LiteralPath $systemFolder -File | ForEach-Object Name | Sort-Object)
    $moved = @(Get-ChildItem -LiteralPath $dupFolder -File | ForEach-Object Name | Sort-Object)

    Assert-Equal 4 $moved.Count "Ejecutar: 4 ficheros en _duplicates\psx (2 de Crash + 2 de Spyro)"
    Assert-Equal $true (@($remaining | Where-Object { $_ -like "Solo*" }).Count -eq 2) "Ejecutar: 'Solo' sigue entero"
    Assert-Equal $true (@($remaining | Where-Object { $_ -like "FF7*" }).Count -eq 4) "Ejecutar: FF7 sigue entero (.m3u + 3 discos)"
    Assert-Equal 2 @($remaining | Where-Object { $_ -like "Crash*" }).Count "Ejecutar: queda un Crash completo (.cue + .bin)"
    Assert-Equal 2 @($remaining | Where-Object { $_ -like "Spyro*" }).Count "Ejecutar: queda un Spyro completo (2 discos)"

    $null = Invoke-UndoLastPlan -Root $tempRoot 6>$null

    $after = @{}
    Get-ChildItem -LiteralPath $systemFolder -File | ForEach-Object { $after[$_.Name] = (Get-Content -LiteralPath $_.FullName -Raw) }

    Assert-Equal $before.Count $after.Count "Deshacer: vuelven todos los ficheros a la carpeta del sistema"
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $dupFolder -File -ErrorAction SilentlyContinue).Count "Deshacer: _duplicates\psx queda vacia"

    $sameContent = $true
    foreach($name in $before.Keys) { if($after[$name] -ne $before[$name]) { $sameContent = $false } }

    Assert-Equal $true $sameContent "Deshacer: el contenido de cada fichero no cambia"

    #
    # Choque en el destino: el juego no se parte
    #

    New-Item -ItemType Directory -Path $dupFolder -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dupFolder "Crash (USA).bin") -Value "ya estaba"
    Set-Content -LiteralPath (Join-Path $dupFolder "Crash (Europe).bin") -Value "ya estaba"

    $result = Get-Actions

    Assert-Equal 0 @($result.Actions | Where-Object { $_.Action -eq "MOVE" -and (Split-Path $_.Source -Leaf) -like "Crash*" }).Count "Choque: el juego que perderia no se mueve NI A MEDIAS (ni .cue ni .bin)"
    Assert-Equal 2 @($result.Actions | Where-Object { $_.Action -eq "MOVE" -and (Split-Path $_.Source -Leaf) -like "Spyro*" }).Count "Choque: los demas juegos se procesan con normalidad"
}
finally
{
    $Global:OverridesPath = $saved.OverridesPath
    $Global:Settings.Language = $saved.Language
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup
    $Global:OverrideContextSystem = ""

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
