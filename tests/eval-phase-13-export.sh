#!/usr/bin/env bash
#
# eval-phase-13-export.sh - Phase 13 bundle schema and export eval.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SCHEMA="$REPO_ROOT/skills/deep-plan/references/handoff-schema.md"
DISTILL="$REPO_ROOT/skills/deep-plan/references/intel-distill.md"
TEMPLATE="$REPO_ROOT/skills/deep-plan/references/plan-template.md"
CONFIG="$REPO_ROOT/skills/deep-plan/references/config.md"
COMMAND="$REPO_ROOT/commands/deep-plan-export-plan.md"

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

assert_file "$SCHEMA" "handoff schema"
assert_contains "$SCHEMA" 'bundle_version' 'schema documents bundle_version'
assert_contains "$SCHEMA" 'source_model' 'schema documents source_model'
assert_contains "$SCHEMA" 'source_plugin' 'schema documents source_plugin'
assert_contains "$SCHEMA" 'source_repo_id' 'schema documents source_repo_id'
assert_contains "$SCHEMA" 'exported_at' 'schema documents exported_at'
assert_contains "$SCHEMA" 'phase_id' 'schema documents phase_id'
assert_contains "$SCHEMA" 'phase_name' 'schema documents phase_name'
assert_contains "$SCHEMA" 'target_model_hint' 'schema documents target_model_hint'
assert_contains "$SCHEMA" 'sections_included' 'schema documents sections_included'
assert_contains "$SCHEMA" 'original_paths' 'schema documents original_paths'
assert_contains "$SCHEMA" 'BUNDLE SECTION: PLAN' 'schema documents PLAN section marker'
assert_contains "$SCHEMA" 'BUNDLE SECTION: CONTEXT' 'schema documents CONTEXT section marker'
assert_contains "$SCHEMA" 'BUNDLE SECTION: RESEARCH' 'schema documents RESEARCH section marker'
assert_contains "$SCHEMA" 'BUNDLE SECTION: INTEL_SUMMARY' 'schema documents INTEL_SUMMARY section marker'
assert_contains "$SCHEMA" 'PLAN.*yes' 'schema declares PLAN required'
assert_contains "$SCHEMA" 'CONTEXT.*yes' 'schema declares CONTEXT required'
assert_contains "$SCHEMA" 'verbatim' 'schema documents verbatim preservation'
assert_contains "$SCHEMA" 'fenced code block' 'schema documents fence-aware marker parsing'

assert_file "$DISTILL" "intel distillation"
assert_contains "$DISTILL" 'deps\.json' 'distill documents deps.json'
assert_contains "$DISTILL" 'files\.json' 'distill documents files.json'
assert_contains "$DISTILL" 'apis\.json' 'distill documents apis.json'
assert_contains "$DISTILL" 'arch\.md' 'distill documents arch.md'
assert_contains "$DISTILL" 'research/\*\.md' 'distill documents research markdown'
assert_contains "$DISTILL" 'top 20' 'distill documents top 20 deps'
assert_contains "$DISTILL" '5.{1,3}10.{1,3}KB' 'distill documents 5-10 KB target'
assert_contains "$DISTILL" 'tier-2' 'distill documents tier-2 truncation'
assert_contains "$DISTILL" 'malformed JSON' 'distill documents malformed JSON handling'
assert_contains "$DISTILL" 'secret' 'distill documents secret exclusion'

assert_contains "$TEMPLATE" 'handoff_chain' 'plan template documents handoff_chain'
assert_contains "$TEMPLATE" 'planned.*imported.*reviewed.*executed|planned|imported|reviewed|executed' 'plan template documents action enum'
assert_contains "$TEMPLATE" 'last 5' 'plan template documents 5-entry cap'
assert_contains "$CONFIG" '_telemetry\.handoff' 'config documents _telemetry.handoff'
assert_contains "$CONFIG" 'direction' 'config documents direction field'
assert_contains "$CONFIG" 'export.*import|export|import' 'config documents direction enum'

assert_file "$COMMAND" "export command"
assert_contains "$COMMAND" 'name: deep-plan-export-plan' 'export command has frontmatter name'
assert_contains "$COMMAND" 'argument-hint:.*phase.*--target.*--out.*--minimal' 'export command argument-hint complete'
assert_contains "$COMMAND" 'allowed-tools' 'export command declares allowed tools'
assert_contains "$COMMAND" '╔.*╗' 'export command has banner'
assert_contains "$COMMAND" 'bundle_version' 'export command writes bundle version'
assert_contains "$COMMAND" 'BUNDLE SECTION: PLAN' 'export command writes PLAN section'
assert_contains "$COMMAND" 'BUNDLE SECTION: CONTEXT' 'export command writes CONTEXT section'
assert_contains "$COMMAND" '_telemetry\.handoff' 'export command writes telemetry'
assert_contains "$COMMAND" 'handoff_chain' 'export command updates handoff_chain'
assert_contains "$COMMAND" 'fenced code blocks' 'export command documents fence-aware validation'
assert_contains "$COMMAND" '--minimal' 'export command supports --minimal'
assert_contains "$COMMAND" '--target' 'export command supports --target'

printf '\nPhase 13 export eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
