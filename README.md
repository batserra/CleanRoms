================================================================================
                                CleanROMs v2.5 (BETA)
================================================================================
A powerful PowerShell 7 command-line tool designed for RetroBat installations 
to automatically detect duplicate ROMs, preserve the optimal copy of each game, 
back up the rest safely, and clean up orphaned media files (images, videos, 
and manuals).

*** Note: This application is currently in BETA. It may contain bugs or 
unpredicted behaviors. Always review your cleaning plans before execution. ***

--------------------------------------------------------------------------------
TABLE OF CONTENTS
--------------------------------------------------------------------------------
1. Project Overview & Features
2. Core Engine: The Scoring System
3. Tie-Breaking Mechanics
4. Exclusions (What is Never Moved)
5. How Title Matching Works (Normalization & Aliases)
6. Handling Associated Assets & Orphaned Media
7. Requirements & Installation
8. Configuration Guide
9. How to Use & Menu Options
10. Simulation Mode (PreviewOnly)
11. Generated Reports & Logs
12. Undoing a Clean Operation
13. Supported Systems & Extensions
14. Bug Reporting & Feedback

--------------------------------------------------------------------------------
1. PROJECT OVERVIEW & FEATURES
--------------------------------------------------------------------------------
CleanROMs automates the tedious process of auditing large ROM collections across 
multiple systems in RetroBat. Instead of deleting duplicates, it acts conservatively 
by moving redundant copies to a dedicated backup directory.

Key Features:
- Intelligent Grouping: Identifies duplicate copies of the same game even if filenames 
  differ across regions, formats, or versions.
- Advanced Scoring Engine: Evaluates ROMs dynamically based on custom weights 
  (Region, Language, Dump Quality, Game State, Version/Revision).
- Asset Syncing: Automatically moves save files (.sav, .srm, etc.) and controller 
  configurations alongside their corresponding moved ROMs.
- Orphaned Media Cleaner: Scans media folders to find and isolate images, videos, 
  and manuals left behind from previously deleted or moved ROMs.
- Non-Destructive Safe Backups: Files are NEVER permanently deleted; they are relocated 
  to a `_duplicates\` subdirectory, ensuring zero data loss.
- High Compatibility: Robust support for over 60 emulation systems and 110+ file 
  extensions, completely safe against special characters like brackets `[]`.

--------------------------------------------------------------------------------
2. CORE ENGINE: THE SCORING SYSTEM
--------------------------------------------------------------------------------
Each copy within a duplicate group is assigned a total score. The copy with the 
highest score is marked as "KEEP", while the others are marked as "MOVE". 
Weights are fully customizable in `Config\DecisionWeights.ps1`.

Default Weight Allocations:

REGION SCORES (Highest priority)
- Spain (ESP):          1000 pts
- Europe (EUR):         700 pts
- USA:                  400 pts
- Japan (JPN):          200 pts
- World:                100 pts
- Unknown:              0 pts

LANGUAGE SCORES
- Spanish (Standalone): 500 pts
- Multi-Language (includes Spanish): 350 pts
- Multi-Language (excludes Spanish): 200 pts
- English:              100 pts
- Japanese / Unknown:   0 pts

DUMP QUALITY
- Verified Good Dump [!]: +200 pts
- Bad Dump [b]:           -500 pts

GAME STATE PENALTIES
- Beta:                 -150 pts
- Prototype:            -300 pts
- Demo:                 -300 pts
- Sample:               -300 pts
- Preview:              -300 pts
- Kiosk:                -300 pts

VERSION & REVISION (Fine-tuning ties)
- v1.0 / Rev 0:         100 pts / 0 pts
- v1.1 / Rev 1:         110 pts / 10 pts
- v1.2 / Rev 2:         120 pts / 20 pts
- v1.3 / Rev 3:         130 pts / 30 pts
- v1.4 / Rev 4:         140 pts / 40 pts
- No Version/Revision specified: 0 pts

--------------------------------------------------------------------------------
3. TIE-BREAKING MECHANICS
--------------------------------------------------------------------------------
If two or more ROMs share the exact same total score, the engine processes them 
through the following tie-breaking matrix sequentially:
1. Total Score comparison.
2. Verified dump `[!]` vs Unverified.
3. Bad dump `[b]` status (clean files win).
4. Hack tags (Non-hacks win).
5. Prototype tags (Final games win).
6. Beta tags (Final games win).
7. Demo tags (Final games win).
8. Compression: Uncompressed files (.sfc, .gba) win over compressed (.zip, .7z).
9. Filename Length: Shorter titles win.
10. Alphabetical Order: Earliest alphabetical character wins.
11. Absolute Tie: If identically matched, the program stops and prompts the user 
    interactively to choose which path to preserve.

--------------------------------------------------------------------------------
4. EXCLUSIONS (WHAT IS NEVER MOVED)
--------------------------------------------------------------------------------
The program explicitly isolates 9 specific categories of ROMs. They are completely 
excluded from the deduplication process, never compared against retail copies, 
and never moved or renamed automatically:
- Hacks (Detected via "Hack" in the filename, `[h1]` style tags, or `# Hacks #` folder)
- Fan Translations (Detected via "Traducción", "Translation", `[T+Spa]`, etc.)
- Betas ("Beta" in filename)
- Prototypes ("Proto" or "Prototype" in filename)
- Demos ("Demo" in filename)
- Homebrews ("Homebrew" in filename)
- Pirates ("Pirate" in filename)
- Samples ("Sample" in filename)
- Previews / Kiosks ("Preview" or "Kiosk" in filename)

