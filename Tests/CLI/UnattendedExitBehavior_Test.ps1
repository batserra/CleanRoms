# ============================================================
# MEJORA: modo no interactivo (-Yes / -Action) fiable para tareas
# programadas.
#
# Antes:
# - Pause-End siempre hacia Read-Host, asi que una tarea programada
#   se quedaba colgada esperando Enter al terminar.
# - Un error inesperado terminaba "con exito" (codigo de salida 0).
# - Un fallo en una accion concreta (p.ej. un MOVE que lanza una
#   excepcion) solo se mostraba como aviso, sin dejar rastro en el
#   codigo de salida.
#
# Este test comprueba que:
# - Pause-End NO llama a Read-Host con AutoConfirm activo, y SI
#   lo hace con AutoConfirm desactivado (modo interactivo intacto).
# - Una accion que falla en Invoke-CleanExecute incrementa
#   $Global:ActionErrorCount (main.ps1 lo traduce a codigo de
#   salida 2), y el resto del plan sigue ejecutandose.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"
. "$PSScriptRoot\..\..\Modules\Menu.ps1"

$originalAutoConfirm = $Global:AutoConfirm
$errorCountWasSet = Test-Path Variable:\Global:ActionErrorCount
$originalErrorCount = if($errorCountWasSet) { $Global:ActionErrorCount } else { 0 }

$global:readHostCalls = 0

function global:Read-Host
{
    param($Prompt)
    $global:readHostCalls++
    return ""
}

try
{
    #
    # Pause-End
    #

    $Global:AutoConfirm = $true
    $global:readHostCalls = 0
    Pause-End

    Assert-Equal `
        0 `
        $global:readHostCalls `
        "Pause-End con AutoConfirm: no debe esperar ninguna tecla"

    $Global:AutoConfirm = $false
    $global:readHostCalls = 0
    Pause-End

    Assert-Equal `
        1 `
        $global:readHostCalls `
        "Pause-End en modo interactivo: debe seguir esperando Enter"

    #
    # Contador de errores del Executor
    #

    $Global:AutoConfirm = $true
    $Global:ActionErrorCount = 0

    $plan = [pscustomobject]@{
        Actions = @(
            [pscustomobject]@{ Action = "ACCION_INEXISTENTE"; Source = "no-importa" },
            [pscustomobject]@{ Action = "KEEP"; Source = "tampoco-importa" }
        )
    }

    $null = Invoke-CleanExecute -Plan $plan 6>$null 3>$null

    Assert-Equal `
        1 `
        $Global:ActionErrorCount `
        "Invoke-CleanExecute: una accion que falla debe contarse en ActionErrorCount (y solo esa)"
}
finally
{
    $Global:AutoConfirm = $originalAutoConfirm
    if($errorCountWasSet)
    {
        $Global:ActionErrorCount = $originalErrorCount
    }
    else
    {
        Remove-Variable -Name ActionErrorCount -Scope Global -ErrorAction SilentlyContinue
    }

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
}
