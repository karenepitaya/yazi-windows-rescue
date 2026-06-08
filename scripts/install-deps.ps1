<#
.SYNOPSIS
  Yazi Windows Rescue — dependency check + install.
  Detects which yazi dependencies are present and installs ONLY the missing ones via scoop.

.DESCRIPTION
  Run from PowerShell 7+ (pwsh) AFTER scoop is confirmed installed.
  - Prints each dependency as OK or MISSING (with what it's for).
  - Installs only the missing scoop packages (scoop skips anything already installed anyway).
  - Auto-sets YAZI_FILE_ONE if not already configured.
  - Idempotent: safe to run more than once.

  Dependencies and the scoop package that provides each:
    yazi        -> yazi         (the file manager)
    fd          -> fd           (file search inside yazi)
    magick      -> imagemagick  (image previews)
    ffmpeg      -> ffmpeg       (video thumbnail previews)
    pdftoppm    -> poppler      (PDF previews)
    jq          -> jq           (JSON pretty previews)
    git         -> git          (provides file.exe used for MIME detection)

.NOTES
  Designed for PowerShell 7+. If run on Windows PowerShell 5.1, it will explain
  how to get pwsh and exit gently (rather than throwing a #requires error).
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    chcp 65001 > $null
} catch { }

# --- Soft PowerShell 7+ check: guide, don't just fail ---
# This skill standardizes on PowerShell 7 (pwsh) because it avoids many of the
# encoding and legacy quirks that break setups on Chinese-locale Windows. Rather
# than refuse with a raw #requires error, explain the situation and how to fix it.
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Write-Output "===== This step needs PowerShell 7 (pwsh) ====="
    Write-Output "You're currently running Windows PowerShell $($PSVersionTable.PSVersion) (the old, built-in one)."
    Write-Output ""
    Write-Output "Why it matters: this skill uses PowerShell 7 (pwsh) on purpose. PowerShell 7 handles"
    Write-Output "UTF-8 and Chinese text far better and avoids many legacy quirks that cause exactly the"
    Write-Output "kind of breakage we're fixing. The install step is written for it."
    Write-Output ""
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        Write-Output "Good news: PowerShell 7 is already installed at: $($pwshCmd.Source)"
        Write-Output "What to do: close this window, open PowerShell 7 (run 'pwsh', or find it in the Start Menu),"
        Write-Output "and run this script again from there."
    } else {
        Write-Output "PowerShell 7 doesn't appear to be installed yet. Install it (any one of these):"
        Write-Output "  - scoop install pwsh        (matches this skill's scoop-based approach; recommended)"
        Write-Output "  - winget install --id Microsoft.PowerShell"
        Write-Output "  - MSI: https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows"
        Write-Output ""
        Write-Output "After installing, close this window, start PowerShell 7 by running 'pwsh', then run this script again."
    }
    Write-Output ""
    Write-Output "(Nothing was installed or changed. This was only a version check.)"
    return
}

try {

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Output "ERROR: scoop is not installed yet. Install scoop first (see SKILL.md Phase 4a), then re-run this."
    Write-Output "  Quick install: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser; Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
    Write-Output "  Scoop docs: https://scoop.sh/"
    return
}

# command-name -> @(scoop-package, human description)
$deps = [ordered]@{
    "yazi"     = @("yazi",        "the file manager itself")
    "fd"       = @("fd",          "file search inside yazi")
    "magick"   = @("imagemagick", "image previews")
    "ffmpeg"   = @("ffmpeg",      "video thumbnail previews")
    "pdftoppm" = @("poppler",     "PDF previews")
    "jq"       = @("jq",          "JSON pretty previews")
    "git"      = @("git",         "provides file.exe for MIME detection")
}

# Smart git detection: if user cloned this repo, they almost certainly have git.
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    Write-Output "NOTE: git is already available ($($gitCmd.Source)). Since you cloned this repo, this is expected."
}

Write-Output ""
Write-Output "===== Dependency status ====="
$missingPkgs = @()
foreach ($cmd in $deps.Keys) {
    $pkg  = $deps[$cmd][0]
    $desc = $deps[$cmd][1]
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) {
        Write-Output ("OK       {0,-10} -> {1}" -f $cmd, $found.Source)
    } else {
        Write-Output ("MISSING  {0,-10} ({1}) -> will install scoop package '{2}'" -f $cmd, $desc, $pkg)
        if ($missingPkgs -notcontains $pkg) { $missingPkgs += $pkg }
    }
}

