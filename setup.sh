#!/usr/bin/env bash
set -euo pipefail

# deep-plan plugin installer
# Checks prerequisites (GSD, Compound Engineering) and installs deep-plan

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[OK]${NC} $1"; }
fail() { echo -e "  ${RED}[MISSING]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}==>${NC} ${BOLD}$1${NC}"; }

echo ""
echo -e "${BOLD}deep-plan installer${NC}"
echo "Bridges GSD strategic planning with CE implementation planning"
echo ""

errors=0

# --- Check Claude Code ---
info "Checking prerequisites..."

if command -v claude &>/dev/null; then
    pass "Claude Code CLI"
else
    fail "Claude Code CLI not found"
    echo ""
    echo "    Install Claude Code first:"
    echo "      npm install -g @anthropic-ai/claude-code"
    echo ""
    errors=$((errors + 1))
fi

# --- Check GSD ---
if [ -f "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" ]; then
    pass "GSD (Get Shit Done)"
else
    fail "GSD not found"
    echo ""
    echo "    GSD is distributed through its Discord community."
    echo "    1. Join: https://discord.gg/gsd-plugin"
    echo "    2. Follow install instructions in #getting-started"
    echo ""
    errors=$((errors + 1))
fi

# --- Check Compound Engineering ---
plugins_file="$HOME/.claude/plugins/installed_plugins.json"
if [ -f "$plugins_file" ] && grep -q "compound-engineering" "$plugins_file" 2>/dev/null; then
    pass "Compound Engineering (CE)"
else
    fail "Compound Engineering not found"
    echo ""
    echo "    Install CE with:"
    echo "      claude plugin marketplace add EveryInc/compound-engineering-plugin"
    echo "      claude plugin install compound-engineering"
    echo ""
    errors=$((errors + 1))
fi

# --- Bail if prerequisites missing ---
if [ $errors -gt 0 ]; then
    echo ""
    echo -e "${RED}${BOLD}$errors prerequisite(s) missing.${NC} Install them first, then re-run this script."
    echo ""
    exit 1
fi

echo ""

# --- Install deep-plan ---
info "Installing deep-plan plugin..."
echo ""

if claude plugin marketplace add schylerchase/deep-plan-plugin && claude plugin install deep-plan; then
    echo ""
    pass "deep-plan installed"
else
    echo ""
    fail "Installation failed"
    echo ""
    echo "    Try manually:"
    echo "      claude plugin marketplace add schylerchase/deep-plan-plugin"
    echo "      claude plugin install deep-plan"
    echo ""
    exit 1
fi

# --- Verify ---
echo ""
info "Verifying installation..."

if [ -f "$plugins_file" ] && grep -q "deep-plan" "$plugins_file" 2>/dev/null; then
    pass "deep-plan plugin registered"
else
    warn "Could not verify in plugins file (this is OK if Claude prompted you to confirm)"
fi

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "  Usage (inside a Claude Code session):"
echo ""
echo "    /deep-plan              # Auto-detect next phase"
echo "    /deep-plan 18           # Plan specific phase"
echo "    /deep-plan 18 --review  # Plan + feasibility review"
echo ""
echo "  Workflow:"
echo ""
echo "    /gsd-discuss-phase 18   # GSD gathers decisions -> CONTEXT.md"
echo "    /deep-plan 18           # CE researches code, writes plan"
echo "    /gsd-execute-phase 18   # GSD executes the plan"
echo ""
