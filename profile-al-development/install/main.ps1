<#
.SYNOPSIS
    Installs prerequisites and all installable MCP servers for the profile-al-development
    Claude Code plugin, then runs the health check.

.DESCRIPTION
    Run via install.ps1 (which fetches this repo first) or directly once the repo is already
    cloned. Every step checks current state before acting, so re-running is always safe.

    Order matters: the plugin must be registered with Claude Code (step 3) before the plugin's
    cache copy of .mcp.json exists on disk, which the alcops step (step 4) needs to read.

.PARAMETER DryRun
    Print the planned actions without installing or changing anything.
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$script:HadFailure = $false

# --- logging helpers ---------------------------------------------------------

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "    OK   $Message" -ForegroundColor Green }
function Write-Skip([string]$Message) { Write-Host "    SKIP $Message" -ForegroundColor DarkGray }
function Write-WarnLine([string]$Message) { Write-Host "    WARN $Message" -ForegroundColor Yellow }
function Write-FailLine([string]$Message) { Write-Host "    FAIL $Message" -ForegroundColor Red; $script:HadFailure = $true }
function Write-DryRunLine([string]$Message) { Write-Host "    [DryRun] would run: $Message" -ForegroundColor Magenta }

$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$PluginDir = Split-Path $PSScriptRoot -Parent

# --- winget helper -------------------------------------------------------------

function Install-WingetPackage([string]$Id, [string]$DisplayName) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-FailLine "$DisplayName — winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
        return
    }

    $already = winget list --id $Id -e 2>$null | Select-String -SimpleMatch $Id
    if ($already) {
        Write-Skip "$DisplayName already installed"
        return
    }

    if ($DryRun) {
        Write-DryRunLine "winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements"
        return
    }

    Write-Host "    Installing $DisplayName via winget..."
    winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$DisplayName installed"
    } else {
        Write-FailLine "$DisplayName — winget install exited with code $LASTEXITCODE"
    }
}

# --- step 1: prerequisites -----------------------------------------------------

function Install-Prerequisites {
    Write-Step "Installing prerequisites (Git, Node.js, .NET SDK, jq) via winget"

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-FailLine "winget not found. This should ship with Windows 11 22H2+; if missing, install 'App Installer' from the Microsoft Store and re-run."
        return
    }

    Install-WingetPackage -Id 'Git.Git' -DisplayName 'Git for Windows'
    Install-WingetPackage -Id 'OpenJS.NodeJS.LTS' -DisplayName 'Node.js LTS'
    Install-WingetPackage -Id 'Microsoft.DotNet.SDK.8' -DisplayName '.NET SDK 8'
    Install-WingetPackage -Id 'jqlang.jq' -DisplayName 'jq (needed by the plugin''s existing compile hooks, not by this installer)'

    # Packages just installed via winget may not be on PATH in this process yet.
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('PATH', 'User')
}

# --- step 2: HOME env var ------------------------------------------------------

function Set-HomeEnvironmentVariable {
    Write-Step "Ensuring `$env:HOME is set (Windows doesn't set it by default; Claude Code's `${HOME} substitution in .mcp.json depends on it)"

    if ($env:HOME -and (Test-Path $env:HOME)) {
        Write-Skip "HOME already set to $env:HOME"
        return
    }

    if ($DryRun) {
        Write-DryRunLine "[Environment]::SetEnvironmentVariable('HOME', '$env:USERPROFILE', 'User')"
        return
    }

    [Environment]::SetEnvironmentVariable('HOME', $env:USERPROFILE, 'User')
    $env:HOME = $env:USERPROFILE
    Write-Ok "HOME set to $env:USERPROFILE (persisted for future sessions, and set for this process)"
}

# --- step 3: plugin registration -----------------------------------------------

function Get-ClaudeSettingsPath {
    Join-Path $env:USERPROFILE '.claude\settings.json'
}

