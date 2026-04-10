# deep-plan plugin installer (Windows)
# Checks prerequisites (GSD, Compound Engineering) and installs deep-plan

$ErrorActionPreference = "Stop"

function Pass($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  [MISSING] $msg" -ForegroundColor Red }
function Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "==> $msg" -ForegroundColor Blue }

Write-Host ""
Write-Host "deep-plan installer" -ForegroundColor White
Write-Host "Bridges GSD strategic planning with CE implementation planning"
Write-Host ""

$errors = 0

# --- Check Claude Code ---
Info "Checking prerequisites..."

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Pass "Claude Code CLI"
} else {
    Fail "Claude Code CLI not found"
    Write-Host ""
    Write-Host "    Install Claude Code first:"
    Write-Host "      winget install Anthropic.ClaudeCode"
    Write-Host "    Requires Git for Windows: https://git-scm.com/downloads/win"
    Write-Host ""
    $errors++
}

# --- Check GSD ---
$gsdPath = Join-Path $env:USERPROFILE ".claude\get-shit-done\bin\gsd-tools.cjs"
if (Test-Path $gsdPath) {
    Pass "GSD (Get Shit Done)"
} else {
    Fail "GSD not found"
    Write-Host ""
    Write-Host "    GSD is distributed through its Discord community."
    Write-Host "    1. Join: https://discord.gg/gsd-plugin"
    Write-Host "    2. Follow install instructions in #getting-started"
    Write-Host ""
    $errors++
}

# --- Check Compound Engineering ---
$pluginsFile = Join-Path $env:USERPROFILE ".claude\plugins\installed_plugins.json"
if ((Test-Path $pluginsFile) -and (Select-String -Quiet "compound-engineering" $pluginsFile)) {
    Pass "Compound Engineering (CE)"
} else {
    Fail "Compound Engineering not found"
    Write-Host ""
    Write-Host "    Install CE with:"
    Write-Host "      claude plugin marketplace add EveryInc/compound-engineering-plugin"
    Write-Host "      claude plugin install compound-engineering"
    Write-Host ""
    $errors++
}

# --- Bail if prerequisites missing ---
if ($errors -gt 0) {
    Write-Host ""
    Write-Host "$errors prerequisite(s) missing. Install them first, then re-run this script." -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""

# --- Install deep-plan ---
Info "Installing deep-plan plugin..."
Write-Host ""

try {
    claude plugin marketplace add schylerchase/deep-plan-plugin
    if ($LASTEXITCODE -ne 0) { throw "marketplace add failed" }
    claude plugin install deep-plan
    if ($LASTEXITCODE -ne 0) { throw "plugin install failed" }
    Write-Host ""
    Pass "deep-plan installed"
} catch {
    Write-Host ""
    Fail "Installation failed"
    Write-Host ""
    Write-Host "    Try manually:"
    Write-Host "      claude plugin marketplace add schylerchase/deep-plan-plugin"
    Write-Host "      claude plugin install deep-plan"
    Write-Host ""
    exit 1
}

# --- Verify ---
Write-Host ""
Info "Verifying installation..."

if ((Test-Path $pluginsFile) -and (Select-String -Quiet "deep-plan" $pluginsFile)) {
    Pass "deep-plan plugin registered"
} else {
    Warn "Could not verify in plugins file (this is OK if Claude prompted you to confirm)"
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Usage (inside a Claude Code session):"
Write-Host ""
Write-Host "    /deep-plan              # Auto-detect next phase"
Write-Host "    /deep-plan 18           # Plan specific phase"
Write-Host "    /deep-plan 18 --review  # Plan + feasibility review"
Write-Host ""
Write-Host "  Workflow:"
Write-Host ""
Write-Host "    /gsd-discuss-phase 18   # GSD gathers decisions -> CONTEXT.md"
Write-Host "    /deep-plan 18           # CE researches code, writes plan"
Write-Host "    /gsd-execute-phase 18   # GSD executes the plan"
Write-Host ""
