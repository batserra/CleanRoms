# ============================================================
# CleanROMs
#
# Strings.ps1
#
# Textos de la interfaz en español e inglés. La función T(clave)
# devuelve el texto en el idioma configurado ($Global:Settings.Language,
# "es" o "en"), con soporte de parámetros tipo -f ({0}, {1}...).
#
# Para añadir un texto nuevo: pon la misma clave en los dos
# bloques (es y en) con el mismo nombre, y usa T("esa.clave") en
# vez de escribir el texto directamente en un Write-Host.
# ============================================================

$Global:Strings = @{

    es = @{

        # ---------- Menú / banner ----------
        "banner.title"              = "CLEAN ROMS v{0}"
        "menu.whatToDo"             = "¿Qué quieres hacer?"
        "menu.option1"              = " 1) Limpiar ROMs duplicadas"
        "menu.option2"              = " 2) Deshacer la última limpieza"
        "menu.option3"              = " 3) Limpiar imágenes/vídeos/manuales huérfanos"
        "menu.option4"              = " 4) TODO: Mover ROMs e imágenes/vídeos/manuales de TODOS los sistemas"
        "menu.option5"              = " 5) Configuración (ruta de RetroBat / idioma)"
        "menu.option6"              = " 6) Purgar _duplicates (BORRAR copias antiguas)"
        "menu.option7"              = " 7) Salir"
        "menu.prompt"               = "Opción"
        "menu.searchingSystems"     = "Buscando sistemas con ROMs..."
        "menu.noSystemsFound"       = "No se ha encontrado ninguna carpeta de sistema con ROMs."
        "menu.noSystemsHint"        = "(revisa la ruta de RetroBat configurada, o si tus ROMs usan una extensión que no está en la lista)"
        "menu.pressEnterContinue"   = "Pulse ENTER para continuar"
        "menu.selectSystem"         = "Seleccione sistema"
        "menu.allSystems"           = " 0) TODOS LOS SISTEMAS"
        "menu.pressEnterExit"       = "Pulse ENTER para salir"
        "menu.pressEnterMainMenu"   = "Pulse ENTER para volver al menú principal"
        "menu.totalCleanTitle"      = "   LIMPIEZA TOTAL: ROMs + imágenes/vídeos/manuales"
        "menu.totalCleanAllSystems" = "   (TODOS los sistemas)"

        # ---------- Menú de configuración ----------
        "config.menuTitle"          = "== Configuración =="
        "config.menuPath"           = "Ruta de RetroBat actual        : {0}"
        "config.menuUiLanguage"     = "Idioma de la interfaz actual   : {0}"
        "config.menuRomPriority"    = "Prioridad de ROMs actual       : {0}"
        "config.opt1"               = " 1) Cambiar la ruta de RetroBat"
        "config.opt2"               = " 2) Cambiar el idioma de la interfaz"
        "config.opt3"               = " 3) Cambiar la prioridad de ROMs (español/inglés)"
        "config.opt4"               = " 4) Cambiar todo lo anterior"
        "config.opt0"               = " 0) Volver al menú principal"

        "priority.askTitle"         = "¿Qué ROMs quieres que gane el programa cuando compitan dos versiones del mismo juego?"
        "priority.opt1"             = " 1) Español (prioriza España > Europa > USA > Japón)"
        "priority.opt2"             = " 2) Inglés (prioriza USA > Europa > España > Japón)"
        "priority.prompt"           = "Opción"
        "priority.labelEs"          = "Español"
        "priority.labelEn"          = "Inglés"

        # ---------- Idioma (primer arranque) ----------
        "lang.prompt.title"         = "Selecciona idioma / Select language:"
        "lang.prompt.option1"       = " 1) Español"
        "lang.prompt.option2"       = " 2) English"
        "lang.prompt.ask"           = "Opción / Option"
        "lang.saved"                = "Idioma guardado. Puedes cambiarlo luego en Config\UserSettings.json ({0})."

        # ---------- Escaneo ----------
        "scan.system"               = "Sistema : {0}"
        "scan.folder"               = "Carpeta : {0}"
        "scan.header"               = " ESCANEANDO ROMS"
        "scan.headerSystem"         = " ESCANEANDO ROMS — {0}"
        "scan.filesFound"           = "Archivos encontrados : {0}"
        "scan.romsProcessed"        = "ROMs procesadas      : {0}"
        "scan.timeTaken"            = "Tiempo empleado      : {0} segundos"
        "scan.romsFound"            = "ROMs encontradas : {0}"
        "scan.groupsFound"          = "Grupos encontrados : {0}"
        "scan.totalGroups"          = "Grupos totales : {0}"
        "scan.noDuplicatesFound"    = "No se han encontrado ROMs duplicadas. Nada que limpiar."

        # ---------- Plan / confirmación ----------
        "plan.previewTitle"         = "             PREVISUALIZACIÓN"
        "plan.confirmMove"          = "¿Confirmas mover los archivos indicados como MOVE a la carpeta de duplicados? (S/N)"
        "plan.cancelled"            = "Cancelado. No se ha movido ni borrado nada."
        "plan.exportedTo"           = "Plan exportado en:"
        "plan.nothingToExecute"     = "No hay ninguna acción que ejecutar."
        "plan.previewOnlyNotice"    = "Modo simulación (PreviewOnly) activo: no se moverá ni borrará nada de verdad."

        # ---------- Resumen ----------
        "summary.title"             = "           RESUMEN DE LIMPIEZA"
        "summary.systems"           = "Sistema(s):"
        "summary.stats"             = "Estadísticas"
        "summary.totalActions"      = "Total acciones : {0}"
        "summary.date"              = "Fecha          : {0}"
        "summary.version"           = "Versión        : {0}"
        "summary.warnings"          = "Advertencias"
        "summary.noDuplicates"      = " - No se han encontrado ROMs duplicadas."
        "summary.emptyPlan"         = " - El plan está vacío."
        "summary.noWarnings"       = "No hay advertencias."
        "summary.importantNotice"  = "Aviso importante arriba en amarillo. Pulse ENTER para continuar"

        # ---------- Ejecución ----------
        "exec.keep"                 = "[KEEP ] {0}"
        "exec.move"                 = "[MOVE ] {0}"
        "exec.moveAsset"            = "[MOVE ]   + {0}"
        "exec.delete"               = "[DELETE] {0}"
        "exec.deleteAsset"          = "[DELETE]   + {0}"
        "exec.rename"               = "[RENAME] {0} -> {1}"
        "exec.skipped"              = "[SALTADO] {0}"
        "exec.fileNotFound"         = "No existe el archivo:"
        "exec.assetMoveFailed"      = "No se pudo mover el archivo asociado: {0} ({1})"
        "asset.destinationExists"   = "Ya existe un archivo con ese nombre en el destino, no se sobrescribe: {0}"
        "gamelist.entryMerged"      = "[GAMELIST] {0}: datos de '{1}' fusionados en '{2}' ({3})"
        "gamelist.entryCreated"     = "[GAMELIST] {0}: entrada nueva para '{1}' con datos de '{2}' ({3})"
        "gamelist.previewMerged"    = "[SIMULACION] [GAMELIST] {0}: datos de '{1}' se fusionarian en '{2}' ({3})"
        "gamelist.previewCreated"   = "[SIMULACION] [GAMELIST] {0}: se crearia entrada para '{1}' con datos de '{2}' ({3})"
        "gamelist.summary"          = "gamelist.xml: {0} entrada(s) actualizada(s), {1} creada(s), en {2} sistema(s)."
        "gamelist.previewSummary"   = "[SIMULACION] gamelist.xml: {0} entrada(s) se actualizarian, {1} se crearian, en {2} sistema(s)."
        "gamelist.backupAt"         = "  Copia de seguridad de gamelist.xml: {0}"
        "gamelist.invalidXml"       = "No se pudo leer {0} ({1}); se omite ese sistema."
        "gamelist.failed"           = "No se pudo actualizar el gamelist.xml de {0}: {1}"
        "gamelist.pathsUpdated"     = "[GAMELIST] {0}: {1} entrada(s) con la ruta actualizada"
        "exec.assetDeleteFailed"    = "No se pudo borrar el archivo asociado: {0}"
        "exec.executing"            = "Ejecutando plan..."
        "exec.done"                 = "Listo."
        "exec.planCompleted"        = "Plan completado."
        "exec.movedOk"              = "  Movidos correctamente     : {0}"
        "exec.previewOnly"          = "  Solo previsualizados      : {0} (modo PreviewOnly)"
        "exec.skippedExists"        = "  SALTADOS (ya existían)    : {0}"
        "exec.skippedMissing"       = "  SALTADOS (no encontrados) : {0}"
        "exec.alreadyExists"        = "Ya existe:"
        "exec.previewMove"          = "[PREVIEW MOVE] {0}"
        "exec.previewDelete"        = "[PREVIEW DELETE] {0}"
        "exec.previewRename"        = "[PREVIEW RENAME] {0}"

        # ---------- Deshacer ----------
        "undo.title"                = "        DESHACER ÚLTIMA LIMPIEZA"
        "undo.chooseTitle"          = "¿Qué limpieza quieres deshacer?"
        "undo.chooseCurrent"        = "  0) La más reciente (Enter)"
        "undo.chooseHistoryItem"    = "  {0}) {1}"
        "undo.choosePrompt"         = "Elige un número"
        "undo.noPlanFound"          = "No se encontró ningún plan anterior en {0}."
        "undo.nothingToUndo"        = "No hay nada que deshacer (la última vez no se movió nada de verdad, o ya se deshizo)."
        "undo.restored"             = "[RESTAURADO] {0}"
        "undo.restoredAsset"        = "               + {0}"
        "undo.assetsRestoredCount"  = "Archivos asociados restaurados : {0}"
        "undo.skippedConflict"      = "[SALTADO] Ya existe algo en el destino, no se sobrescribe: {0}"
        "undo.summaryRestored"      = "Restaurados      : {0}"
        "undo.summarySkipped"       = "No hacía falta    : {0}"
        "undo.summaryConflicts"     = "Omitidos (conflicto) : {0}"
        "undo.confirm"              = "¿Confirmas deshacer la última limpieza? (S/N)"
        "undo.noPlanFoundFull"      = "No se encontró ningún plan anterior."
        "undo.readError"            = "No se pudo leer el plan anterior (archivo dañado o vacío)."
        "undo.checking"             = "Se van a comprobar {0} movimientos del último plan..."
        "undo.occupiedSource"       = "[OMITIDO]    Ya existe algo en el origen:"
        "undo.restoredCount"        = "Restaurados     : {0}"
        "undo.notMovedCount"        = "Sin cambios     : {0} (no se habían movido)"
        "undo.occupiedCount"        = "Omitidos        : {0} (ya había algo en el origen)"
        "undo.failedCount"          = "Con error       : {0} (ver el log)"
        "undo.failed"               = "No se pudo restaurar {0}: {1}"
        "overrides.invalid"         = "No se pudo leer {0} ({1}); se ignoran las decisiones manuales."
        "overrides.entryIncomplete" = "Overrides.json: una entrada de '{0}' no tiene '{1}' y se ignora."
        "overrides.groupIgnored"    = "[IGNORADO] Grupo '{0}': no se toca (Overrides.json: {1})"
        "overrides.ignoredCount"    = "Grupos omitidos por Overrides.json: {0}"
        "overrides.keepReason"      = "Elegida manualmente (Overrides.json)"
        "overrides.moveReason"      = "Hay otra copia fijada como preferida en Overrides.json"
        "overrides.conflict"        = "Overrides.json: varias copias preferidas en el grupo '{0}'; se usa '{1}'."
        "overrides.rememberPrompt"  = "¿Recordar esta elección para las próximas limpiezas (se guarda en Config\Overrides.json)? (S/N)"
        "overrides.remembered"      = "Elección guardada en {0}"
        "overrides.rememberKeepAllPrompt" = "¿Recordar que este juego NO se toca en las próximas limpiezas (se guarda como 'Ignore' en Config\Overrides.json)? (S/N)"
        "multifile.detected"        = "Juegos de varios ficheros (.cue/.bin, discos, .m3u...) tratados como una unidad: {0}"
        "multifile.memberKeep"      = "Parte del juego '{0}' (se conserva junto con él)"
        "multifile.memberMove"      = "Parte del juego '{0}' (se mueve junto con él)"
        "multifile.collision"       = "[OMITIDO] '{0}' no se mueve: ya existe '{1}' en el destino o lo usa otro juego del mismo plan."
        "tie.title"                 = "   EMPATE: no se puede decidir en automático"
        "tie.explanation"           = "Estas dos copias tienen la misma puntuación ({0}) y ningún criterio las diferencia:"
        "tie.ask"                   = "¿Cuál quieres conservar? (1/2, o 3 = conservar TODAS sin mover ninguna)"
        "tie.keepAllChosen"         = "Se conservan todas las copias de este juego: no se mueve ninguna."
        "tie.differentKeepAll"      = "EMPATE: misma puntuación y contenido DISTINTO (hash {0} distinto). Son juegos distintos, no duplicados: se conservan TODAS las copias."
        "tie.contentNotComparable"  = "Aviso: no se pudo comparar el contenido de los dos archivos (¿bloqueado o ilegible?)."
        "tie.autoKeepAll"           = "Modo no interactivo: el contenido es distinto y la puntuación es la misma, así que se conservan TODAS las copias (no se mueve ninguna). Para decidirlo, haz la limpieza interactiva o usa Config\Overrides.json."
        "tie.keepAllReason"         = "Se conserva junto con las demás copias (empate con contenido distinto)"
        "tie.identicalContent"      = "Contenido idéntico (mismo hash {0}): no hace falta preguntar, se conserva una de las dos."
        "tie.differentContent"      = "Aviso: el contenido de los dos archivos NO es idéntico (hash {0} distinto), aunque coincidan en todo lo demás."
        "hash.identical"            = "Contenido idéntico al conservado ({0})"
        "hash.different"            = "Contenido distinto al conservado ({0}) — revisar si de verdad es un duplicado"
        "sevenzip.detected"         = "7-Zip detectado: {0}"
        "sevenzip.notDetected"      = "7-Zip no detectado en el PATH. Los archivos .7z se procesarán solo por su nombre, sin mirar su contenido."
        "config.folderNotExists"    = "Esa carpeta no existe, prueba otra vez."
        "config.rootSaved"          = "Guardado. La próxima vez no hará falta volver a indicarlo."
        "config.rootNotSet"         = "Ruta de RetroBat no configurada todavía."
        "config.rootPrompt"         = "Ruta a la carpeta 'roms' de RetroBat [{0}]"
        "group.label"               = "GRUPO:"
        "group.romCount"            = "ROMS :"
        "alias.loadFailed"          = "Aviso: no se pudo leer Config\TitleAliases.json, se ignoran los alias de título."

        # ---------- Huérfanos ----------
        "media.header"              = "     IMÁGENES / VÍDEOS / MANUALES HUÉRFANOS"
        "media.scanning"            = "Revisando: {0}"
        "media.found"               = "Huérfanos encontrados : {0}"
        "media.noneFound"           = "No se han encontrado imágenes, vídeos ni manuales huérfanos."
        "media.confirm"             = "¿Confirmas mover los huérfanos indicados a la carpeta de duplicados? (S/N)"
        "media.moved"               = "[MOVIDO] {0}"
        "media.movedCount"          = "Movidos  : {0}"
        "media.skippedCount"        = "Saltados : {0}"
        "media.reason"              = "Medio huérfano ({0}): ninguna ROM tiene ese nombre"
        "media.failed"              = "No se pudo mover {0}: {1}"
        "media.undoable"            = "Se puede deshacer con la opción 2 del menú ('Deshacer la última limpieza')."
        "hashcache.summary"         = "Caché de hashes: {0} reutilizados, {1} calculados."
        "cleaner.folderNotFound"    = "  -> Carpeta no encontrada, se omite."
        "cleaner.foldersSkipped"    = "Sistemas sin carpeta en tu RetroBat (omitidos): {0}"
        "plan.duplicateKeep"        = "El plan contiene acciones KEEP duplicadas."
        "plan.moveNoTarget"         = "Acción MOVE sin destino: {0}"
        "exec.progress"             = "Ejecutando plan"
        "exec.unknownAction"        = "Acción desconocida: {0}"
        "progress.status"           = "{0} de {1}"
        "scan.progress"             = "Analizando ROMs"
        "scan.folderMissing"        = "La carpeta no existe: {0}"
        "decision.kept"             = "ROM CONSERVADA"
        "decision.discarded"        = "ROMS DESCARTADAS"
        "main.crash"                = "Se ha producido un error inesperado."
        "main.crashDetails"         = "Detalles guardados en: {0}"
        "purge.header"              = "PURGA DE _duplicates: copias movidas hace {0} días o más"
        "purge.folderMissing"       = "No existe la carpeta {0}: no hay nada que purgar."
        "purge.undated"             = "{0} archivo(s) sin fecha de movimiento conocida: su cuenta empieza hoy y podrán purgarse dentro de {1} días."
        "purge.nothing"             = "No hay archivos con {0} días o más en _duplicates."
        "purge.systemLine"          = "  {0}: {1} archivo(s), {2}"
        "purge.fileLine"            = "    {0}  ({1} días)"
        "purge.more"                = "    ... y {0} más"
        "purge.total"               = "Total a borrar: {0} archivo(s), {1}"
        "purge.confirm"             = "Se van a BORRAR DEFINITIVAMENTE {0} archivo(s) ({1}). Esto NO se puede deshacer. ¿Continuar? (S/N)"
        "purge.cancelled"           = "Purga cancelada. No se ha borrado nada."
        "purge.previewOnly"         = "[SIMULACION] No se ha borrado nada."
        "purge.deleted"             = "Borrados: {0} archivo(s), {1} liberados."
        "purge.failed"              = "No se pudo borrar {0}: {1}"
        "purge.logAt"               = "Lista de lo borrado: {0}"
        "purge.askDays"             = "¿Borrar de _duplicates lo que lleve cuántos días o más? (Intro = {0})"
        "purge.invalidDays"         = "Escribe un número de días entre 1 y 3650."
        "media.nothingDeleted"      = "Nada se ha borrado: si algo no era huérfano de verdad, puedes"
        "media.nothingDeleted2"     = "devolverlo a mano desde '_duplicates'."
        "media.previewTitle"        = "         PREVISUALIZACIÓN"
        "media.system"              = "       Sistema : {0}   Tipo : {1}"
        "media.destination"         = "       Destino : {0}"
        "media.totalFound"          = "Total huérfanos encontrados : {0}"
        "media.confirmFolder"       = "¿Mover estos archivos a la carpeta de respaldo '{0}'? (S/N)"
        "media.cancelled"           = "Operación cancelada. No se ha movido nada."
        "media.alreadyBackedUp"     = "[SALTADO] Ya existe en el respaldo: {0}"
        "media.nothingDeletedFull"  = "devolverlo a mano desde '{0}'."

        # ---------- Organizador de Hacks ----------
        "hackorg.header"            = "     ORGANIZAR ROMS HACKEADAS"
        "hackorg.foundInSystem"     = "  {0}: {1} ROM(s) hackeada(s) sueltas"
        "hackorg.noneFound"         = "No se han encontrado ROMs hackeadas sueltas fuera de '# Hacks y Otros #'."
        "hackorg.previewTitle"      = "         PREVISUALIZACIÓN"
        "hackorg.destination"       = "       Destino : {0}"
        "hackorg.totalFound"        = "Total ROMs hackeadas encontradas : {0}"
        "hackorg.confirm"           = "¿Mover estas ROMs a su propia carpeta '# Hacks y Otros #'? (S/N)"
        "hackorg.moved"             = "[MOVIDO] {0}"
        "hackorg.reason"            = "ROM hackeada organizada en su propia carpeta"
        "hackorg.movedCount"        = "Movidos  : {0}"
        "hackorg.skippedCount"      = "Saltados : {0}"

        # ---------- Deduplicación por hash dentro de Hacks y Otros ----------
        "hackdedup.header"          = "     DUPLICADOS EXACTOS DENTRO DE '# Hacks y Otros #'"
        "hackdedup.foundInSystem"   = "  {0}: {1} grupo(s) de archivos idénticos"
        "hackdedup.noneFound"       = "No se han encontrado duplicados exactos dentro de '# Hacks y Otros #'."
        "hackdedup.hash"            = "{0} : {1}"
        "hackdedup.totalFound"      = "Total duplicados exactos encontrados : {0}"
        "hackdedup.confirmNote"     = "Nota: son copias con el mismo contenido exacto (mismo {0}), solo cambia el nombre del archivo — responder S es seguro y no se pierde nada, ya que la copia movida sigue existiendo dentro de _duplicates. Si cambias de opinión, puedes devolverla a su sitio con la opción 2 del menú ('Deshacer la última limpieza'), igual que en la limpieza normal de ROMs."
        "hackdedup.confirmMove"     = "¿Mover los duplicados indicados arriba? (S/N)"
        "hackdedup.reason"          = "Duplicado exacto (mismo hash) dentro de '# Hacks y Otros #'"

        # ---------- Confirmaciones genéricas ----------
        "plan.destination"           = "Destino : {0}"
        "plan.reason"                = "Motivo:"
        "plan.hash"                  = "{0} : {1}"
        "confirm.yes"                = "S"
        "confirm.yesNoHint"          = "(S/N)"
        "confirm.yesPattern"         = "^\s*(s|si|sí|y|yes)\s*$"
        "confirm.autoConfirmed"      = "(modo no interactivo: se confirma automáticamente con S)"
        "cli.unknownSystem"          = "Sistema no reconocido: '{0}'. Usa el nombre de carpeta tal cual aparece en RetroBat\roms (por ejemplo: snes, gba, megadrive)."
        "cli.rootNotConfigured"      = "No se ha podido determinar la ruta de RetroBat automáticamente (primera ejecución, sin configuración previa, y la carpeta por defecto tampoco existe). Ejecuta el programa una vez sin -Yes para configurarla, o edita Config\UserSettings.json a mano."
        "cli.usageHint"              = "Uso: .\main.ps1 -Action Clean|Orphans|All|Undo|Purge [-System <carpeta>] [-OlderThanDays <n>] [-Yes] [-PreviewOnly]"
        "plan.htmlHint"              = "  - {0}  (informe visual, ábrelo con el navegador)"
        "plan.operationCancelled"    = "Operación cancelada."
        "plan.operationCancelledDetail" = "No se ha movido NINGUNO de los {0} archivos indicados como MOVE — siguen exactamente donde estaban."
    }

    en = @{

        # ---------- Menu / banner ----------
        "banner.title"              = "CLEAN ROMS v{0}"
        "menu.whatToDo"             = "What do you want to do?"
        "menu.option1"              = " 1) Clean up duplicate ROMs"
        "menu.option2"              = " 2) Undo the last cleanup"
        "menu.option3"              = " 3) Clean up orphaned images/videos/manuals"
        "menu.option4"              = " 4) ALL: Move ROMs and images/videos/manuals for EVERY system"
        "menu.option5"              = " 5) Configuration (RetroBat path / language)"
        "menu.option6"              = " 6) Purge _duplicates (DELETE old copies)"
        "menu.option7"              = " 7) Exit"
        "menu.prompt"               = "Option"
        "menu.searchingSystems"     = "Looking for systems with ROMs..."
        "menu.noSystemsFound"       = "No system folder with ROMs was found."
        "menu.noSystemsHint"        = "(check the configured RetroBat path, or whether your ROMs use an extension that isn't in the list)"
        "menu.pressEnterContinue"   = "Press ENTER to continue"
        "menu.selectSystem"         = "Select a system"
        "menu.allSystems"           = " 0) ALL SYSTEMS"
        "menu.pressEnterExit"       = "Press ENTER to exit"
        "menu.pressEnterMainMenu"   = "Press ENTER to return to the main menu"
        "menu.totalCleanTitle"      = "   FULL CLEANUP: ROMs + images/videos/manuals"
        "menu.totalCleanAllSystems" = "   (ALL systems)"

        # ---------- Configuration menu ----------
        "config.menuTitle"          = "== Configuration =="
        "config.menuPath"           = "Current RetroBat path          : {0}"
        "config.menuUiLanguage"     = "Current interface language     : {0}"
        "config.menuRomPriority"    = "Current ROM priority           : {0}"
        "config.opt1"               = " 1) Change the RetroBat path"
        "config.opt2"               = " 2) Change the interface language"
        "config.opt3"               = " 3) Change the ROM priority (Spanish/English)"
        "config.opt4"               = " 4) Change all of the above"
        "config.opt0"               = " 0) Back to the main menu"

        "priority.askTitle"         = "Which ROMs do you want the program to prefer when two versions of the same game compete?"
        "priority.opt1"             = " 1) Spanish (prioritizes Spain > Europe > USA > Japan)"
        "priority.opt2"             = " 2) English (prioritizes USA > Europe > Spain > Japan)"
        "priority.prompt"           = "Option"
        "priority.labelEs"          = "Spanish"
        "priority.labelEn"          = "English"

        # ---------- Language (first run) ----------
        "lang.prompt.title"         = "Selecciona idioma / Select language:"
        "lang.prompt.option1"       = " 1) Español"
        "lang.prompt.option2"       = " 2) English"
        "lang.prompt.ask"           = "Opción / Option"
        "lang.saved"                = "Language saved. You can change it later in Config\UserSettings.json ({0})."

        # ---------- Scanning ----------
        "scan.system"               = "System : {0}"
        "scan.folder"               = "Folder : {0}"
        "scan.header"               = " SCANNING ROMS"
        "scan.headerSystem"         = " SCANNING ROMS — {0}"
        "scan.filesFound"           = "Files found        : {0}"
        "scan.romsProcessed"        = "ROMs processed     : {0}"
        "scan.timeTaken"            = "Time taken          : {0} seconds"
        "scan.romsFound"            = "ROMs found : {0}"
        "scan.groupsFound"          = "Groups found : {0}"
        "scan.totalGroups"          = "Total groups : {0}"
        "scan.noDuplicatesFound"    = "No duplicate ROMs were found. Nothing to clean up."

        # ---------- Plan / confirmation ----------
        "plan.previewTitle"         = "                PREVIEW"
        "plan.confirmMove"          = "Confirm moving the files marked MOVE to the duplicates folder? (Y/N)"
        "plan.cancelled"            = "Cancelled. Nothing was moved or deleted."
        "plan.exportedTo"           = "Plan exported to:"
        "plan.nothingToExecute"     = "There is no action to execute."
        "plan.previewOnlyNotice"    = "Simulation mode (PreviewOnly) is on: nothing will actually be moved or deleted."

        # ---------- Summary ----------
        "summary.title"             = "             CLEANUP SUMMARY"
        "summary.systems"           = "System(s):"
        "summary.stats"             = "Statistics"
        "summary.totalActions"      = "Total actions : {0}"
        "summary.date"              = "Date          : {0}"
        "summary.version"           = "Version       : {0}"
        "summary.warnings"          = "Warnings"
        "summary.noDuplicates"      = " - No duplicate ROMs were found."
        "summary.emptyPlan"         = " - The plan is empty."
        "summary.noWarnings"       = "No warnings."
        "summary.importantNotice"  = "Important notice above in yellow. Press ENTER to continue"

        # ---------- Execution ----------
        "exec.keep"                 = "[KEEP ] {0}"
        "exec.move"                 = "[MOVE ] {0}"
        "exec.moveAsset"            = "[MOVE ]   + {0}"
        "exec.delete"               = "[DELETE] {0}"
        "exec.deleteAsset"          = "[DELETE]   + {0}"
        "exec.rename"               = "[RENAME] {0} -> {1}"
        "exec.skipped"              = "[SKIPPED] {0}"
        "exec.fileNotFound"         = "File does not exist:"
        "exec.assetMoveFailed"      = "Could not move the associated file: {0} ({1})"
        "asset.destinationExists"   = "A file with that name already exists at the destination, not overwriting: {0}"
        "gamelist.entryMerged"      = "[GAMELIST] {0}: data from '{1}' merged into '{2}' ({3})"
        "gamelist.entryCreated"     = "[GAMELIST] {0}: new entry for '{1}' with data from '{2}' ({3})"
        "gamelist.previewMerged"    = "[PREVIEW] [GAMELIST] {0}: data from '{1}' would be merged into '{2}' ({3})"
        "gamelist.previewCreated"   = "[PREVIEW] [GAMELIST] {0}: an entry would be created for '{1}' with data from '{2}' ({3})"
        "gamelist.summary"          = "gamelist.xml: {0} entry(ies) updated, {1} created, in {2} system(s)."
        "gamelist.previewSummary"   = "[PREVIEW] gamelist.xml: {0} entry(ies) would be updated, {1} created, in {2} system(s)."
        "gamelist.backupAt"         = "  gamelist.xml backup: {0}"
        "gamelist.invalidXml"       = "Could not read {0} ({1}); skipping that system."
        "gamelist.failed"           = "Could not update the gamelist.xml of {0}: {1}"
        "gamelist.pathsUpdated"     = "[GAMELIST] {0}: {1} entry(ies) with updated path"
        "exec.assetDeleteFailed"    = "Could not delete the associated file: {0}"
        "exec.executing"            = "Executing plan..."
        "exec.done"                 = "Done."
        "exec.planCompleted"        = "Plan completed."
        "exec.movedOk"              = "  Successfully moved       : {0}"
        "exec.previewOnly"          = "  Preview only             : {0} (PreviewOnly mode)"
        "exec.skippedExists"        = "  SKIPPED (already existed) : {0}"
        "exec.skippedMissing"       = "  SKIPPED (not found)       : {0}"
        "exec.alreadyExists"        = "Already exists:"
        "exec.previewMove"          = "[PREVIEW MOVE] {0}"
        "exec.previewDelete"        = "[PREVIEW DELETE] {0}"
        "exec.previewRename"        = "[PREVIEW RENAME] {0}"

        # ---------- Undo ----------
        "undo.title"                = "        UNDO LAST CLEANUP"
        "undo.chooseTitle"          = "Which cleanup do you want to undo?"
        "undo.chooseCurrent"        = "  0) The most recent one (Enter)"
        "undo.chooseHistoryItem"    = "  {0}) {1}"
        "undo.choosePrompt"         = "Pick a number"
        "undo.noPlanFound"          = "No previous plan was found in {0}."
        "undo.nothingToUndo"        = "There is nothing to undo (last time nothing was actually moved, or it was already undone)."
        "undo.restored"             = "[RESTORED] {0}"
        "undo.restoredAsset"        = "               + {0}"
        "undo.assetsRestoredCount"  = "Associated files restored : {0}"
        "undo.skippedConflict"      = "[SKIPPED] Something already exists at the destination, not overwriting: {0}"
        "undo.summaryRestored"      = "Restored          : {0}"
        "undo.summarySkipped"       = "Not needed        : {0}"
        "undo.summaryConflicts"     = "Skipped (conflict) : {0}"
        "undo.confirm"              = "Confirm undoing the last cleanup? (Y/N)"
        "undo.noPlanFoundFull"      = "No previous plan was found."
        "undo.readError"            = "Could not read the previous plan (corrupted or empty file)."
        "undo.checking"             = "About to check {0} moves from the last plan..."
        "undo.occupiedSource"       = "[SKIPPED]    Something already exists at the source:"
        "undo.restoredCount"        = "Restored        : {0}"
        "undo.notMovedCount"        = "Unchanged       : {0} (had not been moved)"
        "undo.occupiedCount"        = "Skipped         : {0} (something already at the source)"
        "undo.failedCount"          = "Failed          : {0} (see the log)"
        "undo.failed"               = "Could not restore {0}: {1}"
        "overrides.invalid"         = "Could not read {0} ({1}); manual decisions are ignored."
        "overrides.entryIncomplete" = "Overrides.json: an entry in '{0}' has no '{1}' and is ignored."
        "overrides.groupIgnored"    = "[IGNORED] Group '{0}': left untouched (Overrides.json: {1})"
        "overrides.ignoredCount"    = "Groups skipped by Overrides.json: {0}"
        "overrides.keepReason"      = "Chosen manually (Overrides.json)"
        "overrides.moveReason"      = "Another copy is pinned as preferred in Overrides.json"
        "overrides.conflict"        = "Overrides.json: several preferred copies in group '{0}'; using '{1}'."
        "overrides.rememberPrompt"  = "Remember this choice for future cleanups (saved to Config\Overrides.json)? (Y/N)"
        "overrides.remembered"      = "Choice saved to {0}"
        "overrides.rememberKeepAllPrompt" = "Remember that this game is NOT touched in future cleanups (saved as 'Ignore' in Config\Overrides.json)? (Y/N)"
        "multifile.detected"        = "Multi-file games (.cue/.bin, discs, .m3u...) handled as a single unit: {0}"
        "multifile.memberKeep"      = "Part of the game '{0}' (kept together with it)"
        "multifile.memberMove"      = "Part of the game '{0}' (moved together with it)"
        "multifile.collision"       = "[SKIPPED] '{0}' is not moved: '{1}' already exists at the destination or is used by another game in the same plan."
        "tie.title"                 = "   TIE: cannot decide automatically"
        "tie.explanation"           = "These two copies have the same score ({0}) and no criterion tells them apart:"
        "tie.ask"                   = "Which one do you want to keep? (1/2, or 3 = keep ALL, moving none)"
        "tie.keepAllChosen"         = "All copies of this game are kept: none is moved."
        "tie.differentKeepAll"      = "TIE: same score and DIFFERENT content ({0} hash differs). They are different games, not duplicates: ALL copies are kept."
        "tie.contentNotComparable"  = "Warning: the content of the two files could not be compared (locked or unreadable?)."
        "tie.autoKeepAll"           = "Non-interactive mode: the content differs and the score is the same, so ALL copies are kept (none is moved). To decide it, run the interactive cleanup or use Config\Overrides.json."
        "tie.keepAllReason"         = "Kept together with the other copies (tie with different content)"
        "tie.identicalContent"      = "Identical content (same {0} hash): no need to ask, one of the two is kept."
        "tie.differentContent"      = "Notice: the content of the two files is NOT identical (different {0} hash), even though everything else matches."
        "hash.identical"            = "Identical content to the kept file ({0})"
        "hash.different"            = "Different content from the kept file ({0}) — check whether it's really a duplicate"
        "sevenzip.detected"         = "7-Zip detected: {0}"
        "sevenzip.notDetected"      = "7-Zip not found in PATH. .7z files will be processed by their file name only, without looking inside."
        "config.folderNotExists"    = "That folder doesn't exist, try again."
        "config.rootSaved"          = "Saved. You won't need to enter it again next time."
        "config.rootNotSet"         = "RetroBat path not configured yet."
        "config.rootPrompt"         = "Path to RetroBat's 'roms' folder [{0}]"
        "group.label"               = "GROUP:"
        "group.romCount"            = "ROMS :"
        "alias.loadFailed"          = "Warning: could not read Config\TitleAliases.json, title aliases are being ignored."

        # ---------- Orphaned media ----------
        "media.header"              = "     ORPHANED IMAGES / VIDEOS / MANUALS"
        "media.scanning"            = "Checking: {0}"
        "media.found"               = "Orphans found : {0}"
        "media.noneFound"           = "No orphaned images, videos, or manuals were found."
        "media.confirm"             = "Confirm moving the orphans listed to the duplicates folder? (Y/N)"
        "media.moved"               = "[MOVED] {0}"
        "media.movedCount"          = "Moved   : {0}"
        "media.skippedCount"        = "Skipped : {0}"
        "media.reason"              = "Orphaned media ({0}): no ROM has that name"
        "media.failed"              = "Could not move {0}: {1}"
        "media.undoable"            = "You can undo this with menu option 2 ('Undo the last cleanup')."
        "hashcache.summary"         = "Hash cache: {0} reused, {1} computed."
        "cleaner.folderNotFound"    = "  -> Folder not found, skipping."
        "cleaner.foldersSkipped"    = "Systems with no folder in your RetroBat (skipped): {0}"
        "plan.duplicateKeep"        = "The plan contains duplicate KEEP actions."
        "plan.moveNoTarget"         = "MOVE action without a destination: {0}"
        "exec.progress"             = "Running plan"
        "exec.unknownAction"        = "Unknown action: {0}"
        "progress.status"           = "{0} of {1}"
        "scan.progress"             = "Analyzing ROMs"
        "scan.folderMissing"        = "The folder doesn't exist: {0}"
        "decision.kept"             = "KEPT ROM"
        "decision.discarded"        = "DISCARDED ROMS"
        "main.crash"                = "An unexpected error occurred."
        "main.crashDetails"         = "Details saved to: {0}"
        "purge.header"              = "PURGE OF _duplicates: copies moved {0} days ago or more"
        "purge.folderMissing"       = "The folder {0} doesn't exist: nothing to purge."
        "purge.undated"             = "{0} file(s) with no known move date: their clock starts today and they can be purged in {1} days."
        "purge.nothing"             = "No files {0} days old or more in _duplicates."
        "purge.systemLine"          = "  {0}: {1} file(s), {2}"
        "purge.fileLine"            = "    {0}  ({1} days)"
        "purge.more"                = "    ... and {0} more"
        "purge.total"               = "Total to delete: {0} file(s), {1}"
        "purge.confirm"             = "{0} file(s) ({1}) will be PERMANENTLY DELETED. This CANNOT be undone. Continue? (Y/N)"
        "purge.cancelled"           = "Purge cancelled. Nothing was deleted."
        "purge.previewOnly"         = "[PREVIEW] Nothing was deleted."
        "purge.deleted"             = "Deleted: {0} file(s), {1} freed."
        "purge.failed"              = "Could not delete {0}: {1}"
        "purge.logAt"               = "List of what was deleted: {0}"
        "purge.askDays"             = "Delete from _duplicates what is how many days old or more? (Enter = {0})"
        "purge.invalidDays"         = "Enter a number of days between 1 and 3650."
        "media.nothingDeleted"      = "Nothing was deleted: if something wasn't a true orphan, you can"
        "media.nothingDeleted2"     = "move it back by hand from '_duplicates'."
        "media.previewTitle"        = "            PREVIEW"
        "media.system"              = "       System : {0}   Type : {1}"
        "media.destination"         = "       Destination : {0}"
        "media.totalFound"          = "Total orphans found : {0}"
        "media.confirmFolder"       = "Move these files to the backup folder '{0}'? (Y/N)"
        "media.cancelled"           = "Operation cancelled. Nothing was moved."
        "media.alreadyBackedUp"     = "[SKIPPED] Already in the backup: {0}"
        "media.nothingDeletedFull"  = "move it back by hand from '{0}'."

        # ---------- Hack Organizer ----------
        "hackorg.header"            = "     ORGANIZE HACKED ROMS"
        "hackorg.foundInSystem"     = "  {0}: {1} loose hacked ROM(s)"
        "hackorg.noneFound"         = "No loose hacked ROMs were found outside '# Hacks y Otros #'."
        "hackorg.previewTitle"      = "            PREVIEW"
        "hackorg.destination"       = "       Destination : {0}"
        "hackorg.totalFound"        = "Total hacked ROMs found : {0}"
        "hackorg.confirm"           = "Move these ROMs to their own '# Hacks y Otros #' folder? (Y/N)"
        "hackorg.moved"             = "[MOVED] {0}"
        "hackorg.reason"            = "Hacked ROM organized into its own folder"
        "hackorg.movedCount"        = "Moved   : {0}"
        "hackorg.skippedCount"      = "Skipped : {0}"

        # ---------- Hash deduplication inside Hacks and Others ----------
        "hackdedup.header"          = "     EXACT DUPLICATES INSIDE '# Hacks y Otros #'"
        "hackdedup.foundInSystem"   = "  {0}: {1} group(s) of identical files"
        "hackdedup.noneFound"       = "No exact duplicates were found inside '# Hacks y Otros #'."
        "hackdedup.hash"            = "{0} : {1}"
        "hackdedup.totalFound"      = "Total exact duplicates found : {0}"
        "hackdedup.confirmNote"     = "Note: these are copies with the exact same content (same {0}), only the file name differs — answering Y is safe and nothing is lost, since the moved copy still exists inside _duplicates. If you change your mind, you can put it back with menu option 2 ('Undo the last cleanup'), just like in the regular ROM cleanup."
        "hackdedup.confirmMove"     = "Move the duplicates listed above? (Y/N)"
        "hackdedup.reason"          = "Exact duplicate (same hash) inside '# Hacks y Otros #'"

        # ---------- Generic confirmations ----------
        "plan.destination"           = "Destination : {0}"
        "plan.reason"                = "Reason:"
        "plan.hash"                  = "{0} : {1}"
        "confirm.yes"                = "Y"
        "confirm.yesNoHint"          = "(Y/N)"
        "confirm.yesPattern"         = "^\s*(y|yes)\s*$"
        "confirm.autoConfirmed"      = "(non-interactive mode: automatically confirmed with Y)"
        "cli.unknownSystem"          = "Unrecognized system: '{0}'. Use the folder name exactly as it appears under RetroBat\roms (for example: snes, gba, megadrive)."
        "cli.rootNotConfigured"      = "Could not automatically determine the RetroBat path (first run, no saved configuration, and the default folder doesn't exist either). Run the program once without -Yes to configure it, or edit Config\UserSettings.json by hand."
        "cli.usageHint"              = "Usage: .\main.ps1 -Action Clean|Orphans|All|Undo|Purge [-System <folder>] [-OlderThanDays <n>] [-Yes] [-PreviewOnly]"
        "plan.htmlHint"              = "  - {0}  (visual report, open it with your browser)"
        "plan.operationCancelled"    = "Operation cancelled."
        "plan.operationCancelledDetail" = "NONE of the {0} files marked MOVE were moved — they're all exactly where they were."
    }

}

