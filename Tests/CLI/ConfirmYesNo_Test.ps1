# ============================================================
# MEJORA: modo no interactivo (-Yes en main.ps1) para poder
# programar CleanROMs con el Programador de tareas de Windows sin
# que se quede esperando una respuesta S/N.
#
# Este test comprueba la pieza central: Confirm-YesNo debe
# devolver $true sin preguntar nada cuando $Global:AutoConfirm
# está activo, y comportarse exactamente como antes (preguntar de
# verdad y comparar con confirm.yesPattern) cuando no lo está.
# ============================================================

$originalAutoConfirm = $Global:AutoConfirm
$originalLanguage = $Global:Settings.Language

$Global:Settings.Language = "es"

try
{
    #
    # Modo no interactivo: no debe llamar a Read-Host en absoluto.
    # Lo comprobamos sobreescribiendo Read-Host para que falle si
    # llega a invocarse.
    #

    $Global:AutoConfirm = $true

    function global:Read-Host
    {
        param($Prompt)
        throw "Read-Host no debería llamarse con AutoConfirm activo"
    }

    $result = Confirm-YesNo "plan.confirmMove"

    Assert-Equal `
        $true `
        $result `
        "Confirm-YesNo con AutoConfirm=\$true debe devolver \$true sin preguntar"

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    #
    # Modo normal: debe preguntar de verdad y respetar la
    # respuesta (afirmativa y negativa).
    #

    $Global:AutoConfirm = $false

    function global:Read-Host
    {
        param($Prompt)
        return "S"
    }

    $resultYes = Confirm-YesNo "plan.confirmMove"

    Assert-Equal `
        $true `
        $resultYes `
        "Confirm-YesNo sin AutoConfirm: respondiendo 'S' debe devolver \$true"

    function global:Read-Host
    {
        param($Prompt)
        return "N"
    }

    $resultNo = Confirm-YesNo "plan.confirmMove"

    Assert-Equal `
        $false `
        $resultNo `
        "Confirm-YesNo sin AutoConfirm: respondiendo 'N' debe devolver \$false"
}
finally
{
    $Global:AutoConfirm = $originalAutoConfirm
    $Global:Settings.Language = $originalLanguage
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
}
