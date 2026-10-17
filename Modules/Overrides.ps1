# ============================================================
# CleanROMs
#
# Overrides.ps1
#
# Decisiones manuales PERSISTENTES. Si no te gusta lo que decide
# el motor de puntuacion para un juego concreto, lo dices una vez
# en Config\Overrides.json y se respeta en todas las limpiezas
# (tambien en las programadas, sin preguntas).
#
# Formato (ver Config\Overrides.example.json):
#
#   {
#     "Prefer": [
#       { "System": "snes", "File": "Super Mario World (Europe).sfc" }
#     ],
#     "Ignore": [
#       { "System": "snes", "Title": "Super Mario World" },
#       { "System": "nes",  "File": "Zelda II (USA).nes" }
#     ]
#   }
#
# - Prefer: dentro de su grupo de duplicados, esa ROM SIEMPRE se
#   conserva (las demas copias se mueven como siempre).
# - Ignore: el grupo no se toca en absoluto (ni se conserva ni se
#   mueve nada). Se identifica por titulo ("Title": el que se
#   imprime tras "Grupo:" al limpiar, o el titulo normal del
#   juego) o por archivo ("File": si cualquier copia del grupo
#   tiene ese nombre).
# - "System" es el nombre de la carpeta del sistema (snes, nes...);
#   si se omite, o es "*", vale para todos los sistemas.
# - Los nombres de archivo y de sistema no distinguen mayusculas.
#
# Si Config\Overrides.json no existe, no pasa nada: el programa
# funciona exactamente igual que antes.
#
# Tambien se rellena solo: al elegir a mano en un empate (cuando el
# programa pregunta "¿cual conservar?") se ofrece recordar la
# eleccion, y se guarda como un "Prefer".
# ============================================================

# Ruta alternativa (para tests o instalaciones especiales); si esta
# vacia se usa Config\Overrides.json junto al programa.
$Global:OverridesPath = ""

# Sistema del grupo que se esta decidiendo ahora mismo, para poder
# anotarlo al recordar una eleccion de empate (Resolve-RomTie solo
# recibe las dos ROMs).
$Global:OverrideContextSystem = ""

# Titulo normalizado del grupo que se esta decidiendo ahora mismo (para
# poder anotar un "Ignore" al elegir "conservar todas" en un empate).
$Global:OverrideContextTitle = ""

function Get-OverridesPath {

    if(-not [string]::IsNullOrWhiteSpace($Global:OverridesPath))
    {
        return $Global:OverridesPath
    }

    return Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) "Config") "Overrides.json"
}

function Get-OverrideField {

    param($Entry, [string]$Name)

    $prop = $Entry.PSObject.Properties[$Name]

    if($null -eq $prop -or $null -eq $prop.Value)
    {
        return ""
    }

    return ([string]$prop.Value).Trim()
}

function Get-OverrideList {

    param($Json, [string]$Name)

    $prop = $Json.PSObject.Properties[$Name]

    if($null -eq $prop -or $null -eq $prop.Value)
    {
        return @()
    }

    return @($prop.Value)
}

#--------------------------------------------------------------
# Lee y valida Config\Overrides.json. Nunca lanza excepcion: un
# archivo ausente, vacio o corrupto equivale a "sin overrides"
# (con un aviso si esta corrupto).
#--------------------------------------------------------------

function Get-Overrides {

    $result = [PSCustomObject]@{
        Prefer = @()
        Ignore = @()
    }

    $path = Get-OverridesPath

    if(!(Test-Path -LiteralPath $path))
    {
        return $result
    }

    try
    {
        $raw = Get-Content -LiteralPath $path -Raw

        if([string]::IsNullOrWhiteSpace($raw))
        {
            return $result
        }

        $json = $raw | ConvertFrom-Json

        if($null -eq $json)
        {
            return $result
        }

        $prefer = @()
        $ignore = @()

        foreach($e in (Get-OverrideList $json "Prefer"))
        {
            $file = Get-OverrideField $e "File"

            if($file -eq "")
            {
                Write-Warning (T "overrides.entryIncomplete" @("Prefer", "File"))
                continue
            }

            $prefer += [PSCustomObject]@{
                System = (Get-OverrideField $e "System")
                File   = $file
            }
        }

        foreach($e in (Get-OverrideList $json "Ignore"))
        {
            $title = Get-OverrideField $e "Title"
            $file = Get-OverrideField $e "File"

            if($title -eq "" -and $file -eq "")
            {
                Write-Warning (T "overrides.entryIncomplete" @("Ignore", "Title/File"))
                continue
            }

            $ignore += [PSCustomObject]@{
                System = (Get-OverrideField $e "System")
                Title  = $title
                File   = $file
            }
        }

        $result.Prefer = @($prefer)
        $result.Ignore = @($ignore)
    }
    catch
    {
        Write-Warning (T "overrides.invalid" @($path, $_.Exception.Message))
    }

    return $result
}

