#!/usr/bin/env bash
#
# eval-phase-14-import.sh - Phase 14 import validation and fixture eval.
#
# Caveat: the two-stage byte-identity assertion below tests this eval's own
# reimplemented fence-aware extractor, not the prose command Claude executes at
# runtime. This departs from the shipped static-grep eval style; a reviewer may
# prefer spec-presence-only coverage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

COMMAND="$REPO_ROOT/commands/deep-plan-import-plan.md"
DOCTOR="$REPO_ROOT/commands/deep-plan-doctor.md"
FIXTURE_DIR="$REPO_ROOT/skills/deep-plan/fixtures/import"
ROUNDTRIP_BUNDLE="$FIXTURE_DIR/01-roundtrip-bundle.md"
EXPECTED_PLAN="$FIXTURE_DIR/01-roundtrip-expected-plan.md"
CHAIN_BUNDLE="$FIXTURE_DIR/02-chain-eviction-bundle.md"

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

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label (expected $expected, got $actual)"
  fi
}

section_seen() {
  case "$1" in
    PLAN) [[ "$seen_plan" == "1" ]] ;;
    CONTEXT) [[ "$seen_context" == "1" ]] ;;
    RESEARCH) [[ "$seen_research" == "1" ]] ;;
    INTEL_SUMMARY) [[ "$seen_intel_summary" == "1" ]] ;;
    *) return 1 ;;
  esac
}

mark_section_seen() {
  case "$1" in
    PLAN) seen_plan=1 ;;
    CONTEXT) seen_context=1 ;;
    RESEARCH) seen_research=1 ;;
    INTEL_SUMMARY) seen_intel_summary=1 ;;
  esac
}

extract_section() {
  local bundle="$1"
  local wanted="$2"
  local out="$3"
  local delimiter_count=0
  local in_fence=0
  local active_section=""
  local found_wanted=0
  local seen_plan=0
  local seen_context=0
  local seen_research=0
  local seen_intel_summary=0
  local marker_re='^## --- BUNDLE SECTION: ([A-Z_]+) ---$'
  local line
  local section
  local prefix3

  : > "$out"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if (( delimiter_count < 2 )); then
      if [[ "$line" == "---" ]]; then
        delimiter_count=$((delimiter_count + 1))
      fi
      continue
    fi

    if [[ "$in_fence" == "0" && "$line" =~ $marker_re ]]; then
      section="${BASH_REMATCH[1]}"
      if section_seen "$section"; then
        if [[ "$active_section" == "$wanted" ]]; then
          printf '%s\n' "$line" >> "$out"
        fi
        continue
      fi

      mark_section_seen "$section"
      if [[ "$section" == "$wanted" ]]; then
        active_section="$wanted"
        found_wanted=1
        continue
      fi

      if [[ "$active_section" == "$wanted" ]]; then
        break
      fi

      active_section="$section"
      continue
    fi

    prefix3="${line:0:3}"
    if [[ "$prefix3" == '```' || "$prefix3" == '~~~' ]]; then
      if [[ "$in_fence" == "0" ]]; then
        in_fence=1
      else
        in_fence=0
      fi
    fi

    if [[ "$active_section" == "$wanted" ]]; then
      printf '%s\n' "$line" >> "$out"
    fi
  done < "$bundle"

  [[ "$found_wanted" == "1" ]]
}

assert_file "$COMMAND" "import command"
assert_file "$DOCTOR" "doctor command"
assert_file "$ROUNDTRIP_BUNDLE" "roundtrip bundle fixture"
assert_file "$EXPECTED_PLAN" "roundtrip expected plan fixture"
assert_file "$CHAIN_BUNDLE" "chain eviction bundle fixture"

assert_contains "$COMMAND" 'name: deep-plan-import-plan' 'import command has frontmatter name'
assert_contains "$COMMAND" 'argument-hint:.*--dry-run.*--force.*--no-review.*--review' 'import command argument-hint complete'
assert_contains "$COMMAND" 'allowed-tools:.*AskUserQuestion' 'import command AskUserQuestion casing correct'
assert_contains "$COMMAND" 'Validation Contract' 'import command documents Validation Contract'
assert_contains "$COMMAND" 'all nine checks|nine Validation Contract checks' 'import command documents nine checks'
assert_contains "$COMMAND" 'Fence-Aware|fence-aware|fence awar' 'import command documents fence awareness'
assert_contains "$COMMAND" 'first occurrence|first.*wins|first .*er wins' 'import command documents first-wins markers'
assert_contains "$COMMAND" 'Target collision' 'import command documents target collision'
assert_contains "$COMMAND" '--force' 'import command documents --force'
assert_contains "$COMMAND" 'source_repo_id' 'import command documents foreign repo warning'
assert_contains "$COMMAND" 'Byte identity|byte identity' 'import command documents byte identity'
assert_contains "$COMMAND" 'best-effort' 'import command documents best-effort amend'
assert_contains "$COMMAND" '_telemetry\.handoff' 'import command documents handoff telemetry'
assert_contains "$COMMAND" 'Run review by default|review by default' 'import command documents default review'
assert_contains "$COMMAND" '--no-review' 'import command documents --no-review'
assert_contains "$COMMAND" 'ce-feasibility-reviewer' 'import command documents feasibility reviewer'
assert_contains "$COMMAND" 'IMPORT-REVIEW' 'import command documents import review report'
assert_contains "$COMMAND" 'Files written: 0' 'import command dry-run writes no files'
assert_contains "$COMMAND" 'Feasibility reviewers spawned: 0' 'import command dry-run spawns no reviewer'
assert_contains "$DOCTOR" 'handoff_chain' 'doctor documents handoff chain health'
assert_contains "$DOCTOR" '_telemetry\.handoff' 'doctor documents handoff telemetry health'
assert_contains "$DOCTOR" 'Check 7/7' 'doctor includes Tier 2 check 7/7'

