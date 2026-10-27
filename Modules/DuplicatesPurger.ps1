# ============================================================
# CleanROMs
#
# DuplicatesPurger.ps1
#
# Purga de _duplicates. Es lo UNICO que el programa borra de verdad:
# todo lo demas solo MUEVE archivos (y se puede deshacer). Con el
# tiempo _duplicates solo crece, asi que esta opcion borra las copias
# que llevan N dias o mas alli.
#
# Cuidados:
#
# - La antiguedad es "desde que se MOVIO a _duplicates", no la fecha
#   del archivo (que conserva la del archivo original, a veces de
#   hace decadas). Se saca de los planes guardados (CleanPlan.json y
#   Resultado\History\); si hay varios movimientos del mismo archivo
#   cuenta el ULTIMO.
# - Los archivos sin fecha de movimiento conocida (p.ej. de planes
#   que ya se rotaron fuera del historial) no se borran nunca "de
#   golpe": su cuenta empieza el primer dia que la purga los ve
#   (Resultado\DuplicatesSeen.tsv) y hasta pasados N dias no son
#   candidatos.
# - Siempre se enseña antes lo que se va a borrar y se pide
#   confirmacion (con -Yes, sin preguntar). Con PreviewOnly solo se
#   simula.
# - Solo toca archivos dentro de la carpeta _duplicates.
# - Lo borrado se anota en Resultado\PurgeLog_<fecha>.txt.
# - Despues de borrar, "Deshacer" ya no puede devolver esos archivos
#   (se salta los que no estan), pero sigue funcionando para el resto.
# ============================================================

#--------------------------------------------------------------
# Utilidades
#--------------------------------------------------------------

function Get-DuplicatesRoot {

    return Join-Path $Global:RetroBatRoot $Global:DuplicatesFolder
}