function Register-PluginViaCli {
    # Note: command output comes back as a string[] (one element per line). -match/-notmatch on a
    # collection filter to matching/non-matching *elements*, they don't collapse to a single
    # "does the whole thing contain this" boolean — so join to one string first before matching,
    # or a -notmatch check would spuriously be true (most lines never contain the search term).
    $marketplaceList = (claude plugin marketplace list 2>$null) -join "`n"
    if ($marketplaceList -notmatch 'claude-configs') {
        if ($DryRun) {
            Write-DryRunLine "claude plugin marketplace add `"$RepoRoot`""
        } else {
            claude plugin marketplace add "$RepoRoot" | Out-Null
        }
    }

    $pluginList = (claude plugin list 2>$null) -join "`n"
    if ($pluginList -notmatch 'profile-al-development') {
        if ($DryRun) {
            Write-DryRunLine "claude plugin install profile-al-development@claude-configs"
        } else {
            claude plugin install 'profile-al-development@claude-configs' | Out-Null
        }
    }

    if ($DryRun) { return $true }

    $pluginList = (claude plugin list 2>$null) -join "`n"
    return [bool]($pluginList -match 'profile-al-development')
}

function Register-PluginViaSettingsFile {
    $settingsPath = Get-ClaudeSettingsPath
    Write-WarnLine "Falling back to editing $settingsPath directly"

    if ($DryRun) {
        Write-DryRunLine "merge extraKnownMarketplaces.claude-configs + enabledPlugins.'profile-al-development@claude-configs' into $settingsPath"
        return
    }

    $settings = if (Test-Path $settingsPath) {
        Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else {
        New-Item -ItemType Directory -Path (Split-Path $settingsPath -Parent) -Force | Out-Null
        [PSCustomObject]@{}
    }

    if (-not $settings.PSObject.Properties['extraKnownMarketplaces']) {
        $settings | Add-Member -NotePropertyName extraKnownMarketplaces -NotePropertyValue ([PSCustomObject]@{})
    }
    $settings.extraKnownMarketplaces | Add-Member -NotePropertyName 'claude-configs' -NotePropertyValue ([PSCustomObject]@{
        source = [PSCustomObject]@{ source = 'directory'; path = $RepoRoot }
    }) -Force

    if (-not $settings.PSObject.Properties['enabledPlugins']) {
        $settings | Add-Member -NotePropertyName enabledPlugins -NotePropertyValue ([PSCustomObject]@{})
    }
    $settings.enabledPlugins | Add-Member -NotePropertyName 'profile-al-development@claude-configs' -NotePropertyValue $true -Force

    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    Write-Ok "Wrote marketplace + plugin entries to $settingsPath"
}

function Register-Plugin {
    Write-Step "Registering the profile-al-development plugin with Claude Code"

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-FailLine "claude CLI not found on PATH. Install Claude Code first — this installer assumes it's already present."
        return
    }

    $ok = $false
    try {
        $ok = Register-PluginViaCli
    } catch {
        Write-WarnLine "claude plugin CLI failed: $($_.Exception.Message)"
    }

    if ($ok) {
        Write-Ok "Plugin registered (or already was) via the claude CLI"
    } elseif (-not $DryRun) {
        Register-PluginViaSettingsFile
    }
}

# --- step 4: MCP servers -------------------------------------------------------

function Get-InstalledPluginCacheMcpConfig {
    $cacheRoot = Join-Path $env:USERPROFILE '.claude\plugins\cache\claude-configs\profile-al-development'
    if (-not (Test-Path $cacheRoot)) { return $null }

    $versionDir = Get-ChildItem -Path $cacheRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object { try { [version]$_.Name } catch { [version]'0.0.0' } } -Descending |
        Select-Object -First 1
    if (-not $versionDir) { return $null }

    $mcpPath = Join-Path $versionDir.FullName '.mcp.json'
    if (-not (Test-Path $mcpPath)) { return $null }

    return Get-Content $mcpPath -Raw | ConvertFrom-Json
}

function Install-AlMcpServer {
    Write-Step "Warming al-mcp-server (runs on-demand via npx, nothing to install permanently)"
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-FailLine "npx not found — Node.js install may not have completed. Skipping."
        return
    }
    if ($DryRun) { Write-DryRunLine "npx --yes al-mcp-server --version"; return }

    try {
        npx --yes al-mcp-server --version 2>$null | Out-Null
        Write-Ok "al-mcp-server warmed"
    } catch {
        Write-WarnLine "Couldn't warm al-mcp-server ahead of time; it will still install on first real use via npx."
    }
}

function Install-BcCodeIntelligenceMcp {
    Write-Step "Installing bc-code-intelligence-mcp (npm global)"
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-FailLine "npm not found — Node.js install may not have completed. Skipping."
        return
    }
    if (Get-Command bc-code-intelligence-mcp -ErrorAction SilentlyContinue) {
        Write-Skip "bc-code-intelligence-mcp already on PATH"
        return
    }
    if ($DryRun) { Write-DryRunLine "npm install -g bc-code-intelligence-mcp"; return }

    npm install -g bc-code-intelligence-mcp
    if (Get-Command bc-code-intelligence-mcp -ErrorAction SilentlyContinue) {
        Write-Ok "bc-code-intelligence-mcp installed"
    } else {
        Write-FailLine "bc-code-intelligence-mcp — npm install completed but the binary still isn't on PATH. You may need to restart your shell."
    }
}

