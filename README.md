**Languages:** [English](README.md) | [Español](README.es.md)

Beta CleanROMs v2.6
===================

A PowerShell command-line tool that finds duplicate ROMs inside a RetroBat
installation, automatically keeps the best copy of each game, and moves the
rest to a backup folder (it never deletes anything). It can also clean up
orphaned images, videos, and manuals left behind by removed ROMs.

STATUS: BETA. This is being actively tested and may still contain bugs or
unexpected behavior. See "Reporting issues" below.


What it does
------------
For each system folder you choose:

1. Scans it for files with a recognized ROM extension (110+ extensions,
   60+ systems supported: Nintendo, Sega, Sony, arcade, home computers...).
2. Parses each file name (and, for .zip/.7z archives containing a single
   ROM, the inner file name too) to extract region, language, version,
   revision, and special flags (Hack, Beta, Prototype, Demo, Homebrew,
   Pirate, Sample, Preview, Kiosk).
3. Normalizes the title and groups copies that are the same game, ignoring
   those tags -- with a manual alias file for the cases where the name
   genuinely changes between regions (e.g. an official Spanish translation
   with a different title).
4. Scores every copy in a group (region, language, dump quality, version...)
   and picks the best one.
5. Shows you the full plan -- what's kept, what's moved, and why -- before
   touching anything.
6. Only on confirmation, moves the non-winning copies to _duplicates\,
   along with any associated file they had (save file, controller config...).

ROMs tagged as Hack, Fan Translation, Beta, Prototype, Demo, Homebrew,
Pirate, Sample, Preview, or Kiosk are never compared, moved, or touched --
they're treated as genuinely different content worth keeping, not
duplicates of the retail release.


Requirements
------------
- PowerShell 7.3 or later (Windows PowerShell 5.1, which ships with
  Windows by default, is NOT supported):
  https://github.com/PowerShell/PowerShell/releases
- Optional: 7-Zip, to inspect the contents of .7z archives when region/
  language tags are only present on the inner file name. Auto-detected;
  not required.


Installation
------------
Copy the whole "CleanRoms" folder inside the "roms" folder of your RetroBat
installation. Then double-click "Run CleanROMs.bat".

That launcher unblocks every file in the folder and starts main.ps1 for
you, avoiding a common first-run error where Windows refuses to run
main.ps1 directly with "File ... is not digitally signed. You cannot run
this script on the current system." -- that happens because Windows marks
files from a downloaded/unzipped folder as blocked, and PowerShell's
default policy then requires a signature to run them.

If you'd rather run main.ps1 directly (e.g. right-click it and choose "Run
with PowerShell 7", or from a terminal with `.\main.ps1`) and you hit that
error, just unblock the folder once and it won't happen again:

    Get-ChildItem -Path "C:\RetroBat\roms\CleanRoms" -Recurse | Unblock-File

On first run it will ask you to pick a language (Spanish/English) and the
path to your RetroBat "roms" folder -- both are saved in
Config\UserSettings.json so you won't be asked again.

IMPORTANT: if you're updating from a previous version, delete the old
CleanRoms folder completely before extracting the new one. Some unzip
tools don't overwrite existing files by default, which can leave you with
a mix of old and new files (in particular Config\TitleAliases.json).


The main menu
-------------
    1) Clean up duplicate ROMs
    2) Undo the last cleanup
    3) Clean up orphaned images/videos/manuals
    4) ALL: Move ROMs and images/videos/manuals for every system

Every action shows a full preview and asks for confirmation before moving
or deleting anything. Nothing is ever permanently deleted -- files are
moved to a _duplicates\ backup folder, and option 2 can put them back.

A PreviewOnly setting (Config\Settings.ps1) lets you run everything as a
dry run, useful the first time you try it on a new collection.


Configuration
-------------
Everything lives under Config\, plain text, editable with any text editor:

- UserSettings.json   Your RetroBat path and chosen language.
- Settings.ps1        Recognized systems and extensions, ignored folders,
                       recognized media suffixes, and behavior flags
                       (PreviewOnly, MoveAssets, RemoveDuplicates...).
- DecisionWeights.ps1  The full scoring tables (region, language, dump
                       quality, version, revision) -- freely adjustable.
- TitleAliases.json    Manual mappings for titles that genuinely change
                       between editions/languages and can't be resolved
                       by stripping tags alone (see the full manual).


