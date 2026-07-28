# ============================================================
#
# Beta CleanROMs v2.5
#
# RomScanner.ps1
#
# Escaneo de ROMs
#
# ============================================================

function Get-RomFiles {

    param(
        [Parameter(Mandatory)]
        [string]$Folder
    )

    if(-not (Test-Path -LiteralPath $Folder))
    {
        throw "La carpeta no existe: $Folder"
    }

$extensions = $Global:RomExtensions

$ignoredFolders = $Global:IgnoredFolders

    Get-ChildItem `
        -LiteralPath $Folder `
        -File `
        -Recurse |

        Where-Object {

            $extensions -contains $_.Extension.ToLower()

        } |

        Where-Object {

            $parts = $_.DirectoryName.Split('\')

            -not ($parts | Where-Object {
                $ignoredFolders -contains $_
            })

        }

}

# ============================================================
# Escaneo completo
# ============================================================

function Scan-Roms {

    param(
        [Parameter(Mandatory)]
        [string]$Folder
    )

    Write-Host ""
    Write-Host "================================="
    Write-Host (T "scan.header")
    Write-Host "================================="
    Write-Host ""

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $files = @(Get-RomFiles $Folder)

    Write-Host (T "scan.filesFound" $files.Count)
    Write-Host ""

    $result = New-Object System.Collections.Generic.List[object]

    $total = $files.Count
    $index = 0

    foreach($file in $files)
    {
        $index++

        if(($index % 250) -eq 0 -or $index -eq $total)
        {
            Write-Progress `
                -Activity "Analizando ROMs" `
                -Status "$index de $total" `
                -PercentComplete (($index / $total) * 100)
        }

        $rom = Parse-Rom $file.FullName

        if($null -ne $rom)
        {
            $result.Add($rom)
        }
    }

    Write-Progress -Activity "Analizando ROMs" -Completed

    $sw.Stop()

    Write-Host ""
    Write-Host (T "scan.romsProcessed" $result.Count)
    Write-Host (T "scan.timeTaken" ("{0:N2}" -f $sw.Elapsed.TotalSeconds))
    Write-Host ""

    return $result

}

# ============================================================
# Compatibilidad
# ============================================================

function Get-RomsFromFolder {

    param(
        [string]$Path
    )

    return Scan-Roms $Path

}
