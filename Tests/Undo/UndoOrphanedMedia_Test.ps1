# ============================================================
# BUG corregido: "Deshacer la ultima limpieza" (opcion 2 del menu)
# NO devolvia las imagenes, los videos ni los manuales.
#
# Invoke-OrphanedMediaCleanup movia los medios huerfanos con un
# Move-Item directo y no los anotaba en Resultado\CleanPlan.json,
# asi que Deshacer solo restauraba las ROMs: tras limpiar y
# deshacer, las ROMs volvian pero sus imagenes (que al moverse la
# ROM quedaban huerfanas) se quedaban en _duplicates.
#
# Ahora cada medio movido es un MOVE mas del plan. Este test hace
# la secuencia real de "Limpiar TODAS":
#   limpiar ROMs -> limpiar medios huerfanos -> deshacer
# y comprueba que vuelve TODO: ROMs, imagenes, videos y manuales
# (incluidos los de subcarpetas), con el mismo contenido. Tambien
# comprueba que un fallo al mover un medio no aborta el resto.
# ============================================================

. "$PSScriptRoot\..\..\Modules\logger.ps1"

$tempRoot = New-TestTempFolder
$systemFolder = Join-Path $tempRoot "snes"
$dupFolder = Join-Path (Join-Path $tempRoot "_duplicates") "snes"

$saved = @{
    OverridesPath = $Global:OverridesPath
    Language      = $Global:Settings.Language
    PreviewOnly   = $Global:Settings.PreviewOnly
    AutoConfirm   = $Global:AutoConfirm
    Root          = $Global:RetroBatRoot
    Dup           = $Global:DuplicatesFolder
}

$errorCountWasSet = Test-Path Variable:\Global:ActionErrorCount
$originalErrorCount = if($errorCountWasSet) { $Global:ActionErrorCount } else { 0 }

$Global:OverridesPath = (Join-Path $tempRoot "no-overrides.json")
$Global:Settings.Language = "es"
$Global:Settings.PreviewOnly = $false
$Global:AutoConfirm = $true
$Global:RetroBatRoot = $tempRoot
$Global:DuplicatesFolder = "_duplicates"
$Global:ActionErrorCount = 0

