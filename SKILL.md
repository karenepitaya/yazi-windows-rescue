---
name: yazi-windows-rescue
description: Diagnose, clean up, and correctly reinstall the yazi file manager on Windows when a previous (often AI-assisted) installation left it unusable. Use WHENEVER the user says yazi was installed but won't run / won't open / can't be found / has no file previews / shows garbled or tofu (□) icons / throws TOML parse errors, or "Claude installed yazi and it's broken," or that yazi was set up for them and they don't know how, or asks to clean up and reinstall yazi from scratch on Windows. The goal is an out-of-the-box working AND good-looking setup — network is checked up front, preview dependencies AND a Nerd Font are installed automatically (skipped if already present), config is kept minimal, the Catppuccin theme and a quit-to-cd shortcut are offered, and the user is taught the basic keys at the end. The whole conversation is conducted in Simplified Chinese, with plain-language explanations and recommended defaults at every step. Enforces a strict, stop-and-confirm, scoop-based procedure followed exactly, without improvising.
compatibility: Windows 10/11. Diagnosis script works on any PowerShell; install scripts require PowerShell 7+ (pwsh). The skill guides users to install pwsh if missing.
allowed-tools: Bash AskUserQuestion Read
---

# Yazi Windows Rescue

Fix a broken yazi install on Windows. Typical situation: a previous assistant installed yazi some unknown way (scoop / winget / cargo / manual unzip), maybe wrote a broken config, and now yazi won't run, won't preview, or shows tofu (□) boxes instead of icons. The user is **non-technical and frustrated**.

Your job: **check the network → diagnose what exists → report it in plain language → cleanly remove ALL of it → reinstall the standard way with scoop (deps + a Nerd Font) → verify → make it nice and teach the keys** — pausing for the user's confirmation between phases.

## Language (read first)

**Conduct the entire conversation in Simplified Chinese (简体中文).** The target audience is Chinese, non-technical users; every explanation, every `AskUserQuestion` option label, and the closing cheat-sheet must be in Chinese. The scripts print some English — when you relay or summarize their output, do it in Chinese. Mirror English only if the user clearly writes to you in English.

## Core rules (read once, apply throughout)

1. **Do not improvise.** A previous assistant broke this by being "clever." Run the fixed procedure. Use the commands and bundled scripts verbatim. Stop at every STOP marker until the user replies. If reality doesn't match this skill, report what you see and ask — don't invent workarounds.
2. **This is PowerShell on Windows, not bash.** Never use bash-only commands (`grep`, `which`, `touch`, `rm -rf`, `&&`, `mkdir -p`, …). If a command fails, suspect bash syntax first. Full translation table: see `reference/powershell-vs-bash.md`.
3. **Garbled / tofu output (`锘`, `鈻`, `□`) has two different causes — tell them apart.** In script *text* output it's almost always an encoding display issue (the command still succeeded; re-apply UTF-8 and re-run, or ask the user to paste what they see). But tofu *icons in yazi's file list itself* mean a **Nerd Font is missing or not selected in the terminal** — that's Phase 4f, not an encoding bug. Never decide anything based on garbled text.
4. **scoop is the only install method here.** Not winget, not cargo, not manual. If scoop is missing, install scoop first (Phase 4a). Never fall back to another method to "get around" a problem.
5. **Keep config minimal.** The final config is the tiny one in Phase 4e. Never add `[plugin]`, `fetchers`, `previewers`, or `preloaders` — yazi's ~246 lines of defaults are correct, and bloated config is what breaks installs. The Catppuccin flavor (Phase 6a) is the one sanctioned exception, and it only writes a `[flavor]` block to a *separate* `theme.toml`.
6. **Network first.** Everything here downloads from GitHub via scoop. If the user is on a restricted network (very common in China — `raw.githubusercontent.com` is frequently blocked), find out BEFORE deleting or installing anything. A network failure discovered halfway through is the worst outcome. Phase 1.6 is a hard gate.
7. **Never claim it's fixed without running Phase 5 verification.**
8. **Whenever you need a decision or approval from the user, use the `AskUserQuestion` tool — never a plain-text question.** Present 2–4 short options in Chinese, mark the safest one **(推荐)**, and let the user pick rather than type. This applies to every confirmation gate below. A plain prose question ("要继续吗？") is not acceptable where this skill calls for a choice — use the tool so it's a tap.

