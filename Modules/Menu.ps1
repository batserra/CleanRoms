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
    Write-Host ("           {0}           " -f (T "banner.title")) -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
}


#--------------------------------------------------------------
# Menú principal
#--------------------------------------------------------------

function Select-MainAction {

    Write-Host (T "menu.whatToDo")
    Write-Host ""
    Write-Host (T "menu.option1")
    Write-Host (T "menu.option2")
    Write-Host (T "menu.option3")
    Write-Host (T "menu.option4")
    Write-Host (T "menu.option5")
    Write-Host (T "menu.option6")
    Write-Host ""

    do
    {
        $option = Read-Host (T "menu.prompt")
    }
    until($option -match '^[123456]$')

    return [int]$option
}


#--------------------------------------------------------------
# Menú de configuración
#--------------------------------------------------------------

function Show-ConfigMenu {

    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    Write-Host ""
    Write-Host (T "config.menuTitle")
    Write-Host ""
    Write-Host (T "config.menuPath" $Global:RetroBatRoot)
    Write-Host (T "config.menuLanguage" $Global:Settings.Language)
    Write-Host ""
    Write-Host (T "config.opt1")
    Write-Host (T "config.opt2")
    Write-Host (T "config.opt3")
    Write-Host (T "config.opt0")
    Write-Host ""

    do
    {
        $option = Read-Host (T "menu.prompt")
    }
    until($option -match '^[0123]$')

    switch($option)
    {
        "1" { Initialize-RetroBatRoot -Root $Root -Force }
        "2" { Initialize-Language -Root $Root -Force }
        "3" {
            Initialize-RetroBatRoot -Root $Root -Force
            Initialize-Language -Root $Root -Force
        }
    }
}


#--------------------------------------------------------------
# Menú de selección
#--------------------------------------------------------------

function Select-System {

    Write-Host (T "menu.searchingSystems") -ForegroundColor DarkGray

    $systems = @(
        Get-SupportedSystems | Where-Object {
            Test-SystemHasRoms (Get-SystemFolder $_)
        }
    )

    Write-Host ""

    if($systems.Count -eq 0)
    {
        Write-Host (T "menu.noSystemsFound") -ForegroundColor Yellow
        Write-Host (T "menu.noSystemsHint")
        Write-Host ""
        Read-Host (T "menu.pressEnterContinue")
        return "__NONE__"
    }

    Write-Host (T "menu.selectSystem")
    Write-Host ""

    for($i=0;$i -lt $systems.Count;$i++)
    {
        Write-Host ("{0,2}) {1}" -f ($i+1), $systems[$i])
    }

    Write-Host ""
    Write-Host (T "menu.allSystems")
    Write-Host ""

    do
    {
        $option = Read-Host (T "menu.prompt")
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
    Read-Host (T "menu.pressEnterExit")

}