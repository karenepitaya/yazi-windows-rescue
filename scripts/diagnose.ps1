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
    - PowerShell 7+ detection (comprehensive, multi-source)
    - YAZI_FILE_ONE environment variable status
  Paste the whole report back to Claude.
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    chcp 65001 > $null
} catch { }

function Section($title) {
    Write-Output ""
    Write-Output "===== $title ====="
}

try {

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
try {
    $net = Test-Connection raw.githubusercontent.com -Count 1 -Quiet -ErrorAction SilentlyContinue
} catch {
    $net = $false
    Write-Output "  (Network test failed: $($_.Exception.Message))"
}
Write-Output "Can reach GitHub (needed to download scoop/tools): $net"
if (-not $net) {
    Write-Output "  -> If you are behind a proxy or firewall, you may need to configure it before scoop can download packages."
    Write-Output "  -> Check: https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy"
}

Section "6. PowerShell 7+ (pwsh) detection"
$isPwsh = ($PSVersionTable.PSEdition -eq 'Core') -or ($PSVersionTable.PSVersion.Major -ge 6)
if ($isPwsh) {
    Write-Output "Already running PowerShell 7+ (version $($PSVersionTable.PSVersion)). No action needed."
} else {
    Write-Output "You are running Windows PowerShell $($PSVersionTable.PSVersion) (legacy)."
    Write-Output "Scanning for PowerShell 7+ installations..."
    Write-Output ""

    $foundLocations = [System.Collections.Generic.List[string]]::new()

    # a. Get-Command
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        $loc = $pwshCmd.Source
        if ($foundLocations -notcontains $loc) { $foundLocations.Add($loc) }
        Write-Output "  Get-Command pwsh -> $loc"
    }

    # b. Standard MSI paths
    $msiPaths = @(
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe"
    )
    foreach ($p in $msiPaths) {
        if (Test-Path $p) {
            if ($foundLocations -notcontains $p) { $foundLocations.Add($p) }
            Write-Output "  MSI path -> $p"
        }
    }
    # Glob for any version subfolder
    $globResults = Get-ChildItem "$env:ProgramFiles\PowerShell\*\pwsh.exe" -ErrorAction SilentlyContinue
    foreach ($g in $globResults) {
        $loc = $g.FullName
        if ($foundLocations -notcontains $loc) { $foundLocations.Add($loc) }
        Write-Output "  Program Files glob -> $loc"
    }

    # c. Microsoft Store stub
    $storeStub = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
    if (Test-Path $storeStub) {
        if ($foundLocations -notcontains $storeStub) { $foundLocations.Add($storeStub) }
        Write-Output "  Microsoft Store stub -> $storeStub"
        Write-Output "    (NOTE: This is a Store redirect stub. You may need to launch pwsh from the Start Menu first.)"
    }

    # d. Scoop
    $scoopPwsh = "$env:USERPROFILE\scoop\apps\pwsh\current\pwsh.exe"
    if (Test-Path $scoopPwsh) {
        if ($foundLocations -notcontains $scoopPwsh) { $foundLocations.Add($scoopPwsh) }
        Write-Output "  Scoop -> $scoopPwsh"
    }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $scoopList = scoop list pwsh 2>$null
        if ($scoopList) { Write-Output "  scoop list pwsh -> $scoopList" }
    }

    # e. Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wgStable = winget list --id Microsoft.PowerShell 2>$null
        if ($wgStable) { Write-Output "  winget (stable) -> $wgStable" }
        $wgPreview = winget list --id Microsoft.PowerShell.Preview 2>$null
        if ($wgPreview) { Write-Output "  winget (preview) -> $wgPreview" }
    }

    # f. PATH scan
    $pathEntries = $env:PATH -split ';'
    foreach ($entry in $pathEntries) {
        if (-not $entry) { continue }
        $candidate = Join-Path $entry "pwsh.exe"
        if (Test-Path $candidate) {
            if ($foundLocations -notcontains $candidate) { $foundLocations.Add($candidate) }
            Write-Output "  PATH scan -> $candidate"
        }
    }

    # g. Registry uninstall keys
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($rp in $regPaths) {
        try {
            $entries = Get-ItemProperty $rp -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*PowerShell*" }
            foreach ($e in $entries) {
                $info = "$($e.DisplayName) v$($e.DisplayVersion)"
                if ($e.InstallLocation) { $info += " -> $($e.InstallLocation)" }
                Write-Output "  Registry -> $info"
                if ($e.InstallLocation) {
                    $regExe = Join-Path $e.InstallLocation "pwsh.exe"
                    if ((Test-Path $regExe) -and ($foundLocations -notcontains $regExe)) {
                        $foundLocations.Add($regExe)
                    }
                }
            }
        } catch {
            Write-Output "  Registry scan ($rp): access denied or error — $($_.Exception.Message)"
        }
    }

    Write-Output ""
    if ($foundLocations.Count -gt 0) {
        Write-Output "SUMMARY: PowerShell 7+ found at $($foundLocations.Count) location(s):"
        foreach ($loc in $foundLocations) { Write-Output "  - $loc" }
        Write-Output ""
        Write-Output "RECOMMENDATION: Switch to pwsh for the best experience."
        Write-Output "  Run 'pwsh' from any terminal to start it."
        Write-Output "  Official guide: https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows"
    } else {
        Write-Output "SUMMARY: PowerShell 7+ was NOT found on this system."
        Write-Output ""
        Write-Output "RECOMMENDATION: Install PowerShell 7+ for the best experience."
        Write-Output "  Option 1 (recommended): winget install --id Microsoft.PowerShell"
        Write-Output "  Option 2: Download MSI from https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows"
        Write-Output "  Option 3: scoop install pwsh"
    }
}

Section "7. YAZI_FILE_ONE status"
# User scope
$yfoUser = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
if ($yfoUser) {
    Write-Output "YAZI_FILE_ONE (User scope): $yfoUser"
    if (Test-Path $yfoUser) {
        Write-Output "  -> File EXISTS at that path."
    } else {
        Write-Output "  -> WARNING: File does NOT exist at that path. Previews will not work."
    }
} else {
    Write-Output "YAZI_FILE_ONE (User scope): NOT SET"
}
# Machine scope
$yfoMachine = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "Machine")
if ($yfoMachine) {
    Write-Output "YAZI_FILE_ONE (Machine scope): $yfoMachine"
    if (Test-Path $yfoMachine) {
        Write-Output "  -> File EXISTS at that path."
    } else {
        Write-Output "  -> WARNING: File does NOT exist at that path."
    }
} else {
    Write-Output "YAZI_FILE_ONE (Machine scope): NOT SET"
}
# Current session
$yfoSession = $env:YAZI_FILE_ONE
if ($yfoSession) {
    Write-Output "YAZI_FILE_ONE (current session): $yfoSession"
} else {
    Write-Output "YAZI_FILE_ONE (current session): NOT SET"
}

Write-Output ""
Write-Output "########## END OF REPORT — paste everything above back to Claude ##########"

} catch {
    Write-Output ""
    Write-Output "ERROR: Diagnosis script failed unexpectedly."
    Write-Output "What happened: $($_.Exception.Message)"
    Write-Output "Why it matters: The diagnosis report is incomplete. We cannot determine the state of your yazi install."
    Write-Output "What to do: Re-run this script. If it keeps failing, report this error at:"
    Write-Output "  https://github.com/karenepitaya/yazi-windows-rescue/issues"
}
