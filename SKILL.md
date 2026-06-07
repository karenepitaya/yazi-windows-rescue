---
name: yazi-windows-rescue
description: Diagnose, clean up, and correctly reinstall the yazi file manager on Windows when a previous (often AI-assisted) installation left it unusable. Use WHENEVER the user says yazi was installed but won't run / won't open / can't be found / has no file previews / throws TOML parse errors, or "Claude installed yazi and it's broken," or that yazi was set up for them and they don't know how, or asks to clean up and reinstall yazi from scratch on Windows. The goal is an out-of-the-box working setup — preview dependencies are installed automatically (skipped if already present), config is kept minimal, and the user is guided with plain-language explanations and recommended defaults at every step. Enforces a strict, stop-and-confirm, scoop-based procedure followed exactly, without improvising.
allowed-tools: Bash AskUserQuestion Read
---

# Yazi Windows Rescue

Fix a broken yazi install on Windows. Typical situation: a previous assistant installed yazi some unknown way (scoop / winget / cargo / manual unzip), maybe wrote a broken config, and now yazi won't run or won't preview. The user is **non-technical and frustrated**.

Your job: **diagnose what exists → report it in plain language → cleanly remove ALL of it → reinstall the standard way with scoop → verify** — pausing for the user's confirmation between phases.

## Core rules (read once, apply throughout)

1. **Do not improvise.** A previous assistant broke this by being "clever." Run the fixed procedure. Use the commands and bundled scripts verbatim. Stop at every STOP marker until the user replies. If reality doesn't match this skill, report what you see and ask — don't invent workarounds.
2. **This is PowerShell on Windows, not bash.** Never use bash-only commands (`grep`, `which`, `touch`, `rm -rf`, `&&`, `mkdir -p`, …). If a command fails, suspect bash syntax first. Full translation table: see `reference/powershell-vs-bash.md`.
3. **Garbled / tofu output (`锘`, `鈻`, `□`) is an encoding display issue, not a failure.** The command usually succeeded. Re-apply UTF-8 (the scripts do this automatically) and re-run, or ask the user to paste what they see. Never decide anything based on garbled text.
4. **scoop is the only install method here.** Not winget, not cargo, not manual. If scoop is missing, install scoop first (Phase 4a). Never fall back to another method to "get around" a problem.
5. **Keep config minimal.** The final config is the tiny one in Phase 4e. Never add `[plugin]`, `fetchers`, `previewers`, or `preloaders` — yazi's ~246 lines of defaults are correct, and bloated config is what breaks installs.
6. **Never claim it's fixed without running Phase 5 verification.**

## How to treat the user (this is what makes the experience good)

The stop-and-confirm structure exists FOR the user — each pause keeps them informed and in control. At every step:

- **Lead with one or two plain sentences:** what we're doing now, why, and what it gets them. Gloss any jargon. E.g. "Now I'll check how yazi was installed — that tells us the safe way to remove it. This only reads info; nothing changes."
- Give the exact command (or have them run a bundled script), then ask them to paste the output back.
- **When they must choose, always offer a recommended default**, labeled **(recommended)**, with one sentence on why it's safe. Use the `AskUserQuestion` tool so it's a tap, not a typing task. A non-technical user should be able to just pick the recommended option and succeed. Never present equal-looking options with no guidance.
- Be calm and reassuring. The mess was the previous tool's fault, never theirs.

**Why scoop (say this in plain terms when introducing it):** it installs single-file programs into the user's own folder — no admin rights, no system pollution, trivially removable, and it manages PATH automatically. That's why it's the safe choice for them.

---

# Procedure

`${CLAUDE_SKILL_DIR}` below is the folder this skill lives in; use it to run bundled scripts regardless of the user's current directory.

## Phase 0 — Confirm the plan

Explain in two sentences: "Your yazi was installed in a messy way and won't work right. I'll check what's there, clean it out, and reinstall it the simple reliable way — explaining each step, and never deleting anything without showing you first."

Then use `AskUserQuestion` with scoop as the default:
- **"Sounds good — use scoop, the safe/easy way (recommended)"**
- "Tell me more first"

Proceed once they're on board.

### >>> STOP. Wait for the user's go-ahead. <<<

## Phase 1 — Diagnose (read-only)

Tell the user: "This just looks at your system — it changes and deletes nothing." Have them run the bundled diagnosis script, which sets UTF-8, then gathers everything in one report:

```powershell
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\diagnose.ps1"
```

Ask them to paste the whole report back.

### >>> STOP. Get the full report before continuing. <<<

## Phase 2 — Report findings and get approval to clean

Read the report (interpretation guide: `reference/troubleshooting.md`) and tell the user in plain language: is yazi installed and where, how it was installed (scoop / winget / cargo / manual-unknown), and what's wrong. Note any pre-check flags (execution policy, no network).

Then use `AskUserQuestion` to get explicit approval, scoop as default:
- **"Clean it all out and reinstall properly with scoop (recommended — fixes the mess for good)"**
- "Wait, I have questions"

Explain that mixing install methods is what tends to cause this kind of breakage, so consolidating on scoop is the reliable fix.

### >>> STOP. Nothing gets deleted until they approve. <<<