These are kept separate because they represent unique content distinct from final 
retail builds that collectors typically wish to preserve independently.

--------------------------------------------------------------------------------
5. HOW TITLE MATCHING WORKS (NORMALIZATION & ALIASES)
--------------------------------------------------------------------------------
To accurately group duplicates, CleanROMs converts every filename into a lowercase 
"normalized title" using rules defined in `Modules\Title Normalizer.ps1`:
1. Strips catalog numbering prefixes (e.g., `0263 - `).
2. Strips date/time tool suffixes (e.g., `_20260709_034928`).
3. Handles underscore-spaced sets natively (e.g., `Kirby_s_Fun_Pak` -> `Kirbys Fun Pak`).
4. Erases ALL contents within parentheses `()` and square brackets `[]`.
5. Strips stray region/language keywords outside brackets.
6. Strips detached version markers safely (e.g., avoiding words like "Revolver").
7. Converts Roman numerals to digits (e.g., `IV` -> `4`).
8. Removes common articles (e.g., `the`, `a`, `an`, `el`, `la`, `los`).
9. Normalizes punctuation, punctuation tokens (`&`, `+`, `and`, `y`), and extra spaces.

Manual Title Aliases:
When a game title is completely different across regions (e.g., `Narnia - El león, 
la bruja y el armario` vs `The Chronicles of Narnia: The Lion, the Witch and the 
Wardrobe`), you can manually map them together using `Config\TitleAliases.json`.
Format:
{
  "variant normalized name": "canonical normalized name"
}

