# ============================================================
# Beta CleanROMs v2.5
#
# Cleaner.ps1
#
# Genera el plan de limpieza
# ============================================================

# ============================================================
# Crea una acción
# ============================================================

function New-CleanAction {

    param(

        [Parameter(Mandatory)]
        [ValidateSet("KEEP","MOVE","DELETE","RENAME")]
        [string]$Action,

        [Parameter(Mandatory)]
        $Rom,

        [string]$Target = "",

        [string]$Reason = ""

    )

    return [PSCustomObject]@{

        Action = $Action

        Rom = $Rom

        Source = $Rom.FullPath

        Target = $Target

        Reason = $Reason

        TimeStamp = Get-Date

    }

}

# ============================================================
# Genera el plan de limpieza
# ============================================================

# ============================================================
# Limpieza completa de ROMs para uno o varios sistemas
#
# Escanea, agrupa, decide, previsualiza, exporta el plan y
# (si se confirma) lo ejecuta. Se usa tanto para "limpiar un
# sistema" como para "limpiar TODOS los sistemas".
# ============================================================

function Invoke-RomCleaning {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string[]]$SystemFolders
    )

    Write-Host ""

    Initialize-SevenZipSupport

    $groups = @()
    $Global:DiagnosticoMostrado = $false

    foreach($folder in $SystemFolders)
    {
        $systemName = Split-Path $folder -Leaf

        Write-Host ""
        Write-Host "Sistema : $systemName"
        Write-Host "Carpeta : $folder"

        if(!(Test-Path -LiteralPath $folder))
        {
            Write-Host "  -> Carpeta no encontrada, se omite." -ForegroundColor DarkYellow
            continue
        }

        $roms = @(Get-RomsFromFolder $folder)

        Write-Host "ROMs encontradas : $($roms.Count)"

        if($roms.Count -eq 0)
        {
            continue
        }

        $roms = Update-NormalizedTitles $roms

        if(-not $Global:DiagnosticoMostrado)
        {
            Write-Host ""
            Write-Host "----- DIAGNOSTICO -----" -ForegroundColor Magenta

            $roms | Select-Object -First 5 | ForEach-Object {
                Write-Host ("Title            : {0}" -f $_.Title)
                Write-Host ("NormalizedTitle  : '{0}'" -f $_.NormalizedTitle)
                Write-Host ("Hack/Trans/Beta/Proto/Demo/Home/Pirate/Sample/Preview/Kiosk : {0}/{1}/{2}/{3}/{4}/{5}/{6}/{7}/{8}/{9}" -f `
                    $_.Hack, $_.Translation, $_.Beta, $_.Prototype, $_.Demo, $_.Homebrew, $_.Pirate, $_.Sample, $_.Preview, $_.Kiosk)
                Write-Host ""
            }

            $totalRoms = @($roms).Count
            $vacioONulo = @($roms | Where-Object { [string]::IsNullOrWhiteSpace($_.NormalizedTitle) }).Count
            $conHack = @($roms | Where-Object { $_.Hack }).Count
            $conTranslation = @($roms | Where-Object { $_.Translation }).Count
            $conBeta = @($roms | Where-Object { $_.Beta }).Count
            $conProto = @($roms | Where-Object { $_.Prototype }).Count
            $conDemo = @($roms | Where-Object { $_.Demo }).Count
            $conHomebrew = @($roms | Where-Object { $_.Homebrew }).Count
            $conPirate = @($roms | Where-Object { $_.Pirate }).Count
            $conSample = @($roms | Where-Object { $_.Sample }).Count
            $conPreview = @($roms | Where-Object { $_.Preview }).Count
            $conKiosk = @($roms | Where-Object { $_.Kiosk }).Count
            $pasanFiltro = @($roms | Where-Object {
                (-not [string]::IsNullOrWhiteSpace($_.NormalizedTitle)) -and
                (-not $_.Hack) -and (-not $_.Translation) -and (-not $_.Beta) -and
                (-not $_.Prototype) -and (-not $_.Demo) -and (-not $_.Homebrew) -and
                (-not $_.Pirate) -and (-not $_.Sample) -and (-not $_.Preview) -and (-not $_.Kiosk)
            }).Count
            $titulosUnicos = @($roms | Where-Object {
                (-not [string]::IsNullOrWhiteSpace($_.NormalizedTitle)) -and
                (-not $_.Hack) -and (-not $_.Translation) -and (-not $_.Beta) -and
                (-not $_.Prototype) -and (-not $_.Demo) -and (-not $_.Homebrew) -and
                (-not $_.Pirate) -and (-not $_.Sample) -and (-not $_.Preview) -and (-not $_.Kiosk)
            } | Select-Object -ExpandProperty NormalizedTitle -Unique).Count

            Write-Host ("Total ROMs                    : {0}" -f $totalRoms)
            Write-Host ("NormalizedTitle vacio/nulo     : {0}" -f $vacioONulo)
            Write-Host ("Excluidas por Hack             : {0}" -f $conHack)
            Write-Host ("Excluidas por Translation      : {0}" -f $conTranslation)
            Write-Host ("Excluidas por Beta             : {0}" -f $conBeta)
            Write-Host ("Excluidas por Prototype        : {0}" -f $conProto)
            Write-Host ("Excluidas por Demo             : {0}" -f $conDemo)
            Write-Host ("Excluidas por Homebrew         : {0}" -f $conHomebrew)
            Write-Host ("Excluidas por Pirate           : {0}" -f $conPirate)
            Write-Host ("Excluidas por Sample           : {0}" -f $conSample)
            Write-Host ("Excluidas por Preview          : {0}" -f $conPreview)
            Write-Host ("Excluidas por Kiosk            : {0}" -f $conKiosk)
            Write-Host ("ROMs que pasan el filtro       : {0}" -f $pasanFiltro)
            Write-Host ("Titulos normalizados unicos    : {0}" -f $titulosUnicos)
            Write-Host "------------------------------------------" -ForegroundColor Magenta
            Write-Host ""

            $Global:DiagnosticoMostrado = $true
        }

        $sysGroups = @(Group-Roms $roms)

        Write-Host "Grupos encontrados : $($sysGroups.Count)"

        $groups += $sysGroups
    }

    Write-Host ""
    Write-Host "-----------------------------------------"
    Write-Host "Grupos totales : $($groups.Count)"
    Write-Host ""

    #--------------------------------------------------------------
    # Decision Engine + Cleaner
    #--------------------------------------------------------------

    if($groups.Count -eq 0)
    {
        Write-Host ""
        Write-Host "No se han encontrado ROMs duplicadas. Nada que limpiar." -ForegroundColor Green
        Write-Host ""

        $actions = @()
    }
    else
    {
        $actions = Invoke-CleanPreview $groups
    }

    #--------------------------------------------------------------
    # Construcción del plan
    #--------------------------------------------------------------

    $plan = Build-CleanPlan $actions

    #--------------------------------------------------------------
    # Validación
    #--------------------------------------------------------------

    Validate-CleanPlan $plan

    #--------------------------------------------------------------
    # Vista previa
    #--------------------------------------------------------------

    Show-CleanPreview $plan.Actions

    #--------------------------------------------------------------
    # Resumen
    #--------------------------------------------------------------

    Show-CleanSummary $plan

    #--------------------------------------------------------------
    # Exportar plan
    #--------------------------------------------------------------

    $exported = Export-CleanPlan `
        -Plan $plan `
        -OutputFolder (Join-Path $Root "Resultado")

    Write-Host ""
    Write-Host "Plan exportado en:"
    Write-Host "  - $($exported.Json)"
    Write-Host "  - $($exported.Csv)"
    Write-Host "  - $($exported.Html)  (informe visual, ábrelo con el navegador)"

    #--------------------------------------------------------------
    # Confirmación
    #--------------------------------------------------------------

    if($plan.Actions.Count -eq 0)
    {
        Write-Host ""
        Write-Host "No hay ninguna acción que ejecutar."
        return
    }

    if($Global:Settings.AskConfirmation)
    {
        Write-Host ""

        $answer = Read-Host "¿Ejecutar el plan? (S/N)"

        if($answer -notmatch '^[Ss]$')
        {
            Write-Host ""
            Write-Host "Operación cancelada."
            return
        }
    }

    #--------------------------------------------------------------
    # Ejecución
    #--------------------------------------------------------------

    Invoke-CleanExecute $plan

}

function Invoke-CleanPreview {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Groups
    )

    Pause

    $actions = @()

    foreach($group in $Groups)
    {
        foreach($r in $group.Roms)
        {
            Write-Host " -" $r.Title
        }

        Write-Host ""
        Write-Host "===================================="
        Write-Host "GRUPO:" $group.Name
        Write-Host "ROMS :" $group.Roms.Count

        #
        # Decision Engine
        #

        $decision = Decide-RomGroup $group.Roms

        if($null -eq $decision)
        {
            continue
        }

        #
        # KEEP
        #

        $actions += New-CleanAction `
            -Action "KEEP" `
            -Rom $decision.Keep `
            -Reason ($decision.KeepReason -join "`n")

        #
        # MOVE
        #

        foreach($item in $decision.MoveReasons)
        {
            $target = Get-DuplicateTargetFolder $item.Rom

            $actions += New-CleanAction `
                -Action "MOVE" `
                -Rom $item.Rom `
                -Target $target `
                -Reason ($item.Reason -join "`n")
        }
    }

    return $actions

}

# ============================================================
# Obtener estadísticas del plan
# ============================================================

function Get-CleanStatistics {

    param(
        [Parameter(Mandatory)]
        $Plan
    )

    $systems = $Plan.Actions |
        ForEach-Object {
            Split-Path (Split-Path $_.Source -Parent) -Leaf
        } |
        Sort-Object -Unique

    return [PSCustomObject]@{

        TotalActions = $Plan.TotalActions

        KeepCount = $Plan.TotalKeep

        MoveCount = $Plan.TotalMove

        DeleteCount = $Plan.TotalDelete

        RenameCount = $Plan.TotalRename

        SystemCount = $systems.Count

		Systems = $systems

        BuildDate = $Plan.BuildDate

        Version = $Plan.Version

    }

}

# ============================================================
# Mostrar vista previa
# ============================================================

function Show-CleanPreview {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Actions
    )

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "             PREVISUALIZACIÓN"
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""

    foreach($action in $Actions)
    {
        switch($action.Action)
        {
            "KEEP"
            {
                Write-Host "[KEEP]" -ForegroundColor Green
            }

            "MOVE"
            {
                Write-Host "[MOVE]" -ForegroundColor Yellow
            }

            "DELETE"
            {
                Write-Host "[DELETE]" -ForegroundColor Red
            }

            default
            {
                Write-Host "[$($action.Action)]"
            }
        }

        Write-Host $action.Source

        if($action.Target)
        {
            Write-Host "Destino : $($action.Target)"
        }

        Write-Host "Motivo:"
        Write-Host $action.Reason

        Write-Host ""
    }
}

# ============================================================
# Construye el plan completo de limpieza
# ============================================================

function Build-CleanPlan {

    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Actions
    )

    $plan = [PSCustomObject]@{

        Actions = $Actions

        KeepActions = @(
            $Actions | Where-Object Action -eq "KEEP"
        )

        MoveActions = @(
            $Actions | Where-Object Action -eq "MOVE"
        )

        DeleteActions = @(
            $Actions | Where-Object Action -eq "DELETE"
        )

        RenameActions = @(
            $Actions | Where-Object Action -eq "RENAME"
        )

    }

    #
    # Totales
    #

    $plan | Add-Member NoteProperty TotalKeep   $plan.KeepActions.Count
    $plan | Add-Member NoteProperty TotalMove   $plan.MoveActions.Count
    $plan | Add-Member NoteProperty TotalDelete $plan.DeleteActions.Count
    $plan | Add-Member NoteProperty TotalRename $plan.RenameActions.Count
	$plan | Add-Member NoteProperty TotalActions $Actions.Count
	$plan | Add-Member NoteProperty BuildDate (Get-Date)
	$plan | Add-Member NoteProperty Version "Beta Clean Roms v2.5"

    return $plan

}

