# ============================================================
# La limpieza no debe imprimir un "True" suelto en pantalla: es el valor
# que devuelve Validate-CleanPlan al validar el plan, y se llamaba sin
# recogerlo. Se comprueba el codigo (estatico) porque es una linea de
# salida por pantalla: el valor de retorno se descarta con $null =.
# ============================================================

$cleaner = Get-Content -LiteralPath (Join-Path $Root "Modules/Cleaner.ps1") -Raw

Assert-Equal $true ($cleaner -match '\$null = Validate-CleanPlan \$plan') "Invoke-RomCleaning descarta el valor de Validate-CleanPlan"
Assert-Equal $false ($cleaner -match '(?m)^\s*Validate-CleanPlan \$plan') "Invoke-RomCleaning no llama a Validate-CleanPlan sin recoger su valor (saldria 'True')"

Assert-Equal $true (Validate-CleanPlan ([PSCustomObject]@{ KeepActions = @(); MoveActions = @() })) "Validate-CleanPlan sigue devolviendo `$true para un plan valido"
