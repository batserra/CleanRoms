BETA CLEANROMS
==============
Version 2.6 (BETA)

  This application is in BETA. It may still contain bugs or
  unexpected behavior.


WHAT IT DOES
------------
CleanROMs is a command-line (PowerShell) tool for detecting duplicate
ROMs inside a RetroBat installation. For each group of duplicate
copies of the same game, it automatically keeps the best one and
moves the rest to a backup folder (it never deletes anything). It can
also clean up orphaned images, videos, and manuals left behind by
ROMs that were already removed, and undo the last cleanup it ran.

Development of this program started with ChatGPT (GPT-5.5) and was
completed and debugged with Claude, Anthropic's AI assistant, through
several rounds of real-world testing on large collections (several
thousand ROMs per system, 13,600+ ROMs across 35 systems in the most
recent full test).


MAIN FEATURES
-------------
- Scores every copy of a game by region, language, dump quality
  ([!]/[b]), status (Beta/Prototype/Demo/...), version, and revision,
  and keeps the highest-scoring one.
- Hacks, fan translations, Betas, Prototypes, Demos, Homebrew,
  Pirates, Samples, Previews, and Kiosks are always excluded from
  comparison and never moved automatically.
- Recognizes region/language/version tags, underscore-style names,
  and Roman numerals so that renamed or reformatted copies of the
  same game are still grouped together.
- Optional title-alias dictionary (Config\TitleAliases.json) for
  games whose name genuinely changes between languages or editions
  (e.g. official Spanish titles).
- Moves associated files (save files, per-game controller configs)
  together with the ROM they belong to.
- Detects and organizes loose hacked ROMs into their own
  "# Hacks y Otros #" folder inside each system, and can also find
  exact byte-for-byte duplicate hacks inside that folder.
- Cleans up orphaned images/videos/manuals left behind by removed
  ROMs (ScreenScraper/RetroBat naming conventions).
- PreviewOnly simulation mode: see exactly what would happen before
  anything is touched.
- Full JSON/CSV/HTML reports and a complete session log on every run.
- Can undo the last cleanup, restoring files to their original
  location.
- Available in Spanish and English.
- Never deletes files. Ever. Everything goes to a backup folder
  (_duplicates\) that you can review or restore from at any time.


REQUIREMENTS
------------
- PowerShell 7.3 or later. Windows PowerShell 5.1 (the one that ships
  with Windows by default) is NOT enough.
  https://github.com/PowerShell/PowerShell/releases
- Optional: 7-Zip, if you want region/language detection to look
  inside .7z archives too.


INSTALLATION
------------
1. Copy the entire "CleanRoms" folder inside the "roms" folder of
   your RetroBat installation.
2. Right-click main.ps1 and choose "Run with PowerShell 7", or from a
   terminal:

     cd "C:\RetroBat\roms\CleanRoms"
     .\main.ps1

If you already had a previous version installed, delete the whole
CleanRoms folder before extracting the new one -- some unzip tools
don't overwrite existing files by default (in particular
Config\TitleAliases.json), and you could end up with a mix of
versions.

The first time you run it, it will ask for your RetroBat "roms" path
and your preferred language, and will remember both from then on
(Config\UserSettings.json).


QUICK USAGE
-----------
On startup you get a simple menu:

  1) Clean up duplicate ROMs
  2) Undo the last cleanup
  3) Clean up orphaned images/videos/manuals
  4) ALL: Move ROMs and images/videos/manuals for every system

Nothing is ever moved without you reviewing the full plan first and
confirming with "Y". Turn on PreviewOnly in Config\Settings.ps1 the
first time you try it on a new collection to see the plan without
touching any file.


CONFIGURATION
-------------
Almost everything is controlled from plain text/JSON files inside
Config\, no code changes needed:

  Config\Settings.ps1         General behavior (PreviewOnly,
                               MoveAssets, supported systems and
                               extensions, ignored folders...)
  Config\DecisionWeights.ps1  The scoring tables (region, language,
                               dump quality, version, revision...)
  Config\TitleAliases.json    Manual title aliases for games whose
                               name genuinely changes between
                               languages/editions
  Config\UserSettings.json    Your RetroBat path and chosen language


WHAT'S NEW IN 2.6
------------------
- ROM version and revision (V1.1, Rev A...) are now actually
  detected from the file name and feed into the scoring system --
  previously this scoring table existed but had no real effect.
- "[BIOS]" and similar tags are no longer mistaken for a bad dump
  ([b]) and incorrectly penalized.
- Duplicate hacks found inside "# Hacks y Otros #" now move to the
  correct system's duplicates folder instead of occasionally creating
  a stray "_duplicates\# Hacks y Otros #\" folder.
- The confirmation prompt for moving duplicate hacks now explains
  that these are byte-identical files and that this particular step
  cannot be undone with the "Undo the last cleanup" menu option.

See the full user manual for details on every feature and on the
exact scoring/tie-break rules.


REPORTING ISSUES
-----------------
This program is still being tested. If you find a bug or want a
feature added or removed, please email as much detail as you can
(what you did, what you expected, what happened instead) to:

  batserra@gmail.com

Repository: https://github.com/batserra/CleanRoms2

If the issue involves ROMs not grouping as expected, or files
disappearing without explanation, please attach the session log
(Logs\CleanROMs_<date>.log) and, if possible, a file listing of the
affected folder (e.g. dir /s /b > listing.txt).


LICENSE / STATUS
-----------------
This is a BETA. Use at your own risk on collections you care about --
though by design the program never deletes anything, only moves
files to a backup folder you can review and restore from.
