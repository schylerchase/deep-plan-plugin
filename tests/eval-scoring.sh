#!/usr/bin/env bash
#
# eval-scoring.sh — golden-fixture eval for the deep-plan scoring algorithm (Phase 8 SCORE-01..04)
#
# Parallels tests/eval-caveman-rule.sh: same yaml_get / body_of helpers, same iteration shape,
# same [PASS]/[FAIL] / summary block. Extends the analog with float arithmetic via awk and
# a determinism re-run check.
#
# Fixture types:
#   scoring_golden — single fixture type. Each fixture declares 9 input signals plus
#                    expected_volume, expected_structure, expected_risk, expected_combined,
#                    expected_model, expected_advisory; fixture 08 also declares
#                    expected_borderline_hint. The harness computes scores from the inputs,
#                    compares against expected_* with 0.05 tolerance, then re-runs and asserts
#                    byte-equal output for determinism (success criterion #1).
#
# Dependencies: bash, grep, awk, find. No jq, no yq, no python.
#
# Exit codes:
#   0 — all fixtures passed
#   1 — one or more fixture assertions failed
#   3 — fixtures directory does not exist
#   4 — a fixture is missing a required frontmatter field
#   5 — a fixture has an unknown fixture_type
#   6 — numerical mismatch (computed score differs from expected_* beyond 0.05 tolerance)
#   7 — determinism failure (same fixture produced different output on two consecutive runs)

set -euo pipefail

# ── Resolve repo-relative paths from script location ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/skills/deep-plan/fixtures/scoring"

# ── Tolerance for numerical comparison: both sides print to 1 decimal, so 0.05 is the
#    smallest meaningful diff that still allows for awk float-rounding edge cases.
SCORE_TOLERANCE="0.05"

# ── Frontmatter parser: extract a key's value from between --- fences (copied verbatim) ──
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
      if (match($0, "^[[:space:]]*" k "[[:space:]]*:[[:space:]]*")) {
        val = substr($0, RSTART + RLENGTH)
        sub(/[[:space:]]+$/, "", val)
        print val
        exit
      }
    }
  ' "$file"
}

# ── Extract body (everything after the second --- fence) ──
body_of() {
  awk '
    BEGIN { fm = 0 }
    /^---[[:space:]]*$/ {
      fm++
      next
    }
    fm >= 2 { print }
  ' "$1"
}