function Format-FileSize {

    param([long]$Bytes)

    if($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if($Bytes -ge 1MB) { return ("{0:N1} MB" -f ($Bytes / 1MB)) }
    if($Bytes -ge 1KB) { return ("{0:N1} KB" -f ($Bytes / 1KB)) }

    return "$Bytes B"
}

function ConvertTo-PurgeDate {

    param($Value)

    if($null -eq $Value)
    {
        return $null
    }

    if($Value -is [datetime])
    {
        return $Value.ToUniversalTime()
    }

    $text = [string]$Value

    # Windows PowerShell 5.1 serializa las fechas como "/Date(1700000000000)/"
    if($text -match '/Date\((-?\d+)')
    {
        return [System.DateTimeOffset]::FromUnixTimeMilliseconds([long]$Matches[1]).UtcDateTime
    }

    $parsed = [datetime]::MinValue
    $styles = [System.Globalization.DateTimeStyles]::AssumeLocal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal

    if([datetime]::TryParse($text, [System.Globalization.CultureInfo]::InvariantCulture, $styles, [ref]$parsed))
    {
        return $parsed
    }

    return $null
}

#--------------------------------------------------------------
# Cuando llego cada archivo a _duplicates, segun los planes
# guardados: ruta completa (minusculas) -> fecha (UTC) del ULTIMO
# movimiento
#--------------------------------------------------------------

function Get-MoveDatesFromPlans {

    param([Parameter(Mandatory)][string]$Root)

    $dates = @{}

    $resultFolder = Join-Path $Root "Resultado"

    $planFiles = @()

    $current = Join-Path $resultFolder "CleanPlan.json"

    if(Test-Path -LiteralPath $current)
    {
        $planFiles += $current
    }

    $historyFolder = Join-Path $resultFolder "History"

    if(Test-Path -LiteralPath $historyFolder)
    {
        $planFiles += @(Get-ChildItem -LiteralPath $historyFolder -Filter *.json -File | ForEach-Object FullName)
    }

    foreach($planFile in $planFiles)
    {
        try
        {
            $actions = @(Get-Content -LiteralPath $planFile -Raw | ConvertFrom-Json)
        }
        catch
        {
            continue
        }

        foreach($action in $actions)
        {
            if($null -eq $action.PSObject.Properties["Action"] -or $action.Action -ne "MOVE")
            {
                continue
            }

            $date = ConvertTo-PurgeDate $action.PSObject.Properties["TimeStamp"].Value

            if($null -eq $date -or [string]::IsNullOrWhiteSpace([string]$action.Target) -or [string]::IsNullOrWhiteSpace([string]$action.Source))
            {
                continue
            }

            $names = @(Split-Path ([string]$action.Source) -Leaf)

            $assoc = $action.PSObject.Properties["AssociatedFiles"]

            if($null -ne $assoc -and $null -ne $assoc.Value)
            {
                $names += @($assoc.Value | ForEach-Object { [string]$_ })
            }

            foreach($name in $names)
            {
                if([string]::IsNullOrWhiteSpace($name))
                {
                    continue
                }

                try
                {
                    $key = [System.IO.Path]::GetFullPath((Join-Path ([string]$action.Target) $name)).ToLowerInvariant()
                }
                catch
                {
                    continue
                }

                if(-not $dates.ContainsKey($key) -or $date -gt $dates[$key])
                {
                    $dates[$key] = $date
                }
            }
        }
    }

    return $dates
}

#--------------------------------------------------------------
# "Visto por primera vez": para los archivos sin fecha en los
# planes. Cada linea: ruta, tamano, fecha de modificacion, y cuando
# se vio por primera vez. Si el archivo ya no es el mismo (otro
# tamano o fecha) la entrada no vale.
#--------------------------------------------------------------

function Get-DuplicatesSeenPath {

    param([Parameter(Mandatory)][string]$Root)

    return Join-Path (Join-Path $Root "Resultado") "DuplicatesSeen.tsv"
}

function Read-DuplicatesSeen {

    param([Parameter(Mandatory)][string]$Root)

    $seen = @{}
    $path = Get-DuplicatesSeenPath -Root $Root

    if(![System.IO.File]::Exists($path))
    {
        return $seen
    }

    try
    {
        $first = $true

        # ReadAllLines: cierra el archivo siempre, aunque se salga del bucle antes de tiempo
        foreach($line in [System.IO.File]::ReadAllLines($path))
        {
            if($first)
            {
                $first = $false

                if(-not $line.StartsWith("CleanROMs-DuplicatesSeen"))
                {
                    return @{}
                }

                continue
            }

            $parts = $line -split "`t"

            if($parts.Count -ne 4)
            {
                continue
            }

            $size = 0L
            $mtime = 0L
            $seenTicks = 0L

            if([long]::TryParse($parts[1], [ref]$size) -and [long]::TryParse($parts[2], [ref]$mtime) -and [long]::TryParse($parts[3], [ref]$seenTicks))
            {
                $seen[$parts[0].ToLowerInvariant()] = [PSCustomObject]@{
                    Size    = $size
                    Ticks   = $mtime
                    SeenUtc = (New-Object System.DateTime($seenTicks, [System.DateTimeKind]::Utc))
                }
            }
        }
    }
    catch
    {
        return @{}
    }

    return $seen
}

function Save-DuplicatesSeen {

    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$Entries
    )

    $path = Get-DuplicatesSeenPath -Root $Root

    try
    {
        $folder = Split-Path $path -Parent

        if(![System.IO.Directory]::Exists($folder))
        {
            [System.IO.Directory]::CreateDirectory($folder) | Out-Null
        }

        $lines = New-Object 'System.Collections.Generic.List[string]'
        $lines.Add("CleanROMs-DuplicatesSeen`t1")

        foreach($e in $Entries)
        {
            $lines.Add("$($e.Path)`t$($e.Size)`t$($e.Ticks)`t$($e.SeenTicks)")
        }

        [System.IO.File]::WriteAllLines($path, $lines, (New-Object System.Text.UTF8Encoding($false)))
    }
    catch
    {
        # Sin esta anotacion, esos archivos simplemente no se purgaran todavia
    }
}

