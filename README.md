CleanROMs v2.8
==============

A PowerShell command-line tool that finds duplicate ROMs inside a RetroBat
installation, automatically keeps the best copy of each game, and moves the
rest to a backup folder (it never deletes anything on its own; only an
optional purge that you start yourself removes old copies, and it asks
first). It can also clean up orphaned images, videos, and manuals left
behind by removed ROMs.


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
    5) Configuration (RetroBat path / language)
    6) Purge _duplicates (DELETE old copies)
    7) Exit

Every action shows a full preview and asks for confirmation before moving
or deleting anything. Options 1-4 never delete anything -- files are
moved to a _duplicates\ backup folder, and option 2 can put them back.
The only thing the program ever deletes for real is option 6 (see "Purging
_duplicates" below), and only after showing you the list and asking.

A PreviewOnly setting (Config\Settings.ps1) lets you run everything as a
dry run, useful the first time you try it on a new collection.


Configuration
-------------
Everything lives under Config\, plain text, editable with any text editor:

- UserSettings.json   Your RetroBat path and chosen language.
- Systems.json        Supported systems ("Name": "folder"), by category.
- Extensions.json     RomExtensions (what counts as a ROM) and
                       IgnoredFolders (never scanned).
- *.custom.json       Optional Systems.custom.json / Extensions.custom.json
                       to add your own on top, safe from updates.
- Settings.ps1        Recognized media suffixes and behavior flags
                       (PreviewOnly, MoveAssets, RemoveDuplicates,
                       HashCache, PurgeDuplicatesAfterDays...).
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


What's new in 2.8
------------------
Everything below is described in detail in its own section further down.

- Multi-file games (.cue/.bin, .gdi, several discs, .m3u) are now handled as
  ONE unit. Before, a .cue and its .bin looked like copies of each other and
  one was moved, and the discs of a game looked like duplicates of each other.
- "Undo the last cleanup" now also restores the orphaned images, videos and
  manuals; it undoes moves from last to first (a hack moved twice in one
  session returns to its original folder); and a file that can't be restored
  no longer stops the rest.
- RetroBat's gamelist.xml: favorites, play counts, last-played dates and
  ratings of a moved duplicate are carried over to the ROM that stays (also
  for exact duplicate hacks), and the entries of hacks organized into
  "# Hacks y Otros #" follow the files to their new path.
- Manual decisions that stick (Config\Overrides.json): "Prefer" a specific
  ROM or "Ignore" a group, and the program offers to remember your tie-break
  answers.
- Hash cache (Resultado\HashCache.tsv): unchanged files are not hashed again;
  deduplicating hacks skips files whose size is unique.
- Purge of _duplicates (menu option 6 or -Action Purge): deletes copies that
  have been there N days or more. It is the only thing that ever deletes
  files, and it always shows the list and asks first. The menu now has 7
  options.
- Systems, ROM extensions and ignored folders moved from Settings.ps1 to
  Config\Systems.json and Config\Extensions.json, with optional *.custom.json
  files for your own additions.
- Exit codes for scheduled tasks (0 = fine, 1 = error, 2 = some action
  failed) and no waiting for a key at the end in unattended mode.
- The version number lives in one file (VERSION); Tools\Build-Release.ps1 and
  a GitHub workflow build and publish the release ZIP.
- Every on-screen message now comes from Strings.ps1 in Spanish and English.
- Automated tests and CI: Run-AllTests.ps1 (it now fails with exit code 1 when
  a test fails), Check-Project.ps1, Smoke-Unattended.ps1, and a GitHub
  Actions workflow on Windows and Linux. Writing them uncovered and fixed
  several real bugs (described in the sections below).

(Version 2.7 had no notes in this README.)


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
  these are byte-identical files. (Earlier it also said this step could
  not be undone; that was outdated: it can, see below.)
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
- New: Spanish/English ROM priority. The program used to always favor
  Spanish ROMs (and Spain as a region). Now it asks the first time you
  run it (same style as the interface language, but a completely
  separate setting), and you can change it any time from menu option 5
  ("Configuration"), which now has 4 sub-options: RetroBat path,
  interface language, ROM priority, or change all of them. With English
  priority, the region/language scoring table flips (USA/English get
  the point values Spain/Spanish used to have, and vice versa) -- the
  other criteria (dump quality, status, hacks, version, revision) don't
  change. See Config\DecisionWeights.ps1 ($Global:DecisionWeights_ES
  and $Global:DecisionWeights_EN).
- Several file-name detection fixes: "Hack", "Translation", the
  ESP/Spain region, version, and revision are now also recognized in
  file names that use underscores instead of spaces (e.g.
  "Street_Fighter_5_Hack_.smc"), a common renaming style in SNES sets.
  And "Beta", "Prototype", "Demo", "Homebrew", "Pirate", "Sample",
  "Preview", and "Kiosk" no longer produce false positives on
  legitimate games that just happen to contain those letters inside a
  different word (Demon's Crest, Pirates of the Caribbean, Team
  Protoman...).
- The Y/N confirmation now also accepts "si", "sí"/"yes" variants
  (previously it required typing exactly a single "Y").
- Move-Asset (moving associated files like save files) no longer
  silently overwrites a file that already existed at the destination.

See the full user manual for details on every feature and the exact
scoring/tie-break rules.


Undo: hacks and chained moves
------------------------------
- Moving loose hacks into "# Hacks y Otros #" and moving their exact
  duplicates to _duplicates are recorded in the plan and can be undone
  with "Undo the last cleanup", like any other move.
- "Undo" now goes through the moves from last to first. Before, a hack
  that was moved twice in the same run (organized, then sent to
  _duplicates as an exact copy) came back only as far as
  "# Hacks y Otros #" instead of to its original folder.
- "Undo the last cleanup" now also brings back the orphaned images, videos
  and manuals. Before, the orphaned-media step moved them without
  recording them in the plan, so after "Clean ALL" + "Undo" the ROMs came
  back but their images and videos stayed in _duplicates. Every media file
  moved is now one more move in the plan (subfolders included), and one
  that can't be moved is reported without stopping the rest.
- If a single file can't be restored (locked by another program, no
  permission...), "Undo" now warns, counts it ("Failed: N") and goes on
  with the rest. In unattended mode (-Yes) the exit code is then 2.


