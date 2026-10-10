CleanROMs v2.7
==============

Una herramienta de línea de comandos (PowerShell) que detecta ROMs
duplicadas dentro de una instalación de RetroBat, conserva
automáticamente la mejor copia de cada juego, y mueve el resto a una
carpeta de respaldo (nunca borra nada). También puede limpiar imágenes,
vídeos y manuales huérfanos que hayan quedado de ROMs ya eliminadas.


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
    5) Configuración (ruta de RetroBat / idioma)
    6) Purgar _duplicates (BORRAR copias antiguas)
    7) Salir

Cada acción muestra una previsualización completa y pide confirmación
antes de mover o borrar nada. Las opciones 1-4 nunca borran nada -- los
archivos se mueven a una carpeta de respaldo _duplicates\, y la opción 2
puede devolverlos a su sitio. Lo único que el programa borra de verdad es
la opción 6 (ver "Purgar _duplicates" más abajo), y solo después de
enseñarte la lista y preguntarte.

El ajuste PreviewOnly (Config\Settings.ps1) te permite ejecutar todo en
modo simulación, útil la primera vez que lo pruebas en una colección
nueva.


Configuración
-------------
Todo vive dentro de Config\, en texto plano, editable con cualquier
editor de texto:

- UserSettings.json    Tu ruta de RetroBat y el idioma elegido.
- Systems.json         Sistemas soportados ("Nombre": "carpeta"), por
                        categorías.
- Extensions.json      RomExtensions (qué cuenta como ROM) e
                        IgnoredFolders (carpetas que nunca se recorren).
- *.custom.json        Opcionales: Systems.custom.json /
                        Extensions.custom.json para añadir lo tuyo
                        encima, a salvo de las actualizaciones.
- Settings.ps1         Sufijos de medios reconocidos y ajustes de
                        comportamiento (PreviewOnly, MoveAssets,
                        RemoveDuplicates, HashCache,
                        PurgeDuplicatesAfterDays...).
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
  que son archivos idénticos byte a byte. (Antes añadía que este paso no
  se podía deshacer; estaba desfasado: sí se puede, ver más abajo.)
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
  similares): -Action Clean|Orphans|All|Undo|Purge, -System <carpeta>, -Yes
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
- Nuevo: prioridad de ROMs español/inglés. Antes el programa siempre
  daba prioridad a las ROMs en español (y dentro de eso, a España como
  región). Ahora se pregunta la primera vez que se ejecuta (igual que
  el idioma de los menús, pero es un ajuste totalmente aparte), y se
  puede cambiar cuando quieras desde la opción 5 del menú
  ("Configuración"), que ahora tiene 4 sub-opciones: ruta de RetroBat,
  idioma de la interfaz, prioridad de ROMs, o cambiar todo. Con
  prioridad inglés, la tabla de puntuación de región/idioma se invierte
  (USA/Inglés pasan a valer lo que antes valían España/Español, y
  viceversa) -- el resto de criterios (calidad de dump, estado, hacks,
  versión, revisión) no cambian. Ver Config\DecisionWeights.ps1
  ($Global:DecisionWeights_ES y $Global:DecisionWeights_EN).
