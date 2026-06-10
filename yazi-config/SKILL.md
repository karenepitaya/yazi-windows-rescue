---
name: yazi-config
description: Configure, theme, and enhance an ALREADY-WORKING yazi install on Windows - turning "it runs" into "it's a polished daily driver". Use when the user asks to 配置/美化/主题/预览增强 yazi, wants the Catppuccin theme, Markdown preview with glow, fzf/zoxide jumping, handy keybindings, the `y` quit-to-cd shortcut, or says "yazi 能用了但太丑/太原始", "give me the full yazi setup", or wants to switch between a minimal and a complete configuration. PRECONDITION: yazi must be installed and runnable - this skill verifies that first and refuses (pointing to /yazi-install) if not. Re-runnable any time to switch tiers, re-personalize, or add previously skipped optional items (glow Markdown preview, fzf+zoxide jump enhancement). Theme and plugins install from a version-pinned package.toml manifest (ya pkg install) - the exact author-verified revisions, reproducible on every machine. Everything installs defensively: anything that fails to download is skipped and reported, never half-written into config.
license: MIT
compatibility: Windows 10/11. Requires a working yazi install (verified up front) and network access to GitHub for plugins/tools. Scripts run on any PowerShell.
allowed-tools: Bash AskUserQuestion Read
metadata:
  author: karenepitaya
  suite: yazi-windows-rescue
---

# Yazi Config（配置 / 美化 / 增强）

Take a **verified-working** yazi and make it the setup its author actually uses daily: Catppuccin theme, Markdown rendered by glow in the preview pane, a couple of high-value keybindings, your editor wired in, and the `y` quit-to-cd shortcut. Two tiers, re-runnable, always reversible (config is backed up every run).

## Language

**Conduct the entire interaction in Simplified Chinese (简体中文) by default.** All `AskUserQuestion` options in Chinese with a **（推荐）** default. Commands/paths/code verbatim.

## Core rules

1. **Installation first, configuration second — no exceptions.** Phase C0's verdict gates everything. If yazi isn't installed and healthy, refuse politely and point to `/yazi-install`. Configuring on a broken base is how installs got broken in the first place.
2. **Defensive enhancement: never half-write.** Every plugin/flavor/tool is a GitHub download that can fail. The rule is *install first, reference after*: `theme.toml` is written ONLY after the flavor package installs; the markdown previewer block is appended ONLY after BOTH the piper plugin AND glow are confirmed. A config referencing something absent = startup errors = worse than no config.
3. **Backup before every write.** Timestamped copy of the whole config dir at the start of every run. Switching tiers or re-running must never lose anything.
4. **Stay small even in the complete tier.** The vendored templates are deliberately tiny; yazi's defaults do the heavy lifting. Never add `fetchers`/`preloaders`/extra `[plugin]` blocks beyond what this skill specifies. Never put anything but `[flavor]` in `theme.toml`.
5. **PowerShell, not bash** (`../_shared/references/powershell-vs-bash.md`). Garbled script text = encoding, not failure.
6. **Decisions via `AskUserQuestion`**, recommended default marked, one tap to succeed.
7. **Teach while doing.** One plain-Chinese sentence per component: 这是什么、为什么加、想改去哪改。The goal is a transparent finished product, not a black box.

---

# Procedure

`${CLAUDE_SKILL_DIR}` is this skill's folder. Shared engine: `${CLAUDE_SKILL_DIR}\..\_shared\`.

## Phase C0 — Verify the base（the gate）

"先确认 yazi 本身是健康的，配置才有意义。这一步只读不改。"

```powershell
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\..\_shared\scripts\verify-yazi.ps1"
```

Read the pasted output:
- **`VERDICT: NOT-READY`** → refuse to configure. 平实解释列出的原因，然后："先运行 **`/yazi-install`** 把安装修好，再回来跑 `/yazi-config`，一两分钟的事。" **End here.**
- **`VERDICT: READY` + `NETWORK: PROBLEM`** → 说明：最小档不需要网络，可以做；完整档要从 GitHub 拉主题/插件/工具，需要先修网络（代理指引：`scoop config proxy 127.0.0.1:7890`，换自己的端口）。`AskUserQuestion`: **「先修网络再上完整档（推荐）」**／「先用最小档」／「再测一次」.
- **`VERDICT: READY` + `NETWORK: OK`** → continue.

### >>> GATE. READY or nothing gets configured. <<<

## Phase C1 — Choose a tier

两句话介绍："**最小档**＝干净基线，yazi 默认行为＋几行合理设置，永远是安全退路。**完整档**＝作者日常在用的那套：Catppuccin 主题、预览窗里渲染 Markdown、好用的快捷键、接上你的编辑器。" `AskUserQuestion`:
- **「完整推荐档——一步到位的成品（推荐）」**
- 「最小干净档——只要基线」
- 「先讲讲两档的区别」

Re-runs: 先说明当前在哪一档（看 theme.toml/keymap.toml 是否存在即可判断），再问要切换还是重新个性化。

