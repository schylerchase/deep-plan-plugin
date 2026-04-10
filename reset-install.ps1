# deep-plan reset-install (Windows)
# Cleans up stale/zombie plugin state and reinstalls CE + deep-plan from
# canonical HTTPS URLs. Use this when a previous install failed partway
# through, or after the deep-plan-plugin repo history was rewritten.
#
# Handles:
#   - Zombie marketplace cache dirs left behind by failed clones
#   - Stale marketplace registrations pointing at wrong URLs
#   - SSH "No ED25519 host key is known for github.com" on fresh installs
#   - Plugins installed from outdated/incorrect marketplace sources
#
# Does NOT handle:
#   - Installing GSD (distributed via Discord, manual step)
#   - Installing Claude Code itself

$ErrorActionPreference = "Continue"  # graceful fallthrough; we check $LASTEXITCODE manually

# --- Canonical sources (HTTPS sidesteps SSH host-key failures) ---
$CeHttps            = 'https://github.com/EveryInc/compound-engineering-plugin.git'
$DeepPlanHttps      = 'https://github.com/schylerchase/deep-plan-plugin.git'
$CeMarketName       = 'compound-engineering-plugin'
$DeepPlanMarketName = 'deep-plan-plugin'
$CePluginName       = 'compound-engineering'
$DeepPlanPluginName = 'deep-plan'

# --- Helpers ---
function Pass($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "==> $msg" -ForegroundColor Blue }

# --- Banner ---
Write-Host ""
Write-Host "deep-plan reset-install" -ForegroundColor White
Write-Host "Scrub stale state, reinstall CE + deep-plan from canonical URLs"
Write-Host ""
Write-Host "This will:" -ForegroundColor White
Write-Host "  1. Trust GitHub's SSH host key (if not already)"
Write-Host "  2. Remove any stale or broken marketplace entries"
Write-Host "  3. Uninstall CE and deep-plan if present"
Write-Host "  4. Reinstall CE from canonical HTTPS URL"
Write-Host "  5. Reinstall deep-plan from canonical HTTPS URL"
Write-Host "  6. Verify both plugins are registered"
Write-Host ""

# --- [1/6] Pre-flight ---
Info "[1/6] Pre-flight checks"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Fail "Claude Code CLI not found on PATH"
    Write-Host ""
    Write-Host "    Install it first, then re-run this script:"
    Write-Host "      winget install Anthropic.ClaudeCode"
    Write-Host "    Requires Git for Windows: https://git-scm.com/downloads/win"
    Write-Host ""
    exit 1
}
Pass "claude CLI found"

# --- [2/6] Fix SSH host key (belt + suspenders) ---
Write-Host ""
Info "[2/6] Trusting GitHub SSH host key (courtesy fix)"

$sshDir = Join-Path $env:USERPROFILE ".ssh"
$knownHosts = Join-Path $sshDir "known_hosts"

if (-not (Test-Path $sshDir)) {
    try {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        Pass "Created $sshDir"
    } catch {
        Warn "Could not create $sshDir - HTTPS URLs will still work"
    }
}

$alreadyTrusted = $false
if (Test-Path $knownHosts) {
    if (Select-String -Quiet -SimpleMatch "github.com" $knownHosts) {
        $alreadyTrusted = $true
        Pass "github.com already in known_hosts"
    }
}

if (-not $alreadyTrusted -and (Test-Path $sshDir)) {
    if (Get-Command ssh-keyscan -ErrorAction SilentlyContinue) {
        try {
            $keys = ssh-keyscan -t ed25519,rsa github.com 2>$null
            if ($keys) {
                Add-Content -Path $knownHosts -Value $keys
                Pass "Added github.com host keys to known_hosts"
            } else {
                Warn "ssh-keyscan returned nothing (network?) - HTTPS URLs will still work"
            }
        } catch {
            Warn "ssh-keyscan failed - HTTPS URLs will still work"
        }
    } else {
        Warn "ssh-keyscan not available - HTTPS URLs will still work"
    }
}

# --- [3/6] Scrub stale plugin state ---
Write-Host ""
Info "[3/6] Scrubbing stale plugin state"

# Uninstall plugins (quiet - expected to fail if not installed)
Write-Host "    Uninstalling existing CE and deep-plan plugins..."
claude plugin uninstall $CePluginName 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Uninstalled $CePluginName" }
else { Warn "$CePluginName not installed (skipping)" }

claude plugin uninstall $DeepPlanPluginName 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Uninstalled $DeepPlanPluginName" }
else { Warn "$DeepPlanPluginName not installed (skipping)" }

