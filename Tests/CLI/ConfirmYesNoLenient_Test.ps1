# ============================================================
# BUG corregido: confirm.yesPattern exigía escribir EXACTAMENTE
# "S" (una sola letra, sin espacios) para confirmar mover
# archivos -- cualquier variante razonable como "si", "sí", con
# espacios de más, o con mayúsculas distintas, se trataba como
# "No" y cancelaba la limpieza en silencio.
#
# Caso real reportado: un usuario ejecutó "4) TODO", el programa
# detectó correctamente 1731 archivos duplicados, pero la
# confirmación se interpretó como "No" y NINGUNO se movió --
# probablemente por no haber escrito una "S" exacta.
#
# Este test comprueba que Confirm-YesNo ahora acepta variantes
# razonables en español, y sigue rechazando una negativa clara.
# ============================================================

$originalLanguage = $Global:Settings.Language
$originalAutoConfirm = $Global:AutoConfirm

$Global:Settings.Language = "es"
$Global:AutoConfirm = $false

$acceptedAnswers = @("s", "S", "si", "Si", "SI", "sí", "Sí", " s ", "yes")
$rejectedAnswers = @("n", "N", "no", "No", "", "   ")

try
{
    foreach($answer in $acceptedAnswers)
    {
        function global:Read-Host
        {
            param($Prompt)
            return $script:currentAnswer
        }
        $script:currentAnswer = $answer

        $result = Confirm-YesNo "plan.confirmMove"

        Assert-Equal `
            $true `
            $result `
            "Confirm-YesNo: '$answer' debe aceptarse como confirmacion afirmativa"
    }

    foreach($answer in $rejectedAnswers)
    {
        function global:Read-Host
        {
            param($Prompt)
            return $script:currentAnswer
        }
        $script:currentAnswer = $answer

        $result = Confirm-YesNo "plan.confirmMove"

        Assert-Equal `
            $false `
            $result `
            "Confirm-YesNo: '$answer' debe seguir tratandose como negativa"
    }
}
finally
{
    $Global:Settings.Language = $originalLanguage
    $Global:AutoConfirm = $originalAutoConfirm
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    Remove-Variable -Name currentAnswer -Scope Script -ErrorAction SilentlyContinue
}
