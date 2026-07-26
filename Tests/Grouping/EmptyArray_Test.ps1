# ============================================================
# Array vacío
# Agrupar una lista sin ninguna ROM no debe lanzar error
# ============================================================

$groups = @(Group-Roms @())

Assert-Equal `
    0 `
    $groups.Count `
    "Group-Roms con array vacío: no lanza error y devuelve 0 grupos"
