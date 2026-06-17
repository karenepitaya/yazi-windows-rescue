---
name: terminal-boost
description: Set up modern CLI tools (eza, bat, fzf, zoxide, starship, etc.) and terminal enhancements for Windows PowerShell via Scoop. Use when the user wants to 美化终端/modern CLI/终端增强/shell aliases/fzf keybindings/better ls/cat WITHOUT mentioning yazi. Also use when the user says "terminal experience", "modern shell tools", "make my terminal better", or wants a polished PowerShell setup. For yazi-related setup, use /yazi-install and /yazi-config instead.
license: MIT
compatibility: Windows 10/11. Requires Scoop and PowerShell 7+.
metadata:
  author: karenepitaya
  suite: yazi-windows-rescue
---

# Terminal Boost（终端增强）

Install modern CLI tools via Scoop and write a managed PowerShell profile block — no yazi required. This is the standalone entry point for users who want a better terminal without the yazi file manager.

## Language

**Conduct the entire interaction in Simplified Chinese (简体中文) by default.**

## Core rules

- **Scoop only.** Never install via npm -g, winget, MSI, or Install-Module.
- **No admin.** Scoop is user-scope; keep it that way.
- **Detect before installing.** Anything already present is skipped.
- **Back up before editing the profile.**
- **Confirm before side effects** (installing packages, changing git config).
- **Stop on error.** Show the raw output and wait.

---

# Procedure

`${CLAUDE_SKILL_DIR}` is this skill's folder. Shared engine: `${CLAUDE_SKILL_DIR}\..\_shared\`.

## Phase T0 — Preconditions

1. Confirm Windows + PowerShell. If not, stop.
2. Detect `$PSVersionTable.PSVersion`. PowerShell 7+ recommended.
3. Confirm Scoop: `scoop --version`. If missing, stop and tell the user.

## Phase T1 — Detect and install tools

Read `_shared/references/tool-catalog.md` for the curated core + optional sets.

For each tool, check `Get-Command <binary>`. Build a plan table: Tool | Status | Action.

**=== GATE: show the plan and wait for confirm before installing. ===**

After confirmation:
```powershell
pwsh -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\..\_shared\scripts\install-terminal-tools.ps1"
```
Output ends `INSTALL-TERMINAL-TOOLS: OK` or `PARTIAL`. Report each result.

## Phase T2 — Profile block

Write `_shared/scripts/profile-block.ps1` into `$PROFILE` between the `# >>> terminal-boost >>>` / `# <<< terminal-boost <<<` markers. If markers exist, replace the region (idempotent). If not, append. Back up the profile first.

```powershell
$profilePath = $PROFILE
$block = Get-Content "${CLAUDE_SKILL_DIR}\..\_shared\scripts\profile-block.ps1" -Raw -Encoding UTF8
$startMarker = "# >>> terminal-boost >>>"
$endMarker = "# <<< terminal-boost <<<"

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $profilePath "$profilePath.bak-$ts"
"Backed up to: $profilePath.bak-$ts"

$content = Get-Content $profilePath -Raw -Encoding UTF8
if ($content -match [regex]::Escape($startMarker)) {
    $pattern = "(?s)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
    $newContent = [regex]::Replace($content, $pattern, $block)
    Set-Content $profilePath $newContent -NoNewline -Encoding UTF8
    "Replaced existing terminal-boost block"
} else {
    $newContent = $content.TrimEnd() + "`n`n" + $block
    Set-Content $profilePath $newContent -NoNewline -Encoding UTF8
    "Appended terminal-boost block"
}
```

## Phase T3 — Optional per-tool config (confirm each)

- **Windows Terminal keybindings**: if WT detected, offer to apply `_shared/config/wt-keybindings.json`. Backup, replace only `keybindings` array, save.
- **git-delta**: offer to set as git pager. Show commands, confirm, run.

## Phase T4 — Verify

Restart terminal or `. $PROFILE`. Version check each installed tool.

## Phase T5 — Usage guide

Generate a concise cheat sheet from `../_shared/references/tool-catalog.md`. Write to project root as `TERMINAL-BOOST.md`.
