# ============================================================
# MEJORA: decisiones manuales persistentes (Config\Overrides.json).
#
# Este test cubre la lectura, la validacion y la busqueda de
# coincidencias, y el guardado de "Prefer":
# - Sin archivo, vacio o corrupto: sin overrides y SIN excepcion.
# - Las entradas incompletas se descartan (con aviso).
# - Ignore por titulo (natural o normalizado) y por archivo.
# - Prefer por archivo, sin distinguir mayusculas.
# - "System" vacio o "*" vale para todos; otro sistema no coincide.
# - Add-OverridePrefer crea el archivo, no duplica, conserva lo
#   que ya habia y NO sobrescribe un archivo corrupto.
# ============================================================

$tempRoot = New-TestTempFolder
$ovFile = Join-Path $tempRoot "Overrides.json"
$originalPath = $Global:OverridesPath
$originalLanguage = $Global:Settings.Language

$Global:OverridesPath = $ovFile
$Global:Settings.Language = "es"

function New-FakeGroup
{
    param([string]$System, [string]$Name, [string[]]$Files)

    $folder = Join-Path $tempRoot $System

    return [PSCustomObject]@{
        Name   = $Name
        System = $System
        Roms   = @($Files | ForEach-Object { [PSCustomObject]@{ FullPath = (Join-Path $folder $_) } })
    }
}