function Test-OverrideSystemMatch {

    param([string]$EntrySystem, [string]$GroupSystem)

    return ($EntrySystem -eq "" -or $EntrySystem -eq "*" -or $EntrySystem -ieq $GroupSystem)
}

#--------------------------------------------------------------
# Que dicen los overrides de un grupo de duplicados
#
# Devuelve:
#   Ignored       $true si el grupo no se debe tocar
#   IgnoreSource  que entrada lo ignora (para mostrarlo)
#   PreferredPath ruta de la ROM fijada como preferida ("" si no hay)
#--------------------------------------------------------------

function Get-GroupOverride {

    param(
        [Parameter(Mandatory)]
        $Group,

        [Parameter(Mandatory)]
        $Overrides
    )

    $result = [PSCustomObject]@{
        Ignored       = $false
        IgnoreSource  = ""
        PreferredPath = ""
    }

    $groupSystem = [string]$Group.System
    $fileNames = @($Group.Roms | ForEach-Object { Split-Path $_.FullPath -Leaf })

    foreach($entry in @($Overrides.Ignore))
    {
        if(-not (Test-OverrideSystemMatch $entry.System $groupSystem))
        {
            continue
        }

        if($entry.Title -ne "")
        {
            $titleMatches = ($entry.Title -ieq [string]$Group.Name)

            if(-not $titleMatches -and (Get-Command Normalize-Title -ErrorAction SilentlyContinue))
            {
                $titleMatches = ((Normalize-Title $entry.Title) -ieq [string]$Group.Name)
            }

            if($titleMatches)
            {
                $result.Ignored = $true
                $result.IgnoreSource = "Title '$($entry.Title)'"
                return $result
            }
        }

        if($entry.File -ne "" -and ($fileNames -icontains $entry.File))
        {
            $result.Ignored = $true
            $result.IgnoreSource = "File '$($entry.File)'"
            return $result
        }
    }

    $preferred = @()

    foreach($entry in @($Overrides.Prefer))
    {
        if(-not (Test-OverrideSystemMatch $entry.System $groupSystem))
        {
            continue
        }

        foreach($rom in $Group.Roms)
        {
            if((Split-Path $rom.FullPath -Leaf) -ieq $entry.File -and
               ($preferred -notcontains $rom.FullPath))
            {
                $preferred += $rom.FullPath
            }
        }
    }

    if($preferred.Count -gt 0)
    {
        $result.PreferredPath = $preferred[0]

        if($preferred.Count -gt 1)
        {
            Write-Warning (T "overrides.conflict" @($Group.Name, (Split-Path $preferred[0] -Leaf)))
        }
    }

    return $result
}

#--------------------------------------------------------------
# Anade un "Prefer" a Config\Overrides.json (lo crea si no
# existe), sin tocar nada de lo que ya hubiera. Devuelve $true si
# lo guardo.
#--------------------------------------------------------------

