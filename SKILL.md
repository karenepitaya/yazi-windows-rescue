---
name: yazi-windows-rescue
description: Diagnose, clean up, and correctly reinstall the yazi file manager on Windows when a previous (often messy, AI-assisted) installation left it unusable. Use this skill WHENEVER the user mentions that yazi was installed but won't run, won't open, can't be found, has no file previews, throws TOML parse errors, or "Claude/Claude Code installed yazi and it's broken." Also trigger if the user says yazi was set up for them and they don't know how, or asks to clean up and reinstall yazi from scratch on Windows. The goal is an out-of-the-box working setup — preview dependencies are installed automatically (skipped if already present), and config is kept deliberately minimal. Enforces a strict, stop-and-confirm, scoop-based procedure that must be followed exactly without improvising.
---

# Yazi Windows Rescue

This skill fixes a broken yazi installation on Windows. The typical situation: a previous AI assistant installed yazi in some unknown way (scoop, winget, cargo, or a manually unzipped binary), possibly wrote a broken config, and yazi now won't run or won't preview files. The user is non-technical and frustrated.

Your job is to **diagnose what exists, report it, cleanly remove ALL of it, then reinstall the standard way using scoop** — pausing for explicit user confirmation between every phase.

## The single most important rule

**You must NOT improvise, optimize, shortcut, or "be clever."** A previous assistant already broke this environment by improvising. The whole point of this skill is to run a known-good, fixed procedure. Execute the phases in order. Run the commands exactly as written. Stop where told to stop.

If something doesn't match what this skill describes, do NOT invent a workaround. Report exactly what you see to the user and ask them how to proceed. When in doubt, consult the official sources listed at the bottom of this skill rather than relying on memory — yazi's config schema changes between versions, and outdated knowledge is exactly what broke this environment in the first place.

## Absolute prohibitions (NEVER do these)

- **NEVER skip the diagnosis phase.** You must know what is installed and how before removing anything.
- **NEVER delete or uninstall anything before the user has seen the diagnosis report and explicitly approved Phase 3.**
- **NEVER reinstall yazi with anything other than scoop.** Not winget, not cargo, not a manual download. Scoop is the fixed target. If scoop is not installed, install scoop first (Phase 4 covers this) — do not fall back to another method.
- **NEVER write a complex yazi config.** The final config is the minimal one in this skill. Do not add `[plugin]`, `fetchers`, `previewers`, or `preloaders`. yazi's defaults are correct.
- **NEVER modify, merge, or "improve" the commands in this skill.** Run them verbatim. Do not add flags, do not combine steps, do not substitute "equivalent" commands.
- **NEVER invent commands or file paths.** If you need a path you don't have, get it from a diagnosis command's output, not from memory.
- **NEVER continue past a STOP marker without the user replying.**
- **NEVER claim something is fixed without running the Phase 5 verification.**

## How to interact with this user

The user is non-technical and was burned by a previous messy install. For every command block you ask them to run:
1. Tell them in one plain sentence what it does.
2. Give them the exact command to copy-paste.
3. Ask them to paste back the full output.

Do not use jargon without a quick gloss. Be calm and reassuring — they're already frustrated. Never make them feel the breakage was their fault.

---

# The procedure: 5 phases, stop after each

## Phase 1 — Diagnose what exists

Goal: find out (a) whether yazi is on PATH, (b) how it was installed, (c) whether a broken config exists. Removing nothing yet.

Ask the user to run these one at a time and paste back each output. Tell them: "These commands only look at things — they don't change or delete anything."

**1a. Is yazi findable, and where?**
```powershell
Get-Command yazi -ErrorAction SilentlyContinue | Select-Object Name, Source
```

**1b. Was it installed by scoop?**
```powershell
scoop list 2>$null | Select-String yazi
```

**1c. Was it installed by winget?**
```powershell
winget list 2>$null | Select-String -Pattern "yazi"
```

**1d. Was it installed by cargo?**
```powershell
if (Test-Path "$env:USERPROFILE\.cargo\bin\yazi.exe") { "cargo: yes - $env:USERPROFILE\.cargo\bin\yazi.exe" } else { "cargo: no" }
```

**1e. Does a config folder exist, and what's in it?**
```powershell
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) { Get-ChildItem $cfg -Recurse | Select-Object FullName, Length } else { "no config folder" }
```

