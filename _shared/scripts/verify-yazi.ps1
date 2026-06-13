<#
.SYNOPSIS
  Yazi suite - mini verification gate. Read-only.
  Used by /yazi-config as its precondition, and by /yazi-install as the final check.
  Prints a machine-readable verdict:
    VERDICT: READY        -> yazi installed, runs, previews wired
    VERDICT: NOT-READY    -> reasons listed; run /yazi-install
  Plus a separate network line (plugins/flavors are pulled from GitHub):
    NETWORK: OK | PROBLEM
.NOTES
  Works on Windows PowerShell 5.1 and pwsh 7+.
#>
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 > $null
} catch { }

$reasons = @()

Write-Output "===== yazi mini verification (read-only) ====="

# 1. yazi on PATH + version
$yaziCmd = Get-Command yazi -ErrorAction SilentlyContinue
if ($yaziCmd) {
    Write-Output "yazi: FOUND at $($yaziCmd.Source)"
    try {
        $versionOutput = yazi --version 2>&1
        $versionExit = $LASTEXITCODE
        $v = $versionOutput | Select-Object -First 1
        if ($versionExit -ne 0 -or -not $v) {
            $reasons += "yazi exists but failed to run"
            Write-Output "version: FAILED to run (exit $versionExit)"
        } else {
            Write-Output "version: $v"
        }
    } catch {
        $reasons += "yazi exists but failed to run"
        Write-Output "version: FAILED to run ($($_.Exception.Message))"
    }
} else {
    $reasons += "yazi is not on PATH"
    Write-Output "yazi: NOT FOUND on PATH"
}

# 2. Config sanity via yazi --debug (TOML errors)
if ($yaziCmd) {
    try {
        $debugOutput = yazi --debug 2>&1
        $debugExit = $LASTEXITCODE
        $dbg = ($debugOutput | Select-Object -First 60 | Out-String)
        if ($debugExit -ne 0) {
            $reasons += "yazi --debug failed (exit $debugExit)"
            Write-Output "config: yazi --debug FAILED (exit $debugExit)"
        } elseif ($dbg -match "TOML parse error" -or $dbg -match "Press <Enter> to continue") {
            $reasons += "config has TOML errors (yazi fell back to presets)"
            Write-Output "config: TOML ERROR detected in yazi --debug"
        } else {
            Write-Output "config: no TOML errors detected"
        }
    } catch {
        $reasons += "could not run yazi --debug"
        Write-Output "config: could not run yazi --debug ($($_.Exception.Message))"
    }
}

# 3. YAZI_FILE_ONE (previews) - require the current process to see it, because
# yazi launched from this window sees the process environment, not a future one.
$yfo = $env:YAZI_FILE_ONE
if ($yfo -and (Test-Path $yfo)) {
    Write-Output "YAZI_FILE_ONE: OK ($yfo)"
} else {
    $persisted = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
    if (-not $persisted) {
        $persisted = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "Machine")
    }
    if ($persisted -and (Test-Path $persisted)) {
        $reasons += "YAZI_FILE_ONE is persisted but not active in this window"
        Write-Output "YAZI_FILE_ONE: valid persisted value exists, but current window has not loaded it"
        Write-Output "  -> Close all terminal windows and open a fresh one."
    } else {
        $reasons += "YAZI_FILE_ONE not set or invalid (previews broken)"
        Write-Output "YAZI_FILE_ONE: NOT SET or file missing"
    }
}

# 4. Network (needed for ya pkg / scoop pulls from GitHub)
$endpoints = @(
    "https://get.scoop.sh",
    "https://github.com",
    "https://raw.githubusercontent.com",
    "https://objects.githubusercontent.com"
)
$netOk = $true
foreach ($u in $endpoints) {
    try {
        $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        Write-Output "net: $u -> OK"
    } catch {
        # Some endpoints reject HEAD; try GET before declaring failure
        try {
            $r = Invoke-WebRequest -Uri $u -Method Get -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
            Write-Output "net: $u -> OK"
        } catch {
            $netOk = $false
            Write-Output "net: $u -> FAILED ($($_.Exception.Message))"
        }
    }
}
if ($netOk) { Write-Output "NETWORK: OK" } else {
    Write-Output "NETWORK: PROBLEM"
    Write-Output "  -> GitHub unreachable. Plugins/flavors/tools cannot be downloaded."
    Write-Output "  -> If you use a proxy (Clash/V2Ray): enable system proxy or TUN mode, or:"
    Write-Output "       scoop config proxy 127.0.0.1:7890   (use your real host:port)"
}

Write-Output ""
if ($reasons.Count -eq 0) {
    Write-Output "VERDICT: READY"
    exit 0
} else {
    Write-Output "VERDICT: NOT-READY"
    foreach ($r in $reasons) { Write-Output "  - $r" }
    Write-Output "  -> Run /yazi-install to fix the installation first."
    exit 1
}
