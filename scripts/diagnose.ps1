<#
.SYNOPSIS
  Yazi Windows Rescue — diagnosis script.
  Read-only. Changes nothing. Gathers everything needed to decide how to clean up.

.DESCRIPTION
  Run this from PowerShell. It prints a single, clearly-sectioned report covering:
    - UTF-8 setup (so Chinese / output isn't garbled)
    - whether yazi is on PATH and where
    - how yazi was installed (scoop / winget / cargo / manual-unknown)
    - whether a config folder exists and what's in it
    - yazi's own self-check (yazi --debug), if yazi runs
    - environment pre-check (PowerShell version, execution policy, network to GitHub)
  Paste the whole report back to Claude.
#>

# --- Make output UTF-8 so nothing shows up garbled (especially on Chinese systems) ---
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 > $null
} catch { }

function Section($title) {
    Write-Output ""
    Write-Output "===== $title ====="
}

Write-Output "########## YAZI WINDOWS RESCUE — DIAGNOSIS REPORT ##########"
Write-Output "(This script only reads information. It changes and deletes nothing.)"

Section "1. Is yazi on PATH, and where?"
$yaziCmd = Get-Command yazi -ErrorAction SilentlyContinue
if ($yaziCmd) { Write-Output "FOUND: $($yaziCmd.Source)" } else { Write-Output "NOT FOUND on PATH" }

Section "2. How was yazi installed?"
# scoop
$scoopHit = $null
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $scoopHit = (scoop list 2>$null | Select-String -Pattern "yazi")
}
if ($scoopHit) { Write-Output "scoop: YES -> $scoopHit" } else { Write-Output "scoop: no (or scoop not installed)" }
# winget
$wingetHit = $null
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wingetHit = (winget list 2>$null | Select-String -Pattern "yazi")
}
if ($wingetHit) { Write-Output "winget: YES -> $wingetHit" } else { Write-Output "winget: no (or winget not installed)" }
# cargo
$cargoPath = "$env:USERPROFILE\.cargo\bin\yazi.exe"
if (Test-Path $cargoPath) { Write-Output "cargo: YES -> $cargoPath" } else { Write-Output "cargo: no" }
# manual/unknown hint
if ($yaziCmd -and -not $scoopHit -and -not $wingetHit -and -not (Test-Path $cargoPath)) {
    Write-Output "NOTE: yazi exists on PATH but no package manager claims it -> likely a MANUAL / UNKNOWN install at: $($yaziCmd.Source)"
}

Section "3. Config folder contents"
$cfg = "$env:APPDATA\yazi\config"
if (Test-Path $cfg) {
    Get-ChildItem $cfg -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, Length | Format-Table -AutoSize | Out-String | Write-Output
} else {
    Write-Output "No config folder at $cfg"
}

Section "4. yazi self-check (yazi --debug, first 60 lines)"
if ($yaziCmd) {
    try {
        (yazi --debug 2>&1 | Select-Object -First 60 | Out-String) | Write-Output
    } catch {
        Write-Output "yazi --debug could not run: $($_.Exception.Message)"
    }
} else {
    Write-Output "Skipped — yazi is not on PATH."
}

Section "5. Environment pre-check"
Write-Output "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Output "Execution policy (effective list):"
(Get-ExecutionPolicy -List | Out-String) | Write-Output
$net = $false
try { $net = Test-Connection raw.githubusercontent.com -Count 1 -Quiet -ErrorAction SilentlyContinue } catch { $net = $false }
Write-Output "Can reach GitHub (needed to download scoop/tools): $net"

Write-Output ""
Write-Output "########## END OF REPORT — paste everything above back to Claude ##########"
