<#
.SYNOPSIS
  Yazi Windows Rescue — terminal-boost tool installer.
  Detects which modern CLI tools are present and installs ONLY the missing ones via scoop.

.DESCRIPTION
  Run from PowerShell 7+ (pwsh) AFTER scoop is confirmed installed.
  - Prints each tool as OK or MISSING.
  - Installs only the missing scoop packages.
  - Idempotent: safe to run more than once.

  Tools and the scoop package that provides each:
    eza         -> eza          (modern ls with icons/git)
    bat         -> bat          (cat with syntax highlighting)
    delta       -> delta        (pretty git diffs)
    starship    -> starship     (cross-shell prompt)
    dust        -> dust         (visual du)
    duf         -> duf          (friendlier df)
    procs       -> procs        (modern ps)
    btm         -> bottom       (htop replacement)
    yq          -> yq           (YAML/JSON processor)

.NOTES
  Designed for PowerShell 7+.
#>

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    chcp 65001 > $null
} catch { }

$setupOk = $true

if ($PSVersionTable.PSVersion.Major -lt 6) {
    Write-Output "This step needs PowerShell 7 (pwsh)."
    Write-Output "INSTALL-TERMINAL-TOOLS: PARTIAL"
    exit 1
}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Output "ERROR: scoop is not installed yet."
    Write-Output "INSTALL-TERMINAL-TOOLS: PARTIAL"
    exit 1
}

# command-name -> @(scoop-package, human description)
$tools = [ordered]@{
    "eza"      = @("eza",       "modern ls with icons/git")
    "bat"      = @("bat",       "cat with syntax highlighting")
    "delta"    = @("delta",     "pretty git diffs")
    "starship" = @("starship",  "cross-shell prompt")
    "dust"     = @("dust",      "visual du")
    "duf"      = @("duf",       "friendlier df")
    "procs"    = @("procs",     "modern ps")
    "btm"      = @("bottom",    "htop replacement")
    "yq"       = @("yq",        "YAML/JSON processor")
}

Write-Output ""
Write-Output "===== Terminal tool status ====="
$missingPkgs = @()
foreach ($cmd in $tools.Keys) {
    $pkg  = $tools[$cmd][0]
    $desc = $tools[$cmd][1]
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
    Write-Output "All terminal tools already present. Nothing to install."
} else {
    $buckets = scoop bucket list 2>$null
    if ($buckets -notmatch 'main') {
        Write-Output "Scoop 'main' bucket is missing. Adding it..."
        scoop bucket add main
        if ($LASTEXITCODE -ne 0) {
            Write-Output "ERROR: Failed to add the 'main' scoop bucket."
            Write-Output "INSTALL-TERMINAL-TOOLS: PARTIAL"
            exit 1
        }
    }

    Write-Output "Installing missing packages: $($missingPkgs -join ' ')"
    scoop install @missingPkgs
    $installExitCode = $LASTEXITCODE

    if ($installExitCode -ne 0) {
        $setupOk = $false
        Write-Output "WARNING: scoop install finished with exit code $installExitCode."
    } else {
        Write-Output "All packages installed successfully."
    }
}

$stillMissing = @()
foreach ($cmd in $tools.Keys) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        $stillMissing += $cmd
    }
}
if ($stillMissing.Count -gt 0) {
    $setupOk = $false
    Write-Output ""
    Write-Output "Still missing after install attempt: $($stillMissing -join ', ')"
}

Write-Output ""
if ($setupOk) {
    Write-Output "INSTALL-TERMINAL-TOOLS: OK"
    exit 0
} else {
    Write-Output "INSTALL-TERMINAL-TOOLS: PARTIAL"
    exit 1
}