# ── compute_scores: read inputs from frontmatter, compute three perspective scores +
#    quadratic combine + threshold-mapped model + D-01 advisory + D-12 borderline_hint.
#    Emits a 7-field pipe-delimited tuple: volume|structure|risk|combined|model|advisory|borderline_hint
#
#    Float-precision nudge: `+ 1e-9` inside printf "%.1f" defeats the float-binary edge-case
#    described in 08-RESEARCH.md Pitfall 1 (printf "%.1f", 1.005 may round to 1.0
#    in some awk implementations because 1.005 stores as 1.00499...). The bash-layer mirror
#    of the Number.EPSILON correction Plan 03 will document for JS in references/scoring.md.
compute_scores() {
  local fixture="$1"
  local files_modified
  local tasks
  local key_links
  local artifacts
  local truths
  local novel
  local checkpoints
  local unknown_deps
  local input_tokens
  local bias

  files_modified=$(yaml_get "$fixture" files_modified)
  tasks=$(yaml_get "$fixture" tasks)
  key_links=$(yaml_get "$fixture" key_links)
  artifacts=$(yaml_get "$fixture" artifacts)
  truths=$(yaml_get "$fixture" truths)
  novel=$(yaml_get "$fixture" novel)
  checkpoints=$(yaml_get "$fixture" checkpoints)
  unknown_deps=$(yaml_get "$fixture" unknown_deps)
  input_tokens=$(yaml_get "$fixture" input_tokens)
  bias=$(yaml_get "$fixture" bias)

  # Volume = sqrt(files_modified) * 1.5 + tasks * 0.3
  local volume
  volume=$(awk -v f="$files_modified" -v t="$tasks" 'BEGIN { v = sqrt(f) * 1.5 + t * 0.3; printf "%.1f", v + 1e-9 }')

  # Structure = key_links * 3 + artifacts * 1.5 + truths * 0.5
  local structure
  structure=$(awk -v k="$key_links" -v a="$artifacts" -v tr="$truths" 'BEGIN { s = k * 3 + a * 1.5 + tr * 0.5; printf "%.1f", s + 1e-9 }')

  # Risk = novel * 5 + checkpoints * 2 + unknown_deps * 3
  local risk
  risk=$(awk -v n="$novel" -v c="$checkpoints" -v u="$unknown_deps" 'BEGIN { r = n * 5 + c * 2 + u * 3; printf "%.1f", r + 1e-9 }')

  # Combined = sqrt(structure^2 + risk^2 + 0.3 * volume^2)
  local combined
  combined=$(awk -v v="$volume" -v s="$structure" -v r="$risk" 'BEGIN { c = sqrt(s*s + r*r + 0.3*v*v); printf "%.1f", c + 1e-9 }')

  # Threshold map (D-04): opus={quality:8, balanced:12, budget:20}, sonnet={quality:3, balanced:4, budget:6}
  local opus_thresh=12
  local sonnet_thresh=4
  case "$bias" in
    quality)  opus_thresh=8;  sonnet_thresh=3 ;;
    balanced) opus_thresh=12; sonnet_thresh=4 ;;
    budget)   opus_thresh=20; sonnet_thresh=6 ;;
  esac

  # Model selection: opus if combined >= opus_thresh, sonnet if combined >= sonnet_thresh, else haiku
  local model="haiku"
  if awk -v c="$combined" -v t="$opus_thresh" 'BEGIN { exit !(c >= t) }'; then
    model="opus"
  elif awk -v c="$combined" -v t="$sonnet_thresh" 'BEGIN { exit !(c >= t) }'; then
    model="sonnet"
  fi

  # D-01 advisory: input_tokens > 180000 AND combined >= opus_thresh (strict AND gate)
  local advisory="false"
  if [ -n "$input_tokens" ]; then
    if awk -v it="$input_tokens" -v c="$combined" -v t="$opus_thresh" 'BEGIN { exit !(it > 180000 && c >= t) }'; then
      advisory="true"
    fi
  fi

  # D-12 borderline hint: combined within ±10% of either threshold; choose the closer one.
  # If within ±10% of opus_thresh → "close to opus threshold; bump bias to quality if you want opus"
  # Else if within ±10% of sonnet_thresh AND combined < opus_thresh → analogous sonnet hint
  # Else empty string
  local borderline_hint=""
  if awk -v c="$combined" -v t="$opus_thresh" 'BEGIN { d = c - t; if (d < 0) d = -d; exit !(d <= 0.1 * t) }'; then
    borderline_hint="close to opus threshold; bump bias to quality if you want opus"
  elif awk -v c="$combined" -v t="$sonnet_thresh" -v ot="$opus_thresh" 'BEGIN { d = c - t; if (d < 0) d = -d; exit !(d <= 0.1 * t && c < ot) }'; then
    borderline_hint="close to sonnet threshold; bump bias to balanced if you want sonnet"
  fi

  echo "$volume|$structure|$risk|$combined|$model|$advisory|$borderline_hint"
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

      # Numerical field assertions with 0.05 tolerance
      for pair in "vol:$vol:$exp_vol" "str:$str:$exp_str" "ris:$ris:$exp_ris" "com:$com:$exp_com"; do
        label=${pair%%:*}
        rest=${pair#*:}
        got=${rest%%:*}
        want=${rest#*:}
        diff=$(awk -v g="$got" -v w="$want" 'BEGIN { d = g - w; if (d < 0) d = -d; printf "%.3f", d }')
        if awk -v d="$diff" -v tol="$SCORE_TOLERANCE" 'BEGIN { exit !(d > tol) }'; then
          echo "[FAIL] $name: $label numerical mismatch — computed $got, expected $want (diff $diff > $SCORE_TOLERANCE tolerance)"
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

      # Borderline hint assertion (D-12, VALIDATION.md task 8-07-02): only assert when declared
      if [ -n "$exp_bhint" ] && [ "$bhint" != "$exp_bhint" ]; then
        echo "[FAIL] $name: borderline_hint mismatch — computed '$bhint', expected '$exp_bhint'"
        fail=1
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