**1f. If yazi runs at all, what does its self-check say?** (It may error — that's fine, we want to see the error.)
```powershell
yazi --debug 2>&1 | Select-Object -First 60
```

### >>> STOP. Do not proceed to Phase 2 actions until you have all six outputs. <<<

---

## Phase 2 — Report the diagnosis and get approval to clean

Read the six outputs and write the user a short, plain-language summary covering:

- **Is yazi installed?** (yes/no, and where the binary lives)
- **How was it installed?** (scoop / winget / cargo / manual-or-unknown). If 1b shows it, it's scoop. If 1c shows it, winget. If 1d says yes, cargo. If the binary exists (1a) but none of those claim it, it's a **manual/unknown** install (likely an unzipped binary somewhere on PATH).
- **What's wrong?** Map the symptom:
  - 1a finds nothing → not on PATH / not really installed.
  - 1f shows `TOML parse error` + `Press <Enter> to continue with preset settings` → broken config file.
  - 1f shows `YAZI_FILE_ONE : None` and previews don't work → missing the file-type detector (we fix this in Phase 4).
  - yazi runs but previews are blank → missing preview dependencies and/or `YAZI_FILE_ONE` (Phase 4 fixes both).
- **What we're going to do:** remove the existing yazi (whichever way it was installed) and its config, then reinstall cleanly with scoop.

Then present the plan and ask for the go-ahead. Use plain words like: "Here's what I found and what I'd like to do. Reply **继续 / continue** and I'll start the cleanup. Nothing has been deleted yet."

### >>> STOP. Wait for the user to reply "继续"/"continue"/explicit yes before doing anything in Phase 3. <<<

---

## Phase 3 — Clean removal of the old install

Run the steps that match what Phase 1 found. Skip the ones that don't apply. Tell the user before each: "This step removes X."

**3a. Always back up the old config first** (so nothing is truly lost):
```powershell
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) {
    $bak = "$env:APPDATA\yazi\config-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $cfg $bak -Recurse -Force
    "Backed up old config to: $bak"
} else { "No config to back up." }
```

**3b. Remove the config folder** (we'll recreate a clean minimal one later):
```powershell
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) { Remove-Item $cfg -Recurse -Force; "Old config removed (backup kept)." } else { "No config folder." }
```

**3c. Uninstall yazi — ONLY run the line matching how it was installed (from Phase 2):**

If scoop installed it:
```powershell
scoop uninstall yazi
```

If winget installed it:
```powershell
winget uninstall --id sxyazi.yazi
```

If cargo installed it:
```powershell
cargo uninstall yazi-fm; cargo uninstall yazi-cli
```

If it was a manual/unknown install (binary exists but no package manager claims it): do NOT guess and delete files. Instead show the user the path from 1a and ask them to confirm before removing it. Only after they confirm:
```powershell
# Replace <PATH> with the exact Source path from step 1a. Ask the user to confirm first.
Remove-Item "<PATH>" -Force
```

**3d. Confirm yazi is gone:**
```powershell
Get-Command yazi -ErrorAction SilentlyContinue | Select-Object Name, Source
```
This should now return nothing. If it still finds yazi, report the path to the user and ask before touching it — there may be a second copy.

### >>> STOP. Confirm with the user that 3d returned nothing before proceeding to Phase 4. <<<

---

## Phase 4 — Clean install with scoop (the fixed, standard method)

This is the known-good install. Do not deviate.

**4a. Make sure scoop exists.** Check first:
```powershell
Get-Command scoop -ErrorAction SilentlyContinue | Select-Object Source
```
If that returns nothing, install scoop (this is the ONLY approved way to get yazi here, so scoop is required):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```
Then re-run the check and confirm scoop is found before continuing.

**4b. Check which dependencies are already present, then install only what's missing.**

yazi needs a small set of companion tools for full out-of-the-box previews. The goal here is "works out of the box" — but if a dependency is already installed and working, there's no need to reinstall it. First detect what's already there:

```powershell
$deps = @{
    "yazi"       = "the file manager itself"
    "fd"         = "file search inside yazi"
    "magick"     = "image previews (ImageMagick)"
    "ffmpeg"     = "video thumbnail previews"
    "pdftoppm"   = "PDF previews (Poppler)"
    "jq"         = "JSON pretty previews"
    "git"        = "provides file.exe for MIME detection (step 4d)"
}
foreach ($cmd in $deps.Keys) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) { "OK   $cmd  -> $($found.Source)" }
    else        { "MISSING  $cmd  ($($deps[$cmd]))" }
}
```

Read the output to the user in plain language: list what's already OK and what's missing. Then install **only the missing ones**. The scoop package names are: `yazi`, `fd`, `imagemagick` (provides `magick`), `ffmpeg`, `poppler` (provides `pdftoppm`), `jq`, `git`.

For example, if only ImageMagick and Poppler are missing:
```powershell
scoop install imagemagick poppler
```

If you're unsure or several are missing, it is safe to just install the full set — scoop skips anything already installed, it won't reinstall or break working tools:
```powershell
scoop install yazi fd imagemagick ffmpeg poppler jq git
```

Either way, tell the user which packages you're installing and why, before running it. Don't silently install a big list.

**4c. Verify yazi installed:**
```powershell
yazi --version
```

**4d. Set the YAZI_FILE_ONE environment variable** — this is what makes file previews work on Windows. First check whether it's already correctly set (if so, skip the rest of 4d):
```powershell
$existing = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
if ($existing -and (Test-Path $existing)) { "Already set and valid: $existing — skip the rest of 4d" } else { "Not set or invalid — continue with 4d" }
```
If it's already set and valid, tell the user it's fine and move on. Otherwise, find the exact path to git's file.exe:
```powershell
$fileExe = "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe"
if (Test-Path $fileExe) { "Found: $fileExe" } else { "NOT FOUND - report this to the user, do not guess another path." }
```
If found, set it (permanently, for this user):
```powershell
[Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe", "User")
```
Tell the user clearly: **"You must now close ALL PowerShell windows and open a new one — the setting only takes effect in a fresh window."** This is not optional; previews will not work until they reopen the terminal. (If 4d was skipped because the variable was already set, they still need a fresh window only if other changes in Phase 4 require it — but reopening never hurts.)

**4e. Write the minimal, known-good config.** Do NOT write anything beyond this. Run it as one block:
```powershell
$cfgDir = "$env:APPDATA\yazi\config"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null

$yaziToml = @'
[mgr]
ratio          = [ 1, 3, 4 ]
sort_dir_first = true
linemode       = "size"
show_hidden    = false

[preview]
image_delay = 30
'@
[System.IO.File]::WriteAllText("$cfgDir\yazi.toml", $yaziToml, (New-Object System.Text.UTF8Encoding $false))
"Wrote minimal yazi.toml"
```

> Why so minimal: yazi ships ~246 lines of correct defaults. The previous broken install almost certainly came from someone adding `[plugin]`/`fetchers`/`previewers` with outdated syntax, which makes yazi reject the whole config. We deliberately keep it tiny. Do not add to it.

### >>> STOP. Have the user close all PowerShell windows and open a fresh one before Phase 5. <<<

---

## Phase 5 — Verify it actually works

In the **fresh** PowerShell window:

**5a. Confirm the environment variable took effect:**
```powershell
$env:YAZI_FILE_ONE
```
Should print the file.exe path. If it's blank, they didn't reopen the window — have them close all windows and open a new one again.

**5b. Run the self-check — confirm NO config error:**
```powershell
yazi --debug 2>&1 | Select-Object -First 40
```
Look at the very top. If there is **no** `TOML parse error` and **no** `Press <Enter> to continue with preset settings`, the config is loading correctly. Also confirm in the output that `YAZI_FILE_ONE` shows a path (not `None`).

**5c. Launch yazi and test previews:**
```powershell
yazi
```
Ask the user to navigate (arrow keys or `j`/`k`) to: an image file, a PDF, and a text file, and tell you whether each shows a preview in the right-hand pane. Press `q` to quit.

**5d. Report the result.** If previews work and there's no config error, the rescue is complete. If something still fails, do NOT improvise — paste the relevant Phase 5 output and walk back through the matching diagnosis in Phase 2. Common remaining issues and their fixes:
- Previews still blank, `YAZI_FILE_ONE` is `None` in 5b → window wasn't reopened (5a). Reopen and retry.
- `TOML parse error` in 5b → the config write in 4e didn't take; re-run 4e exactly.
- A specific media type doesn't preview (e.g., only PDFs fail) → confirm that dependency installed: `Get-Command pdftoppm, magick, ffmpeg -ErrorAction SilentlyContinue | Select-Object Name, Source`.

---

# Optional add-ons (only if the user explicitly asks)

These are NOT part of the core rescue. Offer them only after Phase 5 succeeds and only if the user wants them. Each is optional; do not push them.

- **Catppuccin theme**: `ya pkg add yazi-rs/flavors:catppuccin-mocha`, then create `theme.toml` containing only:
  ```toml
  [flavor]
  dark = "catppuccin-mocha"
  ```
- **`y` shortcut that cd's to yazi's last directory**: add a `y` function to the PowerShell `$PROFILE`. Only do this if asked, and show the user the function before adding it.

Do not add keymaps, plugins, or any other configuration unless the user specifically requests it — and even then, keep it minimal and never touch the `[plugin]` section.

---

# Sources and references

All commands and configuration choices in this skill are based on yazi's official documentation and source repository, not on assumptions. If you hit a situation this skill doesn't cover, verify against these — do not guess:

- **Official documentation (yazi-rs)**: https://yazi-rs.github.io/
  - Installation (including the `YAZI_FILE_ONE` requirement on Windows): https://yazi-rs.github.io/docs/installation
  - Configuration (the "you don't need to copy the entire file; use `prepend_*`/`append_*` to customize on top of defaults" principle that underlies this skill's minimal-config approach): https://yazi-rs.github.io/docs/configuration/overview
- **Open-source repository (sxyazi/yazi, MIT-licensed)**: https://github.com/sxyazi/yazi
  - Authoritative default config files (the ~246 lines of presets this skill deliberately does NOT duplicate): https://github.com/sxyazi/yazi/tree/shipped/yazi-config/preset

Key facts this skill relies on, all from the above sources:
- yazi ships complete default configuration; user config should only override, never wholesale-replace. Keymaps and rules use `prepend_*`/`append_*`.
- On Windows, yazi needs `file.exe` (from Git for Windows) pointed to by the `YAZI_FILE_ONE` environment variable for reliable MIME-type detection. The official docs specifically advise against the scoop/choco standalone `file` package.
- yazi's config TOML schema has changed across versions (e.g. the `[manager]` section was renamed to `[mgr]`), which is why this skill keeps config minimal and says to verify syntax against the docs rather than trusting older examples.