Multi-file games (.cue/.bin, .gdi, multi-disc, .m3u)
-----------------------------------------------------
Disc-based games (PlayStation, Saturn, Dreamcast, Sega CD, PC Engine CD...)
are made of several files. Each file used to be treated as a separate ROM,
which broke games: a .cue and its .bin looked like copies of each other
and one of them was moved; the discs of a game and its .m3u looked like
duplicates of each other. Now each game is one unit:

- A .cue, .gdi or .m3u carries the files it points to (track .bin/.raw
  files; the discs listed in an .m3u, and their tracks). They are no
  longer treated as ROMs on their own.
- Discs of the same game without an .m3u ("(Disc 1)", "(Disc 2)",
  "(Disk 1)", "(CD 1)", "(Disc 1 of 2)") form a set represented by the
  lowest disc.
- A game is kept or moved WHOLE, never half: you won't end up with a .cue
  and no .bin. A USA set and a Europe set are compared as sets.
- If any file of a game would clash with a file already in _duplicates
  (or with another game in the same plan), that game is left where it is
  and a warning is shown.
- Every file is its own move in the plan, so "Undo" puts each one back in
  its exact original folder.
- A file referenced by more than one .cue/.m3u (a shared track) is never
  moved, so the copy you keep keeps working.
- Known limits: .ccd/.mds descriptors are not parsed; the hack organizer
  still works file by file.


Manual decisions that stick (Config\Overrides.json)
----------------------------------------------------
If you disagree with what the scoring engine picks for a particular game,
say so once and it is respected in every cleanup, including scheduled
(-Yes) ones. Create Config\Overrides.json (see Config\Overrides.example.json):

    {
      "Prefer": [ { "System": "snes", "File": "Super Mario World (Europe).sfc" } ],
      "Ignore": [ { "System": "snes", "Title": "Super Mario World" },
                  { "System": "nes",  "File": "Zelda II (USA).nes" } ]
    }

- Prefer: that ROM always wins its duplicate group; the other copies move
  as usual.
- Ignore: the group is left completely untouched. Identify it by "Title"
  (the name printed after "Group:" during a cleanup, or the game's normal
  title) or by "File" (any copy in the group with that file name).
- "System" is the system folder name (snes, nes...). Leave it out, or use
  "*", to apply to every system. Names are not case-sensitive.
