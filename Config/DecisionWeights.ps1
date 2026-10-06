#
# Región e idioma tienen DOS tablas distintas: una para cuando se
# da prioridad al español, y otra para cuando se da prioridad al
# inglés. Cuál de las dos está activa depende del ajuste
# "Idioma de prioridad de ROMs" (sección 19 del manual, opción 5
# del menú) — $Global:Settings.RomPriorityLanguage ("es" o "en").
#
# El resto de tablas (calidad de dump, estado, hacks, versión,
# revisión) son las mismas siempre, no dependen de este ajuste.
#

#==============================================================
# Prioridad ROMs en ESPAÑOL (valor por defecto)
#==============================================================

$Global:DecisionWeights_ES = @{

    #==========================================================
    # REGIÓN
    #==========================================================

    Region_ESP       = 1000
    Region_EUR       = 700
    Region_USA       = 400
    Region_JPN       = 200
    Region_WORLD     = 100
    Region_UNK       = 0

    #==========================================================
    # IDIOMA
    #==========================================================

    Language_Spanish       = 500
    Language_MultiSpanish  = 350
    Language_Multi         = 200
    Language_English       = 100
    Language_Japanese      = 0
    Language_Unknown       = 0

    #==========================================================
    # CALIDAD DEL DUMP
    #==========================================================

    Verified   = 200
    BadDump    = -500

    #==========================================================
    # ESTADO
    #==========================================================

    Beta        = -150
    Prototype   = -300
    Demo        = -300
    Sample      = -300
    Preview     = -300
    Kiosk       = -300

    #==========================================================
    # HACKS
    #==========================================================

    Hack        = -400
    Homebrew    = -400
    Pirate      = -500

    #==========================================================
    # VERSION
    #
    # Estas claves si se usan de verdad (Get-VersionScore, en
    # DecisionEngine.ps1, las busca por nombre exacto antes de
    # calcular nada). Si una ROM trae una version que no esta
    # aqui listada (p.ej. "1.4"), se calcula sola con la misma
    # escala (version x 100) en vez de fallar o dar 0.
    #==========================================================

    Version_1_0 = 100
    Version_1_1 = 110
    Version_1_2 = 120
    Version_1_3 = 130
    Version_Unknown = 0

    #==========================================================
    # REVISION
    #
    # Igual que con Version: se buscan por nombre exacto antes de
    # calcular nada, asi que se pueden editar libremente. Una
    # revision no listada (p.ej. Rev 5) se calcula sola (revision
    # x 10).
    #==========================================================

    Revision_0 = 0
    Revision_1 = 10
    Revision_2 = 20
    Revision_3 = 30
    Revision_4 = 40
    Revision_Unknown = 0

}

#==============================================================
# Prioridad ROMs en INGLÉS
#
# Misma tabla que arriba, con región e idioma invertidos:
# Estados Unidos pasa a ocupar el primer puesto que antes tenía
# España, e Inglés el que antes tenía Español — el resto de
# posiciones (Europa, Japón, Mundial; Multi, Multi-Español) se
# desplazan en el mismo orden relativo que ya tenían. El resto de
# tablas (calidad de dump, estado, hacks, versión, revisión) es
# exactamente igual que en la tabla de prioridad español, porque
# esos criterios no dependen del idioma.
#==============================================================

$Global:DecisionWeights_EN = @{

    #==========================================================
    # REGIÓN
    #==========================================================

    Region_USA       = 1000
    Region_EUR       = 700
    Region_ESP       = 400
    Region_JPN       = 200
    Region_WORLD     = 100
    Region_UNK       = 0

    #==========================================================
    # IDIOMA
    #==========================================================

    Language_English       = 500
    Language_Multi         = 350
    Language_MultiSpanish  = 200
    Language_Spanish       = 100
    Language_Japanese      = 0
    Language_Unknown       = 0

    #==========================================================
    # CALIDAD DEL DUMP
    #==========================================================

    Verified   = 200
    BadDump    = -500

    #==========================================================
    # ESTADO
    #==========================================================

    Beta        = -150
    Prototype   = -300
    Demo        = -300
    Sample      = -300
    Preview     = -300
    Kiosk       = -300

    #==========================================================
    # HACKS
    #==========================================================

    Hack        = -400
    Homebrew    = -400
    Pirate      = -500

    #==========================================================
    # VERSION
    #==========================================================

    Version_1_0 = 100
    Version_1_1 = 110
    Version_1_2 = 120
    Version_1_3 = 130
    Version_Unknown = 0

    #==========================================================
    # REVISION
    #==========================================================

    Revision_0 = 0
    Revision_1 = 10
    Revision_2 = 20
    Revision_3 = 30
    Revision_4 = 40
    Revision_Unknown = 0

}

#==============================================================
# Tabla activa
#
# Por compatibilidad con el resto del programa (que siempre lee
# $Global:DecisionWeights directamente), aquí se deja ya asignada
# una por defecto -- Set-ActiveDecisionWeights (Settings.ps1) la
# vuelve a asignar en cuanto se sabe qué prioridad tiene guardada
# el usuario, tanto en el primer arranque como en los siguientes.
#==============================================================

$Global:DecisionWeights = $Global:DecisionWeights_ES
