<!--
  README — yazi-windows-rescue
  Chinese section first, English section below.
-->

# yazi-windows-rescue

> **仅限 Windows。** 本 skill 使用 PowerShell、Scoop 和 Windows 专属路径，不适用于 macOS 或 Linux。
>
> [Jump to English](#english)

一个 [Claude Code](https://code.claude.com) skill，用于在 Windows 上 **诊断、清理并正确重装 [yazi](https://github.com/sxyazi/yazi) 文件管理器** —— 当之前（通常是 AI 帮忙）的安装把它弄坏了：打不开、无法运行、没有文件预览、图标全是方块（□）、或报 TOML 解析错误。

专为**中文、非技术用户**设计：全程用中文交流，每一步都用平实的语言解释，删除任何东西前都会先请你确认，并且始终把最安全的选项设为推荐默认。目标不只是"yazi 能跑起来"，而是"能跑、好看、而且你会用"。

---

## 它做什么

1. **一次诊断** yazi 是怎么装的、问题出在哪 —— 只读，不改动任何东西。
2. **开头先测网络** —— 用真正的 HTTPS 探测 scoop 要下载的 GitHub 端点，这样**在删除任何东西之前**就能发现国内/受限网络的问题，而不是装到一半才卡住。
3. **汇报**发现的情况，并征求你同意再继续。
4. **干净卸载**旧的安装（会先备份你的配置）。
5. **用 Scoop 重装**：yazi、你缺的预览依赖，**以及 Maple Mono NF CN 字体**，这样文件类型图标才会正常显示，而不是一堆方块——而且它自带完整中文（CJK），中英文 2:1 对齐，中文文件名和图标用同一套字体渲染。
6. **配好预览**（`YAZI_FILE_ONE`），并指导你把终端字体设成那个 Nerd Font。
7. **写入最小化配置**，然后**推荐 Catppuccin 主题**和 **`y` 退出跳转快捷命令**。
8. **验证** yazi 能运行、图标能显示、预览能工作 —— 最后给你一份**基本操作速查表**。

每个阶段之间都会停下来等你确认，绝不自作主张。

### 相比"随便重装一遍"改进了什么

- **中文优先。** 全程使用简体中文交流。
- **删除前先过网络闸门。** 不再出现"删掉了 yazi，结果新的下不下来"的惨剧。对 Clash/V2Ray 用户附带了 `scoop config proxy ...` 的代理配置指引。
- **Nerd Font 当作依赖处理** —— 自动安装 **Maple Mono NF CN**（Win10 1809+/Win11 按用户安装，无需管理员），并给出在终端里**选用**该字体的清晰步骤，因为光装字体不选用，图标依然是方块。选 Maple Mono NF CN 是因为它一套字体同时搞定图标和中文。
- **默认提供 Catppuccin Mocha** 主题（写成一份只含 `[flavor]` 的干净 `theme.toml`）。
- **真正的收尾引导：** 一份基本操作速查表，以及人见人爱的 `y` 退出跳转快捷命令。

## 前提条件

- Windows 10 / 11
- [Claude Code](https://code.claude.com)（命令行版）
- `git`（用来下载本技能）
- **PowerShell 7+（pwsh）** 用于安装步骤。没有也没关系 —— skill 会自动检测并引导你安装（诊断步骤可在系统自带的 PowerShell 5.1 上运行，所以随便用哪个都能开始）。推荐 PowerShell 7：它对 UTF-8 / 中文的处理好得多，也避免了许多旧版本的坑。

## 安装与使用

有两种安装方式。**如果你只想修一次 yazi、不想留下任何东西，使用方式 A。**

### 方式 A —— 临时使用（推荐，用于一次性修复）

skill 只存在于一个临时文件夹里，用完后删掉，不会有任何残留。打开 **PowerShell**，**按顺序**执行：

```powershell
# 1. 新建一个临时工作文件夹，并进入它
mkdir "$env:USERPROFILE\Desktop\yazi-fix"
cd "$env:USERPROFILE\Desktop\yazi-fix"

# 2. 把 skill 下载到该文件夹的「项目级技能」位置
#    （路径必须正好是 .claude\skills\yazi-windows-rescue）
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills\yazi-windows-rescue"

# 3. 现在，从该文件夹内启动 Claude Code
claude
```

> **顺序很重要。** 必须先建好 `.claude\skills\...` 文件夹，*再*启动 Claude Code。Claude Code 只会识别「会话开始时就已存在」的新 skill 目录。如果先启动了 `claude`、之后才 clone，则需要重启它才能生效。

首次从该文件夹启动时，Claude Code 可能会问你是否信任该工作区 —— 选「是」（这是你自己的文件夹）。然后告诉它你的问题，例如：

> 我的 yazi 装好了但是打不开 / 没有预览 / 图标全是方块，请帮我清理干净并重新正确安装。

用完之后，删除整个文件夹，不留任何痕迹：

```powershell
cd "$env:USERPROFILE\Desktop"
Remove-Item "$env:USERPROFILE\Desktop\yazi-fix" -Recurse -Force
```

### 方式 B —— 长期安装（在所有项目中均可用）

（其实没必要，这本就该是一个一次性的修复工具，但还是给出方法。）装到你的「个人技能」文件夹：

```powershell
git clone https://github.com/karenepitaya/yazi-windows-rescue.git "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
```

重启 Claude Code，运行 `/skills` 确认列表中有 `yazi-windows-rescue`。以后更新：

```powershell
cd "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
git pull
```

## 两种启动方式

1. **直接描述问题** —— 例如「我的 yazi 打不开 / 没有预览 / 图标是方块」。Claude Code 会自动识别并启动。
2. **输入斜杠命令** `/yazi-windows-rescue` 回车。开始输入 `/yazi` 时会出现在自动补全里。

两种方式效果完全相同。

## 目录结构

```
yazi-windows-rescue/
├── SKILL.md                      # Claude 遵循的主流程
├── scripts/
│   ├── diagnose.ps1              # 只读的一键诊断（含 HTTPS 网络测试）
│   ├── install-deps.ps1          # 安装缺失依赖 + Maple Mono NF CN 字体；设置 YAZI_FILE_ONE
│   └── set-yazi-file-one.ps1     # 独立的文件预览配置辅助脚本
└── reference/
    ├── powershell-vs-bash.md     # bash 到 PowerShell 命令对照
    ├── troubleshooting.md        # 症状→修复对照表（图标、网络、预览）及官方来源
    └── yazi-cheatsheet.md        # 收尾时展示的基本操作速查表
```

## 来源

本 skill 参考 yazi 官方文档与仓库，而非凭记忆：
[文档](https://yazi-rs.github.io/) · [安装](https://yazi-rs.github.io/docs/installation) · [Flavors](https://yazi-rs.github.io/docs/flavors/overview) · [源码 (MIT)](https://github.com/sxyazi/yazi) · [Nerd Fonts scoop bucket](https://github.com/matthewjberger/scoop-nerd-fonts) · [Maple Mono](https://github.com/subframe7536/maple-font)

关于 skill 的规范设计来源于：[一份指南](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) 和[官方文档](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)。

## 许可证

MIT

<br>

---

<br>

# English

> **Windows only.** This skill uses PowerShell, Scoop, and Windows-specific paths. It is not for macOS or Linux.

A [Claude Code](https://code.claude.com) skill that **diagnoses, cleans up, and correctly reinstalls the [yazi](https://github.com/sxyazi/yazi) file manager on Windows** when a previous (often AI-assisted) install left it broken — won't run, won't open, no file previews, shows boxes (□) instead of icons, or TOML parse errors.

Built for **non-technical, Chinese-speaking users**: the whole conversation happens in Chinese, every step is explained in plain language, you confirm before anything is deleted, and the safest option is always the recommended default. The goal is not just "yazi runs" but "yazi runs, looks good, and you know how to use it."

---

## What it does

1. **Diagnoses** how yazi was installed and what's wrong — read-only, changes nothing.
2. **Checks the network up front** — a real HTTPS test against the GitHub endpoints scoop downloads from, so a restricted/China network is caught *before* anything is removed (not halfway through).
3. **Reports** the findings in plain language and asks for your go-ahead.
4. **Cleanly removes** the old install (backing up your config first).
5. **Reinstalls** with Scoop: yazi, the preview dependencies you're missing, **and the Maple Mono NF CN font** so file-type icons render instead of showing as boxes — and because it bundles full CJK with 2:1 alignment, Chinese filenames and icons come from one font.
6. **Wires up previews** (`YAZI_FILE_ONE`) and points your terminal at the Nerd Font.
7. **Writes a minimal config**, then **offers the Catppuccin theme** and the **`y` quit-to-cd shortcut**.
8. **Verifies** that yazi runs, icons show, and previews work — then hands you a short **cheat sheet** of the basic keys.

It pauses for your confirmation between every phase and never improvises.

### What's improved over a plain reinstall

- **Chinese-first.** The entire interaction is conducted in 简体中文.
- **Network gate before deletion.** No more "deleted yazi, then couldn't download the new one." Includes proxy guidance (`scoop config proxy ...`) for users behind Clash/V2Ray.
- **Nerd Font handled as a dependency** — installs **Maple Mono NF CN** automatically (per-user, no admin on Win10 1809+/Win11) — plus clear steps to select it in the terminal, because installing the font alone doesn't fix the icons. Maple Mono NF CN is chosen because one font covers both icons and CJK.
- **Catppuccin Mocha** offered by default (written as a clean `theme.toml` with only `[flavor]`).
- **A real onboarding ending:** a basic-keys cheat sheet and the beloved `y` quit-to-cd shortcut.

## Requirements

- Windows 10 / 11
- [Claude Code](https://code.claude.com) (CLI)
- `git` (to download this skill)
- **PowerShell 7+ (pwsh)** for the install steps. Don't have it? That's fine — the skill detects this and walks you through installing it (the diagnosis step runs on the built-in PowerShell 5.1, so you can start either way). PowerShell 7 is recommended because it handles UTF-8 / Chinese text far better and avoids many legacy quirks.

## Install and use

There are two ways to install. **If you only want to fix yazi once and not keep anything around, use Option A.**

### Option A — Temporary (recommended for a one-time fix)

This keeps your setup clean: the skill lives only inside a throwaway folder, and when you're done you delete that folder. Nothing is left behind.

Open **PowerShell** and run these in order:

```powershell
# 1. Make a temporary working folder and go into it
mkdir "$env:USERPROFILE\Desktop\yazi-fix"
cd "$env:USERPROFILE\Desktop\yazi-fix"

# 2. Download the skill INTO this folder's project-level skills location
#    (the path must be exactly .claude\skills\yazi-windows-rescue)
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills\yazi-windows-rescue"

# 3. NOW start Claude Code from inside this folder
claude
```

> **Order matters.** Create the `.claude\skills\...` folder *before* starting Claude Code. Claude Code only picks up a brand-new skills directory that already existed when the session started. If you start `claude` first and clone afterward, you must restart it.

On first launch from this folder, Claude Code may ask you to trust the workspace — say yes (it's your own folder). Then tell Claude Code what's wrong, for example:

> 我的 yazi 装好了但是打不开 / 没有预览 / 图标全是方块，请帮我清理干净并重新正确安装。

When you're finished, delete the whole folder and no trace is left:

```powershell
cd "$env:USERPROFILE\Desktop"
Remove-Item "$env:USERPROFILE\Desktop\yazi-fix" -Recurse -Force
```

### Option B — Permanent (available in every project)

Install into your personal skills folder so it's always available:

```powershell
git clone https://github.com/karenepitaya/yazi-windows-rescue.git "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
```

Restart Claude Code, then run `/skills` to confirm `yazi-windows-rescue` is listed. Update later with:

```powershell
cd "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
git pull
```

## Two ways to start it

1. **Just describe the problem in plain language** — e.g. "我的 yazi 打不开 / 没有预览 / 图标是方块". Claude Code recognizes it and starts the skill automatically.
2. **Type the slash command** `/yazi-windows-rescue` and press Enter. Start typing `/yazi` and it appears in the autocomplete menu.

Both do exactly the same thing.

## Structure

```
yazi-windows-rescue/
├── SKILL.md                      # the procedure Claude follows
├── scripts/
│   ├── diagnose.ps1              # read-only one-shot diagnosis (incl. HTTPS network test)
│   ├── install-deps.ps1          # installs missing deps + Maple Mono NF CN; sets YAZI_FILE_ONE
│   └── set-yazi-file-one.ps1     # standalone helper to wire up file previews
└── reference/
    ├── powershell-vs-bash.md     # bash to PowerShell command translations
    ├── troubleshooting.md        # symptom to fix table (icons, network, previews), plus official sources
    └── yazi-cheatsheet.md        # the basic-keys map shown at the end
```

## Sources

Commands follow yazi's official documentation and repository, not assumptions:
[docs](https://yazi-rs.github.io/) · [installation](https://yazi-rs.github.io/docs/installation) · [flavors](https://yazi-rs.github.io/docs/flavors/overview) · [source (MIT)](https://github.com/sxyazi/yazi) · [Nerd Fonts scoop bucket](https://github.com/matthewjberger/scoop-nerd-fonts) · [Maple Mono](https://github.com/subframe7536/maple-font)

## License

MIT
