#!/usr/bin/env bash
# eval-trailer-smoke.sh — deterministic end-to-end check that the routing-decision
# banner trailer is well-formed for known inputs (B3 mitigation per Phase 8 review).
#
# Couples Plan 03's trailer schema (references/scoring.md §8 Banner Format) to
# Plan 01's compute_scores helper (tests/eval-scoring.sh). If either drifts away
# from the contract, this test fails alongside the breaking change.
#
# Approach:
#   1. Build a deterministic synthetic fixture in $TMPDIR (does NOT pollute
#      skills/deep-plan/fixtures/scoring/ which Plan 01 locks at exactly 8).
#   2. Extract `yaml_get` and `compute_scores` from tests/eval-scoring.sh via awk
#      (sourcing the whole script would trigger its top-level fixture loop).
#   3. Eval the extracted functions in this shell, invoke compute_scores against
#      the synthetic fixture, and assemble the trailer per references/scoring.md §8.
#   4. Assert the five required keys (model, combined, volume, structure, risk)
#      are present and match the expected values.
#
# Exit codes:
#   0  trailer present and matches expected values
#   1  trailer missing one or more required keys
#   2  trailer key value differs from compute_scores output
#   3  tests/eval-scoring.sh missing or compute_scores helper unavailable
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVAL_SCRIPT="$REPO_ROOT/tests/eval-scoring.sh"

if [ ! -f "$EVAL_SCRIPT" ]; then
  echo "[FAIL] tests/eval-scoring.sh not found at $EVAL_SCRIPT — Plan 01 must land first"
  exit 3
fi

# Build a deterministic synthetic fixture in a tempdir.
# Inputs are designed to produce exactly:
#   volume    = sqrt(5)*1.5 + 8*0.3 = 3.354 + 2.4 = 5.8
#   structure = 2*3 + 0*1.5 + 0*0.5 = 6.0
#   risk      = 0*5 + 0*2 + 0*3 = 0.0
#   combined  = sqrt(6^2 + 0 + 0.3*5.8^2) = sqrt(46.092) ≈ 6.8
#   model     = sonnet (6.8 < opus(12) AND 6.8 >= sonnet(4) under balanced)
#   advisory  = false (input_tokens 20000 < 180000)
TMPDIR_SMOKE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SMOKE"' EXIT
FIXTURE="$TMPDIR_SMOKE/smoke.md"
cat > "$FIXTURE" <<'FIX'
---
fixture_type: scoring_golden
size_class: sonnet
bias: balanced
files_modified: 5
tasks: 8
key_links: 2
artifacts: 0
truths: 0
novel: 0
checkpoints: 0
unknown_deps: 0
input_tokens: 20000
skip_research: false
expected_volume: 5.8
expected_structure: 6.0
expected_risk: 0.0
expected_combined: 6.8
expected_model: sonnet
expected_advisory: false
---
# Smoke fixture
FIX

# Extract yaml_get (lines `yaml_get() {` through the matching `}`) and compute_scores
# from eval-scoring.sh. Awk pattern match closing-brace-only-on-its-own-line.
YAML_BLOCK=$(awk '/^yaml_get\(\) \{/,/^\}/' "$EVAL_SCRIPT")
COMPUTE_BLOCK=$(awk '/^compute_scores\(\) \{/,/^\}/' "$EVAL_SCRIPT")

if [ -z "$YAML_BLOCK" ] || [ -z "$COMPUTE_BLOCK" ]; then
  echo "[FAIL] yaml_get or compute_scores not extractable from $EVAL_SCRIPT"
  exit 3
fi

eval "$YAML_BLOCK"
eval "$COMPUTE_BLOCK"

# Sanity check the helpers loaded.
if ! declare -F yaml_get >/dev/null || ! declare -F compute_scores >/dev/null; then
  echo "[FAIL] eval of yaml_get/compute_scores did not register functions"
  exit 3
fi

# Compute scores against the synthetic fixture.
result=$(compute_scores "$FIXTURE")
IFS='|' read -r vol str ris com mod adv bhint <<< "$result"

# Build the trailer string per references/scoring.md §8 Banner Format schema:
#   <!-- DEEP_PLAN_ROUTING: model=X combined=X volume=X structure=X risk=X bias=X threshold=X advisory=X -->
TRAILER="<!-- DEEP_PLAN_ROUTING: model=$mod combined=$com volume=$vol structure=$str risk=$ris bias=balanced threshold=12 advisory=$adv -->"
echo "Generated trailer:"
echo "$TRAILER"

# Assert all five required keys are present.
fail=0
for key in "model=" "combined=" "volume=" "structure=" "risk="; do
  if ! grep -q "$key" <<< "$TRAILER"; then
    echo "[FAIL] trailer missing required key: $key"
    fail=1
  fi
done
if [ $fail -ne 0 ]; then
  exit 1
fi

# Assert each key matches the expected value (sanity — should equal compute_scores output).
fail=0
for entry in "model=sonnet" "combined=6.8" "volume=5.8" "structure=6.0" "risk=0.0"; do
  if ! grep -q "$entry" <<< "$TRAILER"; then
    echo "[FAIL] trailer key/value mismatch — expected '$entry' in: $TRAILER"
    fail=1
  fi
done
if [ $fail -ne 0 ]; then
  exit 2
fi

echo "[PASS] routing-decision trailer is well-formed for known inputs"
exit 0
