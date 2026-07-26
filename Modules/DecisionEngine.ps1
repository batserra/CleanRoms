# ============================================================
#
# Beta CleanROMs v2.5
#
# DecisionEngine.ps1
#
# Motor de decisión
#
# ============================================================

Set-StrictMode -Version Latest

# ============================================================
# Comprobar configuración
# ============================================================

if($null -eq $Global:DecisionWeights)
{
    throw "DecisionWeights.ps1 no ha sido cargado."
}

# ============================================================
# Comprueba si una ROM es elegible
# ============================================================

function Test-RomEligibility
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    if($null -eq $Rom)
    {
        return $false
    }

    #
    # Nunca conservar Homebrew
    #

    if($Rom.Homebrew)
    {
        return $false
    }

    #
    # Nunca conservar Pirate
    #

    if($Rom.Pirate)
    {
        return $false
    }

    #
    # Nunca conservar Hacks
    #

    if($Rom.Hack)
    {
        return $false
    }

    return $true
}

# ============================================================
# Obtiene un peso de la configuración
# ============================================================

function Get-DecisionWeight
{
    param(
        [Parameter(Mandatory)]
        [string]$Key
    )

    if($Global:DecisionWeights.ContainsKey($Key))
    {
        return [int]$Global:DecisionWeights[$Key]
    }

    return 0
}

# ============================================================
# PUNTUACIÓN POR REGIÓN
# ============================================================

function Get-RegionScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    if([string]::IsNullOrWhiteSpace($Rom.Region))
    {
        return 0
    }

    $key = "Region_$($Rom.Region.ToUpper())"

    return Get-DecisionWeight $key
}

# ============================================================
# PUNTUACIÓN POR IDIOMA
# ============================================================

function Get-LanguageScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    if([string]::IsNullOrWhiteSpace($Rom.Language))
    {
        return 0
    }

    switch($Rom.Language)
    {
        "Spanish"
        {
            return Get-DecisionWeight "Language_Spanish"
        }

        "Multi-Spanish"
        {
            return Get-DecisionWeight "Language_MultiSpanish"
        }

        "Multi"
        {
            return Get-DecisionWeight "Language_Multi"
        }

        "English"
        {
            return Get-DecisionWeight "Language_English"
        }

        "Japanese"
        {
            return Get-DecisionWeight "Language_Japanese"
        }

        default
        {
            return Get-DecisionWeight "Language_Unknown"
        }
    }
}

# ============================================================
# PUNTUACIÓN POR DUMP
# ============================================================

function Get-DumpScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $score = 0

    if($Rom.Verified)
    {
        $score += Get-DecisionWeight "Verified"
    }

    if($Rom.BadDump)
    {
        $score += Get-DecisionWeight "BadDump"
    }

    return $score
}

# ============================================================
# PUNTUACIÓN POR ESTADO
# ============================================================

function Get-StateScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $score = 0

    if($Rom.Beta)
    {
        $score += Get-DecisionWeight "Beta"
    }

    if($Rom.Prototype)
    {
        $score += Get-DecisionWeight "Prototype"
    }

    if($Rom.Demo)
    {
        $score += Get-DecisionWeight "Demo"
    }

    if($Rom.Sample)
    {
        $score += Get-DecisionWeight "Sample"
    }

    if($Rom.Preview)
    {
        $score += Get-DecisionWeight "Preview"
    }

    if($Rom.Kiosk)
    {
        $score += Get-DecisionWeight "Kiosk"
    }

    return $score
}

# ============================================================
# PUNTUACIÓN POR HACKS
# ============================================================

function Get-HackScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $score = 0

    if($Rom.Hack)
    {
        $score += Get-DecisionWeight "Hack"
    }

    if($Rom.Homebrew)
    {
        $score += Get-DecisionWeight "Homebrew"
    }

    if($Rom.Pirate)
    {
        $score += Get-DecisionWeight "Pirate"
    }

    return $score
}

# ============================================================
# PUNTUACIÓN POR VERSIÓN
# ============================================================

function Get-VersionScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    if([string]::IsNullOrWhiteSpace($Rom.Version))
    {
        return 0
    }

    $version = $Rom.Version.Trim()

    if($version -match '^([0-9]+(?:\.[0-9]+)?)$')
    {
        return [int]([double]$Matches[1] * 10)
    }

    return 0
}

# ============================================================
# PUNTUACIÓN POR REVISIÓN
# ============================================================

function Get-RevisionScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    if([string]::IsNullOrWhiteSpace($Rom.Revision))
    {
        return 0
    }

    if($Rom.Revision -match '([0-9]+)')
    {
        return [int]$Matches[1]
    }

    return 0
}

# ============================================================
# CALCULAR SCORE TOTAL
# ============================================================

