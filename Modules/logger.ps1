# ============================================================
# Beta CleanROMs v2.6
# Logger.ps1
#
# El log guarda TODO lo que se ve en pantalla (escaneo,
# previsualización, resumen, y lo que el usuario responde en
# el menú y en la confirmación S/N), usando Start-Transcript.
# Write-Log se mantiene aparte para marcadores puntuales
# (inicio, fin, errores concretos).
# ============================================================

$script:LogFile = $null
$script:TranscriptActive = $false

function Start-Log {

    param(
        [string]$RootFolder
    )

    $logFolder = Join-Path $RootFolder "Logs"

    if(!(Test-Path -LiteralPath $logFolder))
    {
        New-Item $logFolder -ItemType Directory | Out-Null
    }

    $date = Get-Date -Format "yyyyMMdd_HHmmss"

    $script:LogFile = Join-Path $logFolder "CleanROMs_$date.log"

    Write-Log "==========================================="
    Write-Log "Beta CleanROMs v2.6"
    Write-Log "Inicio : $(Get-Date)"
    Write-Log "==========================================="

    try
    {
        Start-Transcript -Path $script:LogFile -Append -ErrorAction Stop | Out-Null
        $script:TranscriptActive = $true
    }
    catch
    {
        #
        # Si por lo que sea no se puede iniciar la transcripción
        # (por ejemplo, ya hay una activa en la sesión), seguimos
        # sin cortar la ejecución: simplemente no habrá log completo.
        #

        $script:TranscriptActive = $false
    }
}

function Write-Log {

    param(
        [string]$Text
    )

    if($script:LogFile)
    {
        Add-Content $script:LogFile $Text
    }
}

function Stop-Log {

    if($script:TranscriptActive)
    {
        try
        {
            Stop-Transcript | Out-Null
        }
        catch
        {
            # No había transcripción activa, no pasa nada
        }

        $script:TranscriptActive = $false
    }

    Write-Log ""
    Write-Log "==========================================="
    Write-Log "Fin : $(Get-Date)"
    Write-Log "==========================================="
}

function Get-LogFile {

    return $script:LogFile

}