# ============================================================
# PULIDO: Tools\Build-Release.ps1 (lo usa .github\workflows\release.yml)
#
# - El ZIP lleva todo dentro de UNA carpeta con la version
#   (CleanRoms-v<VERSION>\...), asi que no se mezcla con una
#   instalacion anterior.
# - No incluye nada personal ni generado (UserSettings.json,
#   Overrides.json, *.custom.json, Logs, Resultado, crash_log.txt,
#   .git/.github, ManualSrc).
# - Con -Tag que no coincide con VERSION falla SIN crear el ZIP.
# - Se crea el .sha256 y coincide con el ZIP.
# ============================================================

$version = (Get-Content -LiteralPath (Join-Path $Root "VERSION") -TotalCount 1).Trim()
$script = Join-Path (Join-Path $Root "Tools") "Build-Release.ps1"

$tempRoot = New-TestTempFolder
$pwshExe = (Get-Process -Id $PID).Path

# Archivos personales de prueba en el proyecto (se quitan al terminar)
$personal = @(
    (Join-Path $Root "Config/Overrides.json"),
    (Join-Path $Root "Config/Systems.custom.json"),
    (Join-Path $Root "Config/Extensions.custom.json")
)

$createdPersonal = @()

# Cosas AJENAS al proyecto que puede haber en la carpeta (un script propio,
# una carpeta de trabajo con subcarpetas "Logs"/"dist"...): NO deben entrar en
# el ZIP. Se crean aqui y se borran al terminar.
$extraItems = @(
    (Join-Path $Root "Calcular-Extra-Personal.ps1"),
    (Join-Path $Root "notas-personales.txt"),
    (Join-Path $Root "ZzExtraPersonal/Logs/script.ps1"),
    (Join-Path $Root "ZzExtraPersonal/dist/otro.ps1")
)

$createdExtras = @()

try
{
    foreach($p in $personal)
    {
        if(!(Test-Path -LiteralPath $p))
        {
            Set-Content -LiteralPath $p -Value "{}"
            $createdPersonal += $p
        }
    }

    foreach($extra in $extraItems)
    {
        New-Item -ItemType Directory -Path (Split-Path $extra -Parent) -Force | Out-Null
        Set-Content -LiteralPath $extra -Value "ajeno al proyecto"
        $createdExtras += $extra
    }

    $out = Join-Path $tempRoot "dist"

    $output = & $pwshExe -NoProfile -File $script -OutputFolder $out -Tag "v$version" 2>&1

    $zipPath = Join-Path $out "CleanRoms-v$version.zip"

    Assert-Equal $true (Test-Path -LiteralPath $zipPath) "Release: se crea CleanRoms-v$version.zip"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

    try
    {
        $names = @($zip.Entries | ForEach-Object FullName)
    }
    finally
    {
        $zip.Dispose()
    }

    $prefix = "CleanRoms-v$version/"

    Assert-Equal 0 @($names | Where-Object { -not $_.StartsWith($prefix) }).Count "Release: todo va dentro de la carpeta con la version"

    foreach($must in "main.ps1", "VERSION", "Config/Systems.json", "Config/Extensions.json", "Config/Strings.ps1", "Modules/UndoManager.ps1", "README.md", "CleanROMs.bat")
    {
        Assert-Equal $true ($names -contains ($prefix + $must)) "Release: incluye $must"
    }

    foreach($mustNot in "Config/UserSettings.json", "Config/Overrides.json", "Config/Systems.custom.json", "Config/Extensions.custom.json", "crash_log.txt")
    {
        Assert-Equal $false ($names -contains ($prefix + $mustNot)) "Release: NO incluye $mustNot (es personal)"
    }

    $badTop = @($names | Where-Object { $_ -match ('^' + [regex]::Escape($prefix) + '(\.git|\.github|Logs|Resultado|ManualSrc|dist)/') })

    Assert-Equal 0 $badTop.Count "Release: sin .git, .github, Logs, Resultado, ManualSrc ni dist en la raiz ($($badTop -join ', '))"

    $foreign = @($names | Where-Object { $_ -match 'Personal|Calcular-Extra' })

    Assert-Equal 0 $foreign.Count "Release: no entra NADA ajeno al proyecto (scripts propios, carpetas de trabajo...) ($($foreign -join ', '))"

    # Todo lo que entra es un archivo conocido de la raiz o esta dentro de Config, Modules, Tests o Tools
    $knownRoot = @("main.ps1", "CleanROMs.bat", "Run-AllTests.bat", "VERSION", "LICENSE", "README.md", "README_ES.md", "CleanROMs_Manual_EN.pdf", "CleanROMs_Manual_ES.pdf", "CleanROMs_Sistemas_y_formatos.xlsx", "CleanROMs_Systems_and_Formats.xlsx")

    $unexpected = @($names | Where-Object {
        $rel = $_.Substring($prefix.Length)
        $isDirectory = $rel.EndsWith("/") -or $rel -eq ""

        if($isDirectory) { return $false }

        if($rel.Contains("/")) { return -not (@("Config", "Modules", "Tests", "Tools") -contains $rel.Split("/")[0]) }

        return -not ($knownRoot -contains $rel)
    })

    Assert-Equal 0 $unexpected.Count "Release: solo entran archivos del proyecto (lista blanca) ($($unexpected -join ', '))"

    $sha = (Get-Content -LiteralPath "$zipPath.sha256" -Raw).Trim()
    $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()

    Assert-Equal $true ($sha -like "$actual*") "Release: el .sha256 coincide con el ZIP"

    #
    # Etiqueta que no coincide: falla y no crea nada
    #

    $out2 = Join-Path $tempRoot "dist2"
    $null = & $pwshExe -NoProfile -File $script -OutputFolder $out2 -Tag "v0.0.1" 2>&1
    $exit = $LASTEXITCODE

    Assert-Equal $true ($exit -ne 0) "Release: una etiqueta que no coincide con VERSION falla"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $out2 "CleanRoms-v$version.zip")) "Release: con etiqueta incorrecta no se crea el ZIP"
}
finally
{
    foreach($p in $createdPersonal) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }

    foreach($extra in $createdExtras) { Remove-Item -LiteralPath $extra -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath (Join-Path $Root "ZzExtraPersonal") -Recurse -Force -ErrorAction SilentlyContinue

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
