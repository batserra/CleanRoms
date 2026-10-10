# ============================================================
#
# CleanROMs Test Suite
#
# Ejecuta todas las pruebas automáticamente
#
# ============================================================

# En CI (sin consola real) Clear-Host puede fallar: no es motivo para parar
try { Clear-Host } catch { }

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
. "$Root\Modules\GamelistManager.ps1"
. "$Root\Modules\Overrides.ps1"
. "$Root\Modules\RomSets.ps1"
. "$Root\Modules\HashCache.ps1"
. "$Root\Modules\DuplicatesPurger.ps1"

# Los tests no deben tocar la cache de hashes real del usuario
# (Resultado\HashCache.tsv): usan una propia, temporal.
$Global:HashCachePath = Join-Path ([System.IO.Path]::GetTempPath()) ("CleanRoms_Tests_HashCache_" + [guid]::NewGuid() + ".tsv")
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

    #
    # Si un test lanza una excepcion que lo corta a la mitad, antes
    # el resto de sus comprobaciones se perdia en silencio y el
    # resumen seguia diciendo "todos superados". Ahora cuenta como
    # fallo.
    #

    try
    {
        & $test.FullName
    }
    catch
    {
        $Global:TestsRun++
        $Global:TestsFailed++

        Write-Host ("[FAIL] {0} se interrumpio con una excepcion: {1}" -f $test.Name, $_.Exception.Message) -ForegroundColor Red
    }
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

Remove-Item -LiteralPath $Global:HashCachePath -Force -ErrorAction SilentlyContinue
Reset-HashCache

#----------------------------------------------------------
# Codigo de salida (lo usa el CI: 0 = todo bien, 1 = algo fallo)
#----------------------------------------------------------

if($Global:TestsFailed -gt 0 -or $Global:TestsRun -eq 0)
{
    exit 1
}

exit 0
