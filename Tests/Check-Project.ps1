# ============================================================
# CleanROMs - comprobaciones estaticas del proyecto
#
# Pensado para el CI (.github\workflows\tests.yml), pero se puede
# lanzar a mano:   pwsh Tests\Check-Project.ps1
#
# Comprueba:
# 1. Que todos los .ps1 tienen sintaxis valida.
# 2. Que cada archivo cargado con "$Root\..." o "$PSScriptRoot\..."
#    existe con la MAYUSCULA/minuscula EXACTA. En Windows da igual,
#    pero en Linux "Logger.ps1" y "logger.ps1" son archivos
#    distintos (fallo real que ya se dio con main.ps1).
# 3. Que todos los .json de Config\ son JSON valido.
#
# Termina con codigo 1 si encuentra algun problema.
# ============================================================

$Root = Split-Path $PSScriptRoot -Parent

$problems = New-Object System.Collections.Generic.List[string]

function Resolve-ExactCasePath {

    param([string]$BaseFolder, [string]$RelativePath)

    $current = $BaseFolder

    foreach($segment in ($RelativePath -split '[\\/]'))
    {
        if($segment -eq "" -or $segment -eq ".")
        {
            continue
        }

        if($segment -eq "..")
        {
            $current = Split-Path $current -Parent
            continue
        }

        $child = Get-ChildItem -LiteralPath $current -Force |
            Where-Object { $_.Name -ceq $segment } |
            Select-Object -First 1

        if($null -eq $child)
        {
            return $null
        }

        $current = $child.FullName
    }

    return $current
}

$files = @(
    Get-ChildItem -LiteralPath $Root -Recurse -File -Filter *.ps1 |
        Where-Object { $_.FullName -notmatch '[\\/](\.git|Logs|Resultado)[\\/]' }
)

foreach($file in $files)
{
    $relName = [System.IO.Path]::GetRelativePath($Root, $file.FullName)

    #
    # 1) Sintaxis
    #

    $tokens = $null
    $parseErrors = $null

    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)

    foreach($e in @($parseErrors))
    {
        $problems.Add(("{0}:{1} sintaxis: {2}" -f $relName, $e.Extent.StartLineNumber, $e.Message))
    }

    #
    # 2) Rutas cargadas con $Root / $PSScriptRoot
    #

    $lineNumber = 0

    foreach($line in (Get-Content -LiteralPath $file.FullName))
    {
        $lineNumber++

        foreach($m in [regex]::Matches($line, '"\$(Root|PSScriptRoot)\\([^"]+\.(?:ps1|json))"'))
        {
            $base = if($m.Groups[1].Value -eq "Root") { $Root } else { $file.DirectoryName }

            if($null -eq (Resolve-ExactCasePath -BaseFolder $base -RelativePath $m.Groups[2].Value))
            {
                $problems.Add(("{0}:{1} no existe (o difiere en mayusculas/minusculas): {2}" -f $relName, $lineNumber, $m.Groups[2].Value))
            }
        }
    }
}

#
# 3) JSON
#

foreach($json in @(Get-ChildItem -LiteralPath (Join-Path $Root "Config") -Filter *.json -File))
{
    try
    {
        Get-Content -LiteralPath $json.FullName -Raw | ConvertFrom-Json | Out-Null
    }
    catch
    {
        $problems.Add(("Config/{0} JSON invalido: {1}" -f $json.Name, $_.Exception.Message))
    }
}

Write-Host ("Archivos .ps1 revisados: {0}" -f $files.Count)

if($problems.Count -gt 0)
{
    Write-Host ""

    foreach($p in $problems)
    {
        Write-Host ("[PROBLEMA] {0}" -f $p) -ForegroundColor Red
    }

    Write-Host ""
    Write-Host ("{0} problema(s) encontrado(s)." -f $problems.Count) -ForegroundColor Red
    exit 1
}

Write-Host "Proyecto correcto: sintaxis, rutas y JSON." -ForegroundColor Green
exit 0
