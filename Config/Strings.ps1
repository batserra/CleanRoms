# ============================================================
# Beta CleanROMs v2.6
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
        "banner.title"              = "BETA CLEAN ROMS v2.6"
        "menu.whatToDo"             = "¿Qué quieres hacer?"
        "menu.option1"              = " 1) Limpiar ROMs duplicadas"
        "menu.option2"              = " 2) Deshacer la última limpieza"
        "menu.option3"              = " 3) Limpiar imágenes/vídeos/manuales huérfanos"
        "menu.option4"              = " 4) TODO: Mover ROMs e imágenes/vídeos/manuales de TODOS los sistemas"
        "menu.option5"              = " 5) Configuración (ruta de RetroBat / idioma)"
        "menu.option6"              = " 6) Salir"
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
        "config.menuPath"           = "Ruta de RetroBat actual : {0}"
        "config.menuLanguage"       = "Idioma actual           : {0}"
        "config.opt1"               = " 1) Cambiar la ruta de RetroBat"
        "config.opt2"               = " 2) Cambiar el idioma"
        "config.opt3"               = " 3) Cambiar ambas cosas"
        "config.opt0"               = " 0) Volver al menú principal"

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
        "tie.title"                 = "   EMPATE: no se puede decidir en automático"
        "tie.explanation"           = "Estas dos copias tienen la misma puntuación ({0}) y ningún criterio las diferencia:"
        "tie.ask"                   = "¿Cuál quieres conservar? (1/2)"
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
        "hackdedup.confirmNote"     = "Nota: son copias con el mismo contenido exacto (mismo {0}), solo cambia el nombre del archivo — responder S es seguro y no se pierde nada, ya que la copia movida sigue existiendo dentro de _duplicates y se puede recuperar a mano si algún día la necesitas. Eso sí: a diferencia de la limpieza normal de ROMs, este paso concreto NO se puede deshacer con la opción 2 del menú ('Deshacer la última limpieza')."
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
        "cli.usageHint"              = "Uso: .\main.ps1 -Action Clean|Orphans|All|Undo [-System <carpeta>] [-Yes] [-PreviewOnly]"
        "plan.htmlHint"              = "  - {0}  (informe visual, ábrelo con el navegador)"
        "plan.operationCancelled"    = "Operación cancelada."
        "plan.operationCancelledDetail" = "No se ha movido NINGUNO de los {0} archivos indicados como MOVE — siguen exactamente donde estaban."
    }

    en = @{

        # ---------- Menu / banner ----------
        "banner.title"              = "BETA CLEAN ROMS v2.6"
        "menu.whatToDo"             = "What do you want to do?"
        "menu.option1"              = " 1) Clean up duplicate ROMs"
        "menu.option2"              = " 2) Undo the last cleanup"
        "menu.option3"              = " 3) Clean up orphaned images/videos/manuals"
        "menu.option4"              = " 4) ALL: Move ROMs and images/videos/manuals for EVERY system"
        "menu.option5"              = " 5) Configuration (RetroBat path / language)"
        "menu.option6"              = " 6) Exit"
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
        "config.menuPath"           = "Current RetroBat path : {0}"
        "config.menuLanguage"       = "Current language      : {0}"
        "config.opt1"               = " 1) Change the RetroBat path"
        "config.opt2"               = " 2) Change the language"
        "config.opt3"               = " 3) Change both"
        "config.opt0"               = " 0) Back to the main menu"

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
        "tie.title"                 = "   TIE: cannot decide automatically"
        "tie.explanation"           = "These two copies have the same score ({0}) and no criterion tells them apart:"
        "tie.ask"                   = "Which one do you want to keep? (1/2)"
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
        "hackdedup.confirmNote"     = "Note: these are copies with the exact same content (same {0}), only the file name differs — answering Y is safe and nothing is lost, since the moved copy still exists inside _duplicates and can be manually recovered if you ever need it. That said, unlike the regular ROM cleanup, this particular step CANNOT be undone with menu option 2 ('Undo the last cleanup')."
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
        "cli.usageHint"              = "Usage: .\main.ps1 -Action Clean|Orphans|All|Undo [-System <folder>] [-Yes] [-PreviewOnly]"
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