Write-Output ""
if ($missingPkgs.Count -eq 0) {
    Write-Output "All dependencies already present. Nothing to install."
} else {
    # Verify scoop 'main' bucket exists (needed for most packages)
    $buckets = scoop bucket list 2>$null
    if ($buckets -notmatch 'main') {
        Write-Output "Scoop 'main' bucket is missing. Adding it..."
        scoop bucket add main
        if ($LASTEXITCODE -ne 0) {
            Write-Output ""
            Write-Output "ERROR: Failed to add the 'main' scoop bucket."
            Write-Output "Why it matters: Without the main bucket, scoop cannot find most packages (yazi, fd, jq, etc.)."
            Write-Output "What to do: Run 'scoop bucket add main' manually. If it fails, check your network/proxy settings."
            Write-Output "  -> Scoop proxy docs: https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy"
            return
        }
    }

    Write-Output "Installing missing packages: $($missingPkgs -join ' ')"
    Write-Output "Running: scoop install $($missingPkgs -join ' ')"
    Write-Output ""
    scoop install @missingPkgs
    $installExitCode = $LASTEXITCODE
    Write-Output ""

    if ($installExitCode -ne 0) {
        Write-Output "WARNING: scoop install finished with exit code $installExitCode. Some packages may have failed."
        Write-Output "What to do: Re-run this script to check which packages are still missing."
        Write-Output "  If a specific package keeps failing, try installing it manually:"
        foreach ($pkg in $missingPkgs) {
            Write-Output "    scoop install $pkg"
        }
        Write-Output "  -> Scoop troubleshooting: https://github.com/ScoopInstaller/Scoop/wiki/Troubleshooting"
    } else {
        Write-Output "All packages installed successfully."
    }
    Write-Output "Re-run this script to confirm everything now shows OK."
}

# Auto-set YAZI_FILE_ONE if not already configured
Write-Output ""
Write-Output "===== YAZI_FILE_ONE setup ====="
$existingYfo = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
if ($existingYfo -and (Test-Path $existingYfo)) {
    Write-Output "YAZI_FILE_ONE already set and valid: $existingYfo"
} else {
    $fileExe = $null

    # Method 1: scoop's git
    $scoopGitFile = "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe"
    if (Test-Path $scoopGitFile) {
        $fileExe = $scoopGitFile
        Write-Output "Found file.exe via scoop git: $fileExe"
    }

    # Method 2: git on PATH -> derive file.exe location
    if (-not $fileExe) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) {
            $gitDir = Split-Path (Split-Path $gitCmd.Source)
            $candidate = Join-Path $gitDir "usr\bin\file.exe"
            if (Test-Path $candidate) {
                $fileExe = $candidate
                Write-Output "Found file.exe via git on PATH: $fileExe"
            }
        }
    }

    # Method 3: common Git for Windows install paths
    if (-not $fileExe) {
        $candidates = @(
            "$env:ProgramFiles\Git\usr\bin\file.exe",
            "${env:ProgramFiles(x86)}\Git\usr\bin\file.exe"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                $fileExe = $c
                Write-Output "Found file.exe at standard install path: $fileExe"
                break
            }
        }
    }

    if ($fileExe) {
        [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $fileExe, "User")
        Write-Output ""
        Write-Output "SUCCESS: YAZI_FILE_ONE set to: $fileExe"
        Write-Output "IMPORTANT: Close ALL PowerShell windows and open a new one for this to take effect."
    } else {
        Write-Output ""
        Write-Output "Could not auto-detect git's file.exe."
        Write-Output "Why it matters: Without file.exe, yazi cannot detect file types for previews."
        Write-Output ""
        Write-Output "To set it manually, run this command in a new PowerShell window:"
        Write-Output '  [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe", "User")'
        Write-Output ""
        Write-Output "Or run the standalone helper script:"
        Write-Output "  pwsh -File set-yazi-file-one.ps1"
        Write-Output ""
        Write-Output "After setting, close ALL PowerShell windows and open a new one."
    }
}

} catch {
    Write-Output ""
    Write-Output "ERROR: install-deps.ps1 failed unexpectedly."
    Write-Output "What happened: $($_.Exception.Message)"
    Write-Output "Why it matters: Dependencies may be partially installed. Your yazi setup may be incomplete."
    Write-Output "What to do: Re-run this script. If it keeps failing, report this error at:"
    Write-Output "  https://github.com/karenepitaya/yazi-windows-rescue/issues"
}