# ============================================================
# Pregunta de confirmación S/N unificada.
#
# En modo interactivo (de siempre), muestra el texto de $PromptKey
# con Read-Host y devuelve $true/$false según la respuesta.
#
# En modo no interactivo ($Global:AutoConfirm = $true, activado
# con "-Yes" al ejecutar main.ps1 para tareas programadas), no
# pregunta nada: imprime el texto igualmente (para que quede en el
# log qué se habría preguntado) y responde "sí" automáticamente.
#
# Se centraliza aquí, en vez de repetir Read-Host + comparar con
# confirm.yesPattern en cada sitio, para que todos los puntos de
# confirmación del programa (limpieza de ROMs, huérfanos,
# organizar hacks, deduplicar hacks) se beneficien del modo no
# interactivo a la vez, sin tener que tocarlos uno a uno si algún
# día cambia cómo se decide "sí"/"no".
# ============================================================

function Confirm-YesNo {

    param(
        [Parameter(Mandatory)]
        [string]$PromptKey,

        $PromptArgs = $null
    )

    $promptText = T $PromptKey $PromptArgs

    if($Global:AutoConfirm)
    {
        Write-Host $promptText
        Write-Host (T "confirm.autoConfirmed") -ForegroundColor DarkGray
        return $true
    }

    $answer = Read-Host $promptText

    return ($answer -match (T "confirm.yesPattern"))

}

function T {

    param(
        [Parameter(Mandatory)]
        [string]$Key,

        $FormatArgs = $null
    )

    $lang = "es"

    if($Global:Settings -and $Global:Settings.ContainsKey("Language") -and $Global:Settings.Language)
    {
        $lang = $Global:Settings.Language
    }

    if(-not $Global:Strings.ContainsKey($lang))
    {
        $lang = "es"
    }

    $template = $Global:Strings[$lang][$Key]

    if($null -eq $template)
    {
        # Clave no encontrada: se devuelve la propia clave para que
        # sea evidente en pantalla que falta traducir, en vez de
        # fallar silenciosamente
        return "[$Key]"
    }

    if($null -eq $FormatArgs)
    {
        return $template
    }

    return ($template -f @($FormatArgs))

}
