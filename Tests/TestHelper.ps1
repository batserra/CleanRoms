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

    if($Expected -eq $Actual)
    {
        $Global:TestsPassed++

        Write-Host ("[ OK ] {0}" -f $TestName) -ForegroundColor Green
        return
    }

    $Global:TestsFailed++

    Write-Host ("[FAIL] {0}" -f $TestName) -ForegroundColor Red
    Write-Host ("       Esperado : {0}" -f $Expected)
    Write-Host ("       Obtenido : {0}" -f $Actual)
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