try
{
    #
    # Lectura
    #

    $o = Get-Overrides
    Assert-Equal 0 (@($o.Prefer).Count + @($o.Ignore).Count) "Overrides: sin archivo no hay decisiones manuales"

    Set-Content -LiteralPath $ovFile -Value ""
    $o = Get-Overrides
    Assert-Equal 0 (@($o.Prefer).Count + @($o.Ignore).Count) "Overrides: archivo vacio no da error ni decisiones"

    Set-Content -LiteralPath $ovFile -Value "{ esto no es json"

    $threw = $false
    try { $o = Get-Overrides 3>$null } catch { $threw = $true }

    Assert-Equal $false $threw "Overrides: archivo corrupto no lanza excepcion"
    Assert-Equal 0 (@($o.Prefer).Count + @($o.Ignore).Count) "Overrides: archivo corrupto equivale a sin decisiones"

    Set-Content -LiteralPath $ovFile -Value @'
{
  "Prefer": [
    { "System": "snes", "File": "Game (Europe).sfc" },
    { "System": "snes" },
    { "File": "Otro (USA).sfc" }
  ],
  "Ignore": [
    { "System": "snes", "Title": "Super Game" },
    { "System": "nes",  "File": "Zelda II (USA).nes" },
    { "System": "nes" }
  ]
}
'@

    $o = Get-Overrides 3>$null

    Assert-Equal 2 @($o.Prefer).Count "Overrides: 2 Prefer validos (el que no tiene File se descarta)"
    Assert-Equal 2 @($o.Ignore).Count "Overrides: 2 Ignore validos (el que no tiene Title ni File se descarta)"

    #
    # Coincidencias
    #

    $g = New-FakeGroup "snes" "game" @("Game (USA).sfc", "Game (Europe).sfc")
    $r = Get-GroupOverride -Group $g -Overrides $o

    Assert-Equal $false $r.Ignored "Get-GroupOverride: grupo sin Ignore no se ignora"
    Assert-Equal (Join-Path (Join-Path $tempRoot "snes") "Game (Europe).sfc") $r.PreferredPath "Get-GroupOverride: Prefer elige la ROM indicada"

    $gOtherSystem = New-FakeGroup "nes" "game" @("Game (USA).nes", "Game (Europe).nes")
    $o2 = Get-Overrides 3>$null
    $r = Get-GroupOverride -Group $gOtherSystem -Overrides $o2

    Assert-Equal "" $r.PreferredPath "Get-GroupOverride: un Prefer de snes no afecta a otro sistema"

    $gUpper = New-FakeGroup "SNES" "game" @("game (europe).SFC", "Game (USA).sfc")
    $r = Get-GroupOverride -Group $gUpper -Overrides $o

    Assert-Equal (Join-Path (Join-Path $tempRoot "SNES") "game (europe).SFC") $r.PreferredPath "Get-GroupOverride: sistema y archivo no distinguen mayusculas"

    $gAnySystem = New-FakeGroup "megadrive" "otro" @("Otro (USA).sfc", "Otro (Europe).sfc")
    $r = Get-GroupOverride -Group $gAnySystem -Overrides $o

    Assert-Equal (Join-Path (Join-Path $tempRoot "megadrive") "Otro (USA).sfc") $r.PreferredPath "Get-GroupOverride: un Prefer sin System vale para todos los sistemas"

    $gIgnoreTitle = New-FakeGroup "snes" "super game" @("Super Game (USA).sfc", "Super Game (Europe).sfc")
    $r = Get-GroupOverride -Group $gIgnoreTitle -Overrides $o

    Assert-Equal $true $r.Ignored "Get-GroupOverride: Ignore por titulo (escrito con mayusculas) ignora el grupo"
    Assert-Equal $false ($r.IgnoreSource -eq "") "Get-GroupOverride: indica que entrada ignora el grupo"

    $gIgnoreFile = New-FakeGroup "nes" "zelda ii" @("Zelda II (USA).nes", "Zelda II (Europe).nes")
    $r = Get-GroupOverride -Group $gIgnoreFile -Overrides $o

    Assert-Equal $true $r.Ignored "Get-GroupOverride: Ignore por archivo ignora el grupo que lo contiene"

    $gIgnoreOtherSystem = New-FakeGroup "snes" "zelda ii" @("Zelda II (USA).nes", "Zelda II (Europe).nes")
    $r = Get-GroupOverride -Group $gIgnoreOtherSystem -Overrides $o

    Assert-Equal $false $r.Ignored "Get-GroupOverride: el Ignore de nes no afecta a snes"

    #
    # Guardado
    #

    Remove-Item -LiteralPath $ovFile -Force

    Assert-Equal $true (Add-OverridePrefer -System "snes" -File "Game (Europe).sfc") "Add-OverridePrefer: crea el archivo si no existe"

    $o = Get-Overrides
    Assert-Equal 1 @($o.Prefer).Count "Add-OverridePrefer: queda un Prefer"
    Assert-Equal "snes" $o.Prefer[0].System "Add-OverridePrefer: guarda el sistema"
    Assert-Equal "Game (Europe).sfc" $o.Prefer[0].File "Add-OverridePrefer: guarda el archivo"

    $null = Add-OverridePrefer -System "snes" -File "game (europe).SFC"
    Assert-Equal 1 @((Get-Overrides).Prefer).Count "Add-OverridePrefer: no duplica la misma decision"

    Set-Content -LiteralPath $ovFile -Value '{ "Prefer": [], "Ignore": [ { "System": "nes", "Title": "Zelda" } ] }'
    $null = Add-OverridePrefer -System "nes" -File "Mario (USA).nes"
    $o = Get-Overrides

    Assert-Equal 1 @($o.Prefer).Count "Add-OverridePrefer: anade el Prefer nuevo"
    Assert-Equal 1 @($o.Ignore).Count "Add-OverridePrefer: conserva los Ignore que ya habia"

    Set-Content -LiteralPath $ovFile -Value "{ roto"
    $before = Get-Content -LiteralPath $ovFile -Raw

    $saved = Add-OverridePrefer -System "nes" -File "X.nes" 3>$null

    Assert-Equal $false $saved "Add-OverridePrefer: no guarda si el archivo existente esta corrupto"
    Assert-Equal $before (Get-Content -LiteralPath $ovFile -Raw) "Add-OverridePrefer: no sobrescribe un archivo corrupto (no pierde lo escrito a mano)"
}
finally
{
    $Global:OverridesPath = $originalPath
    $Global:Settings.Language = $originalLanguage

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
