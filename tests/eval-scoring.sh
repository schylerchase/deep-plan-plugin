#!/usr/bin/env bash
#
# eval-scoring.sh — golden-fixture eval for the deep-plan scoring algorithm (Phase 8 SCORE-01..04)
#
# Iterates skills/deep-plan/fixtures/scoring/*.md, computes scores per the algorithm in
# references/scoring.md, and asserts each fixture's expected_* fields with 0.05 tolerance.
# Re-runs each fixture twice and asserts byte-equal output for determinism.
#
# Helpers (yaml_get, body_of, validate_int, compute_scores) are defined in tests/lib-scoring.sh
# and shared with tests/eval-trailer-smoke.sh. See that file for the public API contract.
#
# Fixture types:
#   scoring_golden — single fixture type. Each fixture declares 9 input signals plus
#                    expected_volume, expected_structure, expected_risk, expected_combined,
#                    expected_model, expected_advisory; fixture 08 also declares
#                    expected_borderline_hint. Fixture 04 asserts an empty hint via
#                    expected_borderline_hint: "" (locks WR-2 fix from Phase 8 review).
#
# Dependencies: bash, grep, awk, find. No jq, no yq, no python.
#
# Exit codes:
#   0 — all fixtures passed
#   1 — one or more fixture assertions failed
#   3 — fixtures directory does not exist
#   4 — a fixture is missing a required frontmatter field, OR has an invalid signal value
#       (non-numeric or negative; see validate_int in tests/lib-scoring.sh)
#   5 — a fixture has an unknown fixture_type
#   6 — numeric mismatch (computed score differs from expected_* beyond 0.05 tolerance)
#   7 — determinism failure (same fixture produced different output on two consecutive runs)

set -euo pipefail

# ── Resolve repo-relative paths from script location ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/skills/deep-plan/fixtures/scoring"

# ── Source shared helpers (yaml_get, body_of, validate_int, compute_scores) and
#    the SCORE_TOLERANCE constant. The lib has no top-level side effects.
# shellcheck source=tests/lib-scoring.sh
. "$SCRIPT_DIR/lib-scoring.sh"

# ── Precondition: fixtures dir must exist ──
if [ ! -d "$FIXTURES_DIR" ]; then
  echo "ERROR: fixtures directory not found at $FIXTURES_DIR" >&2
  exit 3
fi

# ── Iterate fixtures (sorted lexically) ──
total=0
pass_count=0
fail_count=0

fixture_list=$(find "$FIXTURES_DIR" -maxdepth 1 -type f -name "*.md" | LC_ALL=C sort)

if [ -z "$fixture_list" ]; then
  echo "ERROR: no fixtures found under $FIXTURES_DIR" >&2
  exit 3
fi

while IFS= read -r fixture; do
  [ -z "$fixture" ] && continue
  total=$((total + 1))
  name="$(basename "$fixture")"

  fixture_type="$(yaml_get "$fixture" fixture_type)"

  if [ -z "$fixture_type" ]; then
    echo "ERROR: fixture $name missing required field fixture_type" >&2
    exit 4
  fi

  case "$fixture_type" in
    scoring_golden)
      # First pass — compute and compare against expected_*
      result1=$(compute_scores "$fixture")
      IFS='|' read -r vol str ris com mod adv bhint <<< "$result1"

      exp_vol=$(yaml_get "$fixture" expected_volume)
      exp_str=$(yaml_get "$fixture" expected_structure)
      exp_ris=$(yaml_get "$fixture" expected_risk)
      exp_com=$(yaml_get "$fixture" expected_combined)
      exp_mod=$(yaml_get "$fixture" expected_model)
      exp_adv=$(yaml_get "$fixture" expected_advisory)
      exp_bhint=$(yaml_get "$fixture" expected_borderline_hint)

      fail=0

      # Numeric field assertions with 0.05 tolerance
      for pair in "vol:$vol:$exp_vol" "str:$str:$exp_str" "ris:$ris:$exp_ris" "com:$com:$exp_com"; do
        label=${pair%%:*}
        rest=${pair#*:}
        got=${rest%%:*}
        want=${rest#*:}
        diff=$(awk -v g="$got" -v w="$want" 'BEGIN { d = g - w; if (d < 0) d = -d; printf "%.3f", d }')
        if awk -v d="$diff" -v tol="$SCORE_TOLERANCE" 'BEGIN { exit !(d > tol) }'; then
          echo "[FAIL] $name: $label numeric mismatch — computed $got, expected $want (diff $diff > $SCORE_TOLERANCE tolerance)"
          fail_count=$((fail_count + 1))
          exit 6
        fi
      done

      # Model assertion (exact string match)
      if [ "$mod" != "$exp_mod" ]; then
        echo "[FAIL] $name: model mismatch — computed $mod, expected $exp_mod"
        fail=1
      fi

      # Advisory assertion (D-01, ROADMAP success criterion #3): only assert when expected_advisory was declared
      if [ -n "$exp_adv" ] && [ "$adv" != "$exp_adv" ]; then
        echo "[FAIL] $name: advisory mismatch — computed $adv, expected $exp_adv"
        fail=1
      fi

      # Borderline hint assertion (D-12, VALIDATION.md task 8-07-02): only assert when declared.
      # Special case: `expected_borderline_hint: ""` (literal two-char string) declares
      # "no hint expected" — strip the quotes and assert against empty string. This lets
      # fixture 04 (combined == opus_threshold, model already opus) lock in the WR-2 fix
      # that the opus hint must NOT fire when the user is at or above the threshold.
      if [ -n "$exp_bhint" ]; then
        if [ "$exp_bhint" = '""' ]; then
          exp_bhint=""
        fi
        if [ "$bhint" != "$exp_bhint" ]; then
          echo "[FAIL] $name: borderline_hint mismatch — computed '$bhint', expected '$exp_bhint'"
          fail=1
        fi
      fi

      # Determinism: re-run and require byte-equal output (success criterion #1)
      result2=$(compute_scores "$fixture")
      if [ "$result1" != "$result2" ]; then
        echo "[FAIL] $name: determinism failure — first run '$result1' second run '$result2'"
        fail_count=$((fail_count + 1))
        exit 7
      fi

      if [ "$fail" -eq 0 ]; then
        printf '[PASS] %-30s vol=%s str=%s risk=%s combined=%s -> %s adv=%s\n' \
          "$name" "$vol" "$str" "$ris" "$com" "$mod" "$adv"
        pass_count=$((pass_count + 1))
      else
        fail_count=$((fail_count + 1))
      fi
      ;;
    *)
      echo "[FAIL] $name: unknown fixture_type '$fixture_type'"
      fail_count=$((fail_count + 1))
      exit 5
      ;;
  esac
done <<< "$fixture_list"

# ── Summary block ──
echo "─────────────────────────────────"
echo "Scoring Algorithm Eval (Phase 8)"
echo "Fixtures: $total"
echo "Passed:   $pass_count"
echo "Failed:   $fail_count"
echo "─────────────────────────────────"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
