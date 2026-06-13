<#
.SYNOPSIS
  Set YAZI_FILE_ONE environment variable for yazi file previews on Windows.

.DESCRIPTION
  Finds git's file.exe (used by yazi for MIME type detection on Windows) and
  sets the YAZI_FILE_ONE user environment variable permanently.

  Detection order:
    1. Scoop-managed git: $env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe
    2. Git on PATH: derive file.exe from git.exe location
    3. Common Git for Windows install paths (Program Files)

  If auto-detection fails, prints a copy-paste command for manual setup.

  After setting, you MUST close all PowerShell windows and open a new one.

.NOTES
  This helper uses only cmdlets available in every PowerShell version, so it runs
  on Windows PowerShell 5.1 too. PowerShell 7+ (pwsh) is still recommended for the
  rest of this skill. Run with: pwsh -File set-yazi-file-one.ps1
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    chcp 65001 > $null
} catch { }

try {
    Write-Output "===== YAZI_FILE_ONE Setup ====="
    Write-Output "Looking for git's file.exe (needed for yazi file previews on Windows)..."

    # Check if already set and valid
    $existing = [Environment]::GetEnvironmentVariable("YAZI_FILE_ONE", "User")
    if ($existing -and (Test-Path $existing)) {
        Write-Output "YAZI_FILE_ONE is already set and valid: $existing"
        Write-Output "No changes needed."
        Write-Output "YAZI-FILE-ONE: OK"
        exit 0
    }

    $fileExe = $null

    # Method 1: Scoop-managed git (most common in this skill's workflow)
    $scoopPath = "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe"
    if (Test-Path $scoopPath) {
        $fileExe = $scoopPath
        Write-Output "Found via scoop git: $fileExe"
    }

    # Method 2: Git on PATH -> derive file.exe
    if (-not $fileExe) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) {
            $gitRoot = Split-Path (Split-Path $gitCmd.Source)
            $candidate = Join-Path $gitRoot "usr\bin\file.exe"
            if (Test-Path $candidate) {
                $fileExe = $candidate
                Write-Output "Found via git on PATH: $fileExe"
            }
        }
    }

    # Method 3: Standard Git for Windows install locations
    if (-not $fileExe) {
        $candidates = @(
            "$env:ProgramFiles\Git\usr\bin\file.exe",
            "${env:ProgramFiles(x86)}\Git\usr\bin\file.exe"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                $fileExe = $c
                Write-Output "Found at standard install path: $fileExe"
                break
            }
        }
    }

    if ($fileExe) {
        [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $fileExe, "User")
        Write-Output ""
        Write-Output "SUCCESS: YAZI_FILE_ONE set to: $fileExe"
        Write-Output ""
        Write-Output "IMPORTANT: Close ALL PowerShell windows and open a new one."
        Write-Output "The environment variable only takes effect in a fresh session."
        Write-Output "YAZI-FILE-ONE: OK"
        exit 0
    } else {
        Write-Output ""
        Write-Output "ERROR: Could not find git's file.exe on this system."
        Write-Output "Why it matters: Without file.exe, yazi cannot detect file types for previews."
        Write-Output ""
        Write-Output "What to do:"
        Write-Output "  1. Make sure git is installed: scoop install git"
        Write-Output "  2. Then run this script again."
        Write-Output ""
        Write-Output "Or set it manually (copy-paste this into PowerShell):"
        Write-Output '  $f = "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe"'
        Write-Output '  if (Test-Path $f) { [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $f, "User"); "Set OK" } else { "file.exe not found — is git installed via scoop?" }'
        Write-Output ""
        Write-Output "After setting, close ALL PowerShell windows and open a new one."
        Write-Output "YAZI-FILE-ONE: FAILED"
        exit 1
    }

} catch {
    Write-Output ""
    Write-Output "ERROR: set-yazi-file-one.ps1 failed unexpectedly."
    Write-Output "What happened: $($_.Exception.Message)"
    Write-Output "What to do: Try setting YAZI_FILE_ONE manually:"
    Write-Output '  [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe", "User")'
    Write-Output "Then close all PowerShell windows and open a new one."
    Write-Output "YAZI-FILE-ONE: FAILED"
    exit 1
}
