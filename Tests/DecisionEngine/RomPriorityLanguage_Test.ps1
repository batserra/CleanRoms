# ============================================================
# NUEVA FUNCIONALIDAD: prioridad de ROMs español/inglés,
# configurable en el primer arranque y desde la opción 5 del
# menú (Configuración). Cambia qué tabla de
# Config\DecisionWeights.ps1 está activa
# ($Global:DecisionWeights_ES o _EN), sin tocar el resto de
# criterios (calidad de dump, estado, hacks, versión, revisión).
#
# Este test comprueba que Set-ActiveDecisionWeights cambia
# correctamente la tabla activa, y que Get-RegionScore /
# Get-LanguageScore reflejan ese cambio -- en concreto, que con
# prioridad inglés una copia USA gana a una copia ESP, y con
# prioridad español es al reves (justo lo contrario).
# ============================================================

$originalWeights = $Global:DecisionWeights

try
{
    # -------------------------------------------------------
    # Prioridad ESPAÑOL (por defecto): ESP debe ganar a USA
    # -------------------------------------------------------

    Set-ActiveDecisionWeights -Priority "es"

    $romEsp = New-TestRom -Title "Game (ESP)" -NormalizedTitle "game" -Region "ESP" -Language "Spanish"
    $romUsa = New-TestRom -Title "Game (USA)" -NormalizedTitle "game" -Region "USA" -Language "English"

    $scoreEspConEspanol = (Get-RegionScore $romEsp) + (Get-LanguageScore $romEsp)
    $scoreUsaConEspanol = (Get-RegionScore $romUsa) + (Get-LanguageScore $romUsa)

    Assert-Equal `
        $true `
        ($scoreEspConEspanol -gt $scoreUsaConEspanol) `
        "Prioridad ESPAÑOL: la copia ESP debe puntuar mas alto que la copia USA"

    # -------------------------------------------------------
    # Prioridad INGLÉS: ahora USA debe ganar a ESP (lo contrario)
    # -------------------------------------------------------

    Set-ActiveDecisionWeights -Priority "en"

    $scoreEspConIngles = (Get-RegionScore $romEsp) + (Get-LanguageScore $romEsp)
    $scoreUsaConIngles = (Get-RegionScore $romUsa) + (Get-LanguageScore $romUsa)

    Assert-Equal `
        $true `
        ($scoreUsaConIngles -gt $scoreEspConIngles) `
        "Prioridad INGLES: la copia USA debe puntuar mas alto que la copia ESP (justo lo contrario que con prioridad español)"

    # -------------------------------------------------------
    # Los demas criterios (calidad de dump) no deben cambiar
    # entre una prioridad y otra
    # -------------------------------------------------------

    Assert-Equal `
        (Get-DecisionWeight "Verified") `
        200 `
        "Prioridad INGLES: los criterios que no son de idioma (Verified) deben seguir igual"
}
finally
{
    $Global:DecisionWeights = $originalWeights
}
