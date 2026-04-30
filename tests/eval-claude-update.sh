#!/usr/bin/env bash
#
# eval-claude-update.sh - Claude Code update command and doctor integration eval.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

UPDATE="$REPO_ROOT/commands/deep-plan-update.md"
DOCTOR="$REPO_ROOT/commands/deep-plan-doctor.md"
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

assert_file "$UPDATE" "deep-plan update command"
assert_file "$DOCTOR" "deep-plan doctor command"
assert_file "$README" "README"

assert_contains "$UPDATE" 'name: deep-plan-update' 'update command has frontmatter name'
assert_contains "$UPDATE" 'argument-hint:.*--check.*--yes.*--scope' 'update command documents arguments'
assert_contains "$UPDATE" 'claude plugin marketplace update deep-plan-plugin' 'update command refreshes marketplace'
assert_contains "$UPDATE" 'claude plugin update deep-plan@deep-plan-plugin' 'update command updates scoped plugin'
assert_contains "$UPDATE" 'Restart Claude Code' 'update command tells user to restart'
assert_contains "$UPDATE" 'Never update without.*--yes.*confirmation' 'update command requires confirmation'

assert_contains "$DOCTOR" 'Check 9/9: deep-plan update availability' 'doctor adds update availability check'
assert_contains "$DOCTOR" 'deep-plan update available' 'doctor warns on available update'
assert_contains "$DOCTOR" '/deep-plan-update' 'doctor points at update command'
assert_contains "$DOCTOR" '\[N/9\].*Tier 1' 'doctor output discipline uses nine Tier 1 checks'

assert_contains "$README" '/deep-plan-update' 'README documents update command'
assert_contains "$README" 'claude plugin update deep-plan@deep-plan-plugin' 'README documents Claude plugin update command'

printf '\nClaude update eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
