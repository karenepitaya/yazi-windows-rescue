# Troubleshooting and sources

## Reading the diagnosis report

After running `scripts/diagnose.ps1`, map what you see to a cause:

- **Section 1 "NOT FOUND on PATH"** → yazi isn't really installed, or isn't on PATH. A clean scoop install fixes it.
- **Section 2** tells you how it was installed (scoop / winget / cargo / manual-unknown). This determines the uninstall command in Phase 3.
- **Section 4 shows `TOML parse error` + `Press <Enter> to continue with preset settings`** → broken config file. yazi is rejecting the whole config and falling back to presets. Removing the config (Phase 3) and writing the minimal one (Phase 4e) fixes it.
- **Section 4 shows `YAZI_FILE_ONE : None`** → the file-type detector isn't wired up; previews won't work until Phase 4d sets it.
- **Section 5 NETWORK VERDICT: PROBLEM** → one or more GitHub endpoints are unreachable. **This is a hard stop (Phase 1.6).** scoop downloads everything from GitHub; do not delete or install anything until the network section is green. Very common in mainland China, where `raw.githubusercontent.com` is frequently blocked. See "Network / proxy" below.
- **Section 5 execution policy is `Restricted`/`AllSigned`** → scoop's installer may be blocked; Phase 4a has the fallback.
- **Section 6** tells you whether the user is on PowerShell 7 (pwsh) or legacy 5.1, and where pwsh is if installed. Drives Phase 1.5.
- **Section 7 YAZI_FILE_ONE** status across User/Machine/session scopes. Drives Phase 4d.

## Remaining issues after Phase 5

If verification still fails, do NOT improvise — match the symptom here:

| Symptom in Phase 5 | Cause | Fix |
|---|---|---|
| File rows show **□ boxes / tofu / garbage** instead of icons | A Nerd Font isn't selected in the terminal (the most common leftover problem) | Confirm the font is installed (`scoop list Maple-Mono-NF-CN`), then set the terminal's font face to **`Maple Mono NF CN`** (Phase 4f) and reopen the terminal. Installing the font is NOT enough — it must be *selected*. |
| Icons still boxes after selecting the font | Terminal wasn't restarted, or the wrong face was picked | Fully close and reopen the terminal/tab. In Windows Terminal make sure you set it under **Defaults → Appearance**, not just one profile. The face is exactly "Maple Mono NF CN". |
| Chinese filenames AND icons render cleanly | (expected) | `Maple Mono NF CN` bundles full CJK plus Nerd Font icons with perfect 2:1 alignment, so 中文 and icons come from one face — no terminal fallback needed. If you swapped in a non-CJK Nerd Font and Chinese turned to boxes, switch back to Maple Mono NF CN. |
| Previews blank, `$env:YAZI_FILE_ONE` is empty (5a) | Terminal window wasn't reopened after setting the variable | Close ALL PowerShell windows, open a fresh one, retry |
| `TOML parse error` in `yazi --debug` (5b) | The minimal config write (4e) didn't take | Re-run 4e exactly as written |
| Only one media type fails (e.g. PDFs) | That specific dependency is missing | `Get-Command pdftoppm, magick, ffmpeg -ErrorAction SilentlyContinue \| Select-Object Name, Source`, then `scoop install` the missing package |
| Everything blank, `Adapter` shows `Sixel`, `width: 0` | Known cosmetic detail on Windows, NOT the problem | Recheck config-load and `YAZI_FILE_ONE` first; do not chase the terminal protocol |
| scoop command not found right after install | PATH not refreshed | Close all windows, open a fresh one |
| Theme didn't change after Phase 6a | `ya pkg add` failed (often network) or `theme.toml` has extra keys | Recheck network (Phase 1.6); ensure `theme.toml` contains ONLY `[flavor]` / `dark = "..."`; reopen yazi |
| `ya pkg add` errors out | Network/proxy, or `ya` not on PATH | Same GitHub-reachability issue — fix proxy (below); confirm `ya --version` works (it ships with yazi) |
| Script stops and asks for PowerShell 7 | Running in Windows PowerShell 5.1, not pwsh 7+ | Install pwsh 7 — `scoop install pwsh` (recommended), or `winget install --id Microsoft.PowerShell`, or MSI from https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows — then start it with `pwsh` and re-run |
| Font install says "Admin rights are required" | Windows older than 10 1809 (per-user font install unsupported) | Open an elevated (Administrator) PowerShell and run `scoop install nerd-fonts/Maple-Mono-NF-CN` just for the font; the rest of the skill stays non-admin |
| YAZI_FILE_ONE shows "NOT SET" in diagnosis | Environment variable was never configured | Run `scripts/set-yazi-file-one.ps1` or set manually per the script's output |
| YAZI_FILE_ONE set but file does NOT exist | git was uninstalled or path changed | Reinstall git (`scoop install git`) then re-run `scripts/set-yazi-file-one.ps1` |

