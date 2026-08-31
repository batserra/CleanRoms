# ============================================================
#
# CleanROMs Test Suite
#
# Ejecuta todas las pruebas automáticamente
#
# ============================================================

Clear-Host

$Root = Split-Path $PSScriptRoot -Parent

#----------------------------------------------------------
# Cargar módulos
#----------------------------------------------------------

Import-Module "$Root\Config\Settings.ps1"
Import-Module "$Root\Config\DecisionWeights.ps1"

. "$Root\Config\Settings.ps1"
. "$Root\Config\Strings.ps1"
. "$Root\Config\DecisionWeights.ps1"

. "$Root\Modules\RomParser.ps1"
. "$Root\Modules\RomScanner.ps1"
. "$Root\Modules\TitleNormalizer.ps1"
. "$Root\Modules\Grouper.ps1"
. "$Root\Modules\DecisionEngine.ps1"
. "$Root\Modules\MediaCleaner.ps1"
. "$Root\Modules\AssetMover.ps1"
. "$Root\Modules\Cleaner.ps1"
. "$Root\Modules\Executor.ps1"
. "$Root\Modules\HackOrganizer.ps1"
. "$Root\Modules\UndoManager.ps1"
. "$Root\Modules\Summary.ps1"

. "$PSScriptRoot\TestHelper.ps1"

#----------------------------------------------------------
# Variables
#----------------------------------------------------------

$Global:TestsRun = 0
$Global:TestsPassed = 0
$Global:TestsFailed = 0

#----------------------------------------------------------
# Buscar todos los tests
#----------------------------------------------------------

$tests = Get-ChildItem `
    -Path $PSScriptRoot `
    -Recurse `
    -Filter *.ps1 |

    Where-Object {

		$_.Name -like "*_Test.ps1"

    }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "          CleanROMs Test Suite"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

foreach($test in $tests)
{
    Write-Host ""
    Write-Host ("Ejecutando: {0}" -f $test.Name) -ForegroundColor Yellow

    & $test.FullName
}

#----------------------------------------------------------
# Resumen
#----------------------------------------------------------

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "RESULTADO FINAL"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host ("Tests ejecutados : {0}" -f $Global:TestsRun)
Write-Host ("Correctos        : {0}" -f $Global:TestsPassed)

if($Global:TestsFailed -eq 0)
{
    Write-Host ("Fallidos         : {0}" -f $Global:TestsFailed) -ForegroundColor Green
}
else
{
    Write-Host ("Fallidos         : {0}" -f $Global:TestsFailed) -ForegroundColor Red
}

Write-Host ""

if($Global:TestsFailed -eq 0)
{
    Write-Host "✔ Todos los tests superados." -ForegroundColor Green
}
else
{
    Write-Host "✘ Existen pruebas fallidas." -ForegroundColor Red
}

Write-Host ""