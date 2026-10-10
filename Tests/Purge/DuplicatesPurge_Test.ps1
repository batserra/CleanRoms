# ============================================================
# MEJORA: purga de _duplicates (opcion 6 / -Action Purge).
#
# Es lo UNICO que el programa borra de verdad, asi que el test es
# estricto:
# - La antiguedad es desde que se MOVIO (planes guardados), no la
#   fecha del archivo (que aqui es de hoy): si fuera la fecha del
#   archivo, no se borraria nada.
# - Si un archivo se movio varias veces, cuenta el ULTIMO movimiento.
# - Los archivos asociados (.srm...) y los medios de subcarpetas
#   cuentan con la fecha de su movimiento.
# - Sin fecha conocida: no se borra; su cuenta empieza hoy, y si el
#   archivo cambia, la cuenta se reinicia.
# - PreviewOnly y responder N no borran nada.
# - Se borra solo lo que corresponde, se quitan las carpetas vacias
#   (no _duplicates), se anota en PurgeLog y se cuenta lo liberado.
# - Un fallo al borrar un archivo no aborta el resto.
# - "Deshacer" despues de purgar no falla.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$dupSnes = Join-Path (Join-Path $tempRoot "_duplicates") "snes"
$systemFolder = Join-Path $tempRoot "snes"
$resultFolder = Join-Path $tempRoot "Resultado"
$historyFolder = Join-Path $resultFolder "History"

New-Item -ItemType Directory -Path $dupSnes -Force | Out-Null
New-Item -ItemType Directory -Path $historyFolder -Force | Out-Null

$saved = @{
    Language    = $Global:Settings.Language
    PreviewOnly = $Global:Settings.PreviewOnly
    AutoConfirm = $Global:AutoConfirm
    Root        = $Global:RetroBatRoot
    Dup         = $Global:DuplicatesFolder
    Days        = $Global:Settings.PurgeDuplicatesAfterDays
}

$errorCountWasSet = Test-Path Variable:\Global:ActionErrorCount
$originalErrorCount = if($errorCountWasSet) { $Global:ActionErrorCount } else { 0 }

$Global:Settings.Language = "es"
$Global:Settings.PreviewOnly = $false
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"
$Global:Settings.PurgeDuplicatesAfterDays = 90
$Global:ActionErrorCount = 0

function New-DupFile
{
    param([string]$Relative, [string]$Content = "data")

    $path = Join-Path $dupSnes $Relative
    $parent = Split-Path $path -Parent

    if(!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    Set-Content -LiteralPath $path -Value $Content
    return $path
}

function New-MoveEntry
{
    param([string]$Name, [int]$DaysAgo, [string[]]$Assoc = @())

    return [PSCustomObject]@{
        Action          = "MOVE"
        Source          = (Join-Path $systemFolder $Name)
        Target          = $dupSnes
        AssociatedFiles = $Assoc
        TimeStamp       = (Get-Date).AddDays(-$DaysAgo).ToString("o")
    }
}

function Write-Plan
{
    param([string]$File, $Entries)

    @($Entries) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $File -Encoding UTF8
}

try
{
    #
    # Fixture
    #

    New-DupFile "old.sfc" "old rom" | Out-Null
    New-DupFile "old.srm" "old save" | Out-Null
    New-DupFile "images/old.png" "old image" | Out-Null
    New-DupFile "recent.sfc" "recent rom" | Out-Null
    New-DupFile "relocated.sfc" "moved twice" | Out-Null
    New-DupFile "undated.sfc" "no plan knows this one" | Out-Null
    New-DupFile "d45.sfc" "45 days" | Out-Null

    $imagesSource = Join-Path (Join-Path $systemFolder "images") "old.png"

    $imageEntry = [PSCustomObject]@{
        Action = "MOVE"; Source = $imagesSource; Target = (Join-Path $dupSnes "images")
        AssociatedFiles = @(); TimeStamp = (Get-Date).AddDays(-120).ToString("o")
    }

    Write-Plan (Join-Path $resultFolder "CleanPlan.json") @(
        (New-MoveEntry "old.sfc" 200 @("old.srm")),
        (New-MoveEntry "recent.sfc" 10),
        (New-MoveEntry "d45.sfc" 45),
        $imageEntry
    )

    # Historial: "relocated" se movio hace 300 dias y OTRA VEZ hace 5
    Write-Plan (Join-Path $historyFolder "CleanPlan_20200101_000000.json") @(
        (New-MoveEntry "relocated.sfc" 300)
    )
    Write-Plan (Join-Path $historyFolder "CleanPlan_20200102_000000.json") @(
        (New-MoveEntry "relocated.sfc" 5)
    )

    #
    # Candidatos (90 dias)
    #

    $found = Get-PurgeCandidates -Root $tempRoot -Days 90
    $names = @($found.Candidates | ForEach-Object { [System.IO.Path]::GetRelativePath($dupSnes, $_.FullPath).Replace('\', '/') } | Sort-Object)

    Assert-Equal "images/old.png,old.sfc,old.srm" ($names -join ",") "Candidatos: los movidos hace 90 dias o mas, incluidos el archivo asociado y el medio de subcarpeta"
    Assert-Equal 1 @($found.Undated).Count "Candidatos: un archivo sin fecha conocida no es candidato (queda como 'sin fecha')"
    Assert-Equal 7 $found.TotalFiles "Candidatos: se cuentan todos los archivos de _duplicates"
    Assert-Equal $false ($names -contains "relocated.sfc") "Candidatos: si se movio varias veces cuenta el ULTIMO movimiento (hace 5 dias)"
    Assert-Equal $false ($names -contains "recent.sfc") "Candidatos: lo movido hace 10 dias no se toca (los archivos son de hoy: no se usa su fecha)"

    $found30 = Get-PurgeCandidates -Root $tempRoot -Days 30
    Assert-Equal $true (@($found30.Candidates | Where-Object { $_.FullPath -like "*d45.sfc" }).Count -eq 1) "Candidatos: con 30 dias entra el movido hace 45"

    $found90 = $found
    Assert-Equal $true (@($found90.Candidates | Where-Object { $_.FullPath -like "*d45.sfc" }).Count -eq 0) "Candidatos: con 90 dias no entra el movido hace 45"

    Assert-Equal "1,5 KB" (Format-FileSize 1536).Replace(".", ",") "Format-FileSize: KB"
    Assert-Equal "0 B" (Format-FileSize 0) "Format-FileSize: cero"

    #
    # PreviewOnly: no borra nada ni escribe nada
    #

    $Global:Settings.PreviewOnly = $true
    $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>$null

    Assert-Equal 0 $r.Deleted "PreviewOnly: no borra nada"
    Assert-Equal 3 $r.Candidates "PreviewOnly: informa de cuantos borraria"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $dupSnes "old.sfc")) "PreviewOnly: el archivo sigue ahi"
    Assert-Equal $false (Test-Path -LiteralPath (Get-DuplicatesSeenPath -Root $tempRoot)) "PreviewOnly: tampoco apunta fechas de 'visto por primera vez'"

    $Global:Settings.PreviewOnly = $false

    #
    # Responder N: no borra nada
    #

    $global:purgeAnswers = @("N")
    $global:purgeAsked = 0

    function global:Read-Host
    {
        param($Prompt)
        $a = $global:purgeAnswers[$global:purgeAsked]
        $global:purgeAsked++
        return $a
    }

    $Global:AutoConfirm = $false
    $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>$null

    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    Assert-Equal 1 $global:purgeAsked "Confirmacion: se pregunta antes de borrar"
    Assert-Equal 0 $r.Deleted "Confirmacion: respondiendo N no se borra nada"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $dupSnes "old.sfc")) "Confirmacion: respondiendo N el archivo sigue ahi"

    #
    # Borrado real (con -Yes)
    #

    $Global:AutoConfirm = $true
    $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>$null

    Assert-Equal 3 $r.Deleted "Purga: se borran los 3 archivos con 90 dias o mas"
    Assert-Equal 0 $r.Failed "Purga: sin fallos"
    Assert-Equal $true ($r.FreedBytes -gt 0) "Purga: se cuenta el espacio liberado"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $dupSnes "old.sfc")) "Purga: old.sfc borrado"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $dupSnes "old.srm")) "Purga: el archivo asociado tambien"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $dupSnes "images")) "Purga: la carpeta que se queda vacia se elimina"
    Assert-Equal $true (Test-Path -LiteralPath $dupSnes) "Purga: la carpeta del sistema en _duplicates (con archivos) sigue"

    foreach($keep in "recent.sfc", "relocated.sfc", "undated.sfc", "d45.sfc")
    {
        Assert-Equal $true (Test-Path -LiteralPath (Join-Path $dupSnes $keep)) "Purga: $keep NO se toca"
    }

    $logs = @(Get-ChildItem -LiteralPath $resultFolder -Filter "PurgeLog_*.txt")
    Assert-Equal 1 $logs.Count "Purga: se anota lo borrado en PurgeLog"
    Assert-Equal 3 @(Get-Content -LiteralPath $logs[0].FullName).Count "Purga: el log lista los 3 archivos borrados"

    #
    # Sin fecha: la cuenta empezo hoy
    #

    Assert-Equal $true (Test-Path -LiteralPath (Get-DuplicatesSeenPath -Root $tempRoot)) "Sin fecha: se apunta cuando se vio por primera vez"

    $soon = Get-PurgeCandidates -Root $tempRoot -Days 90 -NowUtc ([datetime]::UtcNow.AddDays(10))
    Assert-Equal 0 @($soon.Candidates | Where-Object { $_.FullPath -like "*undated.sfc" }).Count "Sin fecha: a los 10 dias no es candidato"

    $later = Get-PurgeCandidates -Root $tempRoot -Days 90 -NowUtc ([datetime]::UtcNow.AddDays(100))
    Assert-Equal 1 @($later.Candidates | Where-Object { $_.FullPath -like "*undated.sfc" }).Count "Sin fecha: pasados los 90 dias desde que se vio, ya es candidato"

    Set-Content -LiteralPath (Join-Path $dupSnes "undated.sfc") -Value "otro archivo distinto con el mismo nombre"
    $changed = Get-PurgeCandidates -Root $tempRoot -Days 90 -NowUtc ([datetime]::UtcNow.AddDays(100))
    Assert-Equal 0 @($changed.Candidates | Where-Object { $_.FullPath -like "*undated.sfc" }).Count "Sin fecha: si el archivo cambia, la cuenta se reinicia"

    #
    # Dias por defecto (Settings) cuando no se indican
    #

    $Global:Settings.PurgeDuplicatesAfterDays = 30
    $r = Invoke-DuplicatesPurge -Root $tempRoot 6>$null

    Assert-Equal 1 $r.Deleted "Dias por defecto: usa PurgeDuplicatesAfterDays (30) y borra el movido hace 45 dias"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $dupSnes "d45.sfc")) "Dias por defecto: d45.sfc borrado"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $dupSnes "recent.sfc")) "Dias por defecto: recent.sfc (10 dias) sigue"

    #
    # Un fallo al borrar no aborta el resto
    #

    Write-Plan (Join-Path $resultFolder "CleanPlan.json") @(
        (New-MoveEntry "recent.sfc" 400),
        (New-MoveEntry "relocated.sfc" 400)
    )
    Remove-Item -Path (Join-Path $historyFolder "*.json") -Force

    $Global:ActionErrorCount = 0

    function global:Remove-Item
    {
        param([string]$LiteralPath, [switch]$Force, $ErrorAction, [string]$Path, [switch]$Recurse)

        if($LiteralPath -like "*recent.sfc")
        {
            throw "Acceso denegado (simulado)"
        }

        if($LiteralPath) { Microsoft.PowerShell.management\Remove-Item -LiteralPath $LiteralPath -Force:$Force }
        else { Microsoft.PowerShell.management\Remove-Item -Path $Path -Force:$Force -Recurse:$Recurse }
    }

    $threw = $false
    try { $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>$null 3>$null } catch { $threw = $true }

    Remove-Item Function:\Remove-Item -ErrorAction SilentlyContinue

    Assert-Equal $false $threw "Fallo al borrar: no lanza excepcion"
    Assert-Equal 1 $r.Failed "Fallo al borrar: se cuenta 1 fallo"
    Assert-Equal 1 $r.Deleted "Fallo al borrar: el otro archivo SI se borra"
    Assert-Equal 1 $Global:ActionErrorCount "Fallo al borrar: cuenta para el codigo de salida 2"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $dupSnes "recent.sfc")) "Fallo al borrar: el archivo que fallo sigue ahi"

    #
    # Deshacer despues de purgar: no falla y restaura lo que queda
    #

    Write-Plan (Join-Path $resultFolder "CleanPlan.json") @(
        (New-MoveEntry "recent.sfc" 400),
        (New-MoveEntry "relocated.sfc" 400)
    )

    $threwUndo = $false
    try { $null = Invoke-UndoLastPlan -Root $tempRoot 6>$null 3>$null } catch { $threwUndo = $true }

    Assert-Equal $false $threwUndo "Deshacer tras purgar: no lanza excepcion aunque falte algun archivo"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $systemFolder "recent.sfc")) "Deshacer tras purgar: lo que queda en _duplicates se restaura"

    #
    # Sin carpeta _duplicates
    #

    Remove-Item -LiteralPath (Join-Path $tempRoot "_duplicates") -Recurse -Force

    $threwMissing = $false
    try { $r = Invoke-DuplicatesPurge -Root $tempRoot -Days 90 6>$null } catch { $threwMissing = $true }

    Assert-Equal $false $threwMissing "Sin _duplicates: no lanza excepcion"
    Assert-Equal 0 $r.Deleted "Sin _duplicates: no hay nada que borrar"
}
finally
{
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    Remove-Item Function:\Remove-Item -ErrorAction SilentlyContinue

    $Global:Settings.Language = $saved.Language
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup
    $Global:Settings.PurgeDuplicatesAfterDays = $saved.Days

    if($errorCountWasSet) { $Global:ActionErrorCount = $originalErrorCount }
    else { Remove-Variable -Name ActionErrorCount -Scope Global -ErrorAction SilentlyContinue }

    Microsoft.PowerShell.Management\Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
