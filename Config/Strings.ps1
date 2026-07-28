# ============================================================
# Beta CleanROMs v2.5
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
        "banner.title"              = "BETA CLEAN ROMS v2.5"
        "menu.whatToDo"             = "¿Qué quieres hacer?"
        "menu.option1"              = " 1) Limpiar ROMs duplicadas"
        "menu.option2"              = " 2) Deshacer la última limpieza"
        "menu.option3"              = " 3) Limpiar imágenes/vídeos/manuales huérfanos"
        "menu.option4"              = " 4) TODO: Mover ROMs e imágenes/vídeos/manuales de TODOS los sistemas"
        "menu.option5"              = " 5) Salir"
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
        "exec.assetMoveFailed"      = "No se pudo mover el archivo asociado: {0}"
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
        "undo.noPlanFound"          = "No se encontró ningún plan anterior en {0}."
        "undo.nothingToUndo"        = "No hay nada que deshacer (la última vez no se movió nada de verdad, o ya se deshizo)."
        "undo.restored"             = "[RESTAURADO] {0}"
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

        # ---------- Confirmaciones genéricas ----------
        "plan.destination"           = "Destino : {0}"
        "plan.reason"                = "Motivo:"
        "confirm.yes"                = "S"
        "confirm.yesNoHint"          = "(S/N)"
        "confirm.yesPattern"         = "^[Ss]$"
        "plan.htmlHint"              = "  - {0}  (informe visual, ábrelo con el navegador)"
        "plan.operationCancelled"    = "Operación cancelada."
    }

    en = @{

        # ---------- Menu / banner ----------
        "banner.title"              = "BETA CLEAN ROMS v2.5"
        "menu.whatToDo"             = "What do you want to do?"
        "menu.option1"              = " 1) Clean up duplicate ROMs"
        "menu.option2"              = " 2) Undo the last cleanup"
        "menu.option3"              = " 3) Clean up orphaned images/videos/manuals"
        "menu.option4"              = " 4) ALL: Move ROMs and images/videos/manuals for EVERY system"
        "menu.option5"              = " 5) Exit"
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
        "exec.assetMoveFailed"      = "Could not move the associated file: {0}"
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
        "undo.noPlanFound"          = "No previous plan was found in {0}."
        "undo.nothingToUndo"        = "There is nothing to undo (last time nothing was actually moved, or it was already undone)."
        "undo.restored"             = "[RESTORED] {0}"
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

        # ---------- Generic confirmations ----------
        "plan.destination"           = "Destination : {0}"
        "plan.reason"                = "Reason:"
        "confirm.yes"                = "Y"
        "confirm.yesNoHint"          = "(Y/N)"
        "confirm.yesPattern"         = "^[Yy]$"
        "plan.htmlHint"              = "  - {0}  (visual report, open it with your browser)"
        "plan.operationCancelled"    = "Operation cancelled."
    }

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