# Remove marketplace entries by all plausible names (canonical + zombie variants)
Write-Host "    Removing stale marketplace registrations..."
$staleMarketNames = @(
    'compound-engineering-plugin',
    'compound-engineering-claude-code-plugin',
    'compound-engineering',
    'deep-plan-plugin',
    'deep-plan',
    'schylerchase-deep-plan-plugin'
)
foreach ($name in $staleMarketNames) {
    claude plugin marketplace remove $name 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Pass "Removed marketplace: $name" }
}

# Belt + suspenders: delete any leftover cache dirs matching known zombie patterns
Write-Host "    Scrubbing leftover marketplace cache directories..."
$marketplacesDir = Join-Path $env:USERPROFILE ".claude\plugins\marketplaces"
if (Test-Path $marketplacesDir) {
    $zombiePatterns = @(
        'compound-engineering-plugin',
        'compound-engineering-claude-code-plugin',
        'deep-plan-plugin',
        'schylerchase-deep-plan-plugin'
    )
    foreach ($pattern in $zombiePatterns) {
        $dir = Join-Path $marketplacesDir $pattern
        if (Test-Path $dir) {
            try {
                Remove-Item -Recurse -Force $dir -ErrorAction Stop
                Pass "Removed leftover dir: $pattern"
            } catch {
                Warn "Could not remove $pattern (may be in use - try closing Claude Code)"
            }
        }
    }
}

# --- [4/6] Fresh install CE ---
Write-Host ""
Info "[4/6] Installing Compound Engineering"
Write-Host ""

claude plugin marketplace add $CeHttps
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Fail "Failed to add CE marketplace from $CeHttps"
    Write-Host ""
    Write-Host "    Check network, firewall, and GitHub status."
    Write-Host "    Then try manually:"
    Write-Host "      claude plugin marketplace add $CeHttps"
    Write-Host ""
    exit 1
}
Pass "CE marketplace added"

claude plugin install "$CePluginName@$CeMarketName"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Fail "Failed to install CE plugin"
    Write-Host ""
    Write-Host "    Try manually:"
    Write-Host "      claude plugin install $CePluginName@$CeMarketName"
    Write-Host ""
    exit 1
}
Pass "CE plugin installed"

# --- [5/6] Fresh install deep-plan ---
Write-Host ""
Info "[5/6] Installing deep-plan"
Write-Host ""

claude plugin marketplace add $DeepPlanHttps
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Fail "Failed to add deep-plan marketplace from $DeepPlanHttps"
    Write-Host ""
    Write-Host "    Check network, firewall, and GitHub status."
    Write-Host "    Then try manually:"
    Write-Host "      claude plugin marketplace add $DeepPlanHttps"
    Write-Host ""
    exit 1
}
Pass "deep-plan marketplace added"

claude plugin install "$DeepPlanPluginName@$DeepPlanMarketName"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Fail "Failed to install deep-plan plugin"
    Write-Host ""
    Write-Host "    Try manually:"
    Write-Host "      claude plugin install $DeepPlanPluginName@$DeepPlanMarketName"
    Write-Host ""
    exit 1
}
Pass "deep-plan plugin installed"

# --- [6/6] Verify ---
Write-Host ""
Info "[6/6] Verifying installation"

$pluginsFile = Join-Path $env:USERPROFILE ".claude\plugins\installed_plugins.json"
if (Test-Path $pluginsFile) {
    $content = Get-Content $pluginsFile -Raw
    if ($content -match 'compound-engineering@') {
        Pass "CE registered in installed_plugins.json"
    } else {
        Warn "CE not found in installed_plugins.json (install may have partially completed)"
    }
    if ($content -match 'deep-plan@') {
        Pass "deep-plan registered in installed_plugins.json"
    } else {
        Warn "deep-plan not found in installed_plugins.json (install may have partially completed)"
    }
} else {
    Warn "Could not find installed_plugins.json - verification skipped"
}

# --- Success ---
Write-Host ""
Write-Host "Reset complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Close and reopen Claude Code" -ForegroundColor White
Write-Host "     (plugin changes need a restart to take effect)"
Write-Host ""
Write-Host "  2. Inside a fresh Claude Code session, run:" -ForegroundColor White
Write-Host "       /deep-plan-doctor"
Write-Host "     to verify deep-plan can see CE and GSD."
Write-Host ""
Write-Host "  3. If /deep-plan-doctor reports GSD missing:" -ForegroundColor White
Write-Host "     This script does NOT install GSD (distributed via Discord)."
Write-Host "     Join: https://discord.gg/gsd-plugin"
Write-Host "     Then follow install instructions in #getting-started."
Write-Host ""
