<#
.SYNOPSIS
  Yazi Windows Rescue — diagnosis script.
  Read-only. Changes nothing. Gathers everything needed to decide how to clean up.

.DESCRIPTION
  Prints a single, clearly-sectioned report. FAULT-ISOLATED: every section runs
  inside its own guard, so one failing probe can never kill the checks after it
  (a failed section prints why and the report continues). Covers:
    1. yazi on PATH          2. install method        3. config folder + files
    4. yazi --debug          5. NETWORK (real HTTPS)  6. PS version + exec policy
    7. pwsh 7+ detection     8. YAZI_FILE_ONE         9. Nerd Font + terminal font
    10. yazi packages (ya pkg list)
  Works on Windows PowerShell 5.1 and pwsh 7+.
#>

# --- Prologue: UTF-8 + PSModulePath hygiene -------------------------------
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    chcp 65001 > $null
} catch { }

# Windows PowerShell 5.1 spawned from another process (e.g. an agent/IDE) often
# inherits a PSModulePath polluted with PowerShell 7 module dirs, which breaks
# auto-loading of core modules like Microsoft.PowerShell.Security
# (Get-ExecutionPolicy then throws). Putting 5.1's own module dir FIRST fixes it.
try {
    if ($PSVersionTable.PSEdition -ne 'Core') {
        $own = "$PSHOME\Modules"
        if ($env:PSModulePath -notlike "$own*") {
            $env:PSModulePath = "$own;" + $env:PSModulePath
        }
    }
} catch { }

function Section($title) {
    Write-Output ""
    Write-Output "===== $title ====="
}

# Per-section fault isolation. A diagnosis script's job is "check what it can,
# label what it can't" — one failed probe must never abort the rest.
function Invoke-Check($title, [scriptblock]$block) {
    Section $title
    try {
        & $block
    } catch {
        Write-Output "[CHECK FAILED] $title"
        Write-Output "  reason: $($_.Exception.Message)"
        Write-Output "  -> Skipping this section and continuing. Items here are UNCHECKED, not OK."
        Write-Output "     (Failures here are common on PowerShell 5.1 with a polluted module path;"
        Write-Output "      re-running this script in pwsh 7 usually yields a complete report.)"
    }
}

# Real reachability test over HTTPS. ICMP ping is unreliable (many hosts block
# ICMP, and ping says nothing about port 443). Non-2xx still means reached.
function Test-Endpoint($name, $url) {
    try {
        $null = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
        Write-Output ("  [OK]      {0,-26} {1}" -f $name, $url)
        return $true
    } catch {
        $resp = $_.Exception.Response
        if ($null -ne $resp) {
            Write-Output ("  [OK*]     {0,-26} {1}  (reached host; non-2xx status)" -f $name, $url)
            return $true
        } else {
            Write-Output ("  [BLOCKED] {0,-26} {1}" -f $name, $url)
            Write-Output ("            reason: {0}" -f $_.Exception.Message)
            return $false
        }
    }
}

Write-Output "########## YAZI WINDOWS RESCUE — DIAGNOSIS REPORT ##########"
Write-Output "(This script only reads information. It changes and deletes nothing.)"

$script:yaziCmd = $null

Invoke-Check "1. Is yazi on PATH, and where?" {
    $script:yaziCmd = Get-Command yazi -ErrorAction SilentlyContinue
    if ($script:yaziCmd) { Write-Output "FOUND: $($script:yaziCmd.Source)" } else { Write-Output "NOT FOUND on PATH" }
}

Invoke-Check "2. How was yazi installed?" {
    $scoopHit = $null
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $scoopHit = (scoop list 2>$null | Select-String -Pattern "yazi")
    }
    if ($scoopHit) { Write-Output "scoop: YES -> $scoopHit" } else { Write-Output "scoop: no (or scoop not installed)" }
    $wingetHit = $null
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wingetHit = (winget list 2>$null | Select-String -Pattern "yazi")
    }
    if ($wingetHit) { Write-Output "winget: YES -> $wingetHit" } else { Write-Output "winget: no (or winget not installed)" }
    $cargoPath = "$env:USERPROFILE\.cargo\bin\yazi.exe"
    if (Test-Path $cargoPath) { Write-Output "cargo: YES -> $cargoPath" } else { Write-Output "cargo: no" }
    if ($script:yaziCmd -and -not $scoopHit -and -not $wingetHit -and -not (Test-Path $cargoPath)) {
        Write-Output "NOTE: yazi exists on PATH but no package manager claims it -> likely MANUAL / UNKNOWN install at: $($script:yaziCmd.Source)"
    }
}

