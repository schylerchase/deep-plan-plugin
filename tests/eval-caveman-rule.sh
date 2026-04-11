#!/usr/bin/env bash
#
# eval-caveman-rule.sh — v0 eval for the caveman deep-plan stage weighting rule.
#
# Contract:
#   Reads each fixture in skills/deep-plan/fixtures/caveman/*.md, parses its
#   frontmatter (stage, expected_mode, hard_override), applies the v0 rule
#   (mode_for_stage), asserts actual == expected, prints one line per fixture,
#   prints a summary block, exits 0 on full pass / non-zero on any failure.
#
# Dependencies: bash, grep, awk, find. No jq, no yq, no python.
#
# Exit codes:
#   0 — all fixtures passed
#   1 — one or more fixture mode assertions failed
#   2 — a fixture stage value produced ERROR_UNKNOWN_STAGE (rule or fixture bug)
#   3 — fixtures directory does not exist
#   4 — a fixture is missing a required frontmatter field

set -euo pipefail

# ── Resolve repo-relative paths from script location ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/skills/deep-plan/fixtures/caveman"

# ── v0 rule: stage → caveman mode (mirrors caveman-rule.md decision table) ──
mode_for_stage() {
  case "$1" in
    parse_args)            echo full ;;
    load_gsd_context)      echo full ;;
    gather_intel)          echo full ;;
    build_planning_brief)  echo lite ;;
    ce_research)           echo full ;;
    resolve_questions)     echo lite ;;
    structure_units)       echo lite ;;
    write_plan)            echo off  ;;   # HARD override
    plan_validation)       echo full ;;
    feasibility_review)    echo lite ;;
    handoff)               echo ultra ;;
    *) echo "ERROR_UNKNOWN_STAGE" ;;
  esac
}

# ── Frontmatter parser: extract a key's value from between the --- fences ──
# Usage: yaml_get <file> <key>
# Prints the value (stripped of surrounding whitespace) or empty string if absent.
yaml_get() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { fm = 0 }
    /^---[[:space:]]*$/ {
      if (fm == 0) { fm = 1; next }
      else          { exit }
    }
    fm == 1 {
      # Match "key:" at start of line, optional surrounding space
      if (match($0, "^[[:space:]]*" k "[[:space:]]*:[[:space:]]*")) {
        val = substr($0, RSTART + RLENGTH)
        # Trim trailing whitespace
        sub(/[[:space:]]+$/, "", val)
        print val
        exit
      }
    }
  ' "$file"
}

# ── Precondition: fixtures dir must exist ──
if [ ! -d "$FIXTURES_DIR" ]; then
  echo "ERROR: fixtures directory not found at $FIXTURES_DIR" >&2
  exit 3
fi

# ── Iterate fixtures (sorted lexically) ──
total=0
pass_count=0
fail_count=0
unknown_stage_hit=0

# Use find to collect fixture paths in a null-delimited list, then sort.
# This keeps us resilient to odd filenames without relying on nullglob.
fixture_list=$(find "$FIXTURES_DIR" -maxdepth 1 -type f -name "*.md" | LC_ALL=C sort)

if [ -z "$fixture_list" ]; then
  echo "ERROR: no fixtures found under $FIXTURES_DIR" >&2
  exit 3
fi

while IFS= read -r fixture; do
  [ -z "$fixture" ] && continue
  total=$((total + 1))
  name="$(basename "$fixture")"

  stage="$(yaml_get "$fixture" stage)"
  expected="$(yaml_get "$fixture" expected_mode)"
  hard="$(yaml_get "$fixture" hard_override)"

  if [ -z "$stage" ]; then
    echo "ERROR: fixture $name missing required field stage" >&2
    exit 4
  fi
  if [ -z "$expected" ]; then
    echo "ERROR: fixture $name missing required field expected_mode" >&2
    exit 4
  fi
  # hard_override is optional in the sense that empty → treated as false for display,
  # but per plan it is required in every fixture. Flag if missing.
  if [ -z "$hard" ]; then
    echo "ERROR: fixture $name missing required field hard_override" >&2
    exit 4
  fi

  actual="$(mode_for_stage "$stage")"

  if [ "$actual" = "ERROR_UNKNOWN_STAGE" ]; then
    printf '[FAIL] %-28s stage=%s  expected=%s  actual=ERROR_UNKNOWN_STAGE  hard=%s\n' \
      "$name" "$stage" "$expected" "$hard"
    unknown_stage_hit=1
    fail_count=$((fail_count + 1))
    continue
  fi

  if [ "$actual" = "$expected" ]; then
    printf '[PASS] %-28s stage=%s  expected=%s  actual=%s  hard=%s\n' \
      "$name" "$stage" "$expected" "$actual" "$hard"
    pass_count=$((pass_count + 1))
  else
    printf '[FAIL] %-28s stage=%s  expected=%s  actual=%s  hard=%s\n' \
      "$name" "$stage" "$expected" "$actual" "$hard"
    fail_count=$((fail_count + 1))
  fi
done <<< "$fixture_list"

# ── Summary block ──
echo "─────────────────────────────────"
echo "Caveman Rule Eval (v0)"
echo "Fixtures: $total"
echo "Passed:   $pass_count"
echo "Failed:   $fail_count"
echo "─────────────────────────────────"

# ── Exit code precedence: unknown stage (2) > any failure (1) > pass (0) ──
if [ "$unknown_stage_hit" -eq 1 ]; then
  exit 2
fi
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
