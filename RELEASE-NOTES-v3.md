# v3 发布备忘（给本地 Claude Code / github-batch-push 用）

## 这是什么
yazi-windows-rescue 从单一 rescue skill 重构为三命令套件（/yazi-detect, /yazi-install, /yazi-config + _shared 共享引擎）。

## 建议提交信息
```
refactor!: restructure into a three-command suite (detect / install / config)

BREAKING CHANGE: 仓库根目录现在直接就是 skills 目录。
安装方式从
  git clone <repo> ".claude\skills\yazi-windows-rescue"
变为
  git clone <repo> ".claude\skills"
按旧方式安装将导致三个命令无法注册。详见 README「安装本套件」。

- /yazi-detect: 纯只读诊断入口，无前置
- /yazi-install: 自含诊断 + 删除前网络硬闸门 + scoop 重装 + 验证；
  失败时提供 cleanup.ps1 一键恢复干净状态
- /yazi-config: 前置验证（verify-yazi.ps1 闸门）+ 最小/完整分档 +
  防御式增强（装好才引用，绝不写半截配置）
- 版本可复现：主题与插件经 vendored package.toml（rev+hash 钉死，
  piper @598cdb6, catppuccin-mocha @36c49ac）以 ya pkg install 安装
- 可选项：glow Markdown 预览；fzf+zoxide 跳转增强（含 PROFILE 挂钩）
- 字体：Maple Mono NF CN（图标+中文同字体，2:1 对齐）
- _shared/ 单一事实源引擎；刻意偏离 agentskills 自包含建议，README 有说明
```

## 发布流程提醒
1. github-batch-push 先 dry-run + secret 扫描（PowerShell 脚本里无凭证，但走流程）
2. 本地仓库根的旧文件（SKILL.md, scripts/, reference/）需删除——目录结构整体迁移，
   建议 `git rm -r` 旧布局后整树拷入新布局，一次提交
3. 推送后给 2 个 star 的老用户留意：README 顶部安装命令已变
4. 可顺手打 tag v3.0.0