Reports and logs
-----------------
Every run exports, in Resultado\:
- CleanPlan.json  Full plan detail (also used by "Undo").
- CleanPlan.csv   Summary for Excel.
- CleanPlan.html  Visual report with stats and a color-coded table.

Every full session is also logged to Logs\CleanROMs_<date>.log.


Documentation
-------------
Full user manuals, in both English (CleanROMs_Manual_EN.pdf) and Spanish
(CleanROMs_Manual_ES.pdf), covering the scoring system, tie-break rules,
the title normalization/alias system, associated-file handling,
configuration reference, supported systems, and real test results are
included in the repository.


What's new in 2.6
------------------
- ROM version and revision (V1.1, Rev A...) are now actually detected
  from the file name and feed into the scoring system -- previously this
  scoring table existed but had no real effect.
- "[BIOS]" and similar tags are no longer mistaken for a bad dump ([b])
  and incorrectly penalized.
- Duplicate hacks found inside "# Hacks y Otros #" now move to the
  correct system's duplicates folder instead of occasionally creating a
  stray "_duplicates\# Hacks y Otros #\" folder.
- The confirmation prompt for moving duplicate hacks now explains that
  these are byte-identical files and that this particular step cannot be
  undone with the "Undo the last cleanup" menu option.
- Added "Run CleanROMs.bat", a launcher that unblocks the folder and
  starts the program so first-time users don't hit the "not digitally
  signed" PowerShell error.
- "Undo the last cleanup" can now undo more than just the very last run:
  every completed session is archived to Resultado\History\, and the
  menu lets you pick an older one (keeps the last 10 by default, see
  UndoHistoryLimit in Config\Settings.ps1). It also now restores
  associated files (save files, controller configs) moved along with a
  ROM, not just the ROM itself.
- New command-line parameters on main.ps1 for scheduled/unattended runs
  (Windows Task Scheduler and similar): -Action Clean|Orphans|All|Undo,
  -System <folder>, -Yes (auto-confirm every prompt), -PreviewOnly. See
  "Command-line / scheduled use" below. Running main.ps1 with no
  parameters works exactly as before.
- Hashing (used to find duplicates, verify moves, and dedupe exact
  copies inside "# Hacks y Otros #") now runs in parallel on large
  batches instead of one file at a time, using PowerShell 7's
  ForEach-Object -Parallel. Controlled by HashParallelThreshold and
  HashParallelism in Config\Settings.ps1 (defaults: don't bother below
  20 files, 4 at a time above that). Lower HashParallelism to 1 if
  you're on a slow HDD and notice things got slower instead of faster.

See the full user manual for details on every feature and the exact
scoring/tie-break rules.


Command-line / scheduled use
------------------------------
For unattended runs (Task Scheduler, cron under WSL, etc.), main.ps1
accepts:

    -Action Clean|Orphans|All|Undo   What to do (skips the menu entirely)
    -System <folder>                 Which system's folder (e.g. "snes",
                                      "gba"); omit or use "ALL" for every
                                      configured system. Ignored by -Action
                                      Undo.
    -Yes                             Auto-confirm every Y/N prompt instead
                                      of waiting for input.
    -PreviewOnly                     Force simulation mode for this run
                                      only, without editing Settings.ps1.

Examples:

    pwsh -File main.ps1 -Action Clean -System snes -Yes
    pwsh -File main.ps1 -Action All -Yes
    pwsh -File main.ps1 -Action Undo -Yes

Without -Action, main.ps1 behaves exactly as it always has (interactive
menu). Without -Yes, -Action still skips the menu but still asks for
confirmation at each step, same as usual -- -Yes is what actually makes
a run unattended.


Reporting issues
-----------------
This is a BETA. If you hit a bug or want a feature added or removed,
please email as much detail as you can (what you did, what you expected,
what happened instead) to:

    batserra@gmail.com

If the issue involves ROMs not grouping as expected, or files disappearing
without explanation, please attach the log file from that run
(Logs\CleanROMs_<date>.log) and, if possible, a full file listing of the
affected folder (e.g. `dir /s /b > listing.txt` from that system's folder).


Credits
-------
Development started with ChatGPT (GPT-5.5) and was completed and debugged
with Claude, Anthropic's AI assistant, through several rounds of testing on
real collections (tens of thousands of ROMs across 35+ systems).


Repository
----------
https://github.com/batserra/CleanRoms
