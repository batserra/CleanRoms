Beta CleanROMs v2.5
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
installation. Then either right-click main.ps1 and choose "Run with
PowerShell 7", or from a terminal:

    cd "C:\RetroBat\roms\CleanRoms"
    .\main.ps1

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
A full user manual (in Spanish) covering the scoring system, tie-break
rules, the title normalization/alias system, associated-file handling,
configuration reference, supported systems, and real test results is
included in the repository.


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
