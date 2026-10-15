# ============================================================
# CleanROMs
#
# Tools\Build-Release.ps1
#
# Crea el ZIP de una version para publicar:
#
#   pwsh -File Tools\Build-Release.ps1
#
# Genera dist\CleanRoms-v<VERSION>.zip (y su .sha256). Lo usa tambien
# el flujo de GitHub .github\workflows\release.yml al subir una
# etiqueta "v<VERSION>".
#
# - El ZIP lleva TODO dentro de UNA carpeta con la version
#   (CleanRoms-v2.8\...). Asi, descomprimirlo encima de una instalacion
#   anterior no mezcla archivos viejos con nuevos (el problema de
#   siempre): se descomprime aparte y se copia lo que se quiera.
# - NO incluye nada personal ni generado: Config\UserSettings.json,
#   Config\Overrides.json, los *.custom.json, Logs, Resultado,
#   crash_log.txt, ni la carpeta .git/.github ni ManualSrc.
# - Con -Tag se comprueba que la etiqueta coincide con VERSION
#   (v2.8 <-> 2.8); si no, falla sin crear nada.
# ============================================================

param(
    # Carpeta donde se deja el ZIP (por defecto dist\ dentro del proyecto)
    [string]$OutputFolder = "",

    # Etiqueta de GitHub a comprobar contra VERSION (p.ej. "v2.8")
    [string]$Tag = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent

$versionFile = Join-Path $root "VERSION"

if(!(Test-Path -LiteralPath $versionFile))
{
    throw "Falta el archivo VERSION / Missing VERSION file: $versionFile"
}

$version = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()

if($version -notmatch '^\d+(\.\d+){1,3}$')
{
    throw "VERSION no tiene un formato valido / VERSION has an invalid format: '$version'"
}

if($Tag -ne "" -and $Tag -ne "v$version")
{
    throw "La etiqueta '$Tag' no coincide con VERSION ($version): se esperaba 'v$version' / the tag '$Tag' does not match VERSION ($version): expected 'v$version'"
}

if($OutputFolder -eq "")
{
    $OutputFolder = Join-Path $root "dist"
}

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$zipPath = Join-Path $OutputFolder "CleanRoms-v$version.zip"

if(Test-Path -LiteralPath $zipPath)
{
    Remove-Item -LiteralPath $zipPath -Force
}

# Carpetas de primer nivel que no se incluyen
$excludedFolders = @(".git", ".github", "dist", "Logs", "Resultado", "ManualSrc")

# Archivos personales o generados (ruta relativa con /)
$excludedFiles = @(
    "crash_log.txt",
    "Config/UserSettings.json",
    "Config/Overrides.json"
)

$excludedPatterns = @("Config/*.custom.json")

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\', '/')

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
$count = 0

try
{
    foreach($file in (Get-ChildItem -LiteralPath $root -Recurse -File -Force | Sort-Object FullName))
    {
        $relative = [System.IO.Path]::GetRelativePath($rootFull, $file.FullName).Replace('\', '/')
        $topFolder = ($relative -split '/')[0]

        if($relative.Contains('/') -and $excludedFolders -contains $topFolder)
        {
            continue
        }

        if($excludedFiles -contains $relative)
        {
            continue
        }

        $skip = $false

        foreach($pattern in $excludedPatterns)
        {
            if($relative -like $pattern)
            {
                $skip = $true
            }
        }

        if($skip)
        {
            continue
        }

        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip,
            $file.FullName,
            "CleanRoms-v$version/$relative",
            [System.IO.Compression.CompressionLevel]::Optimal
        )

        $count++
    }
}
finally
{
    $zip.Dispose()
}

$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$zipPath.sha256" -Value ("$hash  " + (Split-Path $zipPath -Leaf)) -Encoding ASCII

Write-Host "Version : $version"
Write-Host "Archivos: $count"
Write-Host "ZIP     : $zipPath"
Write-Host "SHA256  : $hash"