Invoke-Check "3. Config folder contents" {
    $cfg = "$env:APPDATA\yazi\config"
    if (Test-Path $cfg) {
        Get-ChildItem $cfg -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, Length | Format-Table -AutoSize | Out-String | Write-Output
        foreach ($f in "yazi.toml","keymap.toml","theme.toml","package.toml","init.lua") {
            $p = Join-Path $cfg $f
            if (Test-Path $p) { Write-Output ("  present: {0}" -f $f) } else { Write-Output ("  absent : {0}  (optional)" -f $f) }
        }
    } else {
        Write-Output "No config folder at $cfg"
    }
}

Invoke-Check "4. yazi self-check (yazi --debug, first 60 lines)" {
    if ($script:yaziCmd) {
        (yazi --debug 2>&1 | Select-Object -First 60 | Out-String) | Write-Output
    } else {
        Write-Output "Skipped — yazi is not on PATH."
    }
}

Invoke-Check "5. NETWORK — can we reach the servers scoop/ya download from?" {
    Write-Output "(Tested over HTTPS. The #1 cause of installs failing halfway — especially on networks in mainland China, where raw.githubusercontent.com is often blocked.)"
    $net_scoop = Test-Endpoint "get.scoop.sh"               "https://get.scoop.sh"
    $net_gh    = Test-Endpoint "github.com"                 "https://github.com"
    $net_raw   = Test-Endpoint "raw.githubusercontent.com"  "https://raw.githubusercontent.com"
    $net_obj   = Test-Endpoint "objects.githubusercontent.com" "https://objects.githubusercontent.com"
    Write-Output ""
    if ($net_gh -and $net_raw -and $net_scoop) {
        Write-Output "NETWORK VERDICT: OK — the critical GitHub endpoints are reachable. Safe to install."
    } else {
        Write-Output "NETWORK VERDICT: PROBLEM — at least one critical endpoint is blocked."
        Write-Output "  -> Do NOT start installing yet, or downloads will fail partway through."
        Write-Output "  -> Proxy tool (e.g. Clash): turn on system proxy / TUN mode and re-run this script."
        Write-Output "  -> Or point scoop at your proxy:  scoop config proxy 127.0.0.1:7890   (your real port)"
        Write-Output "     (remove later with:  scoop config rm proxy)"
        Write-Output "  -> Guide: https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy"
    }
    Write-Output ""
    Write-Output "--- Proxy settings currently visible ---"
    $anyProxy = $false
    foreach ($v in 'HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','http_proxy','https_proxy','all_proxy') {
        $val = [Environment]::GetEnvironmentVariable($v)
        if ($val) { Write-Output "  env $v = $val"; $anyProxy = $true }
    }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        try {
            $sp = scoop config proxy 2>$null
            if ($sp) { Write-Output "  scoop config proxy = $sp"; $anyProxy = $true }
        } catch { }
    }
    if (-not $anyProxy) { Write-Output "  (no proxy environment variables or scoop proxy configured)" }
}

Invoke-Check "6. Environment pre-check (PS version, execution policy)" {
    Write-Output "PowerShell version: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
    # Get-ExecutionPolicy needs Microsoft.PowerShell.Security — the probe most
    # likely to fail on 5.1 with module-path pollution, so it gets its OWN guard:
    try {
        Write-Output "Execution policy (effective list):"
        (Get-ExecutionPolicy -List | Out-String) | Write-Output
    } catch {
        Write-Output "Execution policy: COULD NOT READ ($($_.Exception.Message))"
        Write-Output "  -> Known 5.1 quirk (Microsoft.PowerShell.Security failed to load)."
        Write-Output "  -> Does NOT affect yazi. Treat policy as UNKNOWN; the scoop install step has fallbacks."
    }
}

