# ============================================================
# CleanROMs
#
# GamelistManager.ps1
#
# Conserva los datos del usuario de gamelist.xml (favorito, veces
# jugada, ultima partida, nota...) cuando una ROM se mueve a
# _duplicates: se fusionan en la entrada de la ROM que se queda.
#
# Reglas (pensadas para que ejecutar la fusion dos veces, por
# ejemplo tras un "Deshacer" y una limpieza nueva, NO duplique
# datos):
#
# - Datos de uso: favorite = verdadero si lo es en cualquiera;
#   playcount y gametime = el mayor de los dos (NO se suman);
#   lastplayed = la fecha mas reciente; rating = la nota mas alta.
# - Datos descriptivos (name, desc, developer, publisher, genre,
#   players, releasedate, kidgame, adult, family): solo se copian
#   si la ROM que se queda no los tiene.
# - NUNCA se copian rutas de imagen/video/manual, ni md5, crc32,
#   region o lang: pertenecen al archivo concreto, y los medios de
#   la ROM movida los trata despues "Limpiar huerfanos".
# - NUNCA se borra ninguna entrada: la de la ROM movida se queda
#   donde esta (EmulationStation ignora las entradas sin archivo),
#   asi "Deshacer" sigue funcionando sin tocar el gamelist.xml.
# - Antes de guardar se hace copia de seguridad del gamelist.xml
#   en Resultado\GamelistBackups\.
# ============================================================

$Global:GamelistTextFields = @(
    "name", "desc", "developer", "publisher", "genre",
    "players", "releasedate", "kidgame", "adult", "family"
)

#--------------------------------------------------------------
# Normaliza una ruta de gamelist ("./sub\Juego.sfc") a una clave
# comparable ("sub/juego.sfc")
#--------------------------------------------------------------