## Phase C2 — Backup（every run, both tiers）

```powershell
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) {
    $bak = "$env:APPDATA\yazi\config-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $cfg $bak -Recurse -Force; "已备份到: $bak"
} else { New-Item -ItemType Directory -Force -Path $cfg | Out-Null; "新建了配置目录。" }
```

## Phase C3 — Minimal tier（if chosen; then skip to C8）

```powershell
$cfgDir = "$env:APPDATA\yazi\config"
Copy-Item "${CLAUDE_SKILL_DIR}\..\_shared\config\yazi-minimal.toml" "$cfgDir\yazi.toml" -Force
foreach ($f in "theme.toml","keymap.toml") {
    $p = Join-Path $cfgDir $f
    if (Test-Path $p) { Remove-Item $p -Force; "已移除 $f（备份里都有）" }
}
"最小档写入完成"
```
说明：增强件都收回了，备份俱在，随时可再跑本命令切回完整档。Go to C8.

## Phase C4 — Complete tier: base files

```powershell
$cfgDir = "$env:APPDATA\yazi\config"
Copy-Item "${CLAUDE_SKILL_DIR}\..\_shared\config\yazi-complete.toml"  "$cfgDir\yazi.toml"   -Force
Copy-Item "${CLAUDE_SKILL_DIR}\..\_shared\config\keymap-complete.toml" "$cfgDir\keymap.toml" -Force
"基础配置已写入（先不含主题与 Markdown 预览——装好对应组件后才会接上）"
```
讲解 keymap 的两条："`g h` 回家目录；**`!` 在当前目录打开 PowerShell**——逛到哪、就在哪开终端，日常价值极高。"

## Phase C5 — Complete tier: Markdown 预览（可选项, glow）

"可选增强：预览窗里直接把 Markdown 渲染成排版好的样子（用 glow），逛笔记和 README 的体验完全不同。" `AskUserQuestion`:
- **「要——预览窗渲染 Markdown（推荐）」**
- 「不用，跳过这项」

If yes:
```powershell
powershell -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}\..\_shared\scripts\install-preview-tools.ps1"
```
Output ends `PREVIEW-TOOLS: OK` or `PARTIAL`. PARTIAL（几乎都是网络）→ 修代理重跑，或明确告知"这项先跳过，其余继续"。Script also sets `CLICOLOR_FORCE=1`（User）— glow 被管道调用时保持彩色输出的 Windows 正确做法；新窗口才生效。

**Remember the outcome**（要了且 OK / 跳过）— C6b 据此决定写不写 previewer。If skipped, piper still installs via the manifest below — 它不被 previewer 引用时是惰性的，无副作用，而且让用户以后重跑本 skill 补开 Markdown 预览时无需重新拉插件。

## Phase C6 — Complete tier: theme & plugin（钉死版本的清单安装）

**C6a. 按清单安装（一条命令，可复现）.** 说明："套件自带一份作者机器上验证过的组件清单（catppuccin-mocha 主题 + piper 预览插件，精确到提交号）——装到的就是验证过的那个版本组合，不是 GitHub 上碰巧的最新版。"

```powershell
$cfgDir = "$env:APPDATA\yazi\config"
$dst = Join-Path $cfgDir "package.toml"
$src = "${CLAUDE_SKILL_DIR}\..\_shared\config\package.toml"
if ((Test-Path $dst) -and ((Get-FileHash $dst).Hash -ne (Get-FileHash $src).Hash)) {
    "注意：你已有一份不同的 package.toml（C2 的备份里有原件），将被套件清单覆盖。"
}
Copy-Item $src $dst -Force
ya pkg install
```

- **成功（`$LASTEXITCODE -eq 0`）** → 立即接上主题：
  ```powershell
  Copy-Item "${CLAUDE_SKILL_DIR}\..\_shared\config\theme.toml" "$env:APPDATA\yazi\config\theme.toml" -Force
  "主题已启用"
  ```
- **失败（几乎都是网络）** → **不写 theme.toml、不写 previewer**，如实报告，给代理指引（troubleshooting 的 Network 节），可稍后重跑本 skill 补齐。继续 C7。

**C6b. 接入 Markdown previewer（仅当 C6a 成功 且 C5 选了要并且 OK）:** append（this exact block, UTF-8 no BOM）:
  ```powershell
  $block = @'

[[plugin.prepend_previewers]]
url = "*.md"
run = 'piper -- glow -w=$w -s=dark "$1"'
'@
  [System.IO.File]::AppendAllText("$env:APPDATA\yazi\config\yazi.toml", $block, (New-Object System.Text.UTF8Encoding $false))
  "Markdown 预览已接入"
  ```
  注：官方示例的 `CLICOLOR_FORCE=1` 前缀是 POSIX 写法，Windows 不适用——C5 已用持久环境变量等价替代，命令里不要加前缀。
- 任一失败 → **绝不写 previewer block**（引用缺失组件＝启动报错）。如实报告并继续。

