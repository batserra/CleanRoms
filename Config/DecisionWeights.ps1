$Global:DecisionWeights = @{

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