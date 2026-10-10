# ============================================================
# MEJORA: un fallo puntual al restaurar un archivo (bloqueado por
# otro programa, sin permisos...) ya no aborta todo el "Deshacer".
#
# Antes, la excepcion de Move-Item subia hasta main.ps1 y el resto
# de movimientos del plan se quedaban sin deshacer. Ahora se avisa,
# se cuenta en $Global:ActionErrorCount (codigo de salida 2 en modo
# desatendido) y se continua con el siguiente.
#
# El test simula el fallo sobrescribiendo Move-Item para que falle
# con UN archivo concreto.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
$targetFolder = Join-Path (Join-Path $tempRoot "_duplicates") "snes"

New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null
New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null

$errorCountWasSet = Test-Path Variable:\Global:ActionErrorCount
$originalErrorCount = if($errorCountWasSet) { $Global:ActionErrorCount } else { 0 }
$originalAutoConfirm = $Global:AutoConfirm
$originalLanguage = $Global:Settings.Language

$Global:AutoConfirm = $true
$Global:Settings.Language = "es"
$Global:ActionErrorCount = 0

function global:Move-Item
{
    param(
        [string]$LiteralPath,
        [string]$Destination
    )

    if($LiteralPath -like "*Bloqueada*")
    {
        throw "El proceso no puede obtener acceso al archivo (simulado)"
    }

    Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
}

try
{
    $names = @("Bloqueada (USA).sfc", "Normal (USA).sfc")

    $actions = @()

    foreach($name in $names)
    {
        Set-Content -LiteralPath (Join-Path $targetFolder $name) -Value "x"

        $actions += [PSCustomObject]@{
            Action          = "MOVE"
            Source          = (Join-Path $systemFolder $name)
            Target          = $targetFolder
            AssociatedFiles = @()
        }
    }

    $resultFolder = Join-Path $tempRoot "Resultado"
    New-Item -ItemType Directory -Path $resultFolder -Force | Out-Null

    $actions | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $resultFolder "CleanPlan.json") -Encoding UTF8

    $threw = $false

    try
    {
        $null = Invoke-UndoLastPlan -Root $tempRoot 6>$null 3>$null
    }
    catch
    {
        $threw = $true
    }

    Assert-Equal $false $threw "Deshacer: un archivo que no se puede mover no lanza excepcion"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $systemFolder "Normal (USA).sfc")) "Deshacer: el resto de archivos SI se restauran"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $systemFolder "Bloqueada (USA).sfc")) "Deshacer: el archivo bloqueado se queda donde estaba"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $targetFolder "Bloqueada (USA).sfc")) "Deshacer: el archivo bloqueado sigue integro en su destino"
    Assert-Equal 1 $Global:ActionErrorCount "Deshacer: el fallo se cuenta en ActionErrorCount (codigo de salida 2)"
}
finally
{
    Remove-Item Function:\Move-Item -ErrorAction SilentlyContinue

    $Global:AutoConfirm = $originalAutoConfirm
    $Global:Settings.Language = $originalLanguage

    if($errorCountWasSet)
    {
        $Global:ActionErrorCount = $originalErrorCount
    }
    else
    {
        Remove-Variable -Name ActionErrorCount -Scope Global -ErrorAction SilentlyContinue
    }

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
