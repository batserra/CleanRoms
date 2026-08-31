# ============================================================
# BUG corregido: ni Invoke-HackOrganizer (organizar hacks sueltos
# en "# Hacks y Otros #") ni Invoke-HackDeduplication (deduplicar
# copias exactas dentro de esa carpeta) comprobaban en ningun
# punto $Global:Settings.PreviewOnly -- con PreviewOnly=$true los
# archivos se movian igualmente en cuanto se confirmaba con "S".
#
# Este test monta un sistema de prueba con una ROM hackeada suelta
# (fuera de "# Hacks y Otros #"), activa PreviewOnly, y comprueba
# que Invoke-HackOrganizer NO la mueve de su sitio original.
# ============================================================

$tempSystem = New-TestTempFolder
$tempRoot = New-TestTempFolder

$looseHackFile = Join-Path $tempSystem "Super Game (Hack).smc"
Set-Content -LiteralPath $looseHackFile -Value "fake rom content"

$originalPreviewOnly = $Global:Settings.PreviewOnly
$originalLanguage = $Global:Settings.Language

$Global:Settings.PreviewOnly = $true
$Global:Settings.Language = "es"

function global:Read-Host
{
    param($Prompt)
    return "S"
}

try
{
    Invoke-HackOrganizer -Root $tempRoot -SystemFolders @($tempSystem)

    Assert-Equal `
        $true `
        (Test-Path -LiteralPath $looseHackFile) `
        "BUG PreviewOnly: la ROM hackeada suelta debe seguir en su sitio original (no se mueve nada en modo simulacion)"

    $hacksFolder = Join-Path $tempSystem "# Hacks y Otros #"

    Assert-Equal `
        $false `
        (Test-Path -LiteralPath (Join-Path $hacksFolder "Super Game (Hack).smc")) `
        "BUG PreviewOnly: la ROM hackeada suelta NO debe aparecer dentro de '# Hacks y Otros #' en modo simulacion"
}
finally
{
    $Global:Settings.PreviewOnly = $originalPreviewOnly
    $Global:Settings.Language = $originalLanguage

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    Remove-Item -Path $tempSystem -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
