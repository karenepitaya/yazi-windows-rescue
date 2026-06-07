# yazi-windows-rescue

A [Claude Code](https://claude.ai/code) skill that diagnoses, cleans up, and correctly reinstalls the [yazi](https://yazi-rs.github.io/) file manager on Windows when a previous (often messy, AI-assisted) installation left it unusable.

## When to use

Use this skill **whenever**:

- yazi was installed but won't run, won't open, or can't be found
- yazi has no file previews
- yazi throws TOML parse errors
- "Claude / Claude Code installed yazi and it's broken"
- The user says yazi was set up for them and they don't know how
- The user wants to clean up and reinstall yazi from scratch on Windows

## What it does

The skill follows a strict, 5-phase, stop-and-confirm procedure:

1. **Diagnose** — Find out how yazi was installed (scoop, winget, cargo, or manual), where the binary lives, and whether a broken config exists
2. **Report** — Summarize the findings in plain language and get user approval before touching anything
3. **Clean** — Back up and remove the old installation and config completely
4. **Reinstall** — Install yazi and its preview dependencies cleanly via scoop, set the `YAZI_FILE_ONE` environment variable, and write a minimal known-good config
5. **Verify** — Confirm the config loads without errors, the environment variable is set, and file previews actually work

## Install

```bash
claude skill add karenepitaya/yazi-windows-rescue
```

Or clone manually into your skills directory:

```bash
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ~/.claude/skills/yazi-windows-rescue
```

## Design principles

- **Never improvise.** A previous assistant broke the install by improvising. This skill runs a known-good, fixed procedure.
- **Stop and confirm.** Pauses for explicit user approval between every phase. Nothing is deleted without consent.
- **Minimal config.** Ships ~10 lines of config that override only what's needed. yazi's ~246-line default config is correct — don't replace it.
- **Scoop only.** Scoop is the fixed, supported installation target on Windows.
- **Verify everything.** Never claims the fix worked without running the full Phase 5 verification.

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Internet connection (for scoop install)
- User-level admin access (to set environment variables)

## License

MIT