--------------------------------------------------------------------------------
6. HANDLING ASSOCIATED ASSETS & ORPHANED MEDIA
--------------------------------------------------------------------------------
Associated Assets:
If a ROM is selected to be moved, files sharing its base name (Simple Match, e.g., 
`Game.sav`) or full filename string (Composite Match, e.g., `Game(Europe).dsk.p2k.cfg`) 
are moved to `_duplicates\` concurrently. This prevents leaving save states or 
custom pad layouts orphaned. Controlled via `MoveAssets` in settings.

Orphaned Media Cleaner:
Scans the `images\`, `videos\`, and `manuals\` folders inside each system for media 
files belonging to deleted or moved ROMs. It matches files by automatically removing 
known media suffixes appended by scrapers like ScreenScraper.
Supported media suffixes:
`-image`, `-video`, `marquee`, `thumb`, `wheel`, `manual`, `boxfront`, `-boxback`, 
`-box2dfront`, `-box2dback`, `box3d`, `fanart`, `title`, `-screenshot`, 
`-screenshottitle`, `-cartridge`, `-support`, `-mix`, `bezel`, `-map`.

--------------------------------------------------------------------------------
7. REQUIREMENTS & INSTALLATION
--------------------------------------------------------------------------------
Requirements:
- PowerShell 7.3 or higher (Windows default PowerShell 5.1 is NOT compatible).
  Download: https://github.com/PowerShell/PowerShell/releases
- 7-Zip (Optional): If installed, the tool can inspect inside `.7z` archives to read 
  internal filenames for accurate region/language extraction.

Installation Steps:
1. Delete any existing older version of the `CleanRoms` folder entirely from your disk 
   to avoid file configuration conflicts.
2. Extract the complete `CleanRoms` directory into the `roms\` folder of your RetroBat 
   installation (e.g., `C:\RetroBat\roms\CleanRoms`).
3. Right-click `main.ps1` and select "Run with PowerShell 7", or execute via terminal:
   cd "C:\RetroBat\roms\CleanRoms"
   .\main.ps1

--------------------------------------------------------------------------------
8. CONFIGURATION GUIDE
--------------------------------------------------------------------------------
The utility is highly modular and customizable through the files located in `Config\`:
- UserSettings.json: Caches your RetroBat `roms` directory path. Prompted on first launch.
- Settings.ps1: Houses core environment variables, including:
  * `PreviewOnly`: Set to `$true` to simulate execution without modifying disk files.
  * `MoveAssets`: Toggles moving associated files (`$true`/`$false`).
  * `RemoveDuplicates`: Set to `$false` by default to force moving instead of deletion.
  * `$Global:RomExtensions`: Array of 110+ tracked ROM file extensions.
  * `$Global:IgnoredFolders`: Directories omitted from scanning (`images`, `_duplicates`, etc.).
  * `$Global:SystemPaths`: List of 60+ mapped system folder names.
- DecisionWeights.ps1: Hosts the numerical point tables detailing scoring rules.
- TitleAliases.json: Contains your mapping dictionaries for region-swapped names.

--------------------------------------------------------------------------------
9. HOW TO USE & MENU OPTIONS
--------------------------------------------------------------------------------
Upon running `main.ps1`, you will face an interactive main menu offering 4 pathways:

1) Clean duplicate ROMs: Processes a selected system directory (or all). Scans, groups, 
   calculates scores, prints the evaluation breakdown, exports files, and prompts 
   for execution confirmation ("S" to approve, "N" to cancel).
2) Undo the last cleaning operation: Restores moved assets safely (see Section 12).
3) Clean orphaned images/videos/manuals: Performs media sweep exclusively.
4) ALL: Move ROMs and images/videos/manuals for ALL systems: Chained sequential run 
   of choices (1) and (3) across all detected system targets seamlessly.

--------------------------------------------------------------------------------
10. SIMULATION MODE (PREVIEWONLY)
--------------------------------------------------------------------------------
Before making changes to a newly added library, you can toggle simulation mode 
within `Config\Settings.ps1`:
PreviewOnly = $true

When active, confirming operations with "S" will only print simulation indicators 
(`[PREVIEW MOVE]`) in the console window. The tool evaluates the active libraries 
and exports structural logs normally without writing or moving any data on disk.

--------------------------------------------------------------------------------
11. GENERATED REPORTS & LOGS
--------------------------------------------------------------------------------
Every deduplication sweep generates analytical data saved under `Resultado\`:
- CleanPlan.json: Complete, structured structural map used by the recovery engine.
- CleanPlan.csv: Summarized ledger matrix ready to open in spreadsheet editors like Excel.
- CleanPlan.html: Visual analytical dashboard complete with dynamic styling, counts, 
  and coloring for quick browser reviews.

Full Session Logging:
Every console interaction, menu decision, file action, and confirmation is written 
directly to `Logs\CleanROMs_<date>.log` for troubleshooting historical runs.

--------------------------------------------------------------------------------
12. UNDOING A CLEAN OPERATION
--------------------------------------------------------------------------------
Selecting Option 2 from the main menu invokes a safe rollback system using the most 
recent execution file (`Resultado\CleanPlan.json`):
- The script checks if target files genuinely reside inside `_duplicates\` before 
  attempting movement.
- If an asset's original location has since been occupied by another file, the tool 
  aborts that individual recovery step to prevent overwriting active files.
- Provides a summary detailing: Files restored, Unmodified items, and Omitted conflicts.
* Note: Only the immediate last finalized cleaning layout is stored for undoing.

--------------------------------------------------------------------------------
13. SUPPORTED SYSTEMS & EXTENSIONS
--------------------------------------------------------------------------------
Tracks 60+ emulation ecosystems (Nintendo, Sega, Sony, Arcade cabinets, Retro 
Home Computers) across 110+ extensions. 
Examples include:
- Nintendo: NES, SNES, N64, GameCube, Wii, Game Boy Series, NDS.
- Sega: Master System, Mega Drive/Genesis, Game Gear, Saturn, Dreamcast.
- Sony: PlayStation, PlayStation 2, PSP, PS Vita (.vpk).
- Arcade: MAME, FinalBurn Neo, Neo Geo, CPS1/2/3 platforms.
- Computers: Amstrad CPC, ZX Spectrum, MSX, Commodore 64, X68000.

* Arcade Note: Multi-core arcade distributions are processed independently per system 
  directory. Duplicate checking does not cross-reference between individual arcade folders 
  (e.g., MAME vs Neo Geo) to preserve specific core launch configurations in RetroBat.
* Folder Formats: Games stored natively as structural directories (e.g., PS3 structures, 
  PC DOS folders) are currently out of bounds; the engine tracks file extensions only.

--------------------------------------------------------------------------------
14. BUG REPORTING & FEEDBACK
--------------------------------------------------------------------------------
CleanROMs is an evolving community tool built originally using ChatGPT (GPT-5.5) 
and refined through extensive live environment testing using Anthropic's Claude 
across large scale libraries (13,600+ ROM datasets).

If you encounter processing failures, unrecognized structures, or wish to suggest 
features, reach out with deep details (actions taken, expectations, logs) to:
Email: batserra@gmail.com

To facilitate fast bug resolution regarding missed duplicates or scanning errors, 
please attach:
1. The corresponding session log file (`Logs\CleanROMs_<date>.log`).
2. A full text directory listing of the target folder (generated via command: 
   `dir /s /b > file_list.txt`).
================================================================================
