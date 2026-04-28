#!/usr/bin/env bash
# eval-trailer-smoke.sh — deterministic end-to-end check that the routing-decision
# banner trailer is well-formed for known inputs (B3 mitigation per Phase 8 review).
#
# Couples Plan 03's trailer schema (references/scoring.md §8 Banner Format) to
# Plan 01's compute_scores helper. If either drifts away from the contract, this
# test fails alongside the breaking change.
#
# Approach (post-WR-4 from Phase 8 review):
#   1. Build a deterministic synthetic fixture in $TMPDIR (does NOT pollute
#      skills/deep-plan/fixtures/scoring/ which Plan 01 locks at exactly 8).
#   2. Source tests/lib-scoring.sh to get compute_scores in this shell. Previously
#      the helpers were extracted from eval-scoring.sh via brittle awk regex
#      (`/^yaml_get\(\) \{/,/^\}/`) that broke on any benign reformatting of the
#      eval script — switching to `function NAME { }` syntax, adding a space
#      before `()`, or refactoring to a column-0 `}` line inside the function
#      body would silently break this test for reasons unrelated to the
#      schema-parity contract being checked.
#   3. Invoke compute_scores against the synthetic fixture and assemble the
#      trailer per references/scoring.md §8.
#   4. Assert the five required keys (model, combined, volume, structure, risk)
#      are present and match the expected values.
#
# Exit codes:
#   0  trailer present and matches expected values
#   1  trailer missing one or more required keys
#   2  trailer key value differs from compute_scores output
#   3  tests/lib-scoring.sh missing or compute_scores helper unavailable
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_SCRIPT="$SCRIPT_DIR/lib-scoring.sh"

if [ ! -f "$LIB_SCRIPT" ]; then
  echo "[FAIL] tests/lib-scoring.sh not found at $LIB_SCRIPT — cannot source compute_scores helper"
  exit 3
fi

# shellcheck source=tests/lib-scoring.sh
. "$LIB_SCRIPT"

# Sanity check the helpers loaded.
if ! declare -F yaml_get >/dev/null || ! declare -F compute_scores >/dev/null; then
  echo "[FAIL] sourcing lib-scoring.sh did not register yaml_get/compute_scores"
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