#--------------------------------------------------------------
# Que archivos de _duplicates llevan $Days dias o mas
#
# Devuelve:
#   Candidates  archivos que ya se pueden borrar
#   Undated     archivos sin fecha conocida (su cuenta empieza hoy)
#   TotalFiles  todos los archivos de _duplicates
#--------------------------------------------------------------

function Get-PurgeCandidates {

    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][int]$Days,
        [datetime]$NowUtc = [datetime]::UtcNow,

        # Todos los archivos son candidatos, sin importar cuando se movieron
        # (los que no tienen fecha conocida tambien)
        [switch]$All
    )

    $result = [PSCustomObject]@{
        Candidates = @()
        Undated    = @()
        TotalFiles = 0
    }

    $dupRoot = Get-DuplicatesRoot

    if(!(Test-Path -LiteralPath $dupRoot -PathType Container))
    {
        return $result
    }

    $moveDates = Get-MoveDatesFromPlans -Root $Root
    $seen = Read-DuplicatesSeen -Root $Root
    $cutoff = $NowUtc.AddDays(-$Days)

    $dupFull = [System.IO.Path]::GetFullPath($dupRoot).TrimEnd('\', '/')

    $candidates = @()
    $undated = @()
    $total = 0

    foreach($file in @(Get-ChildItem -LiteralPath $dupRoot -File -Recurse -Force))
    {
        # Nunca se sigue un enlace simbolico fuera de _duplicates
        if($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        {
            continue
        }

        $total++

        $key = $file.FullName.ToLowerInvariant()
        $date = $null

        if($moveDates.ContainsKey($key))
        {
            $date = $moveDates[$key]
        }
        elseif($seen.ContainsKey($key))
        {
            $s = $seen[$key]

            if($s.Size -eq $file.Length -and $s.Ticks -eq $file.LastWriteTimeUtc.Ticks)
            {
                $date = $s.SeenUtc
            }
        }

        if($All)
        {
            $relative = [System.IO.Path]::GetRelativePath($dupFull, $file.FullName)

            $candidates += [PSCustomObject]@{
                FullPath = $file.FullName
                System   = ($relative -split '[\\/]')[0]
                Size     = $file.Length
                AgeDays  = $(if($null -ne $date) { [int][math]::Floor(($NowUtc - $date).TotalDays) } else { 0 })
            }

            continue
        }

        if($null -eq $date)
        {
            $undated += $file
            continue
        }

        if($date -le $cutoff)
        {
            $relative = [System.IO.Path]::GetRelativePath($dupFull, $file.FullName)
            $systemName = ($relative -split '[\\/]')[0]

            $candidates += [PSCustomObject]@{
                FullPath = $file.FullName
                System   = $systemName
                Size     = $file.Length
                AgeDays  = [int][math]::Floor(($NowUtc - $date).TotalDays)
            }
        }
    }

    $result.Candidates = @($candidates)
    $result.Undated = @($undated)
    $result.TotalFiles = $total

    return $result
}

#--------------------------------------------------------------
# Anota los archivos sin fecha (y conserva las anotaciones que
# siguen valiendo) para que su cuenta empiece hoy
#--------------------------------------------------------------

function Register-UndatedDuplicates {

    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][array]$Files,
        [datetime]$NowUtc = [datetime]::UtcNow
    )

    $seen = Read-DuplicatesSeen -Root $Root
    $entries = @{}

    foreach($key in $seen.Keys)
    {
        # Solo se conservan las que siguen siendo el mismo archivo
        if(![System.IO.File]::Exists($key))
        {
            continue
        }

        $info = New-Object System.IO.FileInfo $key

        if($info.Length -eq $seen[$key].Size -and $info.LastWriteTimeUtc.Ticks -eq $seen[$key].Ticks)
        {
            $entries[$key] = [PSCustomObject]@{
                Path      = $info.FullName
                Size      = $info.Length
                Ticks     = $info.LastWriteTimeUtc.Ticks
                SeenTicks = $seen[$key].SeenUtc.Ticks
            }
        }
    }

    foreach($file in $Files)
    {
        $key = $file.FullName.ToLowerInvariant()

        if(-not $entries.ContainsKey($key))
        {
            $entries[$key] = [PSCustomObject]@{
                Path      = $file.FullName
                Size      = $file.Length
                Ticks     = $file.LastWriteTimeUtc.Ticks
                SeenTicks = $NowUtc.Ticks
            }
        }
    }

    Save-DuplicatesSeen -Root $Root -Entries @($entries.Values)
}

