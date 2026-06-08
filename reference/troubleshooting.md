# Troubleshooting and sources

## Reading the diagnosis report

After running `scripts/diagnose.ps1`, map what you see to a cause:

- **Section 1 "NOT FOUND on PATH"** → yazi isn't really installed, or isn't on PATH. A clean scoop install fixes it.
- **Section 2** tells you how it was installed (scoop / winget / cargo / manual-unknown). This determines the uninstall command in Phase 3.
- **Section 4 shows `TOML parse error` + `Press <Enter> to continue with preset settings`** → broken config file. yazi is rejecting the whole config and falling back to presets. Removing the config (Phase 3) and writing the minimal one (Phase 4e) fixes it.
- **Section 4 shows `YAZI_FILE_ONE : None`** → the file-type detector isn't wired up; previews won't work until Phase 4d sets it.
- **Section 5 execution policy is `Restricted`/`AllSigned`** → scoop's installer may be blocked; Phase 4a has the fallback.
- **Section 5 "Can reach GitHub: False"** → network/proxy/firewall issue; downloads will fail until connectivity is resolved.

## Remaining issues after Phase 5

If verification still fails, do NOT improvise — match the symptom here:

| Symptom in Phase 5 | Cause | Fix |
|---|---|---|
| Previews blank, `$env:YAZI_FILE_ONE` is empty (5a) | Terminal window wasn't reopened after setting the variable | Close ALL PowerShell windows, open a fresh one, retry |
| `TOML parse error` in `yazi --debug` (5b) | The minimal config write (4e) didn't take | Re-run 4e exactly as written |
| Only one media type fails (e.g. PDFs) | That specific dependency is missing | `Get-Command pdftoppm, magick, ffmpeg -ErrorAction SilentlyContinue \| Select-Object Name, Source`, then `scoop install` the missing package |
| Everything blank, `Adapter` shows `Sixel`, `width: 0` | This is a known cosmetic detail on Windows, NOT the problem | Recheck config-load and `YAZI_FILE_ONE` first; do not chase the terminal protocol |
| scoop command not found right after install | PATH not refreshed | Close all windows, open a fresh one |
| Script stops and asks for PowerShell 7 | Running in Windows PowerShell 5.1, not pwsh 7+ | Install pwsh 7 — `scoop install pwsh` (recommended), or `winget install --id Microsoft.PowerShell`, or MSI from https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows — then start it with `pwsh` and re-run |
| YAZI_FILE_ONE shows "NOT SET" in diagnosis | Environment variable was never configured | Run `scripts/set-yazi-file-one.ps1` or set manually per the script's output |
| YAZI_FILE_ONE set but file does NOT exist | git was uninstalled or path changed | Reinstall git (`scoop install git`) then re-run `scripts/set-yazi-file-one.ps1` |

## Encoding (garbled / tofu output)

On Chinese/CJK systems the console may default to a non-UTF-8 code page (GBK / cp936), making UTF-8 tool output show as garbled text or tofu boxes (`锘`, `鈻`, `□`). This means the command usually **succeeded** — only the display is wrong. Re-apply UTF-8 and re-run:

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
- **Repository (sxyazi/yazi, MIT)**: https://github.com/sxyazi/yazi
  - Authoritative default config (the ~246 lines this skill deliberately does NOT duplicate): https://github.com/sxyazi/yazi/tree/shipped/yazi-config/preset

Key facts, all from the above:
- yazi ships complete defaults; user config should only override, never wholesale-replace.
- On Windows, yazi needs `file.exe` from Git for Windows via `YAZI_FILE_ONE`. Official docs advise against the scoop/choco standalone `file` package.
- The config section was renamed `[manager]` → `[mgr]` across versions — a reason to keep config minimal and verify syntax against current docs.
