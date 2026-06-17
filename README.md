# yazi-windows-rescue

一套面向 Windows 的 Claude Code skills，用来诊断、重装和配置 [Yazi](https://yazi-rs.github.io/)。

它适合两种情况：

- Yazi 没装好、命令打不开，或者配置已经乱了。
- Yazi 能正常启动，但你想一次配好主题、预览、快捷键和 `y` 跳转。

整个项目只面向 Windows，默认使用 PowerShell、Scoop 和 Claude Code。

## 开始之前

请先确认电脑上有 Git 和 Claude Code：

```powershell
git --version
claude --version
```

缺少的话，先安装 [Git for Windows](https://git-scm.com/downloads/win) 和 [Claude Code](https://code.claude.com/docs/en/setup)。

## 30 秒开始

### 临时使用，推荐第一次体验

下面的命令会在系统临时目录创建一个独立工作区，不会覆盖桌面上的同名文件夹：

```powershell
$work = Join-Path $env:TEMP "yazi-fix-$(Get-Date -Format yyyyMMdd-HHmmss)"
New-Item -ItemType Directory -Path "$work\.claude" -Force | Out-Null
Set-Location $work
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills"
claude
```

进入 Claude Code 后，直接输入：

```text
/yazi-install
/yazi-config
```

确认 Yazi 可以正常使用后，退出 Claude Code，再清理临时工作区：

```powershell
Set-Location $env:TEMP
Remove-Item -LiteralPath $work -Recurse -Force
```

这里只会删除刚才生成的临时目录。已经安装的 Yazi、依赖和配置都会保留。

### 长期安装

如果你想在所有项目里使用这些 skills，可以把它们复制到 Claude Code 的用户级目录：

```powershell
$src = Join-Path $env:TEMP "yazi-windows-rescue-$(Get-Date -Format yyyyMMdd-HHmmss)"
git clone https://github.com/karenepitaya/yazi-windows-rescue.git $src
$dst = "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

foreach ($name in @("yazi-detect", "yazi-install", "yazi-config", "terminal-boost", "_shared")) {
    $target = Join-Path $dst $name
    if (Test-Path $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }
    Copy-Item -Path (Join-Path $src $name) -Destination $target -Recurse
}

Remove-Item -LiteralPath $src -Recurse -Force
```

这段命令只会替换本项目的四个目录，不会动你已有的其他 skills。重新打开 Claude Code 后即可使用。

## 我该运行哪个命令

| 命令 | 适合什么时候用 | 会修改系统吗 |
| --- | --- | --- |
| `/yazi-detect` | 不确定哪里出了问题，想先做检查 | 不会，只读诊断 |
| `/yazi-install` | Yazi 没装、打不开，或想彻底重装 | 会，清理旧安装并通过 Scoop 重装 |
| `/yazi-config` | Yazi 已经能运行，想补齐日常配置 | 会，先备份再写入配置 |
| `/terminal-boost` | 不需要 yazi，只想增强终端体验（ls/cat/fzf/zoxide） | 会，安装工具并写入 profile block |

大多数人的顺序是：

```text
/yazi-install
/yazi-config
```

如果你不确定现状，先运行 `/yazi-detect`。

## 它会不会乱改

这套 skills 对清理和写配置做了几层限制：

- `/yazi-detect` 全程只读，不安装、不删除，也不改配置。
- `/yazi-install` 会先检查 GitHub、Scoop、Gitee 和 jsDelivr。四个端点全部可用后，才允许进入清理阶段。
- `/yazi-config` 只在 Yazi 健康时运行，并会先备份现有配置。
- 完整配置遵循一个原则：组件先安装成功，配置文件才会引用它。安装失败的插件、主题或字体不会留下失效配置。
- 清理阶段只有在确认系统中不再残留可执行的 Yazi 时才会显示 `DONE`，部分清理只会显示 `PARTIAL`。

## 完整配置会得到什么

在 `/yazi-config` 中选择完整档后，会依次尝试配置：

- Catppuccin Mocha 主题。
- Markdown 预览，使用 `piper.yazi` 和 `glow`。
- 常用快捷键，包括 `!` 打开 PowerShell、`g h` 返回用户目录，以及可选的 `g p` 项目目录跳转。
- 编辑器自动检测，优先使用系统里已经存在的编辑器。
- PowerShell 的 `y` 包装函数。退出 Yazi 后，终端会自动进入你最后浏览的目录。
- 中文快捷键帮助。当前快照只对应 Yazi `26.5.6`，其他版本会自动回退到英文模板，避免写入不匹配的键位。

安装流程还会处理 Maple Mono NF CN 字体，以及 Yazi 常用的预览和搜索依赖，包括 `fd`、`ripgrep`、`7zip`、`ffmpeg`、`poppler`、`resvg`、`imagemagick`、`jq` 和 Git。`fzf`、`zoxide` 属于可选增强项。

## 常见用法

你可以直接描述需求，不必记住所有参数：

```text
运行 /yazi-detect，告诉我哪里有问题，但不要修改系统
运行 /yazi-install，彻底重装 Yazi
运行 /yazi-config，使用完整配置
运行 /yazi-config，只写最小配置
```

典型场景：

1. 只想确认环境：`/yazi-detect`
2. Yazi 已损坏：`/yazi-install`，然后运行 `/yazi-config`
3. Yazi 能用，只想美化和补功能：直接运行 `/yazi-config`

如果命令执行中断，重新运行对应 skill 即可。安装和配置脚本都按可重复执行设计。

## 更新和移除

临时使用时，删除 `$work` 指向的临时目录就算移除 skills，不影响已经安装的 Yazi。

长期安装时，重新运行上面的复制命令即可更新。需要彻底移除时，只删除下面四个目录：

```text
%USERPROFILE%\.claude\skills\yazi-detect
%USERPROFILE%\.claude\skills\yazi-install
%USERPROFILE%\.claude\skills\yazi-config
%USERPROFILE%\.claude\skills\terminal-boost
%USERPROFILE%\.claude\skills\_shared
```

## 给维护者

```text
yazi-windows-rescue/
├── yazi-detect/
│   └── SKILL.md
├── yazi-install/
│   └── SKILL.md
├── yazi-config/
│   └── SKILL.md
├── terminal-boost/
│   └── SKILL.md
└── _shared/
    ├── scripts/
    ├── config/
    └── references/
```

`_shared` 保存三个 skills 共用的脚本、模板和参考资料。Agent Skills 规范通常建议每个 skill 自包含，本项目为了避免复制多份 PowerShell 脚本，明确依赖 Claude Code 对同级目录的解析方式。

发布前请运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\_shared\scripts\validate-release.ps1
```

## 资料来源

- [Yazi 官方安装文档](https://yazi-rs.github.io/docs/installation/)
- [Yazi 官方 Windows 配置指南](https://yazi-rs.github.io/docs/installation/#windows)
- [Yazi 官方配置文档](https://yazi-rs.github.io/docs/configuration/overview/)
- [Agent Skills 规范](https://agentskills.io/specification)

本项目采用 [MIT License](LICENSE)。

---

# English summary

`yazi-windows-rescue` is a Windows-only Claude Code skill suite for diagnosing, reinstalling, and configuring Yazi.

## Prerequisites

Install [Git for Windows](https://git-scm.com/downloads/win) and [Claude Code](https://code.claude.com/docs/en/setup), then verify:

```powershell
git --version
claude --version
```

## Quick start

```powershell
$work = Join-Path $env:TEMP "yazi-fix-$(Get-Date -Format yyyyMMdd-HHmmss)"
New-Item -ItemType Directory -Path "$work\.claude" -Force | Out-Null
Set-Location $work
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills"
claude
```

Inside Claude Code, run:

```text
/yazi-install
/yazi-config
```

Four commands, each with a separate job:

| Command | Purpose |
| --- | --- |
| `/yazi-detect` | Read-only diagnosis |
| `/yazi-install` | Connectivity checks, cleanup, Scoop installation, dependencies, and verification |
| `/yazi-config` | Backed-up minimal or complete configuration |
| `/terminal-boost` | Modern CLI tools and terminal enhancements without yazi |

The installer checks all required network endpoints before cleanup. The configurator installs components before referencing them, so failed optional components do not leave broken configuration behind.

For implementation details and release checks, see the Chinese documentation above.
