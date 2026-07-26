<#
.SYNOPSIS
    Standalone health/status check for the profile-al-development plugin's Windows install.

.DESCRIPTION
    Read-only — makes no changes. Called by main.ps1 at the end of installation, and by the
    /install-status skill from inside a live Claude Code session.

    Deliberately reads the *installed plugin cache* copy of .mcp.json
    (~/.claude/plugins/cache/claude-configs/profile-al-development/<version>/.mcp.json), not the
    git-tracked repo copy — the cache copy is what Claude Code actually loads at runtime, and a
    check against the repo copy can report healthy while the live session is still broken.

.OUTPUTS
    A PASS/WARN/FAIL/SKIP table on stdout. Exits 0 if every required check passed (SKIPs for
    intentionally-not-installed components don't count against this), exits 1 otherwise.
#>
[CmdletBinding()]
param()

$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Component, [string]$Status, [string]$Detail) {
    $results.Add([PSCustomObject]@{ Component = $Component; Status = $Status; Detail = $Detail })
}

function Test-CommandVersion([string]$Command, [string[]]$VersionArgs) {
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    try {
        $out = & $Command @VersionArgs 2>$null
        return ($out | Select-Object -First 1)
    } catch {
        return "$Command (version check failed)"
    }
}

# --- basics ------------------------------------------------------------------

Add-Result 'PowerShell' 'PASS' "$($PSVersionTable.PSVersion) on $([System.Environment]::OSVersion.VersionString)"

foreach ($tool in @(
    @{ Name = 'git'; Args = @('--version') },
    @{ Name = 'node'; Args = @('--version') },
    @{ Name = 'npm'; Args = @('--version') },
    @{ Name = 'npx'; Args = @('--version') },
    @{ Name = 'dotnet'; Args = @('--version') },
    @{ Name = 'jq'; Args = @('--version') }
)) {
    $version = Test-CommandVersion -Command $tool.Name -VersionArgs $tool.Args
    if ($version) {
        Add-Result $tool.Name 'PASS' $version
    } else {
        Add-Result $tool.Name 'FAIL' 'not found on PATH'
    }
}

if ($env:HOME -and (Test-Path $env:HOME)) {
    Add-Result 'HOME env var' 'PASS' $env:HOME
} else {
    Add-Result 'HOME env var' 'FAIL' 'not set, or set to a path that does not exist'
}

# --- plugin registration -------------------------------------------------------

if (Get-Command claude -ErrorAction SilentlyContinue) {
    $pluginList = (claude plugin list 2>$null) -join "`n"
    if ($pluginList -match 'profile-al-development') {
        Add-Result 'Plugin registered' 'PASS' 'profile-al-development@claude-configs is enabled'
    } else {
        Add-Result 'Plugin registered' 'FAIL' "'claude plugin list' does not show profile-al-development enabled"
    }
} else {
    Add-Result 'Plugin registered' 'FAIL' 'claude CLI not found on PATH'
}

# --- installed cache copy of .mcp.json -----------------------------------------

$cacheRoot = Join-Path $env:USERPROFILE '.claude\plugins\cache\claude-configs\profile-al-development'
$mcpConfig = $null
$versionDir = $null

if (Test-Path $cacheRoot) {
    $versionDir = Get-ChildItem -Path $cacheRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object { try { [version]$_.Name } catch { [version]'0.0.0' } } -Descending |
        Select-Object -First 1
}

if ($versionDir) {
    $mcpPath = Join-Path $versionDir.FullName '.mcp.json'
    if (Test-Path $mcpPath) {
        Add-Result 'Plugin cache copy' 'PASS' $mcpPath
        $mcpConfig = Get-Content $mcpPath -Raw | ConvertFrom-Json
    } else {
        Add-Result 'Plugin cache copy' 'FAIL' "version dir found ($($versionDir.FullName)) but .mcp.json is missing"
    }
} else {
    Add-Result 'Plugin cache copy' 'FAIL' "no cached install found under $cacheRoot"
}

# --- MCP servers, read from the cache copy -------------------------------------