## Network / proxy (the #1 reason installs fail halfway)

Everything this skill installs comes from GitHub through scoop. On many networks — **especially in mainland China** — `github.com` is slow and `raw.githubusercontent.com` is often blocked outright, so an install that looked fine can die partway through. That is why Phase 1.6 is a hard gate: catch it *before* removing the user's existing yazi.

If Section 5 of the diagnosis reports a blocked endpoint:

1. **Easiest:** have the user turn on a system-wide proxy / TUN mode in their proxy client (Clash Verge, V2Ray, etc.), then re-run `diagnose.ps1` and re-check Section 5.
2. **Point scoop at the proxy directly:**
   ```powershell
   scoop config proxy 127.0.0.1:7890      # use the user's real host:port
   ```
   Remove it later with:
   ```powershell
   scoop config rm proxy
   ```
3. Reference: scoop-behind-a-proxy wiki — https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy

Never switch away from scoop to "get around" a network problem — fix connectivity instead.

## Nerd Font (why icons matter, and how it works)

yazi draws file-type icons using glyphs from a **Nerd Font**. If no Nerd Font is installed, OR the terminal isn't set to use it, every icon renders as a □ box ("tofu"), and the whole UI looks broken even though yazi works perfectly. Fixing this is two steps, both required:

1. **Install** a Nerd Font — `install-deps.ps1` adds the `nerd-fonts` bucket and installs `Maple-Mono-NF-CN` (family name **"Maple Mono NF CN"**), which bundles Nerd Font icons AND full CJK with perfect 2:1 中英 alignment. On Windows 10 1809+ / Windows 11 this is per-user, no admin.
2. **Select** that font in the terminal — Windows Terminal: Settings (Ctrl+,) → Profiles → Defaults → Appearance → Font face → "Maple Mono NF CN". Then reopen the terminal.

This is Phase 4f. The diagnosis screenshots that motivated this skill showed step 1 done but step 2 missing — hence boxes.

## Encoding (garbled / tofu output in script *text*)

This is different from tofu *icons* in yazi. On Chinese/CJK systems the console may default to a non-UTF-8 code page (GBK / cp936), making UTF-8 tool output show as garbled text or tofu boxes (`锘`, `鈻`, `□`) in the script's printed report. This means the command usually **succeeded** — only the display is wrong. Re-apply UTF-8 and re-run:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
```

If a specific output is still unreadable, ask the user to paste exactly what they see rather than guessing.

## Sources (verify here rather than relying on memory)

yazi's config schema changes between versions; outdated knowledge is what breaks these installs. When unsure, check:

- **Official docs**: https://yazi-rs.github.io/
  - Installation (incl. the `YAZI_FILE_ONE` requirement on Windows): https://yazi-rs.github.io/docs/installation
  - Configuration (the "don't copy the whole file; use `prepend_*`/`append_*`" principle behind the minimal-config approach): https://yazi-rs.github.io/docs/configuration/overview
  - Flavors (the `ya pkg add ...` + `[flavor]` in `theme.toml` model): https://yazi-rs.github.io/docs/flavors/overview
- **Repository (sxyazi/yazi, MIT)**: https://github.com/sxyazi/yazi
  - Authoritative default config (the ~246 lines this skill deliberately does NOT duplicate): https://github.com/sxyazi/yazi/tree/shipped/yazi-config/preset
- **Flavors repo (yazi-rs/flavors, MIT)**: https://github.com/yazi-rs/flavors — catppuccin-mocha and others.
- **Nerd Fonts scoop bucket**: https://github.com/matthewjberger/scoop-nerd-fonts — `scoop bucket add nerd-fonts`.

Key facts, all from the above:
- yazi ships complete defaults; user config should only override, never wholesale-replace.
- On Windows, yazi needs `file.exe` from Git for Windows via `YAZI_FILE_ONE`. Official docs advise against the scoop/choco standalone `file` package.
- A flavor is installed with `ya pkg add yazi-rs/flavors:<name>` and enabled by a `theme.toml` containing only `[flavor]` (e.g. `dark = "catppuccin-mocha"`) — nothing else, unless intentionally overriding styles.
- The config section was renamed `[manager]` → `[mgr]` across versions — a reason to keep config minimal and verify syntax against current docs.