## Phase 3 — Clean removal

Run only the steps that match Phase 1's findings. Tell the user before each: "This removes X."

**3a. Back up the old config first (nothing is truly lost):**
```powershell
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) {
    $bak = "$env:APPDATA\yazi\config-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $cfg $bak -Recurse -Force
    "Backed up old config to: $bak"
} else { "No config to back up." }
```

**3b. Remove the config folder:**
```powershell
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) { Remove-Item $cfg -Recurse -Force; "Old config removed (backup kept)." } else { "No config folder." }
```

**3c. Uninstall yazi — run ONLY the line matching how it was installed (from Phase 2):**

- scoop: `scoop uninstall yazi`
- winget: `winget uninstall --id sxyazi.yazi`
- cargo: `cargo uninstall yazi-fm; cargo uninstall yazi-cli`
- manual/unknown: do NOT guess-delete. Show the user the path from the report and confirm before removing it, then `Remove-Item "<that exact path>" -Force`.

**3d. Confirm it's gone:**
```powershell
Get-Command yazi -ErrorAction SilentlyContinue | Select-Object Name, Source
```
Should return nothing. If it still finds yazi, report the path and ask before touching it — there may be a second copy.

### >>> STOP. Confirm 3d returned nothing. <<<

## Phase 4 — Clean install with scoop

**4a. Ensure scoop exists.** Explain: "scoop is the tool we'll use to install yazi cleanly." Check:
```powershell
Get-Command scoop -ErrorAction SilentlyContinue | Select-Object Source
```
If present, skip to 4b. If missing, install it (explain: "It installs into your user folder, no admin rights needed"):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```
Failure handling:
- If `Set-ExecutionPolicy` is blocked by Group Policy, fall back to session-only: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force`, then re-run the install line.
- If `Invoke-RestMethod` fails with a network error (Phase 1 showed no GitHub access), explain it's a network/proxy/firewall issue and have the user resolve connectivity, then retry. Do NOT switch to another install method.
- After install, re-check `Get-Command scoop`. If still missing, have them close all PowerShell windows, open a fresh one, and re-check (PATH refresh). Confirm scoop works before 4b.

**4b. Install only the dependencies that are missing.** Run the bundled script — it reports each dependency's status and installs only what's absent (scoop skips anything already there):
```powershell
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\install-deps.ps1"
```
Tell the user which packages it's installing and why (the script prints this). The packages: `yazi fd imagemagick ffmpeg poppler jq git` (`git` provides the `file.exe` needed in 4d).

**4c. Verify yazi installed:**
```powershell
yazi --version
```

**4d. Set YAZI_FILE_ONE (makes previews work on Windows).** First check if it's already correct:
```powershell
$existing = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
if ($existing -and (Test-Path $existing)) { "Already set and valid: $existing" } else { "Needs setting" }
```
If already valid, say so and move on. Otherwise locate git's file.exe and set it:
```powershell
$fileExe = "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe"
if (Test-Path $fileExe) { [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $fileExe, "User"); "Set to $fileExe" } else { "file.exe NOT FOUND — report this, do not guess another path." }
```
Then tell the user clearly: **"Close ALL PowerShell windows and open a new one — this setting only takes effect in a fresh window."** Not optional.

**4e. Write the minimal config (do NOT add anything):**
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

### >>> STOP. Have the user close all windows and open a fresh one before Phase 5. <<<

## Phase 5 — Verify

In the **fresh** window:

**5a.** `$env:YAZI_FILE_ONE` — should print the file.exe path. Blank means they didn't reopen the window.

**5b.** `yazi --debug 2>&1 | Select-Object -First 40` — the top should show **no** `TOML parse error` and no `Press <Enter> to continue with preset settings`, and `YAZI_FILE_ONE` should show a path (not `None`).

**5c.** `yazi` — have the user move to an image, a PDF, and a text file, and report whether each previews on the right. `q` to quit.

**5d.** If previews work and there's no config error, the rescue is done — tell them warmly. If something still fails, do NOT improvise: match the symptom in `reference/troubleshooting.md` and walk it back.

---

# Optional add-ons (only if the user explicitly asks, after Phase 5 succeeds)

Don't push these. If asked:
- **Catppuccin theme:** `ya pkg add yazi-rs/flavors:catppuccin-mocha`, then a `theme.toml` containing only `[flavor]` / `dark = "catppuccin-mocha"`.
- **`y` shortcut** (cd to yazi's last dir on exit): add a `y` function to the PowerShell `$PROFILE`; show it to the user before adding.

Never add keymaps, plugins, or other config unless specifically requested, and never touch `[plugin]`.

---

# Bundled files

- `scripts/diagnose.ps1` — read-only one-shot diagnosis (Phase 1). Sets UTF-8, then reports PATH, install method, config, `yazi --debug`, and environment pre-check.
- `scripts/install-deps.ps1` — dependency check + install (Phase 4b). Installs only what's missing.
- `reference/powershell-vs-bash.md` — bash→PowerShell command translations. Consult if unsure whether a command is PowerShell-native.
- `reference/troubleshooting.md` — how to read the diagnosis report, symptom→fix table, encoding notes, and official sources to verify against.