- When the program asks you which of two tied ROMs to keep, it now offers
  to remember your answer: it is saved here as a "Prefer".
- If the file doesn't exist, nothing changes. If it can't be read, you get
  a warning and it is ignored (the program never overwrites a file it
  can't read).


RetroBat gamelist.xml (favorites, play counts...)
--------------------------------------------------
When a duplicate ROM is moved, its user data in the system's gamelist.xml
is carried over to the ROM that stays, so you don't lose your favorites
or play history:

- favorite: kept if either copy was a favorite.
- playcount, gametime: the higher of the two (they are NOT added up, so
  undoing and cleaning again never inflates them).
- lastplayed: the most recent date. rating: the highest one.
- name, desc, developer, publisher, genre, players, releasedate...:
  copied only if the ROM that stays doesn't have them.
- Image/video/manual paths are never copied (they belong to the moved
  file). No entry is ever deleted, so "Undo" keeps working as before.
- If the ROM that stays has no entry, a new one is created.
- It also applies to the exact duplicates found inside
  "# Hacks y Otros #".
- When the hack organizer moves loose hacks into "# Hacks y Otros #", each
  hack's gamelist.xml entry follows the file: its <path> is updated (with
  a backup first), so RetroBat doesn't lose its favorites and play history.
  "Undo the last cleanup" puts the path back. Hacks without an entry are
  moved as usual and the gamelist.xml is left untouched.
- Before saving, a copy of gamelist.xml is stored in
  Resultado\GamelistBackups\ (the last UndoHistoryLimit copies per system).

With PreviewOnly it only reports what it would do. To turn it off, set
MergeGamelistMetadata = $false in Config\Settings.ps1 (it disables every
change to the gamelist.xml: the merge and the path updates).


Hash cache
----------
Hashing thousands of ROMs is the slowest part of a cleanup, and every run
used to read and hash the same unchanged files again. The program now keeps
Resultado\HashCache.tsv with each file's hash plus its size and last
modification date at the time it was computed. A stored hash is reused
only while BOTH are still exactly the same; if either changes, the file is
hashed again.

- The next cleanups skip every file that hasn't changed, and the screen
  tells you how many hashes were reused.
- If you change HashAlgorithm (MD5, SHA256...), the cache is discarded.
- It is only an accelerator: if it is missing, damaged or can't be written,
  everything works the same, just slower. Delete Resultado\HashCache.tsv to
  start over, or set HashCache = $false in Config\Settings.ps1 to turn it
  off. (The only way it could ever be wrong is a file whose content changed
  without its size or date changing, which practically never happens.)
- Deduplication of "# Hacks y Otros #" now skips files whose size is unique
  in the folder: two files can only be identical if they weigh exactly the
  same, so most are never even read.


Purging _duplicates (menu option 6, -Action Purge)
---------------------------------------------------
_duplicates only ever grows. Option 6 deletes the copies that have been
there for N days or more (Config\Settings.ps1: PurgeDuplicatesAfterDays,
90 by default; the menu asks for the number and Enter keeps the default).
It is the ONLY thing the program deletes for real, so it is careful:

- Age counts from when the file was MOVED to _duplicates (read from the
  saved plans in Resultado\), not from the file's own date, which is the
  date of the original ROM. If a file was moved several times, the last
  move counts. Associated files (save files...) and media in subfolders
  count with the date of their move.
- Files with no known move date (for example from plans already rotated
  out of the history) are never deleted all at once: their count starts
  the first time the purge sees them (Resultado\DuplicatesSeen.tsv), and
  they only become candidates N days later. If such a file changes, its
  count starts over.
- It always shows what it would delete (per system, the oldest files, the
  total size) and asks for confirmation -- with -Yes it doesn't ask. With
  PreviewOnly it only simulates.
- It only touches files inside _duplicates, removes the folders left
  empty, and writes what it deleted to Resultado\PurgeLog_<date>.txt.
- Purged files can no longer be restored: "Undo" simply skips the ones that
  are gone and restores the rest. A file that can't be deleted is reported
  without stopping the others (exit code 2 in unattended mode).