# ============================================================
# Valida el plan antes de ejecutarlo
# ============================================================

function Validate-CleanPlan {

    param(
        [Parameter(Mandatory)]
        $Plan
    )

    #
    # No puede haber dos KEEP del mismo archivo
    #

    $duplicates = @(
        $Plan.KeepActions |
            Group-Object Source |
            Where-Object Count -gt 1
    )

    if($duplicates.Count -gt 0)
    {
        throw "El plan contiene acciones KEEP duplicadas."
    }

    #
    # Una acción MOVE necesita destino
    #

    foreach($action in $Plan.MoveActions)
    {
        if([string]::IsNullOrWhiteSpace($action.Target))
        {
            throw "Acción MOVE sin destino: $($action.Source)"
        }
    }

    return $true

}

# ============================================================
# Exporta el plan de limpieza
# ============================================================

function Export-CleanPlan {

    param(

        [Parameter(Mandatory)]
        $Plan,

        [Parameter(Mandatory)]
        [string]$OutputFolder

    )

    if(!(Test-Path -LiteralPath $OutputFolder))
    {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    $jsonFile = Join-Path $OutputFolder "CleanPlan.json"

    $csvFile = Join-Path $OutputFolder "CleanPlan.csv"

    $htmlFile = Join-Path $OutputFolder "CleanPlan.html"

    #
    # JSON completo
    #

    $Plan.Actions |
        ConvertTo-Json -Depth 10 |
        Set-Content $jsonFile -Encoding UTF8

    #
    # CSV resumido
    #

    $Plan.Actions |
        Select-Object `
            Action,
            Source,
            Target,
            Reason |
        Export-Csv `
            -Path $csvFile `
            -NoTypeInformation `
            -Encoding UTF8

    #
    # Informe HTML (para abrir con doble clic y revisar cómodamente)
    #

    New-CleanPlanHtmlReport -Plan $Plan |
        Set-Content $htmlFile -Encoding UTF8

    return [PSCustomObject]@{

        Json = $jsonFile

        Csv  = $csvFile

        Html = $htmlFile

    }

}

# ============================================================
# Generar el informe HTML del plan de limpieza
# ============================================================

function New-CleanPlanHtmlReport {

    param(

        [Parameter(Mandatory)]
        $Plan

    )

    function Convert-HtmlSafe($Text)
    {
        if([string]::IsNullOrEmpty($Text))
        {
            return ""
        }

        return [System.Net.WebUtility]::HtmlEncode($Text)
    }

    $rows = ""

    foreach($action in $Plan.Actions)
    {
        $rowClass = switch($action.Action)
        {
            "KEEP"   { "keep" }
            "MOVE"   { "move" }
            "DELETE" { "delete" }
            "RENAME" { "rename" }
            default  { "" }
        }

        $source = Convert-HtmlSafe $action.Source
        $target = Convert-HtmlSafe $action.Target
        $reason = Convert-HtmlSafe ($action.Reason -replace "`n", " · ")

        $rows += "<tr class=`"$rowClass`"><td>$($action.Action)</td><td>$source</td><td>$target</td><td>$reason</td></tr>`n"
    }

    $keepCount   = @($Plan.Actions | Where-Object { $_.Action -eq "KEEP" }).Count
    $moveCount   = @($Plan.Actions | Where-Object { $_.Action -eq "MOVE" }).Count
    $deleteCount = @($Plan.Actions | Where-Object { $_.Action -eq "DELETE" }).Count
    $renameCount = @($Plan.Actions | Where-Object { $_.Action -eq "RENAME" }).Count

    $date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Beta CleanROMs - Informe de limpieza</title>
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background:#f4f6f8; color:#222; margin:0; padding:24px; }
    h1 { color:#1b3a5c; margin-bottom:4px; }
    .meta { color:#666; margin-bottom:20px; }
    .stats { display:flex; gap:14px; margin-bottom:22px; flex-wrap:wrap; }
    .stat { background:#fff; border-radius:8px; padding:10px 22px; box-shadow:0 1px 3px rgba(0,0,0,0.12); min-width:100px; text-align:center; }
    .stat .n { font-size:22px; font-weight:bold; display:block; }
    .stat.keep .n   { color:#2e7d32; }
    .stat.move .n   { color:#b8860b; }
    .stat.delete .n { color:#c62828; }
    .stat.rename .n { color:#1565c0; }
    table { width:100%; border-collapse:collapse; background:#fff; box-shadow:0 1px 3px rgba(0,0,0,0.1); }
    th, td { padding:7px 10px; text-align:left; border-bottom:1px solid #e5e5e5; font-size:12.5px; word-break:break-all; }
    th { background:#1b3a5c; color:#fff; position:sticky; top:0; }
    tr.keep td:first-child   { color:#2e7d32; font-weight:bold; }
    tr.move td:first-child   { color:#b8860b; font-weight:bold; }
    tr.delete td:first-child { color:#c62828; font-weight:bold; }
    tr.rename td:first-child { color:#1565c0; font-weight:bold; }
    tr:hover { background:#f0f4f8; }
</style>
</head>
<body>
    <h1>Beta CleanROMs &mdash; Informe de limpieza</h1>
    <div class="meta">Generado: $date</div>
    <div class="stats">
        <div class="stat keep"><span class="n">$keepCount</span>KEEP</div>
        <div class="stat move"><span class="n">$moveCount</span>MOVE</div>
        <div class="stat delete"><span class="n">$deleteCount</span>DELETE</div>
        <div class="stat rename"><span class="n">$renameCount</span>RENAME</div>
    </div>
    <table>
        <thead>
            <tr><th>Acción</th><th>Archivo</th><th>Destino</th><th>Motivo</th></tr>
        </thead>
        <tbody>
$rows
        </tbody>
    </table>
</body>
</html>
"@

    return $html

}

# ============================================================
# Obtener carpeta destino de duplicados
# ============================================================

function Get-DuplicateTargetFolder {

    param(
        [Parameter(Mandatory)]
        $Rom
    )

    #
    # Carpeta del sistema
    #

    $systemFolder = Split-Path $Rom.FullPath -Parent

    #
    # Nombre del sistema
    #

    $systemName = Split-Path $systemFolder -Leaf

    #
    # Carpeta destino
    #

    $target = Join-Path `
        (Join-Path $Global:RetroBatRoot $Global:DuplicatesFolder) `
        $systemName

    return $target

}


