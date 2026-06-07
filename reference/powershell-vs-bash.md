# PowerShell vs bash — command translations

This skill runs on **Windows, inside PowerShell — not bash**. The most common agent failure here is issuing bash commands that don't exist in PowerShell, behave differently, or only accidentally work through an alias whose flags differ.

Before issuing any command, confirm it is PowerShell-native. If a command fails, suspect bash syntax FIRST and translate it — do not blindly retry variations.

| Bash habit | Why it fails in PowerShell | Use instead |
|---|---|---|
| `grep foo` | not a command | `Select-String foo` |
| `which yazi` | not a command | `Get-Command yazi` |
| `cat file` with bash flags | `cat` is an alias for `Get-Content`; bash flags fail | `Get-Content file` |
| `ls -la` | `ls` aliases `Get-ChildItem`; `-la` is not valid | `Get-ChildItem -Force` |
| `rm -rf dir` | `rm` alias doesn't take `-rf` | `Remove-Item dir -Recurse -Force` |
| `touch f` | not a command | `New-Item -ItemType File f` |
| `export X=y` | not valid | `$env:X = "y"` (session) or `[Environment]::SetEnvironmentVariable("X","y","User")` (permanent) |
| `cmd1 && cmd2` | unsupported in PowerShell 5.1 | run as two commands, or `cmd1; if ($?) { cmd2 }` |
| `cmd1 \| grep x` | `grep` missing | `cmd1 \| Select-String x` |
| `mkdir -p a/b/c` | `-p` not needed/valid | `New-Item -ItemType Directory -Force -Path a\b\c` |
| `$(cmd)` substitution | bash style | `(cmd)` or assign to a variable: `$x = cmd` |
| single quotes for paths with vars | bash style | in PowerShell `'...'` is literal (no `$env:` expansion); use `"..."` when you need expansion |
| `~/.config` | `~` is shell-dependent | `$env:USERPROFILE\.config` (or `$HOME`) |

The commands written verbatim in `SKILL.md` and the bundled scripts are already PowerShell-correct — use them as-is rather than rewriting them.
