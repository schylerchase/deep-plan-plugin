#!/usr/bin/env bash
#
# eval-setup-wizard.sh — setup wizard contract eval for Phase 10.
#
# Verifies that the inline deep-plan hook, standalone /deep-plan-configure
# command, shared setup-wizard reference, README docs, and config-write contract
# all exist and agree on the v1 model_routing schema.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL="$REPO_ROOT/skills/deep-plan/SKILL.md"
REF="$REPO_ROOT/skills/deep-plan/references/setup-wizard.md"
COMMAND="$REPO_ROOT/commands/deep-plan-configure.md"
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
  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file"; then
    fail "$label"
  else
    pass "$label"
  fi
}

assert_file "$REF" "setup wizard reference"
assert_file "$COMMAND" "deep-plan-configure command"
assert_file "$SKILL" "deep-plan skill"
assert_file "$README" "README"

assert_contains "$REF" 'Six-Question First-Run Flow' 'reference defines six-question flow'
assert_contains "$REF" 'deep_plan\.model_routing' 'reference names model_routing block'
assert_contains "$REF" 'preserve unrelated' 'reference requires preserving unrelated config keys'
assert_contains "$REF" 'model_profile' 'reference reads model_profile first'
assert_contains "$REF" 'workflow\.profile' 'reference falls back to workflow.profile'
assert_contains "$REF" 'workflow\.text_mode' 'reference documents text-mode fallback'
assert_contains "$REF" 'gsd_profile_at_setup: null' 'reference documents profile skip-to-null path'

for field in schema_version mode pin bias gsd_profile_at_setup weight_overrides context_thresholds; do
  assert_contains "$REF" "\"?$field\"?" "reference includes schema field $field"
done

assert_contains "$SKILL" 'CONFIG_HAS_MODEL_ROUTING' 'SKILL detects existing model_routing block'
assert_contains "$SKILL" 'PLANNING_EXISTS=yes' 'SKILL gates inline wizard on .planning existing'
assert_contains "$SKILL" 'GSD_TOOLS_EXISTS=yes' 'SKILL gates inline wizard on GSD tools existing'
assert_contains "$SKILL" 'model_routing.*block is missing' 'SKILL documents missing-block inline setup'
assert_contains "$SKILL" 'references/setup-wizard\.md' 'SKILL links shared setup wizard reference'
assert_contains "$SKILL" 're-run the `CONFIG_READ` snippet' 'SKILL reloads config after wizard writes'
assert_contains "$SKILL" 'First-run recovery prompt' 'SKILL documents first-run prerequisite recovery'
assert_contains "$SKILL" 'I installed GSD.*retry checks' 'SKILL lets user retry after installing GSD'
assert_contains "$SKILL" 'up to 3 retry attempts' 'SKILL caps GSD retry attempts'

assert_contains "$COMMAND" '^name: deep-plan-configure$' 'command frontmatter name is correct'
assert_contains "$COMMAND" 'granular edit menu' 'command supports granular edit menu'
assert_contains "$COMMAND" 'workflow\.text_mode' 'command supports text mode'
assert_contains "$COMMAND" 'model_profile' 'command reads model_profile first'
assert_contains "$COMMAND" 'workflow\.profile' 'command falls back to workflow.profile'
assert_contains "$COMMAND" 'preserve unrelated top-level keys' 'command preserves unrelated config keys'
assert_contains "$COMMAND" 'Reset routing config' 'command supports reset path'

assert_contains "$README" '/deep-plan-configure' 'README documents configure command'
assert_contains "$README" 'deep_plan\.model_routing' 'README documents first-run routing block'

assert_not_contains "$REF" '\b(ajv|joi|zod|yup)\b' 'reference avoids schema-validator dependency'
assert_not_contains "$COMMAND" '\b(ajv|joi|zod|yup)\b' 'command avoids schema-validator dependency'

printf '\nSetup wizard eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
