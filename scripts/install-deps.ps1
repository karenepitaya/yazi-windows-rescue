<#
.SYNOPSIS
  Yazi Windows Rescue — dependency check + install.
  Detects which yazi dependencies are present and installs ONLY the missing ones via scoop.

.DESCRIPTION
  Run from PowerShell AFTER scoop is confirmed installed.
  - Prints each dependency as OK or MISSING (with what it's for).
  - Installs only the missing scoop packages (scoop skips anything already installed anyway).
  - Idempotent: safe to run more than once.

  Dependencies and the scoop package that provides each:
    yazi        -> yazi         (the file manager)
    fd          -> fd           (file search inside yazi)
    magick      -> imagemagick  (image previews)
    ffmpeg      -> ffmpeg       (video thumbnail previews)
    pdftoppm    -> poppler      (PDF previews)
    jq          -> jq           (JSON pretty previews)
    git         -> git          (provides file.exe used for MIME detection)
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 > $null
} catch { }

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Output "ERROR: scoop is not installed yet. Install scoop first (see SKILL.md Phase 4a), then re-run this."
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
    Write-Output ("Installing missing packages: " + ($missingPkgs -join " "))
    Write-Output "Running: scoop install $($missingPkgs -join ' ')"
    scoop install $missingPkgs
    Write-Output ""
    Write-Output "Done. Re-run this script to confirm everything now shows OK."
}
