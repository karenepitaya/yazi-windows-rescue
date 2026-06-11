# Troubleshooting and sources

Shared by /yazi-detect, /yazi-install, /yazi-config.

## Reading the diagnosis report (diagnose.ps1)

- **Section 1 "NOT FOUND on PATH"** → yazi isn't really installed or isn't on PATH. /yazi-install fixes it.
- **Section 2** → how it was installed (scoop / winget / cargo / manual-unknown). Determines the uninstall line in install Phase 5c.
- **Section 4 `TOML parse error` + `Press <Enter> to continue with preset settings`** → broken config; yazi fell back to presets. Install Phase 5 (remove) + 6e (minimal rewrite) fixes it.
- **Section 4 `YAZI_FILE_ONE : None`** → preview wiring missing; install Phase 6d sets it.
- **NETWORK VERDICT: PROBLEM** → one or more GitHub endpoints unreachable. **Hard stop (install Phase 2 / config C0).** scoop and `ya pkg` download everything from GitHub; very common in mainland China where raw.githubusercontent.com is often blocked. See "Network / proxy" below.
- **Execution policy `Restricted`/`AllSigned`** → scoop installer may be blocked; install Phase 6a has the fallback.
- **Section 7 (pwsh)** → drives install Phase 3.
- **Section 9 (font)** → whether a Nerd Font is installed and whether Windows Terminal points at one; drives install Phase 6b/6f.

## Symptom → fix

