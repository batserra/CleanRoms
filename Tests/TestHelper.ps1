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

function Get-LongPathName {

    # En los runners de GitHub Windows, $env:TEMP viene en formato corto 8.3
    # (C:\Users\RUNNER~1\...), pero el programa trabaja con las rutas largas
    # (C:\Users\runneradmin\...). Comparar rutas como texto fallaba (el gamelist
    # del Hack Organizer no se actualizaba y WinnerPath no coincidia). Se expande
    # aqui para que el test y el programa hablen de la misma ruta.

    param([string]$Path)

    if($env:OS -ne "Windows_NT" -or $Path -notmatch '~\d') { return $Path }

    try
    {
        if(-not ("CleanRoomsNative.PathUtil" -as [type]))
        {
            Add-Type -Namespace CleanRoomsNative -Name PathUtil -MemberDefinition '[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern uint GetLongPathName(string shortPath, System.Text.StringBuilder longPath, uint bufferSize);'
        }

        $sb  = New-Object System.Text.StringBuilder 2048
        $len = [CleanRoomsNative.PathUtil]::GetLongPathName($Path, $sb, 2048)

        if($len -gt 0 -and $len -lt 2048) { return $sb.ToString() }
    }
    catch { }

    return $Path
}

function New-TestTempFolder {

    # $env:TEMP solo existe en Windows; GetTempPath() vale en todos los sitios
    $tempBase = if($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }

    $folder = Join-Path $tempBase ("CleanRoms_Test_" + [guid]::NewGuid())

    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    return (Get-LongPathName $folder)

}