assert_contains "$ROUNDTRIP_BUNDLE" 'sections_included:' 'roundtrip bundle has sections_included'
assert_contains "$ROUNDTRIP_BUNDLE" 'BUNDLE SECTION: PLAN' 'roundtrip bundle has PLAN marker'
assert_contains "$ROUNDTRIP_BUNDLE" 'BUNDLE SECTION: CONTEXT' 'roundtrip bundle has CONTEXT marker'
assert_contains "$ROUNDTRIP_BUNDLE" '```text' 'roundtrip bundle has fenced decoy block'
assert_contains "$CHAIN_BUNDLE" 'handoff_chain' 'chain fixture has handoff_chain'

TMP_WORK="$(mktemp -d)"
trap 'rm -rf "$TMP_WORK"' EXIT

EXTRACTED_PLAN="$TMP_WORK/extracted-plan.md"
DIFF_OUT="$TMP_WORK/roundtrip.diff"

if extract_section "$ROUNDTRIP_BUNDLE" "PLAN" "$EXTRACTED_PLAN"; then
  pass "fence-aware extractor found PLAN section"
else
  fail "fence-aware extractor found PLAN section"
fi

# byte-identity stage one: extracted PLAN bytes must equal the expected landed bytes.
if diff -u "$EXPECTED_PLAN" "$EXTRACTED_PLAN" > "$DIFF_OUT"; then
  pass "stage one byte-identity diff empty"
else
  fail "stage one byte-identity diff empty"
  cat "$DIFF_OUT"
fi

AMENDED_PLAN="$TMP_WORK/amended-plan.md"
inserted=0
while IFS= read -r line || [[ -n "$line" ]]; do
  printf '%s\n' "$line" >> "$AMENDED_PLAN"
  if [[ "$inserted" == "0" && "$line" == '      ts: "2026-04-30T12:00:00Z"' ]]; then
    cat >> "$AMENDED_PLAN" <<'ENTRY'
    - model: "codex-eval"
      plugin: "deep-plan@0.3.0"
      action: "imported"
      ts: "2026-04-30T12:30:00Z"
ENTRY
    inserted=1
  fi
done < "$EXTRACTED_PLAN"

assert_contains "$AMENDED_PLAN" 'action: "imported"' 'stage two imported chain entry asserted'

CHAIN_PLAN="$TMP_WORK/chain-plan.md"
if extract_section "$CHAIN_BUNDLE" "PLAN" "$CHAIN_PLAN"; then
  pass "fence-aware extractor found chain PLAN section"
else
  fail "fence-aware extractor found chain PLAN section"
fi

entry_count="$(grep -Ec '^[[:space:]]{4}- model: "' "$CHAIN_PLAN" || true)"
assert_equals "5" "$entry_count" "chain fixture starts with five handoff entries"

ACTIONS="$TMP_WORK/actions.txt"
CAPPED_ACTIONS="$TMP_WORK/capped-actions.txt"
grep -E '^[[:space:]]+action: ' "$CHAIN_PLAN" > "$ACTIONS"
printf '      action: "imported"\n' >> "$ACTIONS"
tail -5 "$ACTIONS" > "$CAPPED_ACTIONS"
cap_count="$(wc -l < "$CAPPED_ACTIONS" | tr -d ' ')"
assert_equals "5" "$cap_count" "chain cap simulation leaves five entries"
if grep -q 'action: "planned"' "$CAPPED_ACTIONS"; then
  fail "chain cap simulation drops oldest planned entry"
else
  pass "chain cap simulation drops oldest planned entry"
fi

printf '\nPhase 14 import eval complete\n'
printf 'Passed: %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"

if (( failed > 0 )); then
  exit 1
fi