## How to treat the user (this is what makes the experience good)

The stop-and-confirm structure exists FOR the user — each pause keeps them informed and in control. At every step:

- **Lead with one or two plain Chinese sentences:** what we're doing now, why, and what it gets them. Gloss any jargon.
- Give the exact command (or have them run a bundled script), then ask them to paste the output back.
- **When they must choose, always offer a recommended default**, labeled **(推荐)**, with one sentence on why it's safe. Use `AskUserQuestion` so it's a tap, not a typing task. A non-technical user should be able to just pick the recommended option and succeed. Never present equal-looking options with no guidance.
- Be calm and reassuring. The mess was the previous tool's fault, never theirs.

**Why scoop (say this in plain terms when introducing it):** it installs single-file programs into the user's own folder — no admin rights, no system pollution, trivially removable, and it manages PATH automatically. That's why it's the safe choice for them.

---

# Procedure

`${CLAUDE_SKILL_DIR}` below is the folder this skill lives in; use it to run bundled scripts regardless of the user's current directory.

## Phase 0 — Confirm the plan

Explain in two Chinese sentences, e.g.:
> 你的 yazi 之前是用比较混乱的方式装的，所以现在用不起来。我会先确认网络能不能下载、看看现在装了什么，然后清理干净、用简单可靠的方式（scoop）重装一遍——每一步都讲给你听，删任何东西之前一定先给你看。

Then use `AskUserQuestion` with scoop as the default:
- **「好的，用 scoop 这种安全省事的方式（推荐）」**
- 「先跟我多讲讲」

Proceed once they're on board.

### >>> MANDATORY GATE. Use `AskUserQuestion` for the choice above and wait for the user's selection. Do NOT run anything in Phase 1 until they pick. <<<

## Phase 1 — Diagnose (read-only)

Tell the user (Chinese): "这一步只是查看你的系统，不会改动或删除任何东西。" Have them run the bundled diagnosis script, which sets UTF-8, then gathers everything in one report (PATH, install method, config, `yazi --debug`, **network reachability to the GitHub endpoints scoop needs**, proxy settings, PowerShell 7+ detection, and YAZI_FILE_ONE status):

```powershell
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\diagnose.ps1"
```

Ask them to paste the whole report back.

### >>> STOP. Get the full diagnosis report back from the user before continuing. Do not move to Phase 1.5 without it. <<<

## Phase 1.5 — Ensure PowerShell 7 (pwsh) before any install steps

This skill standardizes on **PowerShell 7 (pwsh)** for the install steps, because it handles UTF-8 / Chinese text far better than the legacy Windows PowerShell 5.1 and avoids many quirks that cause exactly the breakage being fixed. The install scripts are written for pwsh and will gently refuse to run on 5.1.

Read **Section 6 ("PowerShell 7+ detection")** of the diagnosis report from Phase 1, and act on it:

