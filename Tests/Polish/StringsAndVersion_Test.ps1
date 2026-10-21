# ============================================================
# PULIDO:
# - La version vive en UN solo sitio (el archivo VERSION): ya no
#   se repite "v2.7" en cada cabecera ni en el banner, el log o los
#   planes.
# - Los textos que ve el usuario salen de Strings.ps1 (ES/EN), no
#   de literales en el codigo ("Ejecutando plan", "Analizando
#   ROMs", el mensaje de error inesperado...).
# - Comprobacion estatica: TODA clave T "..." que usa el codigo
#   existe en espanol Y en ingles, y los dos idiomas tienen las
#   mismas claves (una clave que falte se muestra vacia).
# - El escaner ignora las carpetas de la lista (images...) tambien
#   cuando la ruta lleva barras "/" (Linux) y no solo "\".
# ============================================================

$versionFile = Join-Path $Root "VERSION"
$expectedVersion = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()

Assert-Equal $true ($expectedVersion -match '^\d+(\.\d+)+$') "Version: VERSION tiene formato numerico ($expectedVersion)"
Assert-Equal $expectedVersion $Global:AppVersion "Version: AppVersion se lee de VERSION"

$Global:Settings.Language = "es"
Assert-Equal $true ((T "banner.title" $Global:AppVersion) -like "*v$expectedVersion*") "Version: el banner del menu muestra la version"

#
# Los README y el manual muestran la version actual (antes se quedaron
# en 2.7 cuando el programa ya era 2.8)
#

foreach($readme in "README.md", "README_ES.md")
{
    $head = @(Get-Content -LiteralPath (Join-Path $Root $readme) -TotalCount 6)

    # La primera linea es el selector de idioma ("[English](README.md) | [Español](README_ES.md)");
    # el titulo viene justo despues
    $title = @($head | Where-Object { $_ -like "CleanROMs v*" })[0]

    Assert-Equal "CleanROMs v$expectedVersion" $title "Version: el titulo de $readme es 'CleanROMs v$expectedVersion'"
    Assert-Equal "[English](README.md) | [Español](README_ES.md)" $head[0].Trim() "Idioma: la primera linea de $readme es el selector English | Español"
}

foreach($manual in @(@("manual_en.json", "Version"), @("manual_es.json", "Versión")))
{
    $manualPath = Join-Path (Join-Path $Root "ManualSrc") $manual[0]

    # ManualSrc es solo para regenerar los PDF: puede no estar (se puede borrar)
    if(Test-Path -LiteralPath $manualPath)
    {
        $json = Get-Content -LiteralPath $manualPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $subtitle = @($json | Where-Object { $_.type -eq "subtitle" })[0]
        $subtitleText = (@($subtitle.runs | ForEach-Object { $_[1] }) -join "")

        Assert-Equal $true ($subtitleText -like "*$($manual[1]) $expectedVersion*") "Version: la portada de $($manual[0]) dice '$($manual[1]) $expectedVersion' (dice: $subtitleText)"
    }
}

#
# Ninguna version "pegada" en el codigo
#

# Solo el codigo del programa: main.ps1 y las carpetas Modules y Config.
# La carpeta Tools NO se revisa: es donde el usuario puede guardar sus propias
# herramientas (p.ej. Calcular-MD5-Excel.ps1), con sus propios textos.
$codeFiles = @(
    Get-ChildItem -LiteralPath $Root -Recurse -File -Filter *.ps1 |
        Where-Object {
            $relative = [System.IO.Path]::GetRelativePath($Root, $_.FullName)
            $top = ($relative -split '[\\/]')[0]

            ($relative -eq "main.ps1") -or (@("Modules", "Config") -contains $top)
        }
)

$hardcoded = @()

foreach($file in $codeFiles)
{
    foreach($line in (Get-Content -LiteralPath $file.FullName))
    {
        if($line -match 'CleanROMs v\d+\.\d+' -or $line -match 'CLEAN ROMS v\d+\.\d+')
        {
            $hardcoded += "$($file.Name): $($line.Trim())"
        }
    }
}

Assert-Equal 0 $hardcoded.Count "Version: no queda ningun 'CleanROMs v<numero>' fijo en el codigo ($($hardcoded -join ' | '))"

#
# Sin literales de usuario en el codigo
#

$literal = @()

foreach($file in $codeFiles)
{
    $text = Get-Content -LiteralPath $file.FullName -Raw

    foreach($m in [regex]::Matches($text, '-Activity\s+"[^"]+"|-Status\s+"[^"]+"|Write-Host\s+"Se ha producido|throw\s+"(La carpeta no existe|Acción|El plan contiene)'))
    {
        $literal += "$($file.Name): $($m.Value)"
    }
}

Assert-Equal 0 $literal.Count "Textos: no quedan literales de usuario en el codigo ($($literal -join ' | '))"

#
# Todas las claves T "..." existen en los dos idiomas
#

$esKeys = @($Global:Strings["es"].Keys)
$enKeys = @($Global:Strings["en"].Keys)

$onlyEs = @($esKeys | Where-Object { $enKeys -notcontains $_ })
$onlyEn = @($enKeys | Where-Object { $esKeys -notcontains $_ })

Assert-Equal 0 $onlyEs.Count "Claves: ninguna clave esta solo en espanol ($($onlyEs -join ', '))"
Assert-Equal 0 $onlyEn.Count "Claves: ninguna clave esta solo en ingles ($($onlyEn -join ', '))"

$used = @{}

foreach($file in (@($codeFiles) | Where-Object { $_.Name -ne "Strings.ps1" }))
{
    $text = Get-Content -LiteralPath $file.FullName -Raw

    foreach($m in [regex]::Matches($text, '\bT\s+"([A-Za-z0-9_.]+)"'))
    {
        $used[$m.Groups[1].Value] = $file.Name
    }
}

$missing = @($used.Keys | Where-Object { $esKeys -notcontains $_ -or $enKeys -notcontains $_ } | Sort-Object)

Assert-Equal $true ($used.Count -gt 150) "Claves: se han encontrado las claves usadas por el codigo ($($used.Count))"
Assert-Equal 0 $missing.Count "Claves: todas las que usa el codigo existen en ES y EN ($($missing -join ', '))"

#
# El escaner ignora carpetas con "/" y con "\"
#

$tempRoot = New-TestTempFolder

try
{
    $sys = Join-Path $tempRoot "snes"
    New-Item -ItemType Directory -Path (Join-Path $sys "images") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sys "sub") -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $sys "Game (USA).sfc") -Value "x"
    Set-Content -LiteralPath (Join-Path $sys "images/Fake (USA).sfc") -Value "x"
    Set-Content -LiteralPath (Join-Path $sys "sub/Other (USA).sfc") -Value "x"

    $found = @(Get-RomFiles -Folder $sys | ForEach-Object Name | Sort-Object)

    Assert-Equal "Game (USA).sfc,Other (USA).sfc" ($found -join ",") "Escaner: ignora la carpeta images y respeta las subcarpetas normales"
}
finally
{
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