function Get-RomScore
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $score = 0

    $score += Get-RegionScore $Rom
    $score += Get-LanguageScore $Rom
    $score += Get-DumpScore $Rom
    $score += Get-StateScore $Rom
    $score += Get-HackScore $Rom
    $score += Get-VersionScore $Rom
    $score += Get-RevisionScore $Rom

    $Rom.Score = $score

    return $score
}


# ============================================================
# OBTENER MOTIVOS DE LA DECISIÓN
# ============================================================

function Get-DecisionReason
{
    param(
        [Parameter(Mandatory)]
        $Rom
    )

    $reason = @()

    #
    # Score
    #

    $reason += "Score total : $($Rom.Score)"

    #
    # Región
    #

    if($Rom.Region -ne "UNK")
    {
        $reason += "Región : $($Rom.Region)"
    }

    #
    # Idioma
    #

    if($Rom.Language -ne "Unknown")
    {
        $reason += "Idioma : $($Rom.Language)"
    }

    #
    # Dump
    #

    if($Rom.Verified)
    {
        $reason += "Dump verificado"
    }

    if($Rom.BadDump)
    {
        $reason += "Bad Dump"
    }

    #
    # Estado
    #

    if($Rom.Beta)
    {
        $reason += "Beta"
    }

    if($Rom.Prototype)
    {
        $reason += "Prototype"
    }

    if($Rom.Demo)
    {
        $reason += "Demo"
    }

    if($Rom.Sample)
    {
        $reason += "Sample"
    }

    if($Rom.Preview)
    {
        $reason += "Preview"
    }

    if($Rom.Kiosk)
    {
        $reason += "Kiosk"
    }

    #
    # Hacks
    #

    if($Rom.Hack)
    {
        $reason += "Hack"
    }

    if($Rom.Homebrew)
    {
        $reason += "Homebrew"
    }

    if($Rom.Pirate)
    {
        $reason += "Pirata"
    }

    #
    # Versión
    #

    if(-not [string]::IsNullOrWhiteSpace($Rom.Version))
    {
        $reason += "Versión : $($Rom.Version)"
    }

    #
    # Revisión
    #

    if(-not [string]::IsNullOrWhiteSpace($Rom.Revision))
    {
        $reason += "Revisión : $($Rom.Revision)"
    }

    return $reason
}


#=========================================================
# RESOLVER UN EMPATE TOTAL PREGUNTANDO AL USUARIO
#=========================================================

function Resolve-RomTie {

    param(
        [Parameter(Mandatory)]
        $A,

        [Parameter(Mandatory)]
        $B
    )

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "   EMPATE: no se puede decidir en automático"
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Estas dos copias tienen la misma puntuación ($($A.Score)) y ningún criterio las diferencia:"
    Write-Host ""
    Write-Host " 1) $($A.FullPath)"
    Write-Host " 2) $($B.FullPath)"
    Write-Host ""

    do
    {
        $choice = Read-Host "¿Cuál quieres conservar? (1/2)"
    }
    until($choice -match '^[12]$')

    if([int]$choice -eq 1)
    {
        return $A
    }

    return $B
}

#=========================================================
# COMPARAR DOS ROMS
#=========================================================

