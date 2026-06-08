<!--
  README — yazi-windows-rescue
  English section first, Chinese section below. / 英文在前,中文在后。
-->

# yazi-windows-rescue

> **Windows only.** This skill uses PowerShell, Scoop, and Windows-specific paths. It is not for macOS or Linux.
>
> English below. [跳到中文说明](#中文说明)

A [Claude Code](https://code.claude.com) skill that **diagnoses, cleans up, and correctly reinstalls the [yazi](https://github.com/sxyazi/yazi) file manager on Windows** when a previous (often AI-assisted) install left it broken — won't run, won't open, no file previews, or TOML parse errors.

Built for **non-technical users**: every step is explained in plain language, you confirm before anything is deleted, and the safest option is always the recommended default.

---

## What it does

1. **Diagnoses** how yazi was installed and what is wrong — read-only, changes nothing.
2. **Reports** the findings in plain language and asks for your go-ahead.
3. **Cleanly removes** the old install (backing up your config first).
4. **Reinstalls** with Scoop, installs only the preview dependencies you are missing, wires up file previews, and writes a minimal config.
5. **Verifies** that yazi runs and previews work.

It pauses for your confirmation between every step and never improvises.

## Requirements

- Windows 10 / 11
- [Claude Code](https://code.claude.com) (CLI)
- `git` (to download this skill)

## Install and use

There are two ways to install. **If you only want to fix yazi once and not keep anything around, use Option A.**

### Option A — Temporary (recommended for a one-time fix)

This keeps your setup clean: the skill lives only inside a throwaway folder, and when you are done you delete that folder. Nothing is left behind.

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

On first launch from this folder, Claude Code may ask you to trust the workspace — say yes (it is your own folder). Then tell Claude Code what is wrong, for example:

> My yazi was installed but it will not open / has no previews — please clean it up and reinstall it properly.

When you are finished, delete the whole folder and no trace is left:

```powershell
cd "$env:USERPROFILE\Desktop"
Remove-Item "$env:USERPROFILE\Desktop\yazi-fix" -Recurse -Force
```

### Option B — Permanent (available in every project)

Install into your personal skills folder so it is always available:

```powershell
git clone https://github.com/karenepitaya/yazi-windows-rescue.git "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
```

Restart Claude Code, then run `/skills` to confirm `yazi-windows-rescue` is listed. Update later with:

```powershell
cd "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
git pull
```

## Two ways to start it

Once installed (either option above), there are two ways to trigger the skill:

1. **Just describe the problem in plain language** — e.g. "my yazi won't open / has no previews." Claude Code recognizes it and starts the skill automatically.
2. **Type the slash command** `/yazi-windows-rescue` and press Enter. The command name comes from the skill's folder name, so it works as soon as the skill is installed. Start typing `/yazi` and it appears in the autocomplete menu.

Both do exactly the same thing. The slash command is handy when you want to start it deliberately; plain language is easier if you don't remember the name.

## How it works (where the skill lives)

Claude Code finds skills in a `.claude/skills/<name>/` folder. **Personal** skills go in `~/.claude/skills/` and are available everywhere; **project** skills go in a `.claude/skills/` inside whatever folder you start Claude Code from, and apply only there. Option A uses the project location inside a temporary folder, which is why it leaves nothing behind once deleted.

## Structure

```
yazi-windows-rescue/
├── SKILL.md                      # the procedure Claude follows
├── scripts/
│   ├── diagnose.ps1              # read-only one-shot diagnosis
│   └── install-deps.ps1          # checks deps, installs only what is missing
└── reference/
    ├── powershell-vs-bash.md     # bash to PowerShell command translations
    └── troubleshooting.md        # symptom to fix table, plus official sources
```

## Sources

Commands follow yazi's official documentation and repository, not assumptions:
[docs](https://yazi-rs.github.io/) · [installation](https://yazi-rs.github.io/docs/installation) · [source (MIT)](https://github.com/sxyazi/yazi)

## License

MIT

<br>

---

<br>

# 中文说明

> **仅限 Windows。** 本技能使用 PowerShell、Scoop 和 Windows 专属路径,不适用于 macOS 或 Linux。

一个 [Claude Code](https://code.claude.com) 技能,用于在 Windows 上 **诊断、清理并正确重装 [yazi](https://github.com/sxyazi/yazi) 文件管理器** —— 当之前(通常是 AI 帮忙)的安装把它弄坏了:打不开、无法运行、没有文件预览、或报 TOML 解析错误。

专为**非技术用户**设计:每一步都用平实的语言解释,删除任何东西前都会先请你确认,并且始终把最安全的选项设为推荐默认。

---

## 它做什么

1. **诊断** yazi 是怎么装的、问题出在哪 —— 只读,不改动任何东西。
2. **用平实的语言汇报**发现的情况,并征求你同意再继续。
3. **干净卸载**旧的安装(会先备份你的配置)。
4. **用 Scoop 重装**,只安装你缺的预览依赖,配好文件预览,写入一份最小化配置。
5. **验证** yazi 能运行、预览能正常工作。

每一步之间都会停下来等你确认,绝不自作主张。

## 前提条件

- Windows 10 / 11
- [Claude Code](https://code.claude.com)(命令行版)
- `git`(用来下载本技能)

## 安装与使用

有两种安装方式。**如果你只想修一次 yazi、不想留下任何东西,使用方式 A。**

### 方式 A —— 临时使用(推荐,用于一次性修复)

这种方式能保持环境干净:技能只存在于一个临时文件夹里,用完后删掉该文件夹,不会有任何残留。

打开 **PowerShell**,**按顺序**执行:

```powershell
# 1. 新建一个临时工作文件夹,并进入它
mkdir "$env:USERPROFILE\Desktop\yazi-fix"
cd "$env:USERPROFILE\Desktop\yazi-fix"

# 2. 把技能下载到该文件夹的「项目级技能」位置
#    (路径必须正好是 .claude\skills\yazi-windows-rescue)
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills\yazi-windows-rescue"

# 3. 现在,从该文件夹内启动 Claude Code
claude
```

> **顺序很重要。** 必须先建好 `.claude\skills\...` 文件夹,*再*启动 Claude Code。Claude Code 只会识别「会话开始时就已存在」的新技能目录。如果先启动了 `claude`、之后才 clone,则需要重启它才能生效。

从该文件夹首次启动时,Claude Code 可能会询问你是否信任该工作区 —— 选择「是」(这是你自己的文件夹)。然后告诉 Claude Code 你的问题,例如:

> 我的 yazi 装了但是打不开 / 没有预览,请帮我清理干净并重新正确安装。

用完之后,删除整个文件夹,不留任何痕迹:

```powershell
cd "$env:USERPROFILE\Desktop"
Remove-Item "$env:USERPROFILE\Desktop\yazi-fix" -Recurse -Force
```

### 方式 B —— 长期安装(在所有项目中均可用)

装到你的「个人技能」文件夹,使其始终可用:

```powershell
git clone https://github.com/karenepitaya/yazi-windows-rescue.git "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
```

重启 Claude Code,运行 `/skills` 确认列表中有 `yazi-windows-rescue`。以后更新:

```powershell
cd "$env:USERPROFILE\.claude\skills\yazi-windows-rescue"
git pull
```

## 两种启动方式

安装好之后(上面两种方式皆可),有两种方式触发本技能:

1. **直接用平实的语言描述问题** —— 例如「我的 yazi 打不开 / 没有预览」。Claude Code 会自动识别并启动本技能。
2. **输入斜杠命令** `/yazi-windows-rescue` 然后回车。命令名来自技能的文件夹名,所以技能一装好就能用。开始输入 `/yazi` 时它会出现在自动补全菜单里。

两种方式效果完全相同。想要明确地手动启动时,斜杠命令很方便;如果记不住命令名,用平实的语言描述更省事。

## 工作原理(技能存放在哪)

Claude Code 会从 `.claude/skills/<名字>/` 文件夹中查找技能。**个人级**技能放在 `~/.claude/skills/`,在任何地方都可用;**项目级**技能放在「你启动 Claude Code 所在文件夹」内的 `.claude/skills/`,且仅在该处生效。方式 A 用的就是临时文件夹内的项目级位置 —— 这就是删除该文件夹后不留任何残留的原因。

## 目录结构

```
yazi-windows-rescue/
├── SKILL.md                      # Claude 遵循的主流程
├── scripts/
│   ├── diagnose.ps1              # 只读的一键诊断脚本
│   └── install-deps.ps1          # 检测依赖,只安装缺少的
└── reference/
    ├── powershell-vs-bash.md     # bash 到 PowerShell 命令对照
    └── troubleshooting.md        # 症状到修复对照表,以及官方来源
```

## 来源

所有命令均依据 yazi 官方文档与仓库,而非凭空假设:
[文档](https://yazi-rs.github.io/) · [安装](https://yazi-rs.github.io/docs/installation) · [源码(MIT)](https://github.com/sxyazi/yazi)

## 许可证

MIT
