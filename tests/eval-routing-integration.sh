#!/usr/bin/env bash
#
# eval-routing-integration.sh — Phase 11 routing integration eval.
#
# Verifies PLAN.md frontmatter contract, Step 9.5 executor-model selection,
# GSD profile cap mapping, and Step 11 feasibility-review model routing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL="$REPO_ROOT/skills/deep-plan/SKILL.md"
TEMPLATE="$REPO_ROOT/skills/deep-plan/references/plan-template.md"
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

assert_file() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    pass "$label exists"
  else
    fail "$label missing"
  fi
}

assert_file "$SKILL" "deep-plan skill"
assert_file "$TEMPLATE" "plan template"
assert_file "$README" "README"

assert_contains "$TEMPLATE" '^executor_model:' 'plan template has executor_model frontmatter'
assert_contains "$TEMPLATE" '^model_recommendation:' 'plan template has model_recommendation frontmatter'
assert_contains "$TEMPLATE" 'recommended_model:' 'plan template includes recommended model'
assert_contains "$TEMPLATE" 'selection_reason:' 'plan template includes selection reason'
assert_contains "$TEMPLATE" 'input_tokens_estimate:' 'plan template includes token estimate'
assert_contains "$TEMPLATE" 'same in-memory routing decision object' 'plan template ties frontmatter to routing object'

assert_contains "$SKILL" 'executor_model' 'SKILL computes executor_model'
assert_contains "$SKILL" 'selection_reason' 'SKILL records selection_reason'
assert_contains "$SKILL" 'workflow\.profile' 'SKILL reads GSD workflow.profile'
assert_contains "$SKILL" 'quality -> opus' 'SKILL maps quality profile to opus'
assert_contains "$SKILL" 'balanced -> sonnet' 'SKILL maps balanced profile to sonnet'
assert_contains "$SKILL" 'budget -> sonnet' 'SKILL maps budget profile to sonnet'
assert_contains "$SKILL" 'haiku < sonnet < opus' 'SKILL defines model ordering'
assert_contains "$SKILL" 'Step 10 validation runs only after this frontmatter update' 'SKILL updates frontmatter before validation'

assert_contains "$SKILL" 'feasibility_model="opus"' 'Step 11 defaults feasibility_model to opus'
assert_contains "$SKILL" 'forces the feasibility reviewer model to opus' 'Step 11 documents forced opus for --review'
assert_contains "$SKILL" 'model: "\$feasibility_model"' 'Step 11 uses Agent model parameter'
assert_contains "$SKILL" 'Agent\(' 'Step 11 uses Agent tool syntax'

assert_contains "$README" 'executor_model' 'README documents executor_model'
assert_contains "$README" 'model_recommendation' 'README documents model_recommendation'

printf '\nRouting integration eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
