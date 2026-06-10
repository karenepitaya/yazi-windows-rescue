<#
.SYNOPSIS
  Yazi suite - one-shot cleanup / reset ("clean slate" option).
  Used when /yazi-install fails partway, or the user wants to start over.
  - Backs up then removes the yazi config folder
  - Uninstalls yazi itself (only if scoop owns it; otherwise reports the path
    and refuses to guess-delete)
  - Leaves shared tools (git, ffmpeg, scoop itself, fonts) alone: they are
    harmless standalone and may be used by other things
  Prints what it did, plus optional removal commands for everything else.
  Ends with: CLEANUP: DONE
.NOTES
  Works on Windows PowerShell 5.1 and pwsh 7+.
#>
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 > $null
} catch { }

try {

Write-Output "===== yazi cleanup / reset ====="

# 1. Backup + remove config
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) {
    $bak = "$env:APPDATA\yazi\config-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $cfg $bak -Recurse -Force
    Write-Output "config: backed up to $bak"
    Remove-Item $cfg -Recurse -Force
    Write-Output "config: removed (backup kept)."
} else {
    Write-Output "config: no config folder found."
}

# 2. Uninstall yazi (scoop-owned only)
$scoopHasYazi = $false
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $hit = scoop list 2>$null | Select-String -Pattern "^yazi\s|/yazi\s|\byazi\b"
    if ($hit) { $scoopHasYazi = $true }
}
if ($scoopHasYazi) {
    Write-Output "yazi: scoop owns it -> uninstalling..."
    scoop uninstall yazi
    if ($LASTEXITCODE -eq 0) { Write-Output "yazi: uninstalled." }
    else { Write-Output "WARNING: scoop uninstall yazi exited $LASTEXITCODE. Re-run, or check 'scoop list'." }
} else {
    $yaziCmd = Get-Command yazi -ErrorAction SilentlyContinue
    if ($yaziCmd) {
        Write-Output "yazi: found at $($yaziCmd.Source) but scoop does not own it."
        Write-Output "  -> NOT deleting automatically. If you want it gone, confirm the path and remove it yourself,"
        Write-Output "     or tell Claude and it will walk you through it."
    } else {
        Write-Output "yazi: not found on PATH. Nothing to uninstall."
    }
}

# 3. What we deliberately keep, and how to remove it if you insist
Write-Output ""
Write-Output "Kept on purpose (harmless, possibly used elsewhere):"
Write-Output "  - scoop itself, git, ffmpeg, imagemagick, poppler, fd, jq, glow, the Nerd Font"
Write-Output "  - YAZI_FILE_ONE / CLICOLOR_FORCE environment variables"
Write-Output "Optional removal commands if you want a deeper clean:"
Write-Output "  scoop uninstall glow fd jq poppler imagemagick ffmpeg"
Write-Output '  [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $null, "User")'
Write-Output '  [Environment]::SetEnvironmentVariable("CLICOLOR_FORCE", $null, "User")'

Write-Output ""
Write-Output "CLEANUP: DONE - you now have a clean slate. Run /yazi-install to start fresh."

} catch {
    Write-Output ""
    Write-Output "ERROR: cleanup.ps1 failed unexpectedly: $($_.Exception.Message)"
    Write-Output "Report at: https://github.com/karenepitaya/yazi-windows-rescue/issues"
}
