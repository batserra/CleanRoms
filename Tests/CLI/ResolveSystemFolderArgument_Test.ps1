# ============================================================
# MEJORA: parametro "-System" de main.ps1 (modo no interactivo).
#
# Resolve-SystemFolderArgument debe aceptar el nombre de CARPETA
# real (p.ej. "nes"), no solo el nombre largo y descriptivo que
# usa el menu interactivo -- y debe funcionar sin distinguir
# mayusculas/minusculas. Si no reconoce el sistema, debe devolver
# $null en vez de fallar con una excepcion.
# ============================================================

$originalRoot = $Global:RetroBatRoot

# Ruta portable: con "C:\RetroBat\roms" Join-Path falla en Linux y las
# comparaciones de abajo se cumplian "por casualidad" (null contra null).
$Global:RetroBatRoot = Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) "RetroBat_Fake") "roms"

try
{
    $byFolderName = Resolve-SystemFolderArgument -System "nes"

    Assert-Equal `
        (Join-Path $Global:RetroBatRoot "nes") `
        $byFolderName `
        "Resolve-SystemFolderArgument: debe reconocer el nombre de carpeta real ('nes')"

    $caseInsensitive = Resolve-SystemFolderArgument -System "NES"

    Assert-Equal `
        (Join-Path $Global:RetroBatRoot "nes") `
        $caseInsensitive `
        "Resolve-SystemFolderArgument: debe funcionar sin distinguir mayusculas/minusculas"

    $byLongName = Resolve-SystemFolderArgument -System "Nintendo Entertainment System (NES)"

    Assert-Equal `
        (Join-Path $Global:RetroBatRoot "nes") `
        $byLongName `
        "Resolve-SystemFolderArgument: tambien debe aceptar el nombre largo, como red de seguridad"

    $unknown = Resolve-SystemFolderArgument -System "esto-no-existe"

    Assert-Equal `
        $null `
        $unknown `
        "Resolve-SystemFolderArgument: un nombre no reconocido debe devolver \$null, no lanzar error"
}
finally
{
    $Global:RetroBatRoot = $originalRoot
}
