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

        "VersionRevision"
        {
            $stem = [System.IO.Path]::GetFileNameWithoutExtension($case.File)

            $actualVersion  = Get-RomVersion  -Title $stem
            $actualRevision = Get-RomRevision -Title $stem

            Assert-Equal `
                $case.ExpectedVersion `
                $actualVersion `
                ("[Version] {0}" -f $case.Name)

            Assert-Equal `
                $case.ExpectedRevision `
                $actualRevision `
                ("[Revision] {0}" -f $case.Name)
        }

        default
        {
            Write-Host ("[FAIL] Tipo de caso desconocido: {0} ({1})" -f $case.Type, $case.Name) -ForegroundColor Red
            $Global:TestsRun++
            $Global:TestsFailed++
        }
    }
}

# ============================================================
# Integridad de Config\TitleAliases.json
#
# Cada clave y cada valor del archivo de alias debe ser ya la
# forma normalizada ACTUAL (sin pasar por el propio alias), es
# decir: Get-CoreNormalizedTitle($clave) -eq $clave. Si no lo es,
# significa que las reglas de normalización cambiaron después de
# generar ese alias y la clave ya no se puede alcanzar nunca
# (esto es justo lo que pasó con Narnia, Gekido, Yu-Gi-Oh y Raid
# en distintos momentos). También comprueba que ningún valor sea
# a su vez una clave (cadena de alias sin aplanar).
# ============================================================

$aliasMap = Get-TitleAliasMap

foreach($key in $aliasMap.Keys)
{
    $recomputed = Get-CoreNormalizedTitle -Title $key

    Assert-Equal `
        $key `
        $recomputed `
        ("[AliasIntegrity] La clave '{0}' ya no coincide con su propia forma normalizada (alias obsoleto, revisar Config\TitleAliases.json)" -f $key)

    $value = $aliasMap[$key]

    $recomputedValue = Get-CoreNormalizedTitle -Title $value

    Assert-Equal `
        $value `
        $recomputedValue `
        ("[AliasIntegrity] El valor '{0}' (de la clave '{1}') ya no coincide con su propia forma normalizada" -f $value, $key)

    Assert-Equal `
        $false `
        $aliasMap.ContainsKey($value) `
        ("[AliasIntegrity] '{0}' -> '{1}' es una cadena sin aplanar (el valor es a su vez otra clave)" -f $key, $value)
}
