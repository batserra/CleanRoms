# ============================================================
# AL SALIR (opcion 7 del menu) el programa debe terminar a la PRIMERA.
#
# Antes: "Pulse ENTER para salir" (main.ps1) y, despues, "Presione una
# tecla para continuar" (el "pause" del lanzador .bat): dos pulsaciones
# para cerrar una ventana que el usuario ya habia decidido cerrar.
#
# Ahora:
# - main.ps1 no hace la pausa cuando se sale con la opcion 7.
# - CleanROMs.bat solo se queda esperando una tecla si el programa
#   termino con un error (para poder leer el mensaje).
#
# (El comportamiento real de main.ps1 lo comprueba Smoke-Unattended.ps1;
# el .bat no se puede ejecutar fuera de Windows, asi que aqui se
# comprueba su contenido.)
# ============================================================

$bat = Get-Content -LiteralPath (Join-Path $Root "CleanROMs.bat") -Raw
$main = Get-Content -LiteralPath (Join-Path $Root "main.ps1") -Raw

Assert-Equal $true ($bat -match 'if not "%EXITCODE%"=="0"') "Lanzador: la pausa solo se hace si el codigo de salida no es 0"
Assert-Equal $true ($bat -match 'exit /b %EXITCODE%\s*$') "Lanzador: acaba devolviendo el codigo de salida, sin 'pause' incondicional al final"

# Todos los "pause" del lanzador estan dentro de un bloque condicional (el de
# error de arranque tambien), nunca sueltos al final
$lines = @($bat -split "`r?`n" | ForEach-Object { $_.TrimEnd() })
$lastNonEmpty = @($lines | Where-Object { $_ -ne "" })[-1]

Assert-Equal "exit /b %EXITCODE%" $lastNonEmpty "Lanzador: la ultima linea es 'exit /b %EXITCODE%'"

Assert-Equal $true ($main -match '\$exitedFromMenu = \$true\s*\r?\n\s*break mainLoop') "main.ps1: al salir con la opcion 7 se anota que la salida fue desde el menu"
Assert-Equal $true ($main -match 'if\(-not \$exitedFromMenu\)\s*\r?\n\s*\{\s*\r?\n\s*Pause-End') "main.ps1: la pausa final solo se hace si NO se salio desde el menu"