function Install-Alcops {
    Write-Step "Installing alcops (ALCops.Mcp dotnet tool + pinned BC DevTools)"

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        Write-FailLine "dotnet not found — .NET SDK install may not have completed. Skipping."
        return
    }

    $existingTools = dotnet tool list -g 2>$null
    if ($existingTools -match 'alcops\.mcp') {
        Write-Skip "ALCops.Mcp already installed as a global dotnet tool"
    } elseif ($DryRun) {
        Write-DryRunLine "dotnet tool install -g ALCops.Mcp --prerelease"
    } else {
        dotnet tool install -g ALCops.Mcp --prerelease
        if ($LASTEXITCODE -ne 0) {
            Write-FailLine "dotnet tool install -g ALCops.Mcp --prerelease exited with code $LASTEXITCODE"
        } else {
            Write-Ok "ALCops.Mcp installed"
        }
    }

    # The pinned BC DevTools version is only knowable from the plugin's installed .mcp.json —
    # it drifts as ALCops.Mcp updates, and we deliberately never hardcode or edit it here.
    $mcpConfig = Get-InstalledPluginCacheMcpConfig
    $toolsPath = $mcpConfig.mcpServers.alcops.env.BCDEVELOPMENTTOOLSPATH
    if (-not $toolsPath) {
        Write-WarnLine "Couldn't read BCDEVELOPMENTTOOLSPATH from the installed plugin's .mcp.json (plugin not registered yet?). Skipping BC DevTools install — re-run this script after the plugin is registered."
        return
    }

    $resolvedToolsPath = $toolsPath -replace '\$\{HOME\}', $env:USERPROFILE
    if ($resolvedToolsPath -match 'devtools-([\d.]+)') {
        $version = $Matches[1]
    } else {
        Write-WarnLine "Couldn't parse a version out of BCDEVELOPMENTTOOLSPATH ('$toolsPath'). Skipping BC DevTools install."
        return
    }
    $toolPath = ($resolvedToolsPath -split '/\.store/')[0]

    if (Test-Path $resolvedToolsPath) {
        Write-Skip "BC DevTools $version already installed at $toolPath"
        return
    }

    if ($DryRun) {
        Write-DryRunLine "dotnet tool install Microsoft.Dynamics.BusinessCentral.Development.Tools --version $version --tool-path `"$toolPath`""
        return
    }

    dotnet tool install Microsoft.Dynamics.BusinessCentral.Development.Tools --version $version --tool-path "$toolPath"
    if ($LASTEXITCODE -eq 0 -and (Test-Path $resolvedToolsPath)) {
        Write-Ok "BC DevTools $version installed at $toolPath (matches BCDEVELOPMENTTOOLSPATH exactly)"
    } else {
        Write-FailLine "BC DevTools install for version $version did not produce the expected path ($resolvedToolsPath). See the plugin README's ALCops troubleshooting section."
    }
}

function Install-BcTelemetryBuddy {
    Write-Step "bc-telemetry-buddy (bctb-mcp)"
    Write-Skip "Not auto-installed — no public npm/PyPI/NuGet package exists for bctb-mcp. This is expected; see the plugin README."
}

function Install-McpServers {
    Install-AlMcpServer
    Install-BcCodeIntelligenceMcp
    Install-Alcops
    Install-BcTelemetryBuddy
    Write-Step "microsoft_docs_mcp"
    Write-Skip "Remote HTTP endpoint — nothing to install"
}

# --- main ------------------------------------------------------------------------

Write-Host "profile-al-development installer" -ForegroundColor White
Write-Host "Repo:   $RepoRoot"
Write-Host "Plugin: $PluginDir"
if ($DryRun) { Write-Host "Mode:   DRY RUN — no changes will be made" -ForegroundColor Magenta }

Install-Prerequisites
Set-HomeEnvironmentVariable
Register-Plugin
Install-McpServers

Write-Step "Running health check"
$healthCheckScript = Join-Path $PSScriptRoot 'health-check.ps1'
# Run as a child process, not `& $healthCheckScript` in-process: health-check.ps1 ends with
# `exit`, which would otherwise terminate this script too and skip the summary below.
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $healthCheckScript
$healthCheckExitCode = $LASTEXITCODE

if ($script:HadFailure) {
    Write-Host "`nInstaller finished with at least one FAIL above — see the plugin README's troubleshooting section." -ForegroundColor Red
    exit 1
}

exit $healthCheckExitCode
