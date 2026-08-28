Beta CleanROMs v2.6
===================

Una herramienta de línea de comandos (PowerShell) que detecta ROMs
duplicadas dentro de una instalación de RetroBat, conserva
automáticamente la mejor copia de cada juego, y mueve el resto a una
carpeta de respaldo (nunca borra nada). También puede limpiar imágenes,
vídeos y manuales huérfanos que hayan quedado de ROMs ya eliminadas.

ESTADO: BETA. Se está probando activamente y puede contener errores o
comportamientos no previstos todavía. Ver "Cómo reportar problemas" más
abajo.


Qué hace
--------
Para cada carpeta de sistema que elijas:

1. La escanea buscando archivos con extensión de ROM reconocida (más de
   110 extensiones, más de 60 sistemas soportados: Nintendo, Sega, Sony,
   arcade, microordenadores...).
2. Analiza cada nombre de archivo (y, si es un .zip/.7z con una sola ROM
   dentro, también el nombre del archivo interno) para extraer región,
   idioma, versión, revisión y marcas especiales (Hack, Beta, Prototipo,
   Demo, Homebrew, Pirata, Sample, Preview, Kiosk).
3. Normaliza el título y agrupa las copias que son el mismo juego,
   ignorando esas etiquetas -- con un archivo de alias manual para los
   casos en los que el nombre cambia de verdad entre regiones (por
   ejemplo, una traducción oficial al español con título distinto).
4. Puntúa cada copia dentro de su grupo (región, idioma, calidad de
   dump, versión...) y elige la mejor.
5. Te muestra el plan completo -- qué se conserva, qué se mueve, y por
   qué -- antes de tocar nada.
6. Solo si confirmas, mueve las copias no elegidas a _duplicates\, junto
   con cualquier archivo asociado que tuvieran (partida guardada,
   configuración de mando...).

Las ROMs marcadas como Hack, Traducción de fans, Beta, Prototipo, Demo,
Homebrew, Pirata, Sample, Preview o Kiosk nunca se comparan, mueven ni
tocan -- se tratan como contenido genuinamente distinto que merece la
pena conservar aparte, no como duplicados de la versión final.


Requisitos
----------
- PowerShell 7.3 o superior (el PowerShell 5.1 que trae Windows por
  defecto NO es compatible):
  https://github.com/PowerShell/PowerShell/releases
- Opcional: 7-Zip, para inspeccionar el contenido de archivos .7z cuando
  las etiquetas de región/idioma solo están en el nombre del archivo
  interno. Se detecta automáticamente; no es obligatorio.


Instalación
-----------
Copia la carpeta completa "CleanRoms" dentro de la carpeta "roms" de tu
instalación de RetroBat. Después, haz doble clic en "Run CleanROMs.bat".

Ese lanzador desbloquea todos los archivos de la carpeta y arranca
main.ps1 por ti, evitando un error habitual en la primera ejecución en
el que Windows se niega a ejecutar main.ps1 directamente con "El archivo
... no está firmado digitalmente. No se puede ejecutar el script en el
sistema actual." -- eso ocurre porque Windows marca como bloqueados los
archivos de una carpeta descargada o descomprimida, y la política por
defecto de PowerShell entonces exige una firma para ejecutarlos.

Si prefieres ejecutar main.ps1 directamente (por ejemplo, clic derecho y
"Ejecutar con PowerShell 7", o desde una terminal con `.\main.ps1`) y te
sale ese error, basta con desbloquear la carpeta una vez y no volverá a
pasar:

    Get-ChildItem -Path "C:\RetroBat\roms\CleanRoms" -Recurse | Unblock-File

La primera vez que lo ejecutes te preguntará el idioma (español/inglés)
y la ruta a tu carpeta "roms" de RetroBat -- ambos se guardan en
Config\UserSettings.json, así que no te lo volverá a preguntar.

IMPORTANTE: si estás actualizando desde una versión anterior, borra la
carpeta CleanRoms antigua completa antes de descomprimir la nueva.
Algunos descompresores no sobreescriben archivos existentes por
defecto, lo que puede dejarte con una mezcla de archivos antiguos y
nuevos (en particular Config\TitleAliases.json).


El menú principal
------------------
    1) Limpiar ROMs duplicadas
    2) Deshacer la última limpieza
    3) Limpiar imágenes/vídeos/manuales huérfanos
    4) TODO: Mover ROMs e imágenes/vídeos/manuales de TODOS los sistemas

Cada acción muestra una previsualización completa y pide confirmación
antes de mover o borrar nada. Nunca se borra nada de forma permanente --
los archivos se mueven a una carpeta de respaldo _duplicates\, y la
opción 2 puede devolverlos a su sitio.

El ajuste PreviewOnly (Config\Settings.ps1) te permite ejecutar todo en
modo simulación, útil la primera vez que lo pruebas en una colección
nueva.


Configuración
-------------
Todo vive dentro de Config\, en texto plano, editable con cualquier
editor de texto:

- UserSettings.json    Tu ruta de RetroBat y el idioma elegido.
- Settings.ps1         Sistemas y extensiones reconocidos, carpetas
                        ignoradas, sufijos de medios reconocidos, y
                        ajustes de comportamiento (PreviewOnly,
                        MoveAssets, RemoveDuplicates...).
- DecisionWeights.ps1   Las tablas de puntuación completas (región,
                        idioma, calidad de dump, versión, revisión) --
                        libremente ajustables.
- TitleAliases.json     Mapeos manuales para títulos que cambian de
                        verdad entre ediciones/idiomas y no se pueden
                        resolver solo quitando etiquetas (ver el manual
                        completo).


