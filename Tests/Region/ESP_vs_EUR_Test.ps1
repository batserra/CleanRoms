# ============================================================
# ESP vs EUR
# Debe ganar la ROM española
# ============================================================

$esp = New-TestRom `
    -Title "Boktai (ESP)" `
    -Region "ESP" `
    -Language "Spanish"

$eur = New-TestRom `
    -Title "Boktai (E)(M5)" `
    -Region "EUR" `
    -Language "Multi-Spanish"

Get-RomScore $esp | Out-Null
Get-RomScore $eur | Out-Null

$winner = Get-BestRom @($esp,$eur)

Assert-Equal `
    "ESP" `
    $winner.Region `
    "ESP vs EUR"