- Varias correcciones de detección por nombre de archivo: "Hack",
  "Traducción", región ESP/España, versión y revisión ahora se
  reconocen también en nombres con guion bajo en vez de espacios
  (p.ej. "Street_Fighter_5_Hack_.smc"), un estilo de renombrado
  frecuente en sets de SNES. Y "Beta", "Prototipo", "Demo", "Homebrew",
  "Pirata", "Sample", "Preview" y "Kiosk" ya no dan falsos positivos
  con juegos legítimos que contienen esas letras dentro de otra
  palabra (Demon's Crest, Pirates of the Caribbean, Team Protoman...).
- La confirmación S/N ahora acepta también "si", "sí" y "yes" (antes
  exigía escribir exactamente una "S" sola).
- Move-Asset (mover archivos asociados como partidas guardadas) ya no
  sobrescribe en silencio un archivo que ya existiera en el destino.

Consulta el manual de usuario completo para el detalle de cada función y
las reglas exactas de puntuación/desempate.


Deshacer: hacks y movimientos encadenados
------------------------------------------
- Mover los hacks sueltos a "# Hacks y Otros #" y mover sus duplicados
  exactos a _duplicates queda registrado en el plan y se puede deshacer
  con "Deshacer la última limpieza", como cualquier otro movimiento.
- "Deshacer" ahora recorre los movimientos del último al primero. Antes,
  un hack movido dos veces en la misma ejecución (organizado y luego
  enviado a _duplicates por ser copia exacta) solo volvía hasta
  "# Hacks y Otros #" en vez de a su carpeta original.
- "Deshacer la última limpieza" ahora también devuelve las imágenes,
  vídeos y manuales huérfanos. Antes, el paso de medios huérfanos los
  movía sin anotarlos en el plan, así que tras "Limpiar TODAS" + "Deshacer"
  volvían las ROMs pero sus imágenes y vídeos se quedaban en _duplicates.
  Ahora cada medio movido es un movimiento más del plan (subcarpetas
  incluidas), y si uno no se puede mover se avisa sin parar el resto.
- Si un archivo concreto no se puede restaurar (bloqueado por otro
  programa, sin permisos...), "Deshacer" avisa, lo cuenta ("Con error:
  N") y sigue con el resto. En modo desatendido (-Yes) el código de
  salida será entonces 2.


Juegos de varios ficheros (.cue/.bin, .gdi, varios discos, .m3u)
-----------------------------------------------------------------
Los juegos de disco (PlayStation, Saturn, Dreamcast, Sega CD, PC Engine
CD...) se componen de varios ficheros. Antes cada fichero se trataba como
una ROM distinta, y eso rompía juegos: un .cue y su .bin parecían copias
uno del otro y se movía uno de los dos; los discos de un juego y su .m3u
parecían duplicados entre sí. Ahora cada juego es una unidad:

- Un .cue, .gdi o .m3u arrastra los ficheros a los que apunta (las pistas
  .bin/.raw; los discos de un .m3u y sus pistas). Dejan de tratarse como
  ROMs sueltas.
- Los discos de un mismo juego sin .m3u ("(Disc 1)", "(Disc 2)",
  "(Disk 1)", "(CD 1)", "(Disc 1 of 2)") forman un conjunto que representa
  el disco de número más bajo.
- Un juego se conserva o se mueve ENTERO, nunca a medias: no te quedas con
  un .cue sin su .bin. Un juego USA y uno Europe se comparan como
  conjuntos.
- Si algún fichero del juego chocara con otro que ya está en _duplicates
  (o con otro juego del mismo plan), ese juego se deja donde está y se
  muestra un aviso.
- Cada fichero es un movimiento propio del plan, así que "Deshacer" lo
  devuelve a su carpeta original exacta.
- Un fichero referenciado por más de un .cue/.m3u (una pista compartida)
  nunca se mueve, para que la copia que conservas siga funcionando.
- Límites conocidos: no se interpretan los descriptores .ccd/.mds; el
  organizador de hacks sigue trabajando fichero a fichero.


Decisiones manuales que se recuerdan (Config\Overrides.json)
-------------------------------------------------------------
Si no estás de acuerdo con lo que decide la puntuación para un juego
concreto, dilo una vez y se respeta en todas las limpiezas, también en
las programadas (-Yes). Crea Config\Overrides.json (mira
Config\Overrides.example.json):

    {
      "Prefer": [ { "System": "snes", "File": "Super Mario World (Europe).sfc" } ],
      "Ignore": [ { "System": "snes", "Title": "Super Mario World" },
                  { "System": "nes",  "File": "Zelda II (USA).nes" } ]
    }

- Prefer: esa ROM gana siempre en su grupo de duplicados; las demás copias
  se mueven como de costumbre.
- Ignore: el grupo no se toca en absoluto. Se identifica por "Title" (el
  nombre que se imprime tras "Grupo:" al limpiar, o el título normal del
  juego) o por "File" (cualquier copia del grupo con ese nombre de
  archivo).
- "System" es el nombre de la carpeta del sistema (snes, nes...). Si se
  omite, o es "*", vale para todos. No distingue mayúsculas.
- Cuando el programa te pregunta cuál de dos ROMs empatadas conservar,
  ahora ofrece recordar tu respuesta: se guarda aquí como un "Prefer".
- Si el archivo no existe, no cambia nada. Si no se puede leer, avisa y
  se ignora (el programa nunca sobrescribe un archivo que no puede leer).


gamelist.xml de RetroBat (favoritos, veces jugada...)
-----------------------------------------------------
Cuando se mueve una ROM duplicada, sus datos de usuario del gamelist.xml
del sistema pasan a la ROM que se queda, para no perder favoritos ni
historial de juego:

- favorite: se conserva si alguna de las copias era favorita.
- playcount, gametime: el mayor de los dos (NO se suman, así que
  deshacer y limpiar de nuevo nunca los infla).
- lastplayed: la fecha más reciente. rating: la nota más alta.
- name, desc, developer, publisher, genre, players, releasedate...: solo
  se copian si la ROM que se queda no los tiene.
- Las rutas de imagen/vídeo/manual nunca se copian (pertenecen al
  archivo movido). Nunca se borra ninguna entrada, así que "Deshacer"
  sigue funcionando igual.
- Si la ROM que se queda no tiene entrada, se crea una nueva.
- También vale para los duplicados exactos de "# Hacks y Otros #".
- Cuando el organizador de hacks mueve hacks sueltos a "# Hacks y Otros #",
  la entrada del gamelist.xml de cada hack sigue al archivo: se actualiza
  su <path> (con copia de seguridad previa), así que RetroBat no pierde sus
  favoritos ni su historial de juego. "Deshacer la última limpieza" devuelve
  la ruta a su sitio. Los hacks sin entrada se mueven igual y el
  gamelist.xml no se toca.
- Antes de guardar se hace una copia del gamelist.xml en
  Resultado\GamelistBackups\ (las últimas UndoHistoryLimit por sistema).

Con PreviewOnly solo informa de lo que haría. Para desactivarlo, pon
MergeGamelistMetadata = $false en Config\Settings.ps1 (desactiva cualquier
cambio en el gamelist.xml: la fusión y las actualizaciones de ruta).


Caché de hashes
----------------
Calcular el hash de miles de ROMs es lo que más tarda de una limpieza, y
cada ejecución volvía a leer y hashear los mismos archivos que no habían
cambiado. Ahora el programa guarda en Resultado\HashCache.tsv el hash de
cada archivo junto con su tamaño y su fecha de modificación en el momento
de calcularlo. Un hash guardado solo se reutiliza mientras AMBOS sigan
siendo exactamente los mismos; si cambia alguno, el archivo se hashea de
nuevo.

- Las siguientes limpiezas se saltan todo archivo que no haya cambiado, y
  en pantalla se indica cuántos hashes se han reutilizado.
- Si cambias HashAlgorithm (MD5, SHA256...), la caché se descarta.
- Es solo un acelerador: si falta, está dañada o no se puede escribir,
  todo funciona igual, solo que más despacio. Borra
  Resultado\HashCache.tsv para empezar de cero, o pon HashCache = $false
  en Config\Settings.ps1 para desactivarla. (La única forma de que se
  equivocara es un archivo cuyo contenido cambie sin cambiar de tamaño ni
  de fecha, algo que prácticamente no ocurre.)
- La deduplicación de "# Hacks y Otros #" ahora se salta los archivos cuyo
  tamaño es único en la carpeta: dos archivos solo pueden ser idénticos si
  pesan exactamente lo mismo, así que la mayoría ni siquiera se leen.


Purgar _duplicates (opción 6 del menú, -Action Purge)
------------------------------------------------------
_duplicates solo crece. La opción 6 borra las copias que llevan allí N
días o más (Config\Settings.ps1: PurgeDuplicatesAfterDays, 90 por
defecto; el menú pregunta el número y con Intro se queda el de por
defecto). Es lo ÚNICO que el programa borra de verdad, así que es muy
cuidadosa:

- La antigüedad cuenta desde que el archivo se MOVIÓ a _duplicates (se lee
  de los planes guardados en Resultado\), no desde la fecha del propio
  archivo, que es la de la ROM original. Si un archivo se movió varias
  veces, cuenta el último movimiento. Los archivos asociados (partidas
  guardadas...) y los medios de subcarpetas cuentan con la fecha de su
  movimiento.
- Los archivos sin fecha de movimiento conocida (por ejemplo de planes que
  ya salieron del historial) nunca se borran de golpe: su cuenta empieza
  la primera vez que la purga los ve (Resultado\DuplicatesSeen.tsv) y solo
  son candidatos N días después. Si uno de esos archivos cambia, su cuenta
  vuelve a empezar.
- Siempre enseña lo que borraría (por sistema, los archivos más antiguos y
  el tamaño total) y pide confirmación -- con -Yes no pregunta. Con
  PreviewOnly solo simula.
- Solo toca archivos dentro de _duplicates, elimina las carpetas que
  queden vacías y anota lo borrado en Resultado\PurgeLog_<fecha>.txt.
- Lo purgado ya no se puede restaurar: "Deshacer" se salta lo que ya no
  está y restaura el resto. Un archivo que no se pueda borrar se avisa sin
  parar a los demás (código de salida 2 en modo desatendido).


Sistemas y extensiones en JSON
------------------------------
Los sistemas que conoce el programa, las extensiones que trata como ROMs y
las carpetas que nunca recorre eran antes listas dentro de
Config\Settings.ps1, mezcladas con código. Ahora viven en Config\Systems.json
y Config\Extensions.json, que se pueden editar sin miedo con cualquier editor
de texto. Para añadir lo tuyo SIN tocar esos archivos (así una actualización
nunca te lo pisa), crea los opcionales Config\Systems.custom.json y/o
Config\Extensions.custom.json, con el mismo formato:

    Systems.custom.json:     { "Mios": { "Mi sistema": "misistema" } }
    Extensions.custom.json:  { "RomExtensions": [".xyz"], "IgnoredFolders": ["mis_cosas"] }

- En los sistemas, si repites un nombre manda la carpeta del archivo custom;
  en extensiones y carpetas ignoradas, las listas se suman.
- Las extensiones se normalizan (".SFC" y "sfc" pasan a ser ".sfc").
- Una entrada concreta no válida se avisa con un mensaje que nombra el
  archivo y se ignora. Si un archivo no se puede leer (JSON roto) o no define
  ningún sistema ni ninguna extensión, el programa se detiene con un mensaje
  que nombra el archivo y el error.


Número de versión y publicación
--------------------------------
El número de versión vive en UN solo archivo, VERSION (antes se repetía en la
cabecera de cada archivo, el banner del menú, el log y los planes). Para
publicar una versión:

    (1) pon el número en VERSION y haz commit
    (2) git tag v2.8
    (3) git push origin v2.8

.github\workflows\release.yml comprueba entonces que la etiqueta coincide con
VERSION, ejecuta las comprobaciones y los tests, genera CleanRoms-v2.8.zip
(y su .sha256) y publica una Release en GitHub con ambos adjuntos. También
puedes generar el ZIP tú mismo con:  pwsh -File Tools\Build-Release.ps1

- Todo el ZIP va dentro de UNA carpeta con el nombre de la versión, así que
  descomprimirlo encima de una instalación anterior no mezcla archivos
  viejos con nuevos.
- No incluye nada personal: UserSettings.json, Overrides.json, tus
  *.custom.json, Logs, Resultado y crash_log.txt nunca van en el ZIP, así
  que una versión nueva no puede pisar tus ajustes ni tus decisiones.
- Todos los mensajes en pantalla (barras de progreso y mensaje de error
  inesperado incluidos) salen ahora de Strings.ps1 en español e inglés; una
  prueba comprueba que cada mensaje que usa el código existe en los dos
  idiomas.


Tests e integración continua
-----------------------------
- Tests\Run-AllTests.ps1 (o Run-AllTests.bat) ejecuta toda la batería de
  tests. Termina con código 1 si algún test falla o se interrumpe por un
  error.
- Tests\Check-Project.ps1 comprueba la sintaxis de todos los .ps1, que
  cada archivo cargado con "$Root\..." existe con las mayúsculas y
  minúsculas exactas (importa en Linux) y que los .json son válidos.
- Tests\Smoke-Unattended.ps1 ejecuta el programa real en modo desatendido
  (-Action ... -Yes) sobre una colección de ejemplo y comprueba que
  termina solo y con el código de salida correcto.
- .github\workflows\tests.yml lanza los tres en cada push y pull request,
  en Windows y en Linux.


Uso por línea de comandos / tareas programadas
-------------------------------------------------
Para ejecuciones desatendidas (Programador de tareas de Windows, etc.),
main.ps1 acepta:

    -Action Clean|Orphans|All|Undo|Purge
                                     Qué hacer (se salta el menú por
                                      completo)
    -System <carpeta>                Carpeta del sistema (p.ej. "snes",
                                      "gba"); omite o usa "ALL" para
                                      todos los sistemas configurados.
                                      Se ignora con -Action Undo y
                                      -Action Purge.
    -OlderThanDays <n>               Solo con -Action Purge: borra las
                                      copias que llevan n días o más en
                                      _duplicates (1-3650). Por defecto:
                                      PurgeDuplicatesAfterDays (90).
    -Yes                             Confirma automáticamente cada
                                      pregunta S/N, en vez de esperar a
                                      que alguien responda.
    -PreviewOnly                     Fuerza el modo simulación solo para
                                      esta ejecución, sin tener que
                                      editar Settings.ps1.

Códigos de salida (útiles para el Programador de tareas y scripts):

    0   Todo correcto.
    1   Error inesperado (detalles en crash_log.txt) o argumentos no válidos.
    2   La ejecución terminó, pero alguna acción falló (ver el log).

En modo no interactivo (-Yes) el programa nunca espera una tecla al
terminar, así que una tarea programada acaba siempre sola.

Ejemplos:

    pwsh -File main.ps1 -Action Clean -System snes -Yes
    pwsh -File main.ps1 -Action All -Yes
    pwsh -File main.ps1 -Action Undo -Yes
    pwsh -File main.ps1 -Action Purge -OlderThanDays 120 -Yes

Sin -Action, main.ps1 se comporta exactamente igual que siempre (menú
interactivo). Sin -Yes, -Action sigue saltándose el menú pero sigue
pidiendo confirmación en cada paso, como de costumbre -- -Yes es lo que
de verdad hace que una ejecución sea desatendida.


Cómo reportar problemas
-------------------------
Si encuentras algún error, o quieres que se añada o se quite alguna
funcionalidad, escribe un correo con el mayor detalle
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
