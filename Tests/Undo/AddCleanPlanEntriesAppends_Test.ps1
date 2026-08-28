# ============================================================
# MEJORA: los movimientos de Invoke-HackOrganizer e
# Invoke-HackDeduplication ahora también quedan registrados en
# Resultado\CleanPlan.json (vía Add-CleanPlanEntries), para que
# "Deshacer la última limpieza" también los cubra.
#
# Este test comprueba la pieza base: Add-CleanPlanEntries debe
# añadir acciones nuevas a un CleanPlan.json ya existente sin
# perder las que ya había.
# ============================================================

$tempRoot = New-TestTempFolder

$resultadoFolder = Join-Path $tempRoot "Resultado"
New-Item -ItemType Directory -Path $resultadoFolder -Force | Out-Null

$existingAction = [PSCustomObject]@{
    Action = "KEEP"
    Source = "Existing Game (Europe).smc"
    Target = ""
    Reason = "Test"
    Hash = "EXISTING-HASH"
    TimeStamp = Get-Date
    AssociatedFiles = @()
}

@($existingAction) |
    ConvertTo-Json -Depth 10 |
    Set-Content (Join-Path $resultadoFolder "CleanPlan.json") -Encoding UTF8

$rom = New-TestRom `
    -Title "Some Hack (Hack).smc" `
    -NormalizedTitle "some hack"

try
{
    $newEntry = New-CleanAction -Action "MOVE" -Rom $rom -Target "C:\fake\target" -Reason "Test hack move"

    Add-CleanPlanEntries -Root $tempRoot -NewActions @($newEntry)

    $finalActions = @(Get-Content -LiteralPath (Join-Path $resultadoFolder "CleanPlan.json") -Raw | ConvertFrom-Json)

    Assert-Equal `
        2 `
        $finalActions.Count `
        "Add-CleanPlanEntries: el JSON final debe tener la acción previa + la nueva"

    $keptExisting = @($finalActions | Where-Object { $_.Hash -eq "EXISTING-HASH" })

    Assert-Equal `
        1 `
        $keptExisting.Count `
        "Add-CleanPlanEntries: la acción que ya había no debe perderse"

    $addedNew = @($finalActions | Where-Object { $_.Source -eq $rom.FullPath })

    Assert-Equal `
        1 `
        $addedNew.Count `
        "Add-CleanPlanEntries: la acción nueva del hack debe estar en el JSON final"
}
finally
{
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
