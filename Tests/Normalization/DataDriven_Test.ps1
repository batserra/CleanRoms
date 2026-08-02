# ============================================================
# Casos de prueba conocidos (regresión)
#
# Ejecuta todos los casos definidos en Tests\TestCases.ps1 contra
# el código real (Normalize-Title, Get-RomFlags,
# Get-MediaRomBaseName). Ver ese archivo para añadir casos nuevos.
# ============================================================

. "$PSScriptRoot\..\TestCases.ps1"

foreach($case in $Global:TestCases)
{
    switch($case.Type)
    {
        "Match"
        {
            $normalized = $case.Files | ForEach-Object {
                $stem = [System.IO.Path]::GetFileNameWithoutExtension($_)
                Normalize-Title -Title $stem
            }

            $distinctCount = @($normalized | Select-Object -Unique).Count

            Assert-Equal `
                1 `
                $distinctCount `
                ("[Match] {0}" -f $case.Name)
        }

        "Distinct"
        {
            $normalized = $case.Files | ForEach-Object {
                $stem = [System.IO.Path]::GetFileNameWithoutExtension($_)
                Normalize-Title -Title $stem
            }

            $distinctCount = @($normalized | Select-Object -Unique).Count

            Assert-Equal `
                $case.Files.Count `
                $distinctCount `
                ("[Distinct] {0}" -f $case.Name)
        }

        "Contains"
        {
            $stem = [System.IO.Path]::GetFileNameWithoutExtension($case.File)
            $normalized = Normalize-Title -Title $stem

            Assert-Equal `
                $true `
                ($normalized -like "*$($case.ExpectedSubstring)*") `
                ("[Contains] {0} (obtenido: '{1}')" -f $case.Name, $normalized)
        }

        "Flag"
        {
            $stem = [System.IO.Path]::GetFileNameWithoutExtension($case.File)
            $flags = Get-RomFlags -Title $stem

            foreach($flagName in $case.ExpectedFlags.Keys)
            {
                Assert-Equal `
                    $case.ExpectedFlags[$flagName] `
                    $flags.$flagName `
                    ("[Flag:{0}] {1}" -f $flagName, $case.Name)
            }
        }

        "MediaSuffix"
        {
            $actual = Get-MediaRomBaseName -FileBaseName $case.File

            Assert-Equal `
                $case.ExpectedBase `
                $actual `
                ("[MediaSuffix] {0}" -f $case.Name)
        }

        "Region"
        {
            $stem = [System.IO.Path]::GetFileNameWithoutExtension($case.File)
            $actual = Get-RomRegion -Title $stem

            Assert-Equal `
                $case.ExpectedRegion `
                $actual `
                ("[Region] {0}" -f $case.Name)
        }

        default
        {
            Write-Host ("[FAIL] Tipo de caso desconocido: {0} ({1})" -f $case.Type, $case.Name) -ForegroundColor Red
            $Global:TestsRun++
            $Global:TestsFailed++
        }
    }
}
