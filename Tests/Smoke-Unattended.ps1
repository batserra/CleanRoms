# ============================================================
# CleanROMs - prueba de humo del modo desatendido
#
# Pensado para el CI, pero se puede lanzar a mano:
#   pwsh Tests\Smoke-Unattended.ps1
#
# Copia el programa a una carpeta temporal con una "coleccion"
# minima de RetroBat (dos ROMs duplicadas y su gamelist.xml) y lo
# ejecuta de verdad, como lo haria el Programador de tareas:
#
# 1. main.ps1 -Action Clean -System snes -Yes
#      -> termina solo (sin esperar teclas), codigo de salida 0,
#         una ROM se mueve a _duplicates, la que queda es la fijada
#         en Config\Overrides.json y conserva los datos del usuario
#         del gamelist.xml de la que se movio.
# 2. main.ps1 -Action Clean -System sistema_inexistente -Yes
#      -> codigo de salida 1.
# 3. main.ps1 -Action Undo -Yes
#      -> codigo de salida 0 y las dos ROMs vuelven a su sitio.
#
# Termina con codigo 1 si algo falla.
# ============================================================

$Root = Split-Path $PSScriptRoot -Parent
$pwshExe = (Get-Process -Id $PID).Path

$tempBase = if($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
$work = Join-Path $tempBase ("CleanRoms_Smoke_" + [guid]::NewGuid())
$roms = Join-Path $work "roms"
$program = Join-Path $roms "CleanRoms"
$snes = Join-Path $roms "snes"

$script:failures = 0

function Assert-Smoke
{
    param([bool]$Condition, [string]$Message)

    if($Condition)
    {
        Write-Host "[ OK ] $Message"
    }
    else
    {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        $script:failures++
    }
}

function Invoke-Program
{
    param([string[]]$Arguments, [string]$InputText = "")

    $out = Join-Path $work "out.txt"
    $err = Join-Path $work "err.txt"

    $argList = @("-NoProfile", "-File", ('"{0}"' -f (Join-Path $program "main.ps1"))) + $Arguments

    $startArgs = @{
        FilePath               = $pwshExe
        ArgumentList           = $argList
        RedirectStandardOutput = $out
        RedirectStandardError  = $err
        PassThru               = $true
        NoNewWindow            = $true
    }

    # Respuestas que se le "escriben" al programa (para probar el menu)
    if($InputText -ne "")
    {
        $inFile = Join-Path $work "in.txt"
        [System.IO.File]::WriteAllText($inFile, $InputText)
        $startArgs["RedirectStandardInput"] = $inFile
    }

    $p = Start-Process @startArgs

    if(-not $p.WaitForExit(180000))
    {
        $p.Kill($true)
        return [PSCustomObject]@{ ExitCode = -1; TimedOut = $true; Output = (Get-Content -LiteralPath $out -Raw) }
    }

    $p.WaitForExit()

    return [PSCustomObject]@{
        ExitCode = $p.ExitCode
        TimedOut = $false
        Output   = ((Get-Content -LiteralPath $out -Raw) + (Get-Content -LiteralPath $err -Raw))
    }
}

try
{
    #
    # Programa + coleccion de ejemplo
    #

    New-Item -ItemType Directory -Path $program -Force | Out-Null

    foreach($item in @(Get-ChildItem -LiteralPath $Root -Force))
    {
        if($item.Name -in @(".git", ".github", "Logs", "Resultado", "crash_log.txt", "Tests"))
        {
            continue
        }

        Copy-Item -LiteralPath $item.FullName -Destination $program -Recurse -Force
    }

    # Sin UserSettings.json: primer arranque, como en una instalacion nueva
    Remove-Item -LiteralPath (Join-Path (Join-Path $program "Config") "UserSettings.json") -Force -ErrorAction SilentlyContinue

    New-Item -ItemType Directory -Path $snes -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $snes "Smoke Game (USA).sfc") -Value "rom data"
    Set-Content -LiteralPath (Join-Path $snes "Smoke Game (Europe).sfc") -Value "rom data"

    $gamelist = @"
<?xml version="1.0"?>
<gameList>
	<game>
		<path>./Smoke Game (USA).sfc</path>
		<name>Smoke Game</name>
		<playcount>2</playcount>
	</game>
	<game>
		<path>./Smoke Game (Europe).sfc</path>
		<name>Smoke Game</name>
		<favorite>true</favorite>
		<playcount>7</playcount>
	</game>
</gameList>
"@

    Set-Content -LiteralPath (Join-Path $snes "gamelist.xml") -Value $gamelist

    #
    # Decision manual: la USA se conserva siempre (Config\Overrides.json).
    # Asi el resultado no depende de la puntuacion y se comprueba
    # tambien que el favorito y el playcount de la copia EUROPE (la
    # que se mueve) pasan a la USA.
    #

    Set-Content -LiteralPath (Join-Path (Join-Path $program "Config") "Overrides.json") -Value @'
{
  "Prefer": [ { "System": "snes", "File": "Smoke Game (USA).sfc" } ],
  "Ignore": []
}
'@

    #
    # 1) Limpieza desatendida
    #

    $r1 = Invoke-Program @("-Action", "Clean", "-System", "snes", "-Yes")

    Assert-Smoke (-not $r1.TimedOut) "Clean -Yes termina solo (no se queda esperando una tecla)"
    Assert-Smoke ($r1.ExitCode -eq 0) "Clean -Yes: codigo de salida 0 (fue $($r1.ExitCode))"

    $remaining = @(Get-ChildItem -LiteralPath $snes -Filter *.sfc)
    $moved = @(Get-ChildItem -LiteralPath (Join-Path $roms "_duplicates") -Recurse -Filter *.sfc -ErrorAction SilentlyContinue)

    Assert-Smoke ($remaining.Count -eq 1) "Clean: queda una sola ROM en el sistema (hay $($remaining.Count))"
    Assert-Smoke ($moved.Count -eq 1) "Clean: la otra ROM esta en _duplicates (hay $($moved.Count))"

    if($remaining.Count -eq 1)
    {
        Assert-Smoke ($remaining[0].Name -eq "Smoke Game (USA).sfc") "Overrides: se conserva la ROM fijada en Overrides.json"

        [xml]$doc = Get-Content -LiteralPath (Join-Path $snes "gamelist.xml") -Raw

        $entry = @($doc.gameList.game | Where-Object { $_.path -eq ("./" + $remaining[0].Name) })

        Assert-Smoke ($entry.Count -eq 1 -and $entry[0].playcount -eq "7") "gamelist.xml: la ROM que queda conserva playcount 7"
        Assert-Smoke ($entry.Count -eq 1 -and $entry[0].favorite -eq "true") "gamelist.xml: la ROM que queda conserva el favorito"
    }

    #
    # 1b) Un juego de disco (.cue + .bin) sin duplicado no se toca.
    #     (Antes el .cue y el .bin se veian como copias uno del otro y
    #     se movia uno de los dos.)
    #

    $psx = Join-Path $roms "psx"
    New-Item -ItemType Directory -Path $psx -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $psx "Solo Disc (USA).bin") -Value "disc data"
    Set-Content -LiteralPath (Join-Path $psx "Solo Disc (USA).cue") -Value 'FILE "Solo Disc (USA).bin" BINARY'

    $r1b = Invoke-Program @("-Action", "Clean", "-System", "psx", "-Yes")

    Assert-Smoke ($r1b.ExitCode -eq 0) "Juego .cue + .bin: codigo de salida 0 (fue $($r1b.ExitCode))"
    Assert-Smoke (@(Get-ChildItem -LiteralPath $psx -File).Count -eq 2) "Juego .cue + .bin: sigue entero en su carpeta (no se parte)"

    #
    # 2) Sistema que no existe
    #

    $r2 = Invoke-Program @("-Action", "Clean", "-System", "sistema_inexistente", "-Yes")

    Assert-Smoke (-not $r2.TimedOut) "Sistema inexistente: termina solo"
    Assert-Smoke ($r2.ExitCode -eq 1) "Sistema inexistente: codigo de salida 1 (fue $($r2.ExitCode))"

    #
    # 2b) Purga desatendida: lo recien movido NO es candidato (la edad
    #     cuenta desde que se movio, no desde la fecha del archivo)
    #

    $r2b = Invoke-Program @("-Action", "Purge", "-OlderThanDays", "1", "-Yes")

    Assert-Smoke (-not $r2b.TimedOut) "Purge -Yes termina solo"
    Assert-Smoke ($r2b.ExitCode -eq 0) "Purge -Yes: codigo de salida 0 (fue $($r2b.ExitCode))"
    Assert-Smoke (@(Get-ChildItem -LiteralPath (Join-Path $roms "_duplicates") -Recurse -File -Filter *.sfc).Count -eq 1) "Purge: lo que acaba de moverse sigue en _duplicates (no se borra nada reciente)"

    #
    # 2c) Salir con la opcion 7 del menu: termina a la PRIMERA, sin pedir
    #     "Pulse ENTER para salir" (antes habia que pulsar Enter y luego
    #     otra tecla en el lanzador)
    #

    $settings = [ordered]@{ RetroBatRoot = $roms; Language = "es"; RomPriorityLanguage = "es" }
    $settings | ConvertTo-Json | Set-Content -LiteralPath (Join-Path (Join-Path $program "Config") "UserSettings.json") -Encoding UTF8

    $r2c = Invoke-Program @() "7`n"

    Assert-Smoke (-not $r2c.TimedOut) "Salir con 7: termina solo"
    Assert-Smoke ($r2c.ExitCode -eq 0) "Salir con 7: codigo de salida 0 (fue $($r2c.ExitCode))"
    Assert-Smoke ($r2c.Output -notmatch "ENTER") "Salir con 7: no pide 'Pulse ENTER para salir' (salida: $($r2c.Output.Trim().Split("`n")[-1]))"

    #
    # 3) Deshacer
    #

    $r3 = Invoke-Program @("-Action", "Undo", "-Yes")

    Assert-Smoke (-not $r3.TimedOut) "Undo -Yes termina solo"
    Assert-Smoke ($r3.ExitCode -eq 0) "Undo -Yes: codigo de salida 0 (fue $($r3.ExitCode))"
    Assert-Smoke (@(Get-ChildItem -LiteralPath $snes -Filter *.sfc).Count -eq 2) "Undo: las dos ROMs vuelven a su sitio"
}
catch
{
    Write-Host ("[FAIL] La prueba de humo fallo con una excepcion: {0}" -f $_.Exception.Message) -ForegroundColor Red
    $script:failures++
}
finally
{
    if($script:failures -gt 0 -and (Test-Path -LiteralPath (Join-Path $work "out.txt")))
    {
        Write-Host ""
        Write-Host "---- Ultima salida del programa ----"
        Get-Content -LiteralPath (Join-Path $work "out.txt") -Tail 40
    }

    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""

if($script:failures -gt 0)
{
    Write-Host ("{0} comprobacion(es) fallida(s)." -f $script:failures) -ForegroundColor Red
    exit 1
}

Write-Host "Prueba de humo superada." -ForegroundColor Green
exit 0