#--------------------------------------------------------------
# Punto de entrada
#--------------------------------------------------------------

function Invoke-DuplicatesPurge {

    param(
        [Parameter(Mandatory)]
        [string]$Root,

        # -1 = usar PurgeDuplicatesAfterDays de Settings.ps1 (90 por defecto)
        #  0 = borrar TODO lo que haya en _duplicates, sin importar cuando se movio
        # >0 = borrar lo que lleve esos dias o mas
        [int]$Days = -1
    )

    $summary = [PSCustomObject]@{
        Deleted    = 0
        Failed     = 0
        FreedBytes = 0L
        Candidates = 0
    }

    $all = ($Days -eq 0)

    if($Days -lt 0)
    {
        $Days = 90

        if($Global:Settings.ContainsKey("PurgeDuplicatesAfterDays") -and [int]$Global:Settings.PurgeDuplicatesAfterDays -gt 0)
        {
            $Days = [int]$Global:Settings.PurgeDuplicatesAfterDays
        }
    }

    $preview = [bool]$Global:Settings.PreviewOnly
    $dupRoot = Get-DuplicatesRoot

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    if($all)
    {
        Write-Host (T "purge.headerAll")
    }
    else
    {
        Write-Host (T "purge.header" $Days)
    }
    Write-Host "==========================================" -ForegroundColor Cyan

    if(!(Test-Path -LiteralPath $dupRoot -PathType Container))
    {
        Write-Host (T "purge.folderMissing" $dupRoot)
        return $summary
    }

    $found = Get-PurgeCandidates -Root $Root -Days $Days -All:$all

    # Los que no tienen fecha empiezan a contar hoy (no en simulacion)
    if($found.Undated.Count -gt 0)
    {
        Write-Host (T "purge.undated" @($found.Undated.Count, $Days)) -ForegroundColor DarkGray

        if(-not $preview)
        {
            Register-UndatedDuplicates -Root $Root -Files $found.Undated
        }
    }

    $candidates = @($found.Candidates)
    $summary.Candidates = $candidates.Count

    if($candidates.Count -eq 0)
    {
        if(-not $all -and $found.TotalFiles -gt 0)
        {
            # Hay archivos, pero aun no llevan los dias pedidos: se explica
            # como borrarlos igualmente (era lo que mas confundia)
            Write-Host (T "purge.nothingButFiles" @($found.TotalFiles, $Days))
        }
        else
        {
            Write-Host (T "purge.nothing" $Days)
        }

        return $summary
    }

    $totalBytes = [long](($candidates | Measure-Object Size -Sum).Sum)

    Write-Host ""

    foreach($systemGroup in ($candidates | Group-Object System | Sort-Object Name))
    {
        $bytes = [long](($systemGroup.Group | Measure-Object Size -Sum).Sum)
        Write-Host (T "purge.systemLine" @($systemGroup.Name, $systemGroup.Count, (Format-FileSize $bytes)))
    }

    Write-Host ""

    $shown = 0

    foreach($c in ($candidates | Sort-Object AgeDays -Descending))
    {
        if($shown -ge 15)
        {
            break
        }

        Write-Host (T "purge.fileLine" @([System.IO.Path]::GetRelativePath($dupRoot, $c.FullPath), $c.AgeDays)) -ForegroundColor DarkGray
        $shown++
    }

    if($candidates.Count -gt $shown)
    {
        Write-Host (T "purge.more" ($candidates.Count - $shown)) -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host (T "purge.total" @($candidates.Count, (Format-FileSize $totalBytes)))

    if($preview)
    {
        Write-Host (T "purge.previewOnly") -ForegroundColor DarkYellow
        return $summary
    }

    $confirmKey = if($all) { "purge.confirmAll" } else { "purge.confirm" }

    if(-not (Confirm-YesNo $confirmKey @($candidates.Count, (Format-FileSize $totalBytes))))
    {
        Write-Host (T "purge.cancelled")
        return $summary
    }

    #
    # Borrado. Una ultima comprobacion por archivo: debe seguir
    # estando DENTRO de _duplicates.
    #

    $dupFull = [System.IO.Path]::GetFullPath($dupRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $deletedPaths = @()

    foreach($c in $candidates)
    {
        try
        {
            $full = [System.IO.Path]::GetFullPath($c.FullPath)

            if(-not $full.StartsWith($dupFull, [System.StringComparison]::OrdinalIgnoreCase))
            {
                continue
            }

            Remove-Item -LiteralPath $full -Force -ErrorAction Stop

            $summary.Deleted++
            $summary.FreedBytes += $c.Size
            $deletedPaths += $full
        }
        catch
        {
            $summary.Failed++
            $Global:ActionErrorCount = [int]$Global:ActionErrorCount + 1

            Write-Warning (T "purge.failed" @($c.FullPath, $_.Exception.Message))
        }
    }

    #
    # Quita las carpetas que hayan quedado vacias (nunca la propia
    # _duplicates)
    #

    foreach($dir in @(Get-ChildItem -LiteralPath $dupRoot -Directory -Recurse -Force |
        Sort-Object { $_.FullName.Length } -Descending))
    {
        if(@(Get-ChildItem -LiteralPath $dir.FullName -Force).Count -eq 0)
        {
            Remove-Item -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    if($deletedPaths.Count -gt 0)
    {
        $logFile = Join-Path (Join-Path $Root "Resultado") ("PurgeLog_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

        try
        {
            $logFolder = Split-Path $logFile -Parent

            if(!(Test-Path -LiteralPath $logFolder))
            {
                New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
            }

            Set-Content -LiteralPath $logFile -Value $deletedPaths -Encoding UTF8
            Write-Host (T "purge.logAt" $logFile) -ForegroundColor DarkGray
        }
        catch
        {
            # el log es un extra
        }
    }

    Write-Host (T "purge.deleted" @($summary.Deleted, (Format-FileSize $summary.FreedBytes)))

    return $summary
}

#--------------------------------------------------------------
# Pregunta cuantos dias (opcion de menu). Devuelve 0 para "el valor
# de Settings.ps1" (Enter, o modo no interactivo).
#--------------------------------------------------------------

function Read-PurgeDays {

    $default = 90

    if($Global:Settings.ContainsKey("PurgeDuplicatesAfterDays") -and [int]$Global:Settings.PurgeDuplicatesAfterDays -gt 0)
    {
        $default = [int]$Global:Settings.PurgeDuplicatesAfterDays
    }

    # Devuelve -1 para "el valor de Settings.ps1" (Intro, o modo no
    # interactivo), 0 para "TODO lo que haya ahora" y N>0 para "N dias o mas".
    if($Global:AutoConfirm)
    {
        return -1
    }

    while($true)
    {
        $answer = (Read-Host (T "purge.askDays" $default)).Trim()

        if($answer -eq "")
        {
            return -1
        }

        $days = 0

        if([int]::TryParse($answer, [ref]$days) -and $days -ge 0 -and $days -le 3650)
        {
            return $days
        }

        Write-Host (T "purge.invalidDays") -ForegroundColor Yellow
    }
}