## Phase C7 — Complete tier: personalize

**C7a. Editor.** Detect first:
```powershell
Get-Command code, nvim -ErrorAction SilentlyContinue | Select-Object Name, Source
```
`AskUserQuestion`（检测到 code 时把 VS Code 设为推荐；都没检测到则记事本为推荐）:
- 「VS Code」 → edit the opener line in `$env:APPDATA\yazi\config\yazi.toml`: put `{ run = 'code %s', desc = "VS Code", for = "windows", orphan = true },` FIRST, keep the notepad line after it as fallback.
- 「Neovim」 → first line `{ run = 'nvim %s', desc = "Neovim", for = "windows", block = true },`, notepad kept as fallback.
- 「记事本就好（保底）」 → leave as-is.

**C7b. 常用项目目录跳转（optional）.** `AskUserQuestion`: **「跳过（推荐——以后随时可加）」**／「我有，帮我加上 `g d` 跳转」. If yes, ask for the path, then append to `keymap.toml`'s `prepend_keymap` array a line like `{ on = ["g", "d"], run = "cd D:/your/path", desc = "Go projects" },`（正斜杠）.

**C7c. `y` 退出跳转函数.** "退出 yazi 时，PowerShell 跟着停在你最后浏览的目录——单项体验提升最大的一个。" `AskUserQuestion`: **「加上（推荐）」**／「先不用」. If yes, show the function first, then:
```powershell
$func = @'

function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
'@
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
if (-not (Select-String -Path $PROFILE -Pattern 'function y \{' -Quiet)) {
    Add-Content -Path $PROFILE -Value $func -Encoding UTF8; "已加入 $PROFILE"
} else { "PROFILE 里已有 y 函数，未重复添加。" }
```
之后用 `y` 启动（`q` 退出并跳转，`Q` 退出不跳转）；新窗口或 `. $PROFILE` 生效。

**C7d. 快速跳转增强（可选项, fzf + zoxide）.** 说明："yazi 默认键位里 `z` 用 fzf 模糊查找、`Z` 用 zoxide 跳到常去的目录——但这两个工具本体需要安装，zoxide 还要在 PowerShell 里挂上钩子才会记录你去过哪。装上后，在终端里 cd 和在 yazi 里跳转会共用同一份'常去目录'记忆。" `AskUserQuestion`:
- **「装上（推荐——用过就回不去）」**
- 「先不用」

If yes:
```powershell
scoop install fzf zoxide
```
失败（网络）→ 如实报告、跳过本项、流程继续。成功 → hook zoxide into the profile（dedup-guarded）:
```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
if (-not (Select-String -Path $PROFILE -Pattern 'zoxide init' -Quiet)) {
    Add-Content -Path $PROFILE -Value "`nInvoke-Expression (& { (zoxide init powershell | Out-String) })" -Encoding UTF8
    "已在 PROFILE 挂上 zoxide"
} else { "PROFILE 已有 zoxide 初始化，未重复添加。" }
```
告知预期："新窗口生效。zoxide 的'常去目录'数据库是随你日常 cd 慢慢积累的——刚装好时按 `Z` 跳不出几个地方是正常的，用几天就顺了；`z`（fzf 模糊找）则立刻可用。"

## Phase C8 — Verify & teach

"关掉所有 PowerShell 窗口，开一个新的（环境变量和 PROFILE 都要新窗口才生效）。"

In the fresh window, have the user run `yazi`（or `y`）and confirm: 主题生效（完整档）；移动到一个 `.md` 文件，预览窗出现渲染后的 Markdown（若 C6 接入了）；图标与图片/PDF 预览正常如前。

Anything off → `../_shared/references/troubleshooting.md`（含 previewer 不生效、glow、主题没变化的对症行）。**Never claim done without this check.**

Then **always** show the cheat sheet `../_shared/references/yazi-cheatsheet.md`，并提一句：`~` 或 `F1` 在 yazi 里看完整帮助。Close warmly: 这套配置就是作者日常在用的形态——每个文件在 `%APPDATA%\yazi\config`，每一行都欢迎打开看、改成自己的口味；改坏了也没事，重跑 `/yazi-config` 即可复原。

---

# Bundled files（shared engine, `..\_shared\`）

- `scripts/verify-yazi.ps1` — the C0 gate（READY/NOT-READY + NETWORK line）.
- `scripts/install-preview-tools.ps1` — glow + CLICOLOR_FORCE（C5, optional item）.
- `config/package.toml` — **version-pinned manifest**（piper @598cdb6, catppuccin-mocha @36c49ac — the author-verified combination; C6a installs from this via `ya pkg install`）.
- `config/yazi-minimal.toml`, `config/yazi-complete.toml`, `config/keymap-complete.toml`, `config/theme.toml` — vendored tier templates.
- `references/troubleshooting.md`, `references/powershell-vs-bash.md`, `references/yazi-cheatsheet.md`.