function New-TestMedia
{
    param([string]$Relative, [string]$Content)

    $path = Join-Path $systemFolder $Relative
    $parent = Split-Path $path -Parent

    if(!(Test-Path -LiteralPath $parent))
    {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $path -Value $Content
}

function Get-Snapshot
{
    $snapshot = @{}

    foreach($file in @(Get-ChildItem -LiteralPath $systemFolder -File -Recurse))
    {
        $snapshot[[System.IO.Path]::GetRelativePath($systemFolder, $file.FullName)] = (Get-Content -LiteralPath $file.FullName -Raw)
    }

    return $snapshot
}

try
{
    New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $systemFolder "Dup (USA).sfc") -Value "rom usa"
    Set-Content -LiteralPath (Join-Path $systemFolder "Dup (Europe).sfc") -Value "rom europe"

    # Medios de las dos ROMs (la que se mueva dejara huerfano el suyo)
    New-TestMedia "images/Dup (USA).png" "img usa"
    New-TestMedia "images/Dup (Europe).png" "img europe"
    New-TestMedia "videos/Dup (USA).mp4" "vid usa"
    New-TestMedia "videos/Dup (Europe).mp4" "vid europe"

    # Medios huerfanos desde el principio (ninguna ROM los reclama)
    New-TestMedia "images/Ghost (USA).png" "img ghost"
    New-TestMedia "images/sub/Ghost Two (USA).png" "img ghost sub"
    New-TestMedia "videos/Ghost (USA).mp4" "vid ghost"
    New-TestMedia "manuals/Ghost (USA).pdf" "manual ghost"

    $before = Get-Snapshot

    #
    # "Limpiar TODAS": ROMs y despues medios huerfanos
    #

    Invoke-RomCleaning -Root $tempRoot -SystemFolders @($systemFolder) 6>$null 3>$null
    Invoke-OrphanedMediaCleanup -Root $tempRoot -SystemFolders @($systemFolder) 6>$null 3>$null

    $after = Get-Snapshot

    Assert-Equal 1 @($after.Keys | Where-Object { $_ -like "*.sfc" }).Count "Limpieza: queda una sola ROM Dup"
    Assert-Equal 1 @($after.Keys | Where-Object { $_ -like "images*Dup*" }).Count "Limpieza: queda solo la imagen de la ROM que se conserva"
    Assert-Equal 1 @($after.Keys | Where-Object { $_ -like "videos*Dup*" }).Count "Limpieza: queda solo el video de la ROM que se conserva"
    Assert-Equal 0 @($after.Keys | Where-Object { $_ -like "*Ghost*" }).Count "Limpieza: los medios huerfanos (imagenes, videos, manuales) ya no estan"

    $planFile = Join-Path (Join-Path $tempRoot "Resultado") "CleanPlan.json"
    $plan = @(Get-Content -LiteralPath $planFile -Raw | ConvertFrom-Json)
    $moves = @($plan | Where-Object { $_.Action -eq "MOVE" })
    $mediaMoves = @($moves | Where-Object { $_.Source -match "[\\/](images|videos|manuals)[\\/]" })

    # Dup: 1 imagen + 1 video; Ghost: imagen, imagen en subcarpeta, video, manual
    Assert-Equal 6 $mediaMoves.Count "Plan: cada medio movido queda anotado como un MOVE (6)"
    Assert-Equal 7 $moves.Count "Plan: 1 ROM + 6 medios = 7 movimientos registrados"

    #
    # Deshacer: vuelve TODO
    #

    $null = Invoke-UndoLastPlan -Root $tempRoot 6>$null

    $restored = Get-Snapshot

    Assert-Equal $before.Count $restored.Count "Deshacer: vuelven TODOS los archivos (ROMs, imagenes, videos y manuales)"

    $sameContent = $true
    foreach($name in $before.Keys)
    {
        if(-not $restored.ContainsKey($name) -or $restored[$name] -ne $before[$name]) { $sameContent = $false }
    }

    Assert-Equal $true $sameContent "Deshacer: cada archivo vuelve a su ruta original con el mismo contenido"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $systemFolder "images/sub/Ghost Two (USA).png")) "Deshacer: los medios de subcarpetas vuelven a su subcarpeta"
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $dupFolder -File -Recurse -ErrorAction SilentlyContinue).Count "Deshacer: _duplicates\snes queda vacio"

    #
    # Un medio que no se puede mover no aborta el resto
    #

    $Global:ActionErrorCount = 0

    function global:Move-Item
    {
        param([string]$LiteralPath, [string]$Destination, $ErrorAction)

        if($LiteralPath -like "*Ghost (USA).mp4")
        {
            throw "El proceso no puede obtener acceso al archivo (simulado)"
        }

        Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
    }

    $threw = $false

    try
    {
        Invoke-OrphanedMediaCleanup -Root $tempRoot -SystemFolders @($systemFolder) 6>$null 3>$null
    }
    catch
    {
        $threw = $true
    }

    Remove-Item Function:\Move-Item -ErrorAction SilentlyContinue

    Assert-Equal $false $threw "Medio bloqueado: no lanza excepcion"
    Assert-Equal $true (Test-Path -LiteralPath (Join-Path $systemFolder "videos/Ghost (USA).mp4")) "Medio bloqueado: se queda donde estaba"
    Assert-Equal $false (Test-Path -LiteralPath (Join-Path $systemFolder "manuals/Ghost (USA).pdf")) "Medio bloqueado: los demas medios SI se mueven"
    Assert-Equal 1 $Global:ActionErrorCount "Medio bloqueado: se cuenta como error (codigo de salida 2 en modo desatendido)"

    $plan2 = @(Get-Content -LiteralPath $planFile -Raw | ConvertFrom-Json)

    # El plan conserva la entrada de la primera pasada (ya deshecha); la
    # segunda NO debe haber anadido otra para el video que fallo.
    $ghostVideoBefore = @($plan | Where-Object { $_.Source -like "*Ghost (USA).mp4" -and $_.Action -eq "MOVE" }).Count
    $ghostVideoAfter = @($plan2 | Where-Object { $_.Source -like "*Ghost (USA).mp4" -and $_.Action -eq "MOVE" }).Count

    Assert-Equal $ghostVideoBefore $ghostVideoAfter "Medio bloqueado: el que fallo no se anota como movido"
}
finally
{
    Remove-Item Function:\Move-Item -ErrorAction SilentlyContinue

    $Global:OverridesPath = $saved.OverridesPath
    $Global:Settings.Language = $saved.Language
    $Global:Settings.PreviewOnly = $saved.PreviewOnly
    $Global:AutoConfirm = $saved.AutoConfirm
    $Global:RetroBatRoot = $saved.Root
    $Global:DuplicatesFolder = $saved.Dup
    $Global:OverrideContextSystem = ""

    if($errorCountWasSet)
    {
        $Global:ActionErrorCount = $originalErrorCount
    }
    else
    {
        Remove-Variable -Name ActionErrorCount -Scope Global -ErrorAction SilentlyContinue
    }

    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
