<#
.SYNOPSIS
    One-click bootstrap for the profile-al-development Claude Code plugin on Windows.

.DESCRIPTION
    Tiny, deliberately dumb entry point: get a copy of this repo onto disk (git clone if
    git is already available, otherwise download the GitHub zip so a bare machine with only
    Claude Code installed can still get started), then hand off to install/main.ps1 for the
    actual prerequisite/MCP-server installation work.

    Intended usage (review the script at the URL below before running it):

        irm https://raw.githubusercontent.com/HazardMK/claude-configs/master/profile-al-development/install/install.ps1 | iex

    Safe to re-run. Never runs `git push`/`git commit`/`git checkout .` against an existing
    clone; only clones if one doesn't already exist at -InstallPath.

.PARAMETER InstallPath
    Where to put (or find) the claude-configs clone. Default: $env:USERPROFILE\claude-configs.

.PARAMETER RepoOwner
    GitHub owner of the claude-configs repo to install from. Default: HazardMK.

.PARAMETER Ref
    Branch (or tag) to install. Default: master.

.PARAMETER SyncRepo
    If the repo already exists locally, run `git pull --ff-only` on it before continuing.

.PARAMETER DryRun
    Forwarded to main.ps1: print the planned actions without installing anything.

.NOTES
    No [CmdletBinding()] here deliberately: this file is meant to be piped through `iex`
    (`irm ... | iex`), where it's evaluated as a script block rather than invoked as a command —
    parameters can't be passed through that way regardless, so only the defaults below ever
    apply for the one-liner. Download the file and run it directly (`-File`) to pass switches
    like -DryRun. main.ps1, which is always invoked with -File, does use [CmdletBinding()].
#>
param(
    [string]$InstallPath = (Join-Path $env:USERPROFILE 'claude-configs'),
    [string]$RepoOwner = 'HazardMK',
    [string]$Ref = 'master',
    [switch]$SyncRepo,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-BootstrapStep([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 or later is required (found $($PSVersionTable.PSVersion)). Update PowerShell and re-run."
    exit 1
}

# Windows PowerShell 5.1 defaults to TLS 1.0 on some machines; GitHub requires TLS 1.2+.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    # Best-effort; some older runtimes don't expose Tls12 as an enum member.
}

$repoUrl = "https://github.com/$RepoOwner/claude-configs.git"

if (Test-Path (Join-Path $InstallPath '.git')) {
    Write-BootstrapStep "Found existing clone at $InstallPath"
    if ($SyncRepo) {
        Write-BootstrapStep "Syncing (git pull --ff-only)"
        Push-Location $InstallPath
        try { git pull --ff-only } finally { Pop-Location }
    }
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
    Write-BootstrapStep "Cloning $repoUrl (branch $Ref) into $InstallPath"
    git clone --branch $Ref --single-branch $repoUrl $InstallPath
} else {
    Write-BootstrapStep "git not found yet — downloading $Ref as a zip instead"
    $zipUrl = "https://github.com/$RepoOwner/claude-configs/archive/refs/heads/$Ref.zip"
    $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) "claude-configs-$Ref.zip"
    $extractDir = Join-Path ([System.IO.Path]::GetTempPath()) "claude-configs-extract-$([guid]::NewGuid())"

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    Get-ChildItem -Path $extractDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

    $extractedRoot = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    if (-not $extractedRoot) {
        Write-Error "Download extracted but no repo folder was found under $extractDir"
        exit 1
    }

    New-Item -ItemType Directory -Path (Split-Path $InstallPath -Parent) -Force | Out-Null
    Move-Item -Path $extractedRoot.FullName -Destination $InstallPath
    Remove-Item -Path $zipPath, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}

$mainScript = Join-Path $InstallPath 'profile-al-development\install\main.ps1'
if (-not (Test-Path $mainScript)) {
    Write-Error "Expected to find $mainScript after fetching the repo, but it's missing. Aborting."
    exit 1
}

Write-BootstrapStep "Handing off to main.ps1"

$mainArgs = @()
if ($DryRun) { $mainArgs += '-DryRun' }

# Run as a child process (rather than dot-sourcing) so -ExecutionPolicy Bypass applies only to
# this one process, not the user's machine-wide policy.
$psi = @{
    FilePath     = 'powershell.exe'
    ArgumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$mainScript`"") + $mainArgs
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
}
$proc = Start-Process @psi
exit $proc.ExitCode