function ConvertTo-GamelistKey {

    param([string]$Path)

    if([string]::IsNullOrWhiteSpace($Path))
    {
        return ""
    }

    $key = $Path.Trim().Replace('\', '/')

    while($key.StartsWith("./"))
    {
        $key = $key.Substring(2)
    }

    return $key.ToLowerInvariant()
}

function Get-RomRelativePath {

    param(
        [Parameter(Mandatory)]
        [string]$SystemFolder,

        [Parameter(Mandatory)]
        [string]$RomPath
    )

    return [System.IO.Path]::GetRelativePath($SystemFolder, $RomPath).Replace('\', '/')
}

function Get-GamelistFieldText {

    param($Node, [string]$Name)

    $child = $Node.SelectSingleNode($Name)

    if($null -eq $child)
    {
        return ""
    }

    return [string]$child.InnerText
}

function Test-XmlWhitespaceNode {

    param($Node)

    return ($null -ne $Node) -and (
        $Node.NodeType -eq [System.Xml.XmlNodeType]::Whitespace -or
        $Node.NodeType -eq [System.Xml.XmlNodeType]::SignificantWhitespace
    )
}

#--------------------------------------------------------------
# Escribe un campo en una entrada <game>, creandolo (con la misma
# sangria que el resto) si no existia
#--------------------------------------------------------------

function Set-GamelistFieldText {

    param($Doc, $Node, [string]$Name, [string]$Value)

    $child = $Node.SelectSingleNode($Name)

    if($null -ne $child)
    {
        $child.InnerText = $Value
        return
    }

    $element = $Doc.CreateElement($Name)
    $element.InnerText = $Value

    $firstWhitespace = $null

    foreach($c in $Node.ChildNodes)
    {
        if(Test-XmlWhitespaceNode $c)
        {
            $firstWhitespace = $c
            break
        }
    }

    $last = $Node.LastChild

    if(($null -ne $firstWhitespace) -and (Test-XmlWhitespaceNode $last))
    {
        $Node.InsertBefore($element, $last) | Out-Null
        $Node.InsertBefore($Doc.CreateWhitespace($firstWhitespace.Value), $element) | Out-Null
    }
    else
    {
        $Node.AppendChild($element) | Out-Null
    }
}

#--------------------------------------------------------------
# Fusiona los datos de la entrada $Loser en la entrada $Winner.
# Devuelve los nombres de los campos que cambiaron en $Winner.
#--------------------------------------------------------------

function Merge-GamelistGameNode {

    param($Doc, $Winner, $Loser)

    $changed = @()

    # Favorito

    if((Get-GamelistFieldText $Loser "favorite") -eq "true" -and
       (Get-GamelistFieldText $Winner "favorite") -ne "true")
    {
        Set-GamelistFieldText $Doc $Winner "favorite" "true"
        $changed += "favorite"
    }

    # Contadores: el mayor de los dos

    foreach($field in @("playcount", "gametime"))
    {
        $l = 0L
        $w = 0L

        [void][long]::TryParse((Get-GamelistFieldText $Loser $field), [ref]$l)
        [void][long]::TryParse((Get-GamelistFieldText $Winner $field), [ref]$w)

        if($l -gt $w)
        {
            Set-GamelistFieldText $Doc $Winner $field (Get-GamelistFieldText $Loser $field).Trim()
            $changed += $field
        }
    }

    # Nota: la mas alta

    $ratingStyle = [System.Globalization.NumberStyles]::Float
    $invariant = [System.Globalization.CultureInfo]::InvariantCulture

    $lr = 0.0
    $wr = 0.0

    [void][double]::TryParse((Get-GamelistFieldText $Loser "rating"), $ratingStyle, $invariant, [ref]$lr)
    [void][double]::TryParse((Get-GamelistFieldText $Winner "rating"), $ratingStyle, $invariant, [ref]$wr)

    if($lr -gt $wr)
    {
        Set-GamelistFieldText $Doc $Winner "rating" (Get-GamelistFieldText $Loser "rating").Trim()
        $changed += "rating"
    }

    # Ultima partida: la mas reciente (formato 20240131T120000)

    $ll = (Get-GamelistFieldText $Loser "lastplayed").Trim()
    $wl = (Get-GamelistFieldText $Winner "lastplayed").Trim()

    if($ll -ne "" -and [string]::CompareOrdinal($ll, $wl) -gt 0)
    {
        Set-GamelistFieldText $Doc $Winner "lastplayed" $ll
        $changed += "lastplayed"
    }

    # Datos descriptivos: solo si faltan

    foreach($field in $Global:GamelistTextFields)
    {
        $lt = (Get-GamelistFieldText $Loser $field).Trim()

        if($lt -ne "" -and (Get-GamelistFieldText $Winner $field).Trim() -eq "")
        {
            Set-GamelistFieldText $Doc $Winner $field $lt
            $changed += $field
        }
    }

    return @($changed)
}

#--------------------------------------------------------------
# Crea (sin insertar todavia) una entrada <game> nueva con solo
# su <path>, con la misma sangria que el resto del archivo
#--------------------------------------------------------------

function New-GamelistGameNode {

    param($Doc, $ListNode, [string]$RelativePath)

    $game = $Doc.CreateElement("game")

    $rootIndent = $null

    foreach($c in $ListNode.ChildNodes)
    {
        if(Test-XmlWhitespaceNode $c)
        {
            $rootIndent = $c.Value
            break
        }
    }

    if($null -ne $rootIndent)
    {
        $game.AppendChild($Doc.CreateWhitespace($rootIndent + "`t")) | Out-Null
    }

    $pathNode = $Doc.CreateElement("path")
    $pathNode.InnerText = "./" + $RelativePath
    $game.AppendChild($pathNode) | Out-Null

    if($null -ne $rootIndent)
    {
        $game.AppendChild($Doc.CreateWhitespace($rootIndent)) | Out-Null
    }

    return $game
}

function Add-GamelistGameNode {

    param($Doc, $ListNode, $Game)

    $last = $ListNode.LastChild

    if(Test-XmlWhitespaceNode $last)
    {
        $ListNode.InsertBefore($Game, $last) | Out-Null
        $ListNode.InsertBefore($Doc.CreateWhitespace($last.Value + "`t"), $Game) | Out-Null
    }
    else
    {
        $ListNode.AppendChild($Game) | Out-Null
    }
}

#--------------------------------------------------------------
# Copia de seguridad del gamelist.xml antes de modificarlo
#--------------------------------------------------------------

function Backup-GamelistFile {

    param(
        [Parameter(Mandatory)]
        [string]$GamelistPath,

        [Parameter(Mandatory)]
        [string]$SystemName,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $backupFolder = Join-Path (Join-Path $Root "Resultado") "GamelistBackups"

    if(!(Test-Path -LiteralPath $backupFolder))
    {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupFolder "gamelist_${SystemName}_$stamp.xml"

    $suffix = 1

    while(Test-Path -LiteralPath $backupFile)
    {
        $backupFile = Join-Path $backupFolder "gamelist_${SystemName}_${stamp}_$suffix.xml"
        $suffix++
    }

    Copy-Item -LiteralPath $GamelistPath -Destination $backupFile

    # Solo se conservan las ultimas copias de cada sistema

    $limit = $Global:Settings.UndoHistoryLimit

    if($null -eq $limit -or $limit -lt 1)
    {
        $limit = 10
    }

    $existing = @(
        Get-ChildItem -LiteralPath $backupFolder -Filter "gamelist_${SystemName}_*.xml" |
            Sort-Object LastWriteTime -Descending
    )

    if($existing.Count -gt $limit)
    {
        foreach($old in ($existing | Select-Object -Skip $limit))
        {
            Remove-Item -LiteralPath $old.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    return $backupFile
}

#--------------------------------------------------------------
# Guarda el XML conservando si el archivo original tenia BOM
#--------------------------------------------------------------

function Save-GamelistDocument {

    param($Doc, [string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)

    $hadBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)

    $encoding = New-Object System.Text.UTF8Encoding($hadBom)
    $writer = New-Object System.IO.StreamWriter($Path, $false, $encoding)

    try
    {
        $Doc.Save($writer)
    }
    finally
    {
        $writer.Dispose()
    }
}

#--------------------------------------------------------------
# Punto de entrada: se llama despues de ejecutar el plan
#--------------------------------------------------------------

function Invoke-GamelistMerge {

    param(
        [Parameter(Mandatory)]
        $Plan,

        [Parameter(Mandatory)]
        [string[]]$SystemFolders,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $result = [PSCustomObject]@{
        Updated = 0
        Created = 0
        Systems = 0
    }

    if($Global:Settings.ContainsKey("MergeGamelistMetadata") -and
       ($Global:Settings.MergeGamelistMetadata -eq $false))
    {
        return $result
    }

    $preview = [bool]$Global:Settings.PreviewOnly

    $moves = @(
        $Plan.MoveActions | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_.WinnerPath) -and
            -not [string]::IsNullOrWhiteSpace($_.System)
        }
    )

    if($moves.Count -eq 0)
    {
        return $result
    }

    foreach($folder in $SystemFolders)
    {
        $systemName = Split-Path $folder -Leaf
        $gamelistPath = Join-Path $folder "gamelist.xml"

        if(!(Test-Path -LiteralPath $gamelistPath))
        {
            continue
        }

        $sysMoves = @($moves | Where-Object { $_.System -eq $systemName })

        if(-not $preview)
        {
            #
            # Solo las ROMs que de verdad se han movido (el origen ya
            # no esta y el archivo esta en su destino)
            #

            $sysMoves = @(
                $sysMoves | Where-Object {
                    (-not (Test-Path -LiteralPath $_.Source)) -and
                    (Test-Path -LiteralPath (Join-Path $_.Target (Split-Path $_.Source -Leaf)))
                }
            )
        }

        if($sysMoves.Count -eq 0)
        {
            continue
        }

        try
        {
            $doc = New-Object System.Xml.XmlDocument
            $doc.PreserveWhitespace = $true

            try
            {
                $doc.Load($gamelistPath)
            }
            catch
            {
                Write-Warning (T "gamelist.invalidXml" @($gamelistPath, $_.Exception.Message))
                continue
            }

            $listNode = $doc.SelectSingleNode("/gameList")

            if($null -eq $listNode)
            {
                continue
            }

            $index = @{}

            foreach($game in @($listNode.SelectNodes("game")))
            {
                $key = ConvertTo-GamelistKey (Get-GamelistFieldText $game "path")

                if($key -ne "" -and -not $index.ContainsKey($key))
                {
                    $index[$key] = $game
                }
            }

            $sysUpdated = 0
            $sysCreated = 0

            foreach($move in $sysMoves)
            {
                $loserKey = ConvertTo-GamelistKey (Get-RomRelativePath $folder $move.Source)

                if(-not $index.ContainsKey($loserKey))
                {
                    continue
                }

                $loserNode = $index[$loserKey]
                $winnerRel = Get-RomRelativePath $folder $move.WinnerPath
                $winnerKey = ConvertTo-GamelistKey $winnerRel

                $loserName = Split-Path $move.Source -Leaf
                $winnerName = Split-Path $move.WinnerPath -Leaf

                if($index.ContainsKey($winnerKey))
                {
                    $changed = @(Merge-GamelistGameNode $doc $index[$winnerKey] $loserNode)

                    if($changed.Count -gt 0)
                    {
                        $sysUpdated++
                        $msgKey = if($preview) { "gamelist.previewMerged" } else { "gamelist.entryMerged" }
                        Write-Host (T $msgKey @($systemName, $loserName, $winnerName, ($changed -join ", "))) -ForegroundColor DarkCyan
                    }
                }
                else
                {
                    $newNode = New-GamelistGameNode $doc $listNode $winnerRel
                    $changed = @(Merge-GamelistGameNode $doc $newNode $loserNode)

                    if($changed.Count -gt 0)
                    {
                        Add-GamelistGameNode $doc $listNode $newNode
                        $index[$winnerKey] = $newNode
                        $sysCreated++
                        $msgKey = if($preview) { "gamelist.previewCreated" } else { "gamelist.entryCreated" }
                        Write-Host (T $msgKey @($systemName, $winnerName, $loserName, ($changed -join ", "))) -ForegroundColor DarkCyan
                    }
                }
            }

            if(($sysUpdated + $sysCreated) -gt 0)
            {
                $result.Systems++
                $result.Updated += $sysUpdated
                $result.Created += $sysCreated

                if(-not $preview)
                {
                    $backup = Backup-GamelistFile -GamelistPath $gamelistPath -SystemName $systemName -Root $Root
                    Save-GamelistDocument -Doc $doc -Path $gamelistPath
                    Write-Host (T "gamelist.backupAt" $backup) -ForegroundColor DarkGray
                }
            }
        }
        catch
        {
            Write-Warning (T "gamelist.failed" @($systemName, $_.Exception.Message))
            Write-Log "ERROR: gamelist $systemName : $($_.Exception.Message)"
            $Global:ActionErrorCount = [int]$Global:ActionErrorCount + 1
        }
    }

    if(($result.Updated + $result.Created) -gt 0)
    {
        $summaryKey = if($preview) { "gamelist.previewSummary" } else { "gamelist.summary" }
        Write-Host (T $summaryKey @($result.Updated, $result.Created, $result.Systems)) -ForegroundColor Cyan
    }

    return $result
}

#--------------------------------------------------------------
# Actualiza la RUTA (<path>) de las entradas del gamelist.xml cuando
# las ROMs cambian de sitio DENTRO del sistema (p.ej. al organizar los
# hacks sueltos en "# Hacks y Otros #", o al deshacerlo). Sin esto la
# entrada seguiria apuntando a la ruta antigua y RetroBat perderia
# los favoritos y el historial de ese juego.
#
# $Changes: objetos con From y To (rutas completas de la ROM antes y
# despues). Devuelve las rutas From cuya entrada se actualizo.
# No hace nada si MergeGamelistMetadata = $false, si no hay
# gamelist.xml, si el XML no se puede leer, o si ya hay otra entrada
# con la ruta nueva.
#--------------------------------------------------------------

function Update-GamelistEntryPaths {

    param(
        [Parameter(Mandatory)]
        [string]$SystemFolder,

        [Parameter(Mandatory)]
        [array]$Changes,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $applied = @()

    if($Global:Settings.ContainsKey("MergeGamelistMetadata") -and
       ($Global:Settings.MergeGamelistMetadata -eq $false))
    {
        return @()
    }

    $gamelistPath = Join-Path $SystemFolder "gamelist.xml"

    if(!(Test-Path -LiteralPath $gamelistPath))
    {
        return @()
    }

    $doc = New-Object System.Xml.XmlDocument
    $doc.PreserveWhitespace = $true

    try
    {
        $doc.Load($gamelistPath)
    }
    catch
    {
        Write-Warning (T "gamelist.invalidXml" @($gamelistPath, $_.Exception.Message))
        return @()
    }

    $listNode = $doc.SelectSingleNode("/gameList")

    if($null -eq $listNode)
    {
        return @()
    }

    $index = @{}

    foreach($game in @($listNode.SelectNodes("game")))
    {
        $key = ConvertTo-GamelistKey (Get-GamelistFieldText $game "path")

        if($key -ne "" -and -not $index.ContainsKey($key))
        {
            $index[$key] = $game
        }
    }

    foreach($change in $Changes)
    {
        $fromKey = ConvertTo-GamelistKey (Get-RomRelativePath $SystemFolder $change.From)
        $toRelative = Get-RomRelativePath $SystemFolder $change.To
        $toKey = ConvertTo-GamelistKey $toRelative

        if(-not $index.ContainsKey($fromKey) -or $index.ContainsKey($toKey))
        {
            continue
        }

        $node = $index[$fromKey]

        Set-GamelistFieldText $doc $node "path" ("./" + $toRelative)

        $index.Remove($fromKey)
        $index[$toKey] = $node

        $applied += $change.From
    }

    if($applied.Count -gt 0)
    {
        $systemName = Split-Path $SystemFolder -Leaf

        $backup = Backup-GamelistFile -GamelistPath $gamelistPath -SystemName $systemName -Root $Root
        Save-GamelistDocument -Doc $doc -Path $gamelistPath

        Write-Host (T "gamelist.pathsUpdated" @($systemName, $applied.Count)) -ForegroundColor DarkCyan
        Write-Host (T "gamelist.backupAt" $backup) -ForegroundColor DarkGray
    }

    return @($applied)
}