Invoke-Check "7. PowerShell 7+ (pwsh) detection" {
    $isPwsh = ($PSVersionTable.PSEdition -eq 'Core') -or ($PSVersionTable.PSVersion.Major -ge 6)
    if ($isPwsh) {
        Write-Output "Already running PowerShell 7+ (version $($PSVersionTable.PSVersion)). No action needed."
        return
    }
    Write-Output "You are running Windows PowerShell $($PSVersionTable.PSVersion) (legacy)."
    Write-Output "Scanning for PowerShell 7+ installations..."
    Write-Output ""
    $found = [System.Collections.Generic.List[string]]::new()
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) { $found.Add($pwshCmd.Source); Write-Output "  Get-Command pwsh -> $($pwshCmd.Source)" }
    foreach ($p in @("$env:ProgramFiles\PowerShell\7\pwsh.exe", "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe")) {
        if ((Test-Path $p) -and ($found -notcontains $p)) { $found.Add($p); Write-Output "  MSI path -> $p" }
    }
    Get-ChildItem "$env:ProgramFiles\PowerShell\*\pwsh.exe" -ErrorAction SilentlyContinue | ForEach-Object {
        if ($found -notcontains $_.FullName) { $found.Add($_.FullName); Write-Output "  Program Files glob -> $($_.FullName)" }
    }
    $storeStub = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
    if (Test-Path $storeStub) {
        if ($found -notcontains $storeStub) { $found.Add($storeStub) }
        Write-Output "  Microsoft Store stub -> $storeStub"
        Write-Output "    (Store redirect stub; may need a first launch from the Start Menu.)"
    }
    $scoopPwsh = "$env:USERPROFILE\scoop\apps\pwsh\current\pwsh.exe"
    if ((Test-Path $scoopPwsh) -and ($found -notcontains $scoopPwsh)) { $found.Add($scoopPwsh); Write-Output "  Scoop -> $scoopPwsh" }
    foreach ($entry in ($env:PATH -split ';')) {
        if (-not $entry) { continue }
        $candidate = Join-Path $entry "pwsh.exe"
        if ((Test-Path $candidate) -and ($found -notcontains $candidate)) { $found.Add($candidate); Write-Output "  PATH scan -> $candidate" }
    }
    foreach ($rp in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        try {
            Get-ItemProperty $rp -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*PowerShell*" } | ForEach-Object {
                $info = "$($_.DisplayName) v$($_.DisplayVersion)"
                if ($_.InstallLocation) { $info += " -> $($_.InstallLocation)" }
                Write-Output "  Registry -> $info"
                if ($_.InstallLocation) {
                    $regExe = Join-Path $_.InstallLocation "pwsh.exe"
                    if ((Test-Path $regExe) -and ($found -notcontains $regExe)) { $found.Add($regExe) }
                }
            }
        } catch { Write-Output "  Registry scan ($rp): $($_.Exception.Message)" }
    }
    Write-Output ""
    if ($found.Count -gt 0) {
        Write-Output "SUMMARY: PowerShell 7+ found at $($found.Count) location(s):"
        foreach ($loc in $found) { Write-Output "  - $loc" }
        Write-Output "RECOMMENDATION: run 'pwsh' to switch."
    } else {
        Write-Output "SUMMARY: PowerShell 7+ NOT found."
        Write-Output "RECOMMENDATION: scoop install pwsh   (or: winget install --id Microsoft.PowerShell)"
    }
}

Invoke-Check "8. YAZI_FILE_ONE status" {
    foreach ($scope in "User","Machine") {
        $v = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", $scope)
        if ($v) {
            Write-Output "YAZI_FILE_ONE ($scope scope): $v"
            if (Test-Path $v) { Write-Output "  -> File EXISTS." } else { Write-Output "  -> WARNING: file does NOT exist. Previews will not work." }
        } else { Write-Output "YAZI_FILE_ONE ($scope scope): NOT SET" }
    }
    if ($env:YAZI_FILE_ONE) { Write-Output "YAZI_FILE_ONE (current session): $env:YAZI_FILE_ONE" }
    else { Write-Output "YAZI_FILE_ONE (current session): NOT SET" }
}

Invoke-Check "9. Nerd Font + terminal font" {
    # Installed fonts: scoop-managed first, then the per-user/system font dirs
    $hit = $false
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $fontPkgs = scoop list 2>$null | Select-String -Pattern "-NF|Nerd|Maple-Mono"
        if ($fontPkgs) { Write-Output "scoop font packages: $fontPkgs"; $hit = $true }
    }
    foreach ($dir in "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:windir\Fonts") {
        $files = Get-ChildItem $dir -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "NerdFont|NF|MapleMono" } | Select-Object -First 5
        foreach ($f in $files) { Write-Output "  font file: $($f.Name)  ($dir)"; $hit = $true }
    }
    if (-not $hit) { Write-Output "No Nerd Font detected -> yazi's icons will render as boxes until one is installed AND selected." }
    # Windows Terminal: which face is actually selected?
    $wt = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wt) {
        try {
            $j = Get-Content $wt.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $face = $j.profiles.defaults.font.face
            if ($face) { Write-Output "Windows Terminal default font face: $face" }
            else { Write-Output "Windows Terminal: no default font face set (profiles may override; icons need a Nerd Font face like 'Maple Mono NF CN')." }
        } catch { Write-Output "Windows Terminal settings.json found but could not be parsed: $($_.Exception.Message)" }
    } else {
        Write-Output "Windows Terminal settings.json not found (different terminal? set its font to a Nerd Font manually)."
    }
}

Invoke-Check "10. yazi packages (plugins / flavors)" {
    if (Get-Command ya -ErrorAction SilentlyContinue) {
        $pkgs = ya pkg list 2>&1 | Out-String
        if ($pkgs.Trim()) { Write-Output $pkgs } else { Write-Output "(ya pkg list returned nothing)" }
    } else {
        Write-Output "Skipped — 'ya' not on PATH (it ships with yazi)."
    }
}

Write-Output ""
Write-Output "########## END OF REPORT ##########"
Write-Output "If any section above says [CHECK FAILED], those items are UNCHECKED — do not assume they are OK."
