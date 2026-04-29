#!/usr/bin/env bash
#
# eval-telemetry-doctor-cleanup.sh — Phase 12 telemetry, doctor, and cleanup eval.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL="$REPO_ROOT/skills/deep-plan/SKILL.md"
DOCTOR="$REPO_ROOT/commands/deep-plan-doctor.md"
VALIDATOR="$REPO_ROOT/agents/plan-validator.md"

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
assert_file "$DOCTOR" "deep-plan doctor command"
assert_file "$VALIDATOR" "plan-validator agent"

assert_contains "$SKILL" '_telemetry\.decisions\[\]' 'SKILL appends to telemetry decisions array'
assert_contains "$SKILL" 'preserve all existing entries' 'SKILL preserves existing telemetry entries'
assert_contains "$SKILL" '"phase_id"' 'telemetry includes phase_id'
assert_contains "$SKILL" '"recommended_model"' 'telemetry includes recommended_model'
assert_contains "$SKILL" '"executor_model"' 'telemetry includes executor_model'
assert_contains "$SKILL" '"override_flag"' 'telemetry includes override_flag'
assert_contains "$SKILL" '"input_tokens_estimate"' 'telemetry includes context estimate'
assert_contains "$SKILL" 'telemetry was skipped' 'SKILL warns when telemetry append is skipped'

assert_contains "$DOCTOR" 'Check 6/6: model_routing config and GSD profile drift' 'doctor adds Tier 2 check 6/6'
assert_contains "$DOCTOR" 'model_routing config missing' 'doctor warns on missing model_routing'
assert_contains "$DOCTOR" 'gsd_profile_at_setup' 'doctor checks setup-time GSD profile'
assert_contains "$DOCTOR" 'GSD profile drift' 'doctor warns on profile drift'
assert_contains "$DOCTOR" '/deep-plan-configure' 'doctor points remediation at configure command'
assert_contains "$DOCTOR" '\[N/6\].*Tier 2' 'doctor output discipline uses six Tier 2 checks'

assert_contains "$VALIDATOR" '^model: claude-sonnet-4-6$' 'plan-validator model pinned to sonnet'

printf '\nTelemetry/doctor/cleanup eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