| Symptom | Cause | Fix |
|---|---|---|
| File rows show **□ boxes / garbage** instead of icons | Nerd Font not SELECTED in the terminal (most common leftover) | Confirm install (`scoop list Maple-Mono-NF-CN`), set terminal font face to **`Maple Mono NF CN`** (install Phase 6f), reopen terminal. Installing ≠ selecting. |
| Icons still boxes after selecting font | Terminal not restarted, or wrong face / wrong profile scope | Fully close & reopen. In Windows Terminal set it under **默认值 → 外观**, face exactly "Maple Mono NF CN". |
| 中文文件名和图标显示 | — | Maple Mono NF CN 自带完整 CJK，图标与中文同字体渲染（2:1 对齐），无需回退。若仍异常，确认选用的是 NF CN 变体而不是无 CN 的 Maple Mono。 |
| Previews blank, `$env:YAZI_FILE_ONE` empty | Window not reopened after setting the env var | Close ALL PowerShell windows, open fresh, retry |
| `TOML parse error` in `yazi --debug` | A config write didn't take, or manual edit broke syntax | Re-run the exact write step (install 6e or config C3/C4); compare against the vendored template |
| Only one media type fails (e.g. PDFs) | That dependency missing | `Get-Command pdftoppm, magick, ffmpeg -ErrorAction SilentlyContinue \| Select-Object Name, Source` then `scoop install` the missing one |
| Everything blank, `Adapter` = `Sixel`, `width: 0` | Known cosmetic detail on Windows, NOT the problem | Recheck config-load and YAZI_FILE_ONE first |
| scoop not found right after install | PATH not refreshed | Fresh window |
| Script refuses, asks for PowerShell 7 | Running 5.1 | `scoop install pwsh` (recommended) or `winget install --id Microsoft.PowerShell`, then `pwsh` and re-run |
| Font install says admin required | Windows older than 10 1809 | Elevated pwsh for `scoop install nerd-fonts/Maple-Mono-NF-CN` only; everything else stays non-admin |
| YAZI_FILE_ONE "NOT SET" | Never configured | `scripts/set-yazi-file-one.ps1` |
| YAZI_FILE_ONE set but file missing | git uninstalled / path changed | `scoop install git` then re-run the script |
| **Markdown preview not rendering (config tier)** | piper or glow missing, or previewer block written without them | `ya pkg list` should show `yazi-rs/plugins:piper`; `Get-Command glow`. Install the missing piece, ensure the previewer block exists in yazi.toml, restart yazi. Re-running /yazi-config repairs this safely. |
| Markdown preview is colorless | `CLICOLOR_FORCE` not set or window not reopened | `[Environment]::GetEnvironmentVariable("CLICOLOR_FORCE","User")` should be `1` (config C5 sets it); fresh window |
| **Theme didn't change** | `ya pkg install` failed (network) or theme.toml has extra keys | `ya pkg list` should show the flavor; theme.toml must contain ONLY `[flavor]` / `dark = "catppuccin-mocha"`; reopen yazi |
| `ya pkg install` / `ya pkg add` errors | Network/proxy, or `ya` not on PATH | Fix proxy (below); `ya --version` (ships with yazi). The manifest (`package.toml`) must be the suite's vendored one for pinned installs. |
| `z` does nothing / errors | fzf not installed | `scoop install fzf`, fresh window |
| `Z` does nothing / finds no dirs | zoxide not installed, profile hook missing, or database still empty | `Get-Command zoxide`; `$PROFILE` must contain `zoxide init powershell` (config C7d adds it); fresh window. A new database is empty — it fills up as you cd around for a few days. |
| Previewer config seems ignored entirely | Known confusion: previewers belong under `[[plugin.prepend_previewers]]` in **yazi.toml**, and changes need a yazi restart (see upstream issue #3224) | Verify block location/spelling against config C6b; restart yazi |
| Diagnosis section prints `[CHECK FAILED]` (e.g. Microsoft.PowerShell.Security failing to load on 5.1) | PS 5.1 spawned with a polluted PSModulePath (pwsh 7 module dirs leaking in); the script self-heals the path and isolates each section, but a section can still fail | The failed section's items are UNCHECKED, not OK — re-run the script in pwsh 7 for a complete report; never conclude "should be fine" about an unchecked item |
| Install failed halfway, user wants out | — | `scripts/cleanup.ps1` — backs up + removes config, uninstalls scoop-owned yazi, prints optional deep-clean lines. Then /yazi-install fresh. |

## Network / proxy (the #1 cause of halfway failures)

Everything is downloaded from GitHub via scoop and `ya pkg`. On many networks — especially mainland China — github.com is slow and raw.githubusercontent.com is often blocked. That's why both /yazi-install (Phase 2) and /yazi-config (C0) gate on a real HTTPS check BEFORE changing anything.

1. Easiest: enable system proxy / TUN mode in the proxy client (Clash Verge, V2Ray…), re-run the check.
2. Point scoop at the proxy: `scoop config proxy 127.0.0.1:7890` (real host:port; remove later with `scoop config rm proxy`).
3. Docs: https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy

Never switch away from scoop to "get around" a network problem.

## Nerd Font (two steps, both required)

1. **Install** — install-deps.ps1 adds the `nerd-fonts` bucket and installs `Maple-Mono-NF-CN` (per-user on Win10 1809+/Win11, no admin).
2. **Select** — Windows Terminal: Ctrl+, → 默认值 → 外观 → 字体 → "Maple Mono NF CN", reopen.

Boxes in yazi's UI with a working install = step 2 was skipped.

## Encoding (garbled script TEXT, different from icon boxes)

CJK consoles may default to GBK/cp936, garbling UTF-8 script output (`锘`,`鈻`,`□`). The command usually succeeded. Scripts re-apply UTF-8 themselves; if needed:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
```

## Sources (verify against these, not memory)

- Official docs: https://yazi-rs.github.io/ — installation (YAZI_FILE_ONE on Windows): /docs/installation · configuration principles (override, don't replace; `prepend_*`): /docs/configuration/overview · flavors: /docs/flavors/overview
- Repo (MIT): https://github.com/sxyazi/yazi — preset defaults: yazi-config/preset
- Official plugins monorepo (piper lives here): https://github.com/yazi-rs/plugins
- Flavors repo: https://github.com/yazi-rs/flavors
- Nerd Fonts scoop bucket: https://github.com/matthewjberger/scoop-nerd-fonts

Key facts:
- yazi ships complete defaults; user config only overrides.
- Windows previews need git's `file.exe` via `YAZI_FILE_ONE`; docs advise against the standalone scoop/choco `file` package.
- A flavor = `ya pkg add yazi-rs/flavors:<name>` + theme.toml containing ONLY `[flavor]`.
- piper's official glow example uses a POSIX env prefix (`CLICOLOR_FORCE=1 glow…`); on Windows set CLICOLOR_FORCE=1 as a persistent User env var instead and drop the prefix.
- Config section rename `[manager]` → `[mgr]` happened across versions — keep config minimal, verify against current docs.
