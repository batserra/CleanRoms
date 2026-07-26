# ============================================================
# Beta CleanROMs v2.5
#
# Menu.ps1
#
# Interfaz principal
# ============================================================

function Show-Banner {

    Clear-Host

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "           BETA CLEAN ROMS v2.5           " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
}


#--------------------------------------------------------------
# Menú principal
#--------------------------------------------------------------

function Select-MainAction {

    Write-Host "Qué quieres hacer?"
    Write-Host ""
    Write-Host " 1) Limpiar ROMs duplicadas"
    Write-Host " 2) Deshacer la última limpieza"
    Write-Host " 3) Limpiar imágenes/vídeos/manuales huérfanos"
    Write-Host " 4) TODO: Mover ROMs e imágenes/vídeos/manuales de TODOS los sistemas"
    Write-Host " 5) Salir"
    Write-Host ""

    do
    {
        $option = Read-Host "Opción"
    }
    until($option -match '^[12345]$')

    return [int]$option
}


#--------------------------------------------------------------
# Menú de selección
#--------------------------------------------------------------

function Select-System {

    Write-Host "Buscando sistemas con ROMs..." -ForegroundColor DarkGray

    $systems = @(
        Get-SupportedSystems | Where-Object {
            Test-SystemHasRoms (Get-SystemFolder $_)
        }
    )

    Write-Host ""

    if($systems.Count -eq 0)
    {
        Write-Host "No se ha encontrado ninguna carpeta de sistema con ROMs." -ForegroundColor Yellow
        Write-Host "(revisa la ruta de RetroBat configurada, o si tus ROMs usan una extensión que no está en la lista)"
        Write-Host ""
        Read-Host "Pulse ENTER para continuar"
        return "__NONE__"
    }

    Write-Host "Seleccione sistema"
    Write-Host ""

    for($i=0;$i -lt $systems.Count;$i++)
    {
        Write-Host ("{0,2}) {1}" -f ($i+1), $systems[$i])
    }

    Write-Host ""
    Write-Host (" 0) TODOS LOS SISTEMAS")
    Write-Host ""

    do
    {
        $option = Read-Host "Opción"
    }
    until(
        ($option -match '^\d+$') -and
        ([int]$option -ge 0) -and
        ([int]$option -le $systems.Count)
    )

    if([int]$option -eq 0)
    {
        return "__ALL__"
    }

    return $systems[[int]$option-1]
}



#--------------------------------------------------------------
# Pausa final
#--------------------------------------------------------------

function Pause-End {

    Write-Host ""
    Read-Host "Pulse ENTER para salir"

}