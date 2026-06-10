<!--
  README — yazi-windows-rescue（三命令套件 / three-command suite）
  中文在前，English below.
-->

# yazi-windows-rescue

> **仅限 Windows。** 本套件使用 PowerShell、Scoop 和 Windows 专属路径，不适用于 macOS 或 Linux。
>
> [Jump to English](#english)

一套 [Claude Code](https://code.claude.com) skill，把 Windows 上的 [yazi](https://github.com/sxyazi/yazi) 文件管理器从「坏掉/没装」一路带到「能用、好看、顺手」。专为**中文、非技术用户**设计：全程中文交流、每步确认、删除先备份、最安全的选项永远是推荐默认。

## 三个命令

| 命令 | 干什么 | 前置 |
|---|---|---|
| **`/yazi-detect`** | 只读诊断：装没装、怎么装的、坏在哪、字体/网络/预览状态。**什么都不改。** | 无，随时可跑 |
| **`/yazi-install`** | 自带诊断 → **删除前先过网络闸门** → 清理 → scoop 重装（依赖 + Maple Mono NF CN 字体）→ 最小配置 → 验证。失败时永远给出路：对症修复，或**一键清理恢复干净状态**重新来过。 | 无（自含诊断，不假设跑过 detect） |
| **`/yazi-config`** | 把「能跑」变成「成品」：Catppuccin 主题、预览窗渲染 Markdown（piper + glow）、高价值快捷键、接入你的编辑器、`y` 退出跳转。分**最小/完整**两档，可反复跑、可切档、每次先备份。 | yazi 必须已装好且健康——开头自动验证，不通过会拒绝并指回 `/yazi-install` |

**核心原则：安装成功是配置的前提。** 安装没验证通过，配置一律不做；增强组件（主题/插件/工具）逐个防御式安装——哪个下载失败就跳过哪个并如实报告，**绝不把缺失的组件写进配置**（那等于亲手制造下一个启动报错）。

## 安装本套件

### 方式 A —— 临时使用（推荐，一次性修复）

```powershell
# 1. 新建临时文件夹并进入
mkdir "$env:USERPROFILE\Desktop\yazi-fix"
cd "$env:USERPROFILE\Desktop\yazi-fix"

# 2. 把整个套件 clone 成该文件夹的「项目级技能目录」
git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills"

# 3. 从该文件夹启动 Claude Code
claude
```

> **顺序很重要：** 先 clone、再启动 `claude`。Claude Code 只识别会话开始时已存在的技能目录。
> 仓库根目录直接就是三个 skill 文件夹（外加共享引擎 `_shared/`），所以 clone 成 `.claude\skills` 后，`/yazi-detect`、`/yazi-install`、`/yazi-config` 三个命令即刻可用（输入 `/yazi` 看自动补全）。

用完删掉整个文件夹，不留痕迹：

```powershell
cd "$env:USERPROFILE\Desktop"
Remove-Item "$env:USERPROFILE\Desktop\yazi-fix" -Recurse -Force
```

### 方式 B —— 长期安装

把仓库 clone 到任意位置，再把四个目录拷进个人技能文件夹：

```powershell
git clone https://github.com/karenepitaya/yazi-windows-rescue.git "$env:USERPROFILE\yazi-windows-rescue"
$dst = "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
foreach ($d in "yazi-detect","yazi-install","yazi-config","_shared") {
    Copy-Item "$env:USERPROFILE\yazi-windows-rescue\$d" "$dst\$d" -Recurse -Force
}
```

重启 Claude Code，`/skills` 里应能看到三个命令。更新：在 clone 目录 `git pull` 后重复上面的拷贝。

## 使用

装好后两种触发方式：直接用平实语言描述（"我的 yazi 打不开 / 图标全是方块 / 帮我配置好看点"），Claude Code 会自动选中对应 skill；或者直接敲 `/yazi-detect`、`/yazi-install`、`/yazi-config`。

典型路径：**朋友的电脑坏了** → `/yazi-install`（自含诊断）→ 成功后它会提示跑 `/yazi-config` → 选「完整推荐档」→ 拿到和作者同款的成品。**只想看看哪儿坏了** → `/yazi-detect`。**装好了想换口味/复原** → 重跑 `/yazi-config` 切档。

## 目录结构

```
yazi-windows-rescue/            ← clone 成 .claude\skills
├── yazi-detect/SKILL.md        # /yazi-detect：只读诊断
├── yazi-install/SKILL.md       # /yazi-install：闸门 + 清理 + 重装 + 验证
├── yazi-config/SKILL.md        # /yazi-config：分档配置器（最小/完整）
├── _shared/                    # 共享引擎（单一事实源，三入口共用）
│   ├── scripts/
│   │   ├── diagnose.ps1              # 只读一键诊断（HTTPS 网络测试、字体、pwsh…）
│   │   ├── install-deps.ps1          # 缺啥装啥 + Nerd Font + YAZI_FILE_ONE
│   │   ├── set-yazi-file-one.ps1     # 预览接线的独立兜底
│   │   ├── verify-yazi.ps1           # config 的前置闸门（READY/NOT-READY）
│   │   ├── install-preview-tools.ps1 # glow + CLICOLOR_FORCE
│   │   └── cleanup.ps1               # 一键清理恢复干净状态
│   ├── config/                 # vendored 配置模板（最小档 / 完整档）
│   └── references/             # PS↔bash 对照、症状→修复表、操作速查表
└── README.md
```

> 设计说明：[Agent Skills 规范](https://agentskills.io/specification)建议每个 skill 自包含、引用不出根目录。本套件刻意偏离这一条——三个入口共享 `_shared/` 引擎（路径 `${CLAUDE_SKILL_DIR}\..\_shared\`），以换取**单一事实源**：脚本与参考只存在一份，永不漂移。Claude Code 对此解析无碍。

## 完整档里有什么（以及为什么）

- **版本钉死的组件清单**——主题与插件不是"装最新、碰运气"，而是从套件自带的 `package.toml`（rev + hash 精确到提交）用 `ya pkg install` 安装：每台机器装到的都是作者亲手验证过的同一组合。升级是显式动作：作者本地先升、先验、再更新清单。
- **Catppuccin Mocha** 主题——theme.toml 只含 `[flavor]`（官方规范），清单安装成功后才落盘。
- **Markdown 预览（可选项）**——官方维护的 [piper](https://github.com/yazi-rs/plugins) 插件 + [glow](https://github.com/charmbracelet/glow)。Windows 适配：官方示例的 `CLICOLOR_FORCE=1` POSIX 前缀改为持久用户环境变量。
- **快速跳转增强（可选项）**——fzf（`z` 模糊查找）+ zoxide（`Z` 跳常去目录，自动在 PowerShell 挂钩、终端与 yazi 共享目录记忆）。
- **`!` 当前目录开 PowerShell、`g h` 回家**——通用高价值键位；个人化跳转（如项目目录）按询问可选添加。
- **编辑器接入**——检测 VS Code/Neovim 并询问，记事本永远保底。
- **`y` 退出跳转函数**——退出 yazi 后 shell 停在最后浏览的目录。
- 以上每一项都遵循**装好才引用**：组件安装失败就跳过该项配置，绝不写半截；可选项当时跳过的，以后重跑 `/yazi-config` 随时补上。

## 来源

[yazi 文档](https://yazi-rs.github.io/) · [安装](https://yazi-rs.github.io/docs/installation) · [Flavors](https://yazi-rs.github.io/docs/flavors/overview) · [官方插件仓库](https://github.com/yazi-rs/plugins) · [yazi 源码 (MIT)](https://github.com/sxyazi/yazi) · [Nerd Fonts scoop bucket](https://github.com/matthewjberger/scoop-nerd-fonts)

Skill 规范：[Agent Skills Specification](https://agentskills.io/specification) · [Anthropic Skills 文档](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) · [OpenAI Codex Skills](https://developers.openai.com/codex/skills)

## 许可证

MIT

<br>

---

<br>

# English

> **Windows only.** PowerShell, Scoop, and Windows-specific paths throughout.

A suite of [Claude Code](https://code.claude.com) skills that takes the [yazi](https://github.com/sxyazi/yazi) file manager on Windows from "broken or absent" all the way to "working, beautiful, and pleasant" — built for non-technical, Chinese-speaking users (the entire interaction runs in Simplified Chinese), with confirmation at every step, backups before every deletion, and the safest option always the recommended default.

## The three commands

| Command | What it does | Precondition |
|---|---|---|
| **`/yazi-detect`** | Read-only diagnosis: install method, config state, font/network/preview wiring. Changes nothing. | None |
| **`/yazi-install`** | Self-contained: own diagnosis → **network gate before any deletion** → clean removal → scoop install (deps + Maple Mono NF CN) → minimal config → verify. On failure, always an exit: targeted fixes or a **one-shot cleanup** back to a clean slate. | None |
| **`/yazi-config`** | Turns "it runs" into a finished product: Catppuccin theme, Markdown rendered in the preview pane (piper + glow), high-value keybindings, your editor, the `y` quit-to-cd function. Two tiers (minimal / complete), re-runnable, backs up first every run. | A healthy yazi — verified up front; refuses and points to `/yazi-install` otherwise |

**Core principle: installation must succeed before configuration happens.** Enhancements install defensively, one at a time — anything that fails to download is skipped and reported, and is **never referenced in config** (a config pointing at absent components is a startup error factory).

## Installing the suite

**Option A — temporary (recommended for a one-time fix):** make a throwaway folder, `git clone https://github.com/karenepitaya/yazi-windows-rescue.git ".claude\skills"` inside it, then start `claude` from that folder (clone BEFORE starting). The repo root *is* the skills directory: three skill folders plus the shared `_shared/` engine, so all three slash commands register immediately. Delete the folder afterwards and nothing remains.

**Option B — permanent:** clone anywhere, then copy `yazi-detect`, `yazi-install`, `yazi-config`, and `_shared` into `~\.claude\skills\`. Update via `git pull` + re-copy.

## Design notes

- Theme and plugins install from a vendored, **version-pinned `package.toml` manifest** (rev + hash per component) via `ya pkg install` — every machine gets the exact author-verified combination, never "whatever is latest". Upgrades are explicit: bump locally, verify, update the manifest.
- The [Agent Skills spec](https://agentskills.io/specification) recommends self-contained skills with references inside the skill root. This suite deliberately deviates: the three entries share one `_shared/` engine (`${CLAUDE_SKILL_DIR}\..\_shared\`) to guarantee a **single source of truth** — scripts and references exist exactly once and cannot drift. Claude Code resolves this fine.
- Windows adaptation worth knowing: piper's official glow example uses a POSIX env prefix (`CLICOLOR_FORCE=1 glow …`), which does not work on Windows; the suite sets `CLICOLOR_FORCE=1` as a persistent User environment variable instead.

## Sources

[yazi docs](https://yazi-rs.github.io/) · [installation](https://yazi-rs.github.io/docs/installation) · [flavors](https://yazi-rs.github.io/docs/flavors/overview) · [official plugins monorepo](https://github.com/yazi-rs/plugins) · [yazi source (MIT)](https://github.com/sxyazi/yazi) · [Nerd Fonts scoop bucket](https://github.com/matthewjberger/scoop-nerd-fonts) · Skill specs: [Agent Skills](https://agentskills.io/specification) · [Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) · [OpenAI Codex](https://developers.openai.com/codex/skills)

## License

MIT
