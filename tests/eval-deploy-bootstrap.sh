#!/usr/bin/env bash
#
# eval-deploy-bootstrap.sh - Static eval for the full deploy bootstrap.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DEPLOY="$REPO_ROOT/deploy.sh"
CODEX_PLUGIN="$REPO_ROOT/.codex-plugin/plugin.json"
CODEX_MARKETPLACE="$REPO_ROOT/.agents/plugins/marketplace.json"
README="$REPO_ROOT/README.md"

passed=0
failed=0

pass() {
  printf 'PASS: %s\n' "$1"
  passed=$((passed + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failed=$((failed + 1))
}

assert_file() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    pass "$label exists"
  else
    fail "$label missing"
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_file "$DEPLOY" "deploy script"
assert_file "$CODEX_PLUGIN" "Codex plugin manifest"
assert_file "$CODEX_MARKETPLACE" "Codex marketplace manifest"
assert_file "$README" "README"

bash -n "$DEPLOY" && pass "deploy script parses" || fail "deploy script syntax"
python3 -m json.tool "$CODEX_PLUGIN" >/dev/null && pass "Codex manifest parses" || fail "Codex manifest JSON"
python3 -m json.tool "$CODEX_MARKETPLACE" >/dev/null && pass "Codex marketplace parses" || fail "Codex marketplace JSON"

assert_contains "$DEPLOY" 'claude plugin marketplace add' 'deploy configures Claude marketplaces'
assert_contains "$DEPLOY" 'install_claude_plugin "Deep Plan".*deep-plan@deep-plan-plugin' 'deploy installs Claude deep-plan'
assert_contains "$DEPLOY" 'codex plugin marketplace add' 'deploy configures Codex marketplaces'
assert_contains "$DEPLOY" 'enable_codex_plugin' 'deploy explicitly enables Codex plugins'
assert_contains "$DEPLOY" 'deep-plan@deep-plan-plugin' 'deploy enables Codex deep-plan'
assert_contains "$DEPLOY" 'compound-engineering@compound-engineering-plugin' 'deploy covers Compound Engineering'
assert_contains "$DEPLOY" 'caveman@caveman' 'deploy covers Claude Caveman'
assert_contains "$DEPLOY" 'caveman@caveman-repo' 'deploy covers Codex Caveman'
assert_contains "$DEPLOY" 'rtk init --global --auto-patch' 'deploy configures Claude RTK'
assert_contains "$DEPLOY" 'rtk init --global --codex' 'deploy configures Codex RTK'
assert_contains "$DEPLOY" 'get-shit-done' 'deploy checks or bridges GSD'
assert_contains "$DEPLOY" 'DEEP_PLAN_SOURCE' 'deploy supports source override'
assert_contains "$DEPLOY" 'Restart Claude Code and Codex' 'deploy tells clients to restart'

assert_contains "$CODEX_PLUGIN" '"name": "deep-plan"' 'Codex manifest names deep-plan'
assert_contains "$CODEX_PLUGIN" '"skills": "./skills/"' 'Codex manifest exports skills'
assert_contains "$CODEX_PLUGIN" '"repository": "https://github.com/schylerchase/deep-plan-plugin"' 'Codex manifest links repository'
assert_contains "$CODEX_MARKETPLACE" '"name": "deep-plan-plugin"' 'Codex marketplace names repo'
assert_contains "$CODEX_MARKETPLACE" '"path": "./"' 'Codex marketplace points at repo plugin root'
assert_contains "$CODEX_MARKETPLACE" '"installation": "INSTALLED_BY_DEFAULT"' 'Codex marketplace auto-installs deep-plan'

assert_contains "$README" './deploy.sh --yes' 'README documents deploy script'
assert_contains "$README" 'Codex' 'README mentions Codex setup'

printf '\nDeploy bootstrap eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
