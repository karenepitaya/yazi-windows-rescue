<#
.SYNOPSIS
  Yazi suite - preview tool installer for /yazi-config (complete tier).
  Installs glow (terminal markdown renderer) via scoop if missing, and sets
  CLICOLOR_FORCE=1 as a User environment variable so glow keeps colors when
  piped by yazi's piper plugin (the POSIX `CLICOLOR_FORCE=1 cmd` prefix from
  the official piper example does NOT work on Windows - a persistent env var
  is the Windows-correct equivalent).
  Defensive and idempotent. Prints a machine-readable summary line:
    PREVIEW-TOOLS: OK | PARTIAL
.NOTES
  Works on Windows PowerShell 5.1 and pwsh 7+.
#>
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 > $null
} catch { }

$ok = $true
Write-Output "===== preview tools setup ====="

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Output "ERROR: scoop not found. Run /yazi-install first (it sets up scoop)."
    Write-Output "PREVIEW-TOOLS: PARTIAL"
    exit 1
}

# glow (markdown rendering in the preview pane, via the piper plugin)
$glow = Get-Command glow -ErrorAction SilentlyContinue
if ($glow) {
    Write-Output "glow: already present ($($glow.Source))"
} else {
    Write-Output "glow: missing -> installing with scoop (renders Markdown beautifully in the preview pane)"
    scoop install glow
    if ($LASTEXITCODE -ne 0) {
        $ok = $false
        Write-Output "WARNING: 'scoop install glow' failed (exit $LASTEXITCODE)."
        Write-Output "  -> Usually a network/proxy issue. Fix connectivity and re-run this script."
    } else {
        Write-Output "glow: installed."
    }
}

# CLICOLOR_FORCE=1 so glow emits colors when piped (Windows equivalent of the POSIX env prefix)
$cc = [Environment]::GetEnvironmentVariable("CLICOLOR_FORCE", "User")
if ($cc -eq "1") {
    Write-Output "CLICOLOR_FORCE: already set."
} else {
    [Environment]::SetEnvironmentVariable("CLICOLOR_FORCE", "1", "User")
    Write-Output "CLICOLOR_FORCE: set to 1 (User scope)."
    Write-Output "IMPORTANT: takes effect in NEW terminal windows only."
}

if ($ok) {
    Write-Output "PREVIEW-TOOLS: OK"
    exit 0
} else {
    Write-Output "PREVIEW-TOOLS: PARTIAL"
    exit 1
}