Systems and extensions in JSON
------------------------------
The systems the program knows, the extensions it treats as ROMs and the
folders it never scans used to be lists inside Config\Settings.ps1, mixed
with code. They now live in Config\Systems.json and Config\Extensions.json,
safe to edit with any text editor. To add your own WITHOUT touching those
files (so an update never overwrites them), create the optional
Config\Systems.custom.json and/or Config\Extensions.custom.json, same format:

    Systems.custom.json:     { "Mine": { "My system": "mysystem" } }
    Extensions.custom.json:  { "RomExtensions": [".xyz"], "IgnoredFolders": ["my_stuff"] }

- In systems, a repeated name takes the folder from the custom file; in
  extensions and ignored folders, the lists are added together.
- Extensions are normalized (".SFC" and "sfc" both become ".sfc").
- A single invalid entry is reported with a warning naming the file and
  ignored. If a file can't be read (broken JSON) or defines no systems or
  extensions, the program stops with a message naming the file and the
  error.


Version number and releases
---------------------------
The version number lives in ONE file, VERSION (it used to be repeated in
every file header, the menu banner, the log and the plans). To publish a
version:

    (1) put the number in VERSION and commit
    (2) git tag v2.8
    (3) git push origin v2.8

.github\workflows\release.yml then checks that the tag matches VERSION, runs
the checks and the tests, builds CleanRoms-v2.8.zip (plus its .sha256) and
publishes a GitHub Release with them attached. You can also build the ZIP
yourself with:  pwsh -File Tools\Build-Release.ps1

- Everything inside the ZIP goes in ONE folder named after the version, so
  unzipping over an older installation never mixes old and new files.
- Nothing personal is included: UserSettings.json, Overrides.json, your
  *.custom.json files, Logs, Resultado and crash_log.txt are never in the
  ZIP, so a new version can't overwrite your settings or decisions.
- Every message on screen (progress bars and the unexpected-error message
  included) now comes from Strings.ps1 in Spanish and English; a test checks
  that every message the code uses exists in both languages.


Tests and continuous integration
---------------------------------
- Tests\Run-AllTests.ps1 (or Run-AllTests.bat) runs the whole test suite.
  It exits with code 1 if any test fails or is interrupted by an error.
- Tests\Check-Project.ps1 checks the syntax of every .ps1, that every file
  loaded with "$Root\..." exists with the exact upper/lower case (it
  matters on Linux), and that the .json files are valid.
- Tests\Smoke-Unattended.ps1 runs the real program in unattended mode
  (-Action ... -Yes) on a small sample collection and checks it finishes
  on its own, with the right exit code.
- .github\workflows\tests.yml runs all three on every push and pull
  request, on Windows and Linux.


Command-line / scheduled use
------------------------------
For unattended runs (Task Scheduler, cron under WSL, etc.), main.ps1
accepts:

    -Action Clean|Orphans|All|Undo|Purge
                                     What to do (skips the menu entirely)
    -System <folder>                 Which system's folder (e.g. "snes",
                                      "gba"); omit or use "ALL" for every
                                      configured system. Ignored by -Action
                                      Undo and -Action Purge.
    -OlderThanDays <n>               Only for -Action Purge: delete the
                                      copies that have been in _duplicates
                                      for n days or more (1-3650). Default:
                                      PurgeDuplicatesAfterDays (90).
    -Yes                             Auto-confirm every Y/N prompt instead
                                      of waiting for input.
    -PreviewOnly                     Force simulation mode for this run
                                      only, without editing Settings.ps1.

Exit codes (useful for Task Scheduler and scripts):

    0   Everything went fine.
    1   Unexpected error (details in crash_log.txt) or invalid arguments.
    2   The run finished, but one or more actions failed (see the log).

In unattended mode (-Yes) the program never waits for a key press at the
end, so a scheduled task always finishes on its own.

Examples:

    pwsh -File main.ps1 -Action Clean -System snes -Yes
    pwsh -File main.ps1 -Action All -Yes
    pwsh -File main.ps1 -Action Undo -Yes
    pwsh -File main.ps1 -Action Purge -OlderThanDays 120 -Yes

Without -Action, main.ps1 behaves exactly as it always has (interactive
menu). Without -Yes, -Action still skips the menu but still asks for
confirmation at each step, same as usual -- -Yes is what actually makes
a run unattended.


Reporting issues
-----------------
If you hit a bug or want a feature added or removed, please email as
much detail as you can (what you did, what you expected,
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