- **Already running pwsh 7+** → good, continue to Phase 1.6.
- **pwsh 7+ is installed but they're in 5.1** (report lists found locations) → tell the user, in plain Chinese: "你装了新版 PowerShell 7，但现在用的还是旧版。请打开它（运行 `pwsh`，或在开始菜单找『PowerShell 7』），我们在那里继续。" Have them re-launch into pwsh, then continue.
- **pwsh 7+ NOT found** → explain warmly why we want it (better UTF-8/Chinese handling, fewer legacy traps — the very problems they're dealing with), then use `AskUserQuestion`, scoop as the recommended default:
  - **「用 scoop 安装 PowerShell 7（推荐——和后面的步骤一套工具）」**
  - 「改用 winget 安装」 → `winget install --id Microsoft.PowerShell`
  - 「先跟我多讲讲」

  **Sequencing note (important):** if they pick the scoop option but scoop isn't installed yet, install scoop FIRST (use the Phase 4a scoop-install block, including its failure handling), then run `scoop install pwsh`. So when pwsh is missing, the order is: install scoop → `scoop install pwsh` → relaunch into pwsh → continue. If they pick winget, scoop can wait until Phase 4a. After pwsh is installed, have them start it (`pwsh`) and continue from there.

### >>> MANDATORY GATE. Do not run the install scripts (Phase 4b onward) until the user is in pwsh 7. The scripts themselves will refuse on 5.1. <<<

## Phase 1.6 — Network gate (do this BEFORE any deletion or install)

Read **Section 5 ("Environment pre-check → Network")** of the diagnosis report. This is the moment to catch a restricted network — especially for users in China, where `github.com` is slow and `raw.githubusercontent.com` is often outright blocked, which would make scoop fail partway through.

- **All endpoints reachable** → say so briefly ("网络没问题，可以正常下载") and continue to Phase 2.
- **Any of `github.com` / `raw.githubusercontent.com` / `get.scoop.sh` blocked** → STOP. Explain plainly: "现在网络连不上 GitHub，scoop 装到一半会失败。我们先把网络/代理弄好再开始，免得清理了一半卡住。" Then guide, using `AskUserQuestion`:
  - **「我已经开好代理了（如 Clash 的 TUN/系统代理），重新测一次（推荐）」** → re-run `diagnose.ps1` and re-read Section 5.
  - 「先教我怎么给 scoop 配代理」 → walk them through it (see below).
  - 「先这样，我自己处理网络」 → acknowledge and pause; do not proceed to install until reachable.

  **Proxy guidance (give in Chinese, concretely):**
  - Easiest: turn on a system-wide proxy / TUN mode in their proxy client (Clash Verge etc.), then re-test.
  - Or point scoop at the proxy directly: `scoop config proxy 127.0.0.1:7890` (replace with their actual port). To clear later: `scoop config rm proxy`.
  - Reference: scoop-behind-a-proxy wiki — https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy

### >>> MANDATORY GATE. Do NOT proceed to Phase 2/3/4 while `github.com` or `raw.githubusercontent.com` is unreachable. Re-run diagnose.ps1 until the network section is green. <<<

## Phase 2 — Report findings and get approval to clean

Read the report (interpretation guide: `reference/troubleshooting.md`) and tell the user in plain Chinese: is yazi installed and where, how it was installed (scoop / winget / cargo / manual-unknown), and what's wrong. Note any pre-check flags (execution policy, network already handled in 1.6).

Then use `AskUserQuestion` to get explicit approval, scoop as default:
- **「全部清理干净，用 scoop 正确重装（推荐——彻底解决这个乱摊子）」**
- 「等等，我有问题」

Explain that mixing install methods is what tends to cause this kind of breakage, so consolidating on scoop is the reliable fix.

### >>> MANDATORY APPROVAL GATE. This is the point of no return for deletion. Use `AskUserQuestion` for the approval above. Do NOT delete or uninstall ANYTHING until the user explicitly selects the cleanup option. <<<

## Phase 3 — Clean removal

Run only the steps that match Phase 1's findings. Tell the user before each (Chinese): "这一步会删除 X。"

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

**4a. Ensure scoop exists.** Explain (Chinese): "scoop 是我们用来干净安装 yazi 的工具，它装在你自己的用户目录里，不需要管理员权限。" Check:
```powershell
Get-Command scoop -ErrorAction SilentlyContinue | Select-Object Source
```
If present, skip to 4b. If missing, install it:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```
Failure handling:
- If `Set-ExecutionPolicy` is blocked by Group Policy, fall back to session-only: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force`, then re-run the install line.
- If `Invoke-RestMethod` fails with a network error, this should already have been caught in Phase 1.6 — re-confirm the proxy/network is up, then retry. Do NOT switch to another install method.
- After install, re-check `Get-Command scoop`. If still missing, have them close all PowerShell windows, open a fresh one, and re-check (PATH refresh). Confirm scoop works before 4b.

**4b. Install the dependencies AND a Nerd Font.** Run the bundled script — it reports each dependency's status, installs only what's absent, installs a Nerd Font for yazi's icons, and automatically attempts to set `YAZI_FILE_ONE`:
```powershell
pwsh -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\install-deps.ps1"
```
Tell the user (Chinese) which packages it's installing and why (the script prints this). The packages: `yazi fd imagemagick ffmpeg poppler jq git` (`git` provides the `file.exe` needed in 4d), plus the Nerd Font `Maple-Mono-NF-CN` from the `nerd-fonts` bucket (this is what makes the file-type icons show instead of tofu boxes — and because it bundles full CJK, Chinese filenames and icons render in one font). The script also reports on git detection and attempts to auto-set `YAZI_FILE_ONE`.

**4c. Verify yazi installed:**
```powershell
yazi --version
```

**4d. Verify YAZI_FILE_ONE was set.** The install script (4b) tries to set this automatically. Verify:
```powershell
$existing = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
if ($existing -and (Test-Path $existing)) { "Already set and valid: $existing" } else { "Needs setting" }
```
If already valid, say so and move on. If the install script could not auto-set it (e.g. git was not found), run the standalone helper:
```powershell
pwsh -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\scripts\set-yazi-file-one.ps1"
```
Then tell the user clearly (Chinese): **「关闭所有 PowerShell 窗口，重新打开一个新窗口——这个设置只有在新窗口里才生效。」** Not optional.

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

**4f. Set the Nerd Font as the terminal font (manual, one-time — installing the font is NOT enough).** This is the step that fixes the tofu-icon problem from the screenshots. The font is installed (4b), but the terminal must be told to use it.

Explain in plain Chinese, e.g.: "字体已经装好了，但还要让终端用上它，图标才会正常显示。" Then give the exact steps for Windows Terminal (the common case):
> 打开 **Windows Terminal → 设置（Ctrl+,）→ 配置文件 → 默认值 → 外观 → 字体 → 选 `Maple Mono NF CN`**，保存即可。

If they use another terminal (PowerShell console, Alacritty, WezTerm, Ghostty…), tell them the principle: set that terminal's font to `Maple Mono NF CN`. Then confirm with `AskUserQuestion`:
- **「设好了，图标显示正常（推荐）」**
- 「还是方块/乱码，需要帮助」 → go to `reference/troubleshooting.md` ("tofu icons") — usually the font face name wasn't selected, or they need to reopen the terminal.

### >>> STOP. Have the user close all windows and open a fresh one before Phase 5. <<<

## Phase 5 — Verify

In the **fresh** window:

**5a.** `$env:YAZI_FILE_ONE` — should print the file.exe path. Blank means they didn't reopen the window.

**5b.** `yazi --debug 2>&1 | Select-Object -First 40` — the top should show **no** `TOML parse error` and no `Press <Enter> to continue with preset settings`, and `YAZI_FILE_ONE` should show a path (not `None`).

**5c.** `yazi` — have the user check three things and report back: (1) do folders/files show proper **icons** (not □ boxes)? (2) move to an image, a PDF, and a text file — does each **preview** on the right? `q` to quit.

**5d.** If icons render, previews work, and there's no config error, the rescue itself is done — move to Phase 6. If something still fails, do NOT improvise: match the symptom in `reference/troubleshooting.md` and walk it back (tofu icons → Phase 4f; one media type fails → that dependency; TOML error → re-run 4e).

## Phase 6 — Make it nice, and teach the keys

The install works now; this phase is what makes the user actually happy. Do all three, each in plain Chinese.

**6a. Offer the Catppuccin theme.** yazi's default look is plain; Catppuccin Mocha is a popular, easy improvement, and it's the sanctioned exception to the minimal-config rule because it only writes a `[flavor]` block to a separate file. Use `AskUserQuestion`:
- **「好的，应用 catppuccin-mocha 主题（推荐）」**
- 「不用，保持默认」

If yes, run:
```powershell
ya pkg add yazi-rs/flavors:catppuccin-mocha
```
then write a `theme.toml` that contains ONLY the flavor selection (nothing else, or yazi may complain):
```powershell
$cfgDir = "$env:APPDATA\yazi\config"
$themeToml = @'
[flavor]
dark = "catppuccin-mocha"
'@
[System.IO.File]::WriteAllText("$cfgDir\theme.toml", $themeToml, (New-Object System.Text.UTF8Encoding $false))
"Wrote theme.toml (catppuccin-mocha)"
```
Have them reopen yazi to see it.

**6b. Show the basic keys.** Most first-time yazi users are lost without a map. Read `reference/yazi-cheatsheet.md` and present the core keys to the user in Chinese (navigation, select, copy/cut/paste, delete, new/rename, open, search, tabs, quit), and tell them they can always press **`~` 或 `F1`** inside yazi for the full list. Keep it to the essentials — don't dump everything.

**6c. Offer the `y` quit-to-cd shortcut.** This is the single most-loved yazi quality-of-life tweak: launch yazi with `y`, and when you quit, your PowerShell lands in whatever folder you were browsing. Explain it in one sentence, then use `AskUserQuestion`:
- **「好的，加上 `y` 快捷命令（推荐）」**
- 「不用了」

If yes, add the function to their PowerShell `$PROFILE` (show it to them first):
```powershell
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
```
To add it safely (creates the profile if missing, appends without clobbering):
```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Add-Content -Path $PROFILE -Value "`nfunction y {`n    `$tmp = [System.IO.Path]::GetTempFileName()`n    yazi `$args --cwd-file=`"`$tmp`"`n    `$cwd = Get-Content -Path `$tmp -Encoding UTF8`n    if (-not [String]::IsNullOrEmpty(`$cwd) -and `$cwd -ne `$PWD.Path) { Set-Location -LiteralPath ([System.IO.Path]::GetFullPath(`$cwd)) }`n    Remove-Item -Path `$tmp`n}"
```
Tell them to reopen PowerShell, then launch with `y`. Done — congratulate them warmly (Chinese).

---

# Optional add-ons (only if the user explicitly asks, after Phase 6)

Don't push these. If asked, you may help with other flavors or a `keymap.toml`, but **never** add `[plugin]`, `fetchers`, `previewers`, or `preloaders`, and never wholesale-replace the default config.

---

# Bundled files

- `scripts/diagnose.ps1` — read-only one-shot diagnosis (Phase 1). Sets UTF-8, then reports PATH, install method, config, `yazi --debug`, **HTTPS network reachability + proxy settings**, PowerShell 7+ detection, and YAZI_FILE_ONE status.
- `scripts/install-deps.ps1` — dependency + Nerd Font check/install (Phase 4b). Installs only what's missing, adds the `nerd-fonts` bucket and a font, checks scoop buckets, and auto-sets YAZI_FILE_ONE.
- `scripts/set-yazi-file-one.ps1` — standalone YAZI_FILE_ONE setup (Phase 4d fallback). Finds git's file.exe and sets the env var permanently.
- `reference/powershell-vs-bash.md` — bash→PowerShell command translations.
- `reference/troubleshooting.md` — how to read the diagnosis report, symptom→fix table (incl. tofu icons and China-network/proxy notes), encoding notes, and official sources.
- `reference/yazi-cheatsheet.md` — the basic-keys map presented to the user in Phase 6b.