if ($mcpConfig) {
    # microsoft_docs_mcp — remote HTTP endpoint
    try {
        $resp = Invoke-WebRequest -Uri $mcpConfig.mcpServers.microsoft_docs_mcp.url -Method Head -TimeoutSec 5 -UseBasicParsing
        Add-Result 'microsoft_docs_mcp' 'PASS' "reachable ($($resp.StatusCode))"
    } catch {
        Add-Result 'microsoft_docs_mcp' 'WARN' 'endpoint not reachable right now (network/proxy?) — not fatal, it is checked again on first real use'
    }

    # al-mcp-server — on-demand via npx
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        Add-Result 'al-mcp-server' 'PASS' 'npx available; server installs on-demand on first use'
    } else {
        Add-Result 'al-mcp-server' 'FAIL' 'npx not found — cannot run this on-demand server'
    }

    # bc-code-intelligence-mcp — global npm install + config file must resolve
    if (Get-Command bc-code-intelligence-mcp -ErrorAction SilentlyContinue) {
        $configEnvValue = $mcpConfig.mcpServers.'bc-code-intelligence-mcp'.env.BC_CODE_INTEL_CONFIG
        $resolvedConfigPath = $configEnvValue -replace '\$\{HOME\}', $env:USERPROFILE
        if ($resolvedConfigPath -and (Test-Path $resolvedConfigPath)) {
            $knowledgeConfig = Get-Content $resolvedConfigPath -Raw | ConvertFrom-Json
            $sourcePath = $knowledgeConfig.knowledge_layers[0].source.path
            # bc-code-intelligence-mcp expands a leading ~ itself (os.homedir()), so a literal
            # ~ here is expected and correct — resolve it the same way before checking it exists.
            $resolvedSourcePath = if ($sourcePath -match '^~') { $sourcePath -replace '^~', $env:USERPROFILE } else { $sourcePath }
            if (Test-Path $resolvedSourcePath) {
                Add-Result 'bc-code-intelligence-mcp' 'PASS' "binary on PATH, config resolves, knowledge dir exists ($resolvedSourcePath)"
            } else {
                Add-Result 'bc-code-intelligence-mcp' 'FAIL' "config's source.path does not exist on disk: $resolvedSourcePath"
            }
        } else {
            Add-Result 'bc-code-intelligence-mcp' 'FAIL' "BC_CODE_INTEL_CONFIG ('$configEnvValue') does not resolve to a file that exists"
        }
    } else {
        Add-Result 'bc-code-intelligence-mcp' 'FAIL' 'binary not found on PATH'
    }

    # alcops — binary AND the pinned DevTools directory must both exist
    $alcopsToolsPath = $mcpConfig.mcpServers.alcops.env.BCDEVELOPMENTTOOLSPATH
    $resolvedAlcopsPath = $alcopsToolsPath -replace '\$\{HOME\}', $env:USERPROFILE
    $alcopsBinaryOk = [bool](Get-Command alcops-mcp -ErrorAction SilentlyContinue)
    $alcopsPathOk = $resolvedAlcopsPath -and (Test-Path $resolvedAlcopsPath)
    if ($alcopsBinaryOk -and $alcopsPathOk) {
        Add-Result 'alcops' 'PASS' "binary on PATH, BCDEVELOPMENTTOOLSPATH exists ($resolvedAlcopsPath)"
    } elseif ($alcopsBinaryOk -and -not $alcopsPathOk) {
        Add-Result 'alcops' 'FAIL' "binary found, but BCDEVELOPMENTTOOLSPATH does not exist on disk: $resolvedAlcopsPath (this is the documented ALCops version-mismatch failure mode — see README)"
    } else {
        Add-Result 'alcops' 'FAIL' 'alcops-mcp binary not found on PATH'
    }

    # bc-telemetry-buddy — expected skip
    Add-Result 'bc-telemetry-buddy' 'SKIP' 'not auto-installed — no public package exists (expected)'
} else {
    foreach ($name in @('microsoft_docs_mcp', 'al-mcp-server', 'bc-code-intelligence-mcp', 'alcops', 'bc-telemetry-buddy')) {
        Add-Result $name 'FAIL' 'could not check — plugin cache copy of .mcp.json was not found'
    }
}

# --- report ----------------------------------------------------------------------

Write-Host ""
$results | Format-Table -AutoSize -Wrap -Property Component, Status, Detail | Out-String | Write-Host

$failures = $results | Where-Object { $_.Status -eq 'FAIL' }
if ($failures.Count -gt 0) {
    Write-Host "$($failures.Count) check(s) FAILED. See the plugin README's Troubleshooting section." -ForegroundColor Red
    exit 1
}

Write-Host "All required checks passed." -ForegroundColor Green
exit 0