Informes y logs
----------------
Cada ejecución exporta, en Resultado\:
- CleanPlan.json  Detalle completo del plan (también usado por
                  "Deshacer").
- CleanPlan.csv   Versión resumida para Excel.
- CleanPlan.html  Informe visual con estadísticas y tabla de colores.

Cada sesión completa también se registra en Logs\CleanROMs_<fecha>.log.


Documentación
-------------
Los manuales de usuario completos, tanto en inglés
(CleanROMs_Manual_EN.pdf) como en español (CleanROMs_Manual_ES.pdf),
cubriendo el sistema de puntuación, las reglas de desempate, el sistema
de normalización/alias de títulos, el manejo de archivos asociados, la
referencia de configuración, los sistemas soportados, y resultados de
pruebas reales, están incluidos en el repositorio.


Novedades de la 2.6
---------------------
- La versión y la revisión de la ROM (V1.1, Rev A...) ahora se detectan
  de verdad a partir del nombre del archivo y alimentan el sistema de
  puntuación -- antes esa tabla existía pero no tenía ningún efecto
  real.
- "[BIOS]" y etiquetas similares ya no se confunden con un mal dump
  ([b]) ni se penalizan por error.
- Los hacks duplicados encontrados dentro de "# Hacks y Otros #" ahora
  se mueven a la carpeta de duplicados del sistema correcto, en vez de
  crear a veces una carpeta suelta "_duplicates\# Hacks y Otros #\".
- La pregunta de confirmación al mover hacks duplicados ahora explica
  que son archivos idénticos byte a byte y que este paso concreto no se
  puede deshacer con la opción "Deshacer la última limpieza" del menú.
- Añadido "Run CleanROMs.bat", un lanzador que desbloquea la carpeta y
  arranca el programa para que quien lo use por primera vez no se
  encuentre con el error de "no está firmado digitalmente" de
  PowerShell.
- "Deshacer la última limpieza" ya no se limita a la última ejecución:
  cada sesión completada se archiva en Resultado\History\, y el menú
  permite elegir una anterior (se conservan las últimas 10 por defecto,
  ver UndoHistoryLimit en Config\Settings.ps1). Además ahora también
  restaura los archivos asociados (partidas guardadas, configuraciones
  de mando) que se hubieran movido junto con una ROM, no solo la ROM.
- Nuevos parámetros de línea de comandos en main.ps1 para ejecuciones
  programadas/desatendidas (Programador de tareas de Windows y
  similares): -Action Clean|Orphans|All|Undo, -System <carpeta>, -Yes
  (confirma automáticamente cada pregunta), -PreviewOnly. Ver "Uso por
  línea de comandos / tareas programadas" más abajo. Ejecutar main.ps1
  sin parámetros funciona exactamente igual que siempre.
- El cálculo de hash (usado para encontrar duplicados, verificar
  movimientos, y deduplicar copias exactas dentro de
  "# Hacks y Otros #") ahora se hace en paralelo en tandas grandes, en
  vez de un archivo cada vez, usando ForEach-Object -Parallel de
  PowerShell 7. Se controla con HashParallelThreshold y HashParallelism
  en Config\Settings.ps1 (por defecto: no compensa por debajo de 20
  archivos, 4 a la vez por encima). Baja HashParallelism a 1 si tienes
  un disco duro mecánico lento y notas que todo va más lento en vez de
  más rápido.

Consulta el manual de usuario completo para el detalle de cada función y
las reglas exactas de puntuación/desempate.


Uso por línea de comandos / tareas programadas
-------------------------------------------------
Para ejecuciones desatendidas (Programador de tareas de Windows, etc.),
main.ps1 acepta:

    -Action Clean|Orphans|All|Undo   Qué hacer (se salta el menú por
                                      completo)
    -System <carpeta>                Carpeta del sistema (p.ej. "snes",
                                      "gba"); omite o usa "ALL" para
                                      todos los sistemas configurados.
                                      Se ignora con -Action Undo.
    -Yes                             Confirma automáticamente cada
                                      pregunta S/N, en vez de esperar a
                                      que alguien responda.
    -PreviewOnly                     Fuerza el modo simulación solo para
                                      esta ejecución, sin tener que
                                      editar Settings.ps1.

Ejemplos:

    pwsh -File main.ps1 -Action Clean -System snes -Yes
    pwsh -File main.ps1 -Action All -Yes
    pwsh -File main.ps1 -Action Undo -Yes

Sin -Action, main.ps1 se comporta exactamente igual que siempre (menú
interactivo). Sin -Yes, -Action sigue saltándose el menú pero sigue
pidiendo confirmación en cada paso, como de costumbre -- -Yes es lo que
de verdad hace que una ejecución sea desatendida.


Cómo reportar problemas
-------------------------
Esto es una BETA. Si encuentras algún error, o quieres que se añada o se
quite alguna funcionalidad, escribe un correo con el mayor detalle
posible (qué hiciste, qué esperabas, y qué pasó en su lugar) a:

    batserra@gmail.com

Si el problema tiene que ver con ROMs que no se agrupan como esperabas,
o con archivos que desaparecen sin explicación, adjunta si puedes el
archivo de log de esa ejecución (Logs\CleanROMs_<fecha>.log) y, si es
posible, un listado completo de los archivos de la carpeta afectada
(por ejemplo con `dir /s /b > listado.txt` desde la carpeta de ese
sistema).


Créditos
--------
El desarrollo se inició con ChatGPT (GPT-5.5) y se ha terminado de
completar y depurar con Claude, el asistente de IA de Anthropic, a lo
largo de varias rondas de pruebas sobre colecciones reales (decenas de
miles de ROMs en más de 35 sistemas).


Repositorio
------------
https://github.com/batserra/CleanRoms