function Add-OverridePrefer {

    param(
        [string]$System = "",

        [Parameter(Mandatory)]
        [string]$File
    )

    $path = Get-OverridesPath

    $prefer = @()
    $ignore = @()

    if(Test-Path -LiteralPath $path)
    {
        try
        {
            $raw = Get-Content -LiteralPath $path -Raw

            if(-not [string]::IsNullOrWhiteSpace($raw))
            {
                $json = $raw | ConvertFrom-Json

                $prefer = @(Get-OverrideList $json "Prefer")
                $ignore = @(Get-OverrideList $json "Ignore")
            }
        }
        catch
        {
            #
            # Archivo corrupto: no se sobrescribe (se perderia lo
            # que el usuario tuviera escrito a mano).
            #

            Write-Warning (T "overrides.invalid" @($path, $_.Exception.Message))
            return $false
        }
    }

    foreach($e in $prefer)
    {
        if((Get-OverrideField $e "File") -ieq $File -and
           (Get-OverrideField $e "System") -ieq $System)
        {
            return $true
        }
    }

    $entry = [ordered]@{}

    if($System -ne "")
    {
        $entry["System"] = $System
    }

    $entry["File"] = $File

    $prefer += [PSCustomObject]$entry

    $folder = Split-Path $path -Parent

    if(!(Test-Path -LiteralPath $folder))
    {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    [ordered]@{
        Prefer = @($prefer)
        Ignore = @($ignore)
    } |
        ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath $path -Encoding UTF8

    return $true
}

#--------------------------------------------------------------
# Tras elegir a mano en un empate: ofrece recordar la eleccion
#--------------------------------------------------------------

function Invoke-OfferRememberChoice {

    param(
        [Parameter(Mandatory)]
        $Chosen
    )

    if(-not (Confirm-YesNo "overrides.rememberPrompt"))
    {
        return
    }

    $fileName = Split-Path $Chosen.FullPath -Leaf

    if(Add-OverridePrefer -System $Global:OverrideContextSystem -File $fileName)
    {
        Write-Host (T "overrides.remembered" (Get-OverridesPath)) -ForegroundColor DarkCyan
    }
}

#--------------------------------------------------------------
# Anade un "Ignore" por titulo a Config\Overrides.json (lo crea si no
# existe), sin tocar nada de lo que ya hubiera. Devuelve $true si lo
# guardo. Igual que Add-OverridePrefer: no sobrescribe un archivo que
# no se puede leer.
#--------------------------------------------------------------

function Add-OverrideIgnore {

    param(
        [string]$System = "",

        [Parameter(Mandatory)]
        [string]$Title
    )

    $path = Get-OverridesPath

    $prefer = @()
    $ignore = @()

    if(Test-Path -LiteralPath $path)
    {
        try
        {
            $raw = Get-Content -LiteralPath $path -Raw

            if(-not [string]::IsNullOrWhiteSpace($raw))
            {
                $json = $raw | ConvertFrom-Json

                $prefer = @(Get-OverrideList $json "Prefer")
                $ignore = @(Get-OverrideList $json "Ignore")
            }
        }
        catch
        {
            Write-Warning (T "overrides.invalid" @($path, $_.Exception.Message))
            return $false
        }
    }

    foreach($e in $ignore)
    {
        if((Get-OverrideField $e "Title") -ieq $Title -and
           (Get-OverrideField $e "System") -ieq $System)
        {
            return $true
        }
    }

    $entry = [ordered]@{}

    if($System -ne "")
    {
        $entry["System"] = $System
    }

    $entry["Title"] = $Title

    $ignore += [PSCustomObject]$entry

    $folder = Split-Path $path -Parent

    if(!(Test-Path -LiteralPath $folder))
    {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    [ordered]@{
        Prefer = @($prefer)
        Ignore = @($ignore)
    } |
        ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath $path -Encoding UTF8

    return $true
}

#--------------------------------------------------------------
# Tras elegir "conservar TODAS" en un empate: ofrece recordarlo (se
# guarda como "Ignore" por titulo, asi ese juego no se vuelve a tocar
# ni a preguntar, tampoco en las limpiezas desatendidas)
#--------------------------------------------------------------

function Invoke-OfferRememberKeepAll {

    if([string]::IsNullOrWhiteSpace($Global:OverrideContextTitle))
    {
        return
    }

    if(-not (Confirm-YesNo "overrides.rememberKeepAllPrompt"))
    {
        return
    }

    if(Add-OverrideIgnore -System $Global:OverrideContextSystem -Title $Global:OverrideContextTitle)
    {
        Write-Host (T "overrides.remembered" (Get-OverridesPath)) -ForegroundColor DarkCyan
    }
}
