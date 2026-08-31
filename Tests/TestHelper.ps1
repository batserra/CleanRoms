# ============================================================
# CleanROMs Test Helper
# ============================================================

function Assert-Equal {

    param(
        $Expected,
        $Actual,
        [string]$TestName
    )

    $Global:TestsRun++

    #
    # OJO: el operador -eq de PowerShell, cuando el operando de la
    # izquierda es un array, no compara igualdad -- FILTRA el
    # array y devuelve los elementos que coincidan (p.ej.
    # @(1,2,3) -eq 2 devuelve @(2), no $true/$false). Con un
    # $Expected/$Actual normal (texto, número, booleano, $null)
    # esto nunca se nota, pero si algún test comparara dos arrays
    # completos directamente, "-eq" daría un resultado sin
    # sentido en vez de comparar de verdad su contenido. Por eso
    # aquí se detecta ese caso aparte y se comparan elemento a
    # elemento, en vez de fiarse siempre de -eq a pelo.
    #

    if($Expected -is [array] -or $Actual -is [array])
    {
        $expectedItems = @($Expected)
        $actualItems = @($Actual)

        $isEqual = ($expectedItems.Count -eq $actualItems.Count)

        if($isEqual)
        {
            for($i = 0; $i -lt $expectedItems.Count; $i++)
            {
                if($expectedItems[$i] -ne $actualItems[$i])
                {
                    $isEqual = $false
                    break
                }
            }
        }
    }
    else
    {
        $isEqual = ($Expected -eq $Actual)
    }

    if($isEqual)
    {
        $Global:TestsPassed++

        Write-Host ("[ OK ] {0}" -f $TestName) -ForegroundColor Green
        return
    }

    $Global:TestsFailed++

    Write-Host ("[FAIL] {0}" -f $TestName) -ForegroundColor Red
    Write-Host ("       Esperado : {0}" -f ($Expected -join ", "))
    Write-Host ("       Obtenido : {0}" -f ($Actual -join ", "))
}
#------------------------------------------------------------

function New-TestRom {

    param(

        [string]$Title,

        [string]$NormalizedTitle,

        [string]$Region,

        [string]$Language,

        [string]$Version,

        [string]$Revision,

        [int]$Score = 0,

        [bool]$Verified = $false,

        [bool]$BadDump = $false,

        [bool]$Hack = $false,

        [bool]$NamedHack = $Hack,

        [bool]$Translation = $false,

        [bool]$Beta = $false,

        [bool]$Prototype = $false,

        [bool]$Demo = $false,

        [bool]$Homebrew = $false,

        [bool]$Pirate = $false,

        [bool]$Sample = $false,

        [bool]$Preview = $false,

        [bool]$Kiosk = $false

    )

    if([string]::IsNullOrWhiteSpace($NormalizedTitle))
    {
        $NormalizedTitle = $Title
    }

    return [PSCustomObject]@{

        Title = $Title

        NormalizedTitle = $NormalizedTitle

        FullPath = $Title

        Region = $Region

        Language = $Language

        Version = $Version

        Revision = $Revision

        Score = $Score

        Verified = $Verified

        BadDump = $BadDump

        Hack = $Hack

        NamedHack = $NamedHack

        Translation = $Translation

        Beta = $Beta

        Prototype = $Prototype

        Demo = $Demo

        Homebrew = $Homebrew

        Pirate = $Pirate

        Sample = $Sample

        Preview = $Preview

        Kiosk = $Kiosk

        Reasons = @()

    }

}

#------------------------------------------------------------

function New-TestTempFolder {

    $folder = Join-Path $env:TEMP ("CleanRoms_Test_" + [guid]::NewGuid())

    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    return $folder

}
