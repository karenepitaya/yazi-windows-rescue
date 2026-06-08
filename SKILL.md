---
name: yazi-windows-rescue
description: Diagnose, clean up, and correctly reinstall the yazi file manager on Windows when a previous (often AI-assisted) installation left it unusable. Use WHENEVER the user says yazi was installed but won't run / won't open / can't be found / has no file previews / throws TOML parse errors, or "Claude installed yazi and it's broken," or that yazi was set up for them and they don't know how, or asks to clean up and reinstall yazi from scratch on Windows. The goal is an out-of-the-box working setup — preview dependencies are installed automatically (skipped if already present), config is kept minimal, and the user is guided with plain-language explanations and recommended defaults at every step. Enforces a strict, stop-and-confirm, scoop-based procedure followed exactly, without improvising.
compatibility: Windows 10/11. Diagnosis script works on any PowerShell; install scripts require PowerShell 7+ (pwsh). The skill guides users to install pwsh if missing.
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
7. **Whenever you need a decision or approval from the user, use the `AskUserQuestion` tool — never a plain-text question.** Present 2–4 short options, mark the safest one **(recommended)**, and let the user pick rather than type. This applies to every confirmation gate below. A plain prose question ("shall I continue?") is not acceptable where this skill calls for a choice — use the tool so it's a tap.

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

### >>> MANDATORY GATE. Use `AskUserQuestion` for the choice above and wait for the user's selection. Do NOT run anything in Phase 1 until they pick. <<<

## Phase 1 — Diagnose (read-only)

Tell the user: "This just looks at your system — it changes and deletes nothing." Have them run the bundled diagnosis script, which sets UTF-8, then gathers everything in one report:

```powershell
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\diagnose.ps1"
```

Ask them to paste the whole report back.

### >>> STOP. Get the full diagnosis report back from the user before continuing. Do not move to Phase 2 without it. <<<

## Phase 1.5 — Ensure PowerShell 7 (pwsh) before any install steps

This skill standardizes on **PowerShell 7 (pwsh)** for the install steps, because it handles UTF-8 / Chinese text far better than the legacy Windows PowerShell 5.1 and avoids many quirks that cause exactly the breakage being fixed. The install scripts are written for pwsh and will gently refuse to run on 5.1.

Read **Section 6 ("PowerShell 7+ detection")** of the diagnosis report from Phase 1, and act on it:

- **Already running pwsh 7+** (report says "Already running PowerShell 7+") → good, continue to Phase 2.
- **pwsh 7+ is installed but they're in 5.1** (report lists found locations) → tell the user, in plain terms: "You have the modern PowerShell 7 installed but aren't using it. Please open it (run `pwsh`, or find 'PowerShell 7' in the Start Menu) and we'll continue there." Have them re-launch into pwsh, then continue.
- **pwsh 7+ NOT found** → this is the key guidance moment. Explain warmly why we want it (better UTF-8/Chinese handling, fewer legacy traps — the very problems they're dealing with), then use `AskUserQuestion` to offer, scoop as the recommended default:
  - **"Install PowerShell 7 with scoop (recommended — matches the rest of this setup)"**
  - "Install it with winget instead" → `winget install --id Microsoft.PowerShell`
  - "Tell me more first"

  **Sequencing note (important):** if they pick the scoop option but scoop isn't installed yet, install scoop FIRST (use the Phase 4a scoop-install block, including its failure handling), then run `scoop install pwsh`. In other words, when pwsh is missing, the order becomes: install scoop → `scoop install pwsh` → relaunch into pwsh → continue. If they pick winget, scoop can wait until Phase 4a. After pwsh is installed, have them start it (`pwsh`) and continue from there.

Frame this as a one-time upgrade that will make their whole terminal life smoother, not a hoop to jump through. Be encouraging — many people are stuck on 5.1 simply because nobody told them 7 exists.

### >>> MANDATORY GATE. Do not run the install scripts (Phase 4b onward) until the user is in pwsh 7. The scripts themselves will refuse on 5.1, so getting here first saves them a confusing detour. <<<

## Phase 2 — Report findings and get approval to clean

Read the report (interpretation guide: `reference/troubleshooting.md`) and tell the user in plain language: is yazi installed and where, how it was installed (scoop / winget / cargo / manual-unknown), and what's wrong. Note any pre-check flags (execution policy, no network).

Then use `AskUserQuestion` to get explicit approval, scoop as default:
- **"Clean it all out and reinstall properly with scoop (recommended — fixes the mess for good)"**
- "Wait, I have questions"

Explain that mixing install methods is what tends to cause this kind of breakage, so consolidating on scoop is the reliable fix.

### >>> MANDATORY APPROVAL GATE. This is the point of no return for deletion. Use `AskUserQuestion` for the approval above. Do NOT delete or uninstall ANYTHING until the user explicitly selects the cleanup option. <<<

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

**4b. Install only the dependencies that are missing.** Run the bundled script — it reports each dependency's status, installs only what's absent (scoop skips anything already there), and automatically attempts to set `YAZI_FILE_ONE`:
```powershell
pwsh -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\install-deps.ps1"
```
Tell the user which packages it's installing and why (the script prints this). The packages: `yazi fd imagemagick ffmpeg poppler jq git` (`git` provides the `file.exe` needed in 4d). The script will also report on git detection (since the user cloned this repo, git is likely already present) and attempt to auto-set `YAZI_FILE_ONE`.

**4c. Verify yazi installed:**
```powershell
yazi --version
```

**4d. Verify YAZI_FILE_ONE was set.** The install script (4b) now tries to set this automatically. Verify:
```powershell
$existing = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
if ($existing -and (Test-Path $existing)) { "Already set and valid: $existing" } else { "Needs setting" }
```
If already valid, say so and move on. If the install script could not auto-set it (e.g. git was not found), run the standalone helper:
```powershell
pwsh -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\set-yazi-file-one.ps1"
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

- `scripts/diagnose.ps1` — read-only one-shot diagnosis (Phase 1). Sets UTF-8, then reports PATH, install method, config, `yazi --debug`, environment pre-check, PowerShell 7+ detection, and YAZI_FILE_ONE status.
- `scripts/install-deps.ps1` — dependency check + install (Phase 4b). Installs only what's missing, checks scoop buckets, and auto-sets YAZI_FILE_ONE.
- `scripts/set-yazi-file-one.ps1` — standalone YAZI_FILE_ONE setup (Phase 4d fallback). Finds git's file.exe and sets the env var permanently.
- `reference/powershell-vs-bash.md` — bash→PowerShell command translations. Consult if unsure whether a command is PowerShell-native.
- `reference/troubleshooting.md` — how to read the diagnosis report, symptom→fix table, encoding notes, and official sources to verify against.