function Compare-Roms {

    param(
        [Parameter(Mandatory)]
        $A,

        [Parameter(Mandatory)]
        $B
    )

    if($A.Score -gt $B.Score){ return $A }
    if($B.Score -gt $A.Score){ return $B }

    #
    # desempates
    #

    if($A.Verified -and -not $B.Verified){ return $A }
    if($B.Verified -and -not $A.Verified){ return $B }

    if(-not $A.BadDump -and $B.BadDump){ return $A }
    if(-not $B.BadDump -and $A.BadDump){ return $B }

    if(-not $A.Hack -and $B.Hack){ return $A }
    if(-not $B.Hack -and $A.Hack){ return $B }

    if(-not $A.Prototype -and $B.Prototype){ return $A }
    if(-not $B.Prototype -and $A.Prototype){ return $B }

    if(-not $A.Beta -and $B.Beta){ return $A }
    if(-not $B.Beta -and $A.Beta){ return $B }

    if(-not $A.Demo -and $B.Demo){ return $A }
    if(-not $B.Demo -and $A.Demo){ return $B }

    #
    # Preferir formato sin comprimir sobre un .zip/.7z del mismo juego
    #

    $archiveExtensions = @(".zip", ".7z")

    $aIsArchive = $archiveExtensions -contains [System.IO.Path]::GetExtension($A.FullPath).ToLower()
    $bIsArchive = $archiveExtensions -contains [System.IO.Path]::GetExtension($B.FullPath).ToLower()

    if(-not $aIsArchive -and $bIsArchive){ return $A }
    if(-not $bIsArchive -and $aIsArchive){ return $B }

    #
    # Preferir un formato de ROM sobre otro, para el mismo sistema:
    #  - N64: .z64 (más compatible) > .n64 > .v64 > .rom
    #  - SNES: .sfc > .smc
    #

    $formatPreference = @{
        ".z64" = 1
        ".n64" = 2
        ".v64" = 3
        ".rom" = 4

        ".sfc" = 10
        ".smc" = 11
    }

    $aExt = [System.IO.Path]::GetExtension($A.FullPath).ToLower()
    $bExt = [System.IO.Path]::GetExtension($B.FullPath).ToLower()

    if($formatPreference.ContainsKey($aExt) -and $formatPreference.ContainsKey($bExt) -and $aExt -ne $bExt)
    {
        if($formatPreference[$aExt] -lt $formatPreference[$bExt]){ return $A }
        if($formatPreference[$bExt] -lt $formatPreference[$aExt]){ return $B }
    }

    #
    # nombre más corto
    #

    if($A.Title.Length -lt $B.Title.Length){ return $A }
    if($B.Title.Length -lt $A.Title.Length){ return $B }

    #
    # orden alfabético (solo si los títulos son distintos)
    #

    if([string]::Compare($A.Title,$B.Title,$true) -ne 0)
    {
        if([string]::Compare($A.Title,$B.Title,$true) -le 0){
            return $A
        }

        return $B
    }

    #
    # Empate total: ni la puntuación ni ningún criterio ha
    # podido decidir. Se pregunta al usuario en vez de elegir
    # en silencio.
    #

    return Resolve-RomTie $A $B
}


#=========================================================
# OBTENER LA MEJOR ROM
#=========================================================

function Get-BestRom {

    param(
        [Parameter(Mandatory)]
        [array]$Roms
    )

    if($Roms.Count -eq 1){
        return $Roms[0]
    }

    foreach($rom in $Roms){
        $rom.Score = Get-RomScore $rom
    }

    $best = $Roms[0]

    for($i=1;$i -lt $Roms.Count;$i++){

        $best = Compare-Roms $best $Roms[$i]

    }

    return $best
}

#=========================================================
# DECIDIR UN GRUPO
#=========================================================

function Decide-RomGroup {

    param(
        [Parameter(Mandatory)]
        [array]$Roms
    )

    if($Roms.Count -eq 0){
        return $null
    }

    $keep = Get-BestRom $Roms

    $move = @()

    foreach($rom in $Roms){

        if($rom.FullPath -ne $keep.FullPath){

            $move += [PSCustomObject]@{

                Rom    = $rom
                Reason = Get-DecisionReason $rom

            }

        }

    }

    return [PSCustomObject]@{

        Keep = $keep

        MoveReasons = $move

        WinnerScore = $keep.Score

        KeepReason = Get-DecisionReason $keep

        DecisionDate = Get-Date

    }

}

#===========================================================
# Mostrar decisión
#===========================================================

function Show-Decision
{
    param(
        [Parameter(Mandatory)]
        [array]$Roms
    )

    $decision = Decide-RomGroup $Roms

    Write-Host ""
    Write-Host "========================================="
    Write-Host "           DECISION ENGINE"
    Write-Host "========================================="
    Write-Host ""

    Write-Host "ROM CONSERVADA" -ForegroundColor Green
    Write-Host "---------------"

    Write-Host $decision.Keep.Title
    Write-Host ""
    Write-Host ("Score : {0}" -f $decision.Keep.Score)

    foreach($line in $decision.KeepReason)
    {
        Write-Host ("  + {0}" -f $line)
    }

    Write-Host ""
    Write-Host "ROMS DESCARTADAS" -ForegroundColor Yellow
    Write-Host "-----------------"

    foreach($item in $decision.MoveReasons)
    {
        Write-Host ""
        Write-Host $item.Rom.Title

        foreach($reason in $item.Reason)
        {
            Write-Host ("   - {0}" -f $reason)
        }
    }

    return $decision
}

#===========================================================
# Procesar todos los grupos
#===========================================================

function Invoke-DecisionEngine
{
    param(
        [Parameter(Mandatory)]
        [array]$Groups
    )

    $results = @()

    foreach($group in $Groups)
    {
        $results += Decide-RomGroup $group.Roms
    }

    return $results
}

#===========================================================
# Compatibilidad con módulos antiguos
#===========================================================

function Compare-RomScore
{
    param(
        $A,
        $B
    )

    return (Compare-Roms $A $B)
}

function Select-BestRom
{
    param(
        [Parameter(Mandatory)]
        [array]$Group
    )

    return (Get-BestRom $Group)
}


