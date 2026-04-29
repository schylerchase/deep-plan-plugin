#!/usr/bin/env bash
#
# eval-config-resolution.sh — golden-fixture eval for the deep-plan config resolution
# layer (Phase 9 CONFIG-01..03)
#
# Exercises fixture cases against the resolveConfig helper:
#   (a) config absent       → all defaults, _source: "defaults"
#   (b) partial override    → deep merge, _source: "merged"
#   (c) malformed field     → lenient fallback + notice, _source: "merged"
#   (d) full custom         → all overrides applied, _source: "config"
#   (e) malformed JSON      → all defaults + read-level notice, _source: "defaults"
#   (f) unsafe numeric      → range fallback + notices, _source: "merged"
#
# Each fixture is a JSON config block plus expected resolved fields, expected notices
# count, and expected _source. The harness invokes resolveConfig (implemented inline as
# a node -e block) per fixture and asserts the output matches.
#
# Re-runs the full fixture suite twice and asserts byte-equal output for determinism
# (Phase 9 success criterion: deterministic resolution).
#
# Defaults are sourced from skills/deep-plan/references/scoring.md and embedded in the
# DEFAULTS constant below. This is a known drift surface — see 09-02-PLAN.md
# <known_drift_surfaces>. v1.2 cleanup candidate: parse scoring.md programmatically.
#
# Dependencies: bash, node. No jq, no yq, no python, no JSON-schema validators (Plan 02 constraint).
#
# Exit codes:
#   0 — all fixtures passed
#   1 — one or more fixture assertions failed
#   2 — node not available
#   3 — fixture format error (internal)

set -euo pipefail

# ── Resolve repo-relative paths from script location ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Precondition: node must be available ──
if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node not found on PATH; required for JSON parse + resolveConfig helper" >&2
  exit 2
fi

# ── resolveConfig helper (inline node -e block). Invoked once per fixture by
#    passing the raw JSON config block on stdin; emits a single line of pipe-
#    separated fields the bash harness parses for assertions.
#    Output format: source|bias|mode|pin|schema_version|gsd_profile|opus_quality|opus_balanced|opus_budget|sonnet_quality|sonnet_balanced|sonnet_budget|volume_coefficient|token_budget|borderline_window|notices_count|notice_paths_csv ──
resolve_config() {
  local raw_json="$1"
  node --input-type=module -e "
    // ── DEFAULTS sourced from skills/deep-plan/references/scoring.md ──
    // Keep in sync; see 09-02-PLAN.md <known_drift_surfaces> for the v1.2 cleanup plan.
    const DEFAULTS = {
      schema_version: 1,
      mode: 'confirm',                                          // from CONTEXT.md D-04 (mode field stub)
      pin: null,                                                // from CONTEXT.md D-01 (pin defaults to null)
      bias: 'balanced',                                         // from scoring.md ## Threshold Map (default bias)
      gsd_profile_at_setup: null,                               // from CONTEXT.md D-12 (Phase 9 holds null; Phase 10 wizard populates)
      weight_overrides: {
        formula: { volume_coefficient: 0.3 },                   // from scoring.md ## Quadratic Combine
        signals: {                                              // from scoring.md ## Signal Extraction (D-16)
          files_modified: 1.5, tasks: 0.3,
          key_links: 3, artifacts: 1.5, truths: 0.5,
          novel: 5, checkpoints: 2, unknown_deps: 3
        }
      },
      context_thresholds: {
        bias_thresholds: {                                      // from scoring.md ## Threshold Map
          opus:   { quality: 8,  balanced: 12, budget: 20 },
          sonnet: { quality: 3,  balanced: 4,  budget: 6 }
        },
        token_budget_advisory: 180000,                          // from scoring.md ## Token Estimation D-01
        borderline_hint_window: 0.10                            // from scoring.md ## Banner Format D-12
      }
    };

    const ALLOWED_MODES = ['auto', 'confirm', 'silent'];
    const ALLOWED_PINS = [null, 'opus', 'sonnet', 'haiku'];
    const ALLOWED_BIASES = ['quality', 'balanced', 'budget'];

    function isNumber(x) { return typeof x === 'number' && Number.isFinite(x); }
    function isInteger(x) { return Number.isInteger(x); }
    function inRange(min, max) { return (x) => isNumber(x) && x >= min && x <= max; }
    function intAtLeast(min) { return (x) => isInteger(x) && x >= min; }

    // Parse raw JSON; on top-level failure, return defaults plus a read-level
    // notice (per D-09 / T-09-07).
    let raw;
    let readLevelMalformed = false;
    try {
      raw = JSON.parse(process.argv[1] || '{}');
    } catch (e) {
      raw = {};
      readLevelMalformed = true;
    }

    const notices = [];
    if (readLevelMalformed) {
      notices.push({
        path: 'deep_plan.model_routing',
        expected: 'valid-json-object',
        got: 'malformed-json'
      });
    } else if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
      const got = raw === null ? 'null' : (Array.isArray(raw) ? 'array' : typeof raw);
      notices.push({
        path: 'deep_plan.model_routing',
        expected: 'object',
        got
      });
      raw = {};
      readLevelMalformed = true;
    }
    let leavesFromInput = 0;
    let totalLeaves = 0;

    // Helper: validate-or-default a leaf. Returns the resolved value, increments
    // leavesFromInput when the input value validated cleanly, and increments
    // totalLeaves unconditionally so _source can distinguish full-config (all
    // leaves provided) from partial-merge (some leaves provided + defaults backfill).
    function resolveLeaf(path, inputVal, defaultVal, validator, expectedTypeStr) {
      totalLeaves++;
      if (inputVal === undefined) return defaultVal;
      if (validator(inputVal)) {
        leavesFromInput++;
        return inputVal;
      }
      const got = inputVal === null ? 'null' : (Array.isArray(inputVal) ? 'array' : typeof inputVal);
      notices.push({ path, expected: expectedTypeStr, got });
      return defaultVal;
    }

    const r = {
      schema_version: resolveLeaf('schema_version', raw.schema_version, DEFAULTS.schema_version, intAtLeast(1), 'integer>=1'),
      mode: resolveLeaf('mode', raw.mode, DEFAULTS.mode, (x) => ALLOWED_MODES.includes(x), 'enum(auto|confirm|silent)'),
      pin: resolveLeaf('pin', raw.pin, DEFAULTS.pin, (x) => ALLOWED_PINS.includes(x), 'enum(null|opus|sonnet|haiku)'),
      bias: resolveLeaf('bias', raw.bias, DEFAULTS.bias, (x) => ALLOWED_BIASES.includes(x), 'enum(quality|balanced|budget)'),
      gsd_profile_at_setup: resolveLeaf(
        'gsd_profile_at_setup',
        raw.gsd_profile_at_setup,
        DEFAULTS.gsd_profile_at_setup,
        (x) => x === null || typeof x === 'string',
        'string-or-null'
      ),
      weight_overrides: {
        formula: {
          volume_coefficient: resolveLeaf(
            'weight_overrides.formula.volume_coefficient',
            raw.weight_overrides?.formula?.volume_coefficient,
            DEFAULTS.weight_overrides.formula.volume_coefficient,
            inRange(0, 10),
            'number[0,10]'
          )
        },
        signals: {}
      },
      context_thresholds: {
        bias_thresholds: { opus: {}, sonnet: {} },
        token_budget_advisory: resolveLeaf(
          'context_thresholds.token_budget_advisory',
          raw.context_thresholds?.token_budget_advisory,
          DEFAULTS.context_thresholds.token_budget_advisory,
          intAtLeast(1),
          'integer>=1'
        ),
        borderline_hint_window: resolveLeaf(
          'context_thresholds.borderline_hint_window',
          raw.context_thresholds?.borderline_hint_window,
          DEFAULTS.context_thresholds.borderline_hint_window,
          inRange(0, 1),
          'number[0,1]'
        )
      }
    };

    // weight_overrides.signals — iterate each default key, validate-or-default per leaf.
    for (const k of Object.keys(DEFAULTS.weight_overrides.signals)) {
      r.weight_overrides.signals[k] = resolveLeaf(
        'weight_overrides.signals.' + k,
        raw.weight_overrides?.signals?.[k],
        DEFAULTS.weight_overrides.signals[k],
        inRange(0, 100),
        'number[0,100]'
      );
    }

    // bias_thresholds.{opus,sonnet}.{quality,balanced,budget} — iterate each default leaf.
    for (const model of ['opus', 'sonnet']) {
      for (const b of ['quality', 'balanced', 'budget']) {
        r.context_thresholds.bias_thresholds[model][b] = resolveLeaf(
          'context_thresholds.bias_thresholds.' + model + '.' + b,
          raw.context_thresholds?.bias_thresholds?.[model]?.[b],
          DEFAULTS.context_thresholds.bias_thresholds[model][b],
          intAtLeast(1),
          'integer>=1'
        );
      }
    }

    // Compute _source per D-12 (CONTEXT.md):
    //   no leaves from input                                       → 'defaults'
    //   ALL leaves from input + zero notices (full-custom config)  → 'config'
    //   otherwise (partial overrides or any notice)                → 'merged'
    // Rationale: 'config' means every field came from the user; 'merged' means
    // user provided some fields and defaults backfilled the rest (partial override
    // path) OR some fields were rejected (lenient fallback path).
    let source;
    if (leavesFromInput === 0 && (notices.length === 0 || readLevelMalformed)) {
      source = 'defaults';
    } else if (leavesFromInput === totalLeaves && notices.length === 0) {
      source = 'config';
    } else {
      source = 'merged';
    }

    // Emit pipe-separated single line for bash to parse.
    const fields = [
      source,
      r.bias,
      r.mode,
      r.pin === null ? 'null' : r.pin,
      r.schema_version,
      r.gsd_profile_at_setup === null ? 'null' : r.gsd_profile_at_setup,
      r.context_thresholds.bias_thresholds.opus.quality,
      r.context_thresholds.bias_thresholds.opus.balanced,
      r.context_thresholds.bias_thresholds.opus.budget,
      r.context_thresholds.bias_thresholds.sonnet.quality,
      r.context_thresholds.bias_thresholds.sonnet.balanced,
      r.context_thresholds.bias_thresholds.sonnet.budget,
      r.weight_overrides.formula.volume_coefficient,
      r.context_thresholds.token_budget_advisory,
      r.context_thresholds.borderline_hint_window,
      notices.length,
      notices.map((n) => n.path).join(',')
    ];
    process.stdout.write(fields.join('|'));
  " "$raw_json"
}

# ── Fixtures (inline; no skills/deep-plan/fixtures/config/ directory created) ──

# Fixture (a) — config absent → all defaults
FIXTURE_A_INPUT='{}'
FIXTURE_A_EXPECTED_SOURCE='defaults'
FIXTURE_A_EXPECTED_BIAS='balanced'
FIXTURE_A_EXPECTED_OPUS_QUALITY='8'
FIXTURE_A_EXPECTED_NOTICES_COUNT='0'

# Fixture (b) — partial override → deep merge
FIXTURE_B_INPUT='{"bias":"quality","context_thresholds":{"bias_thresholds":{"opus":{"quality":7}}}}'
FIXTURE_B_EXPECTED_SOURCE='merged'
FIXTURE_B_EXPECTED_BIAS='quality'
FIXTURE_B_EXPECTED_OPUS_QUALITY='7'
FIXTURE_B_EXPECTED_OPUS_BALANCED='12'
FIXTURE_B_EXPECTED_SONNET_QUALITY='3'
FIXTURE_B_EXPECTED_NOTICES_COUNT='0'

# Fixture (c) — malformed field → lenient fallback + notice
FIXTURE_C_INPUT='{"weight_overrides":{"formula":{"volume_coefficient":"high"}}}'
FIXTURE_C_EXPECTED_SOURCE='merged'
FIXTURE_C_EXPECTED_VOLUME_COEFFICIENT='0.3'
FIXTURE_C_EXPECTED_NOTICES_COUNT='1'
FIXTURE_C_EXPECTED_NOTICE_PATH='weight_overrides.formula.volume_coefficient'

# Fixture (d) — full custom → every field non-default
FIXTURE_D_INPUT='{"schema_version":1,"mode":"auto","pin":"opus","bias":"quality","gsd_profile_at_setup":"quality","weight_overrides":{"formula":{"volume_coefficient":0.5},"signals":{"files_modified":2,"tasks":0.5,"key_links":4,"artifacts":2,"truths":1,"novel":10,"checkpoints":3,"unknown_deps":4}},"context_thresholds":{"bias_thresholds":{"opus":{"quality":5,"balanced":10,"budget":15},"sonnet":{"quality":2,"balanced":3,"budget":5}},"token_budget_advisory":150000,"borderline_hint_window":0.05}}'
FIXTURE_D_EXPECTED_SOURCE='config'
FIXTURE_D_EXPECTED_BIAS='quality'
FIXTURE_D_EXPECTED_PIN='opus'
FIXTURE_D_EXPECTED_OPUS_QUALITY='5'
FIXTURE_D_EXPECTED_NOTICES_COUNT='0'

# Fixture (e) — malformed top-level JSON → all defaults + read-level notice
FIXTURE_E_INPUT='{"bias":'
FIXTURE_E_EXPECTED_SOURCE='defaults'
FIXTURE_E_EXPECTED_BIAS='balanced'
FIXTURE_E_EXPECTED_NOTICES_COUNT='1'
FIXTURE_E_EXPECTED_NOTICE_PATH='deep_plan.model_routing'

# Fixture (f) — unsafe numeric ranges → per-field fallback + notices
FIXTURE_F_INPUT='{"weight_overrides":{"formula":{"volume_coefficient":-0.1},"signals":{"novel":-5}},"context_thresholds":{"token_budget_advisory":-1,"borderline_hint_window":2}}'
FIXTURE_F_EXPECTED_SOURCE='merged'
FIXTURE_F_EXPECTED_VOLUME_COEFFICIENT='0.3'
FIXTURE_F_EXPECTED_TOKEN_BUDGET='180000'
FIXTURE_F_EXPECTED_BORDERLINE_WINDOW='0.1'
FIXTURE_F_EXPECTED_NOTICES_COUNT='4'

# ── Assertion helpers ──

assert_field() {
  local fixture="$1"
  local field_name="$2"
  local got="$3"
  local want="$4"
  if [ "$got" = "$want" ]; then
    return 0
  fi
  echo "[FAIL] $fixture: $field_name mismatch — computed '$got', expected '$want'"
  return 1
}

# ── Run a single fixture and return result fields. Echoes the raw pipe-separated
#    string from resolve_config so callers can re-use it for determinism checks. ──
run_fixture() {
  local input="$1"
  resolve_config "$input"
}

# ── Main fixture loop ──
total=0
pass_count=0
fail_count=0

# Track first-pass results for the determinism check at the end.
RESULT_A_FIRST=""
RESULT_B_FIRST=""
RESULT_C_FIRST=""
RESULT_D_FIRST=""
RESULT_E_FIRST=""
RESULT_F_FIRST=""

# ── Fixture (a) ──
total=$((total + 1))
result_a=$(run_fixture "$FIXTURE_A_INPUT")
RESULT_A_FIRST="$result_a"
IFS='|' read -r src_a bias_a _mode_a _pin_a _sv_a _gsd_a oq_a _ob_a _obu_a _sq_a _sb_a _sbu_a _vc_a _tb_a _bw_a nc_a _np_a <<< "$result_a"

fixture_failed=0
assert_field "fixture-a-absent" "_source" "$src_a" "$FIXTURE_A_EXPECTED_SOURCE" || fixture_failed=1
assert_field "fixture-a-absent" "bias" "$bias_a" "$FIXTURE_A_EXPECTED_BIAS" || fixture_failed=1
assert_field "fixture-a-absent" "opus.quality" "$oq_a" "$FIXTURE_A_EXPECTED_OPUS_QUALITY" || fixture_failed=1
assert_field "fixture-a-absent" "notices_count" "$nc_a" "$FIXTURE_A_EXPECTED_NOTICES_COUNT" || fixture_failed=1

if [ "$fixture_failed" -eq 0 ]; then
  echo "[PASS] fixture-a-absent      _source=$src_a bias=$bias_a opus.quality=$oq_a notices=$nc_a"
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

# ── Fixture (b) ──
total=$((total + 1))
result_b=$(run_fixture "$FIXTURE_B_INPUT")
RESULT_B_FIRST="$result_b"
IFS='|' read -r src_b bias_b _mode_b _pin_b _sv_b _gsd_b oq_b ob_b _obu_b sq_b _sb_b _sbu_b _vc_b _tb_b _bw_b nc_b _np_b <<< "$result_b"

fixture_failed=0
assert_field "fixture-b-partial" "_source" "$src_b" "$FIXTURE_B_EXPECTED_SOURCE" || fixture_failed=1
assert_field "fixture-b-partial" "bias" "$bias_b" "$FIXTURE_B_EXPECTED_BIAS" || fixture_failed=1
assert_field "fixture-b-partial" "opus.quality" "$oq_b" "$FIXTURE_B_EXPECTED_OPUS_QUALITY" || fixture_failed=1
assert_field "fixture-b-partial" "opus.balanced (default-leak)" "$ob_b" "$FIXTURE_B_EXPECTED_OPUS_BALANCED" || fixture_failed=1
assert_field "fixture-b-partial" "sonnet.quality (default-leak)" "$sq_b" "$FIXTURE_B_EXPECTED_SONNET_QUALITY" || fixture_failed=1
assert_field "fixture-b-partial" "notices_count" "$nc_b" "$FIXTURE_B_EXPECTED_NOTICES_COUNT" || fixture_failed=1

if [ "$fixture_failed" -eq 0 ]; then
  echo "[PASS] fixture-b-partial     _source=$src_b bias=$bias_b opus.quality=$oq_b opus.balanced=$ob_b sonnet.quality=$sq_b"
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

# ── Fixture (c) ──
total=$((total + 1))
result_c=$(run_fixture "$FIXTURE_C_INPUT")
RESULT_C_FIRST="$result_c"
IFS='|' read -r src_c _bias_c _mode_c _pin_c _sv_c _gsd_c _oq_c _ob_c _obu_c _sq_c _sb_c _sbu_c vc_c _tb_c _bw_c nc_c np_c <<< "$result_c"

fixture_failed=0
assert_field "fixture-c-malformed" "_source" "$src_c" "$FIXTURE_C_EXPECTED_SOURCE" || fixture_failed=1
assert_field "fixture-c-malformed" "volume_coefficient (fallback)" "$vc_c" "$FIXTURE_C_EXPECTED_VOLUME_COEFFICIENT" || fixture_failed=1
assert_field "fixture-c-malformed" "notices_count" "$nc_c" "$FIXTURE_C_EXPECTED_NOTICES_COUNT" || fixture_failed=1
assert_field "fixture-c-malformed" "notice_path" "$np_c" "$FIXTURE_C_EXPECTED_NOTICE_PATH" || fixture_failed=1

if [ "$fixture_failed" -eq 0 ]; then
  echo "[PASS] fixture-c-malformed   _source=$src_c volume_coefficient=$vc_c notices=$nc_c path=$np_c"
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

# ── Fixture (d) ──
total=$((total + 1))
result_d=$(run_fixture "$FIXTURE_D_INPUT")
RESULT_D_FIRST="$result_d"
IFS='|' read -r src_d bias_d _mode_d pin_d _sv_d _gsd_d oq_d _ob_d _obu_d _sq_d _sb_d _sbu_d _vc_d _tb_d _bw_d nc_d _np_d <<< "$result_d"

fixture_failed=0
assert_field "fixture-d-full" "_source" "$src_d" "$FIXTURE_D_EXPECTED_SOURCE" || fixture_failed=1
assert_field "fixture-d-full" "bias" "$bias_d" "$FIXTURE_D_EXPECTED_BIAS" || fixture_failed=1
assert_field "fixture-d-full" "pin" "$pin_d" "$FIXTURE_D_EXPECTED_PIN" || fixture_failed=1
assert_field "fixture-d-full" "opus.quality" "$oq_d" "$FIXTURE_D_EXPECTED_OPUS_QUALITY" || fixture_failed=1
assert_field "fixture-d-full" "notices_count" "$nc_d" "$FIXTURE_D_EXPECTED_NOTICES_COUNT" || fixture_failed=1

if [ "$fixture_failed" -eq 0 ]; then
  echo "[PASS] fixture-d-full        _source=$src_d bias=$bias_d pin=$pin_d opus.quality=$oq_d notices=$nc_d"
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

# ── Fixture (e) ──
total=$((total + 1))
result_e=$(run_fixture "$FIXTURE_E_INPUT")
RESULT_E_FIRST="$result_e"
IFS='|' read -r src_e bias_e _mode_e _pin_e _sv_e _gsd_e _oq_e _ob_e _obu_e _sq_e _sb_e _sbu_e _vc_e _tb_e _bw_e nc_e np_e <<< "$result_e"

fixture_failed=0
assert_field "fixture-e-malformed-json" "_source" "$src_e" "$FIXTURE_E_EXPECTED_SOURCE" || fixture_failed=1
assert_field "fixture-e-malformed-json" "bias" "$bias_e" "$FIXTURE_E_EXPECTED_BIAS" || fixture_failed=1
assert_field "fixture-e-malformed-json" "notices_count" "$nc_e" "$FIXTURE_E_EXPECTED_NOTICES_COUNT" || fixture_failed=1
assert_field "fixture-e-malformed-json" "notice_path" "$np_e" "$FIXTURE_E_EXPECTED_NOTICE_PATH" || fixture_failed=1

if [ "$fixture_failed" -eq 0 ]; then
  echo "[PASS] fixture-e-malformed-json _source=$src_e bias=$bias_e notices=$nc_e path=$np_e"
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

# ── Fixture (f) ──
total=$((total + 1))
result_f=$(run_fixture "$FIXTURE_F_INPUT")
RESULT_F_FIRST="$result_f"
IFS='|' read -r src_f _bias_f _mode_f _pin_f _sv_f _gsd_f _oq_f _ob_f _obu_f _sq_f _sb_f _sbu_f vc_f tb_f bw_f nc_f np_f <<< "$result_f"

fixture_failed=0
assert_field "fixture-f-unsafe-numeric" "_source" "$src_f" "$FIXTURE_F_EXPECTED_SOURCE" || fixture_failed=1
assert_field "fixture-f-unsafe-numeric" "volume_coefficient" "$vc_f" "$FIXTURE_F_EXPECTED_VOLUME_COEFFICIENT" || fixture_failed=1
assert_field "fixture-f-unsafe-numeric" "token_budget_advisory" "$tb_f" "$FIXTURE_F_EXPECTED_TOKEN_BUDGET" || fixture_failed=1
assert_field "fixture-f-unsafe-numeric" "borderline_hint_window" "$bw_f" "$FIXTURE_F_EXPECTED_BORDERLINE_WINDOW" || fixture_failed=1
assert_field "fixture-f-unsafe-numeric" "notices_count" "$nc_f" "$FIXTURE_F_EXPECTED_NOTICES_COUNT" || fixture_failed=1

for expected_path in \
  "weight_overrides.formula.volume_coefficient" \
  "context_thresholds.token_budget_advisory" \
  "context_thresholds.borderline_hint_window" \
  "weight_overrides.signals.novel"; do
  case "$np_f" in
    *"$expected_path"*) ;;
    *)
      echo "[FAIL] fixture-f-unsafe-numeric: notice_paths missing '$expected_path' in '$np_f'"
      fixture_failed=1
      ;;
  esac
done

if [ "$fixture_failed" -eq 0 ]; then
  echo "[PASS] fixture-f-unsafe-numeric _source=$src_f notices=$nc_f paths=$np_f"
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

# ── Determinism check: re-run all fixtures and require byte-equal output ──
result_a_second=$(run_fixture "$FIXTURE_A_INPUT")
result_b_second=$(run_fixture "$FIXTURE_B_INPUT")
result_c_second=$(run_fixture "$FIXTURE_C_INPUT")
result_d_second=$(run_fixture "$FIXTURE_D_INPUT")
result_e_second=$(run_fixture "$FIXTURE_E_INPUT")
result_f_second=$(run_fixture "$FIXTURE_F_INPUT")

determinism_failed=0
if [ "$RESULT_A_FIRST" != "$result_a_second" ]; then
  echo "[FAIL] fixture-a-absent: determinism failure — first '$RESULT_A_FIRST' second '$result_a_second'"
  determinism_failed=1
fi
if [ "$RESULT_B_FIRST" != "$result_b_second" ]; then
  echo "[FAIL] fixture-b-partial: determinism failure — first '$RESULT_B_FIRST' second '$result_b_second'"
  determinism_failed=1
fi
if [ "$RESULT_C_FIRST" != "$result_c_second" ]; then
  echo "[FAIL] fixture-c-malformed: determinism failure — first '$RESULT_C_FIRST' second '$result_c_second'"
  determinism_failed=1
fi
if [ "$RESULT_D_FIRST" != "$result_d_second" ]; then
  echo "[FAIL] fixture-d-full: determinism failure — first '$RESULT_D_FIRST' second '$result_d_second'"
  determinism_failed=1
fi
if [ "$RESULT_E_FIRST" != "$result_e_second" ]; then
  echo "[FAIL] fixture-e-malformed-json: determinism failure — first '$RESULT_E_FIRST' second '$result_e_second'"
  determinism_failed=1
fi
if [ "$RESULT_F_FIRST" != "$result_f_second" ]; then
  echo "[FAIL] fixture-f-unsafe-numeric: determinism failure — first '$RESULT_F_FIRST' second '$result_f_second'"
  determinism_failed=1
fi

if [ "$determinism_failed" -eq 0 ]; then
  echo "[PASS] determinism-check     all $total fixtures byte-equal across 2 runs"
fi

# ── Summary block ──
echo "─────────────────────────────────"
echo "Config Resolution Eval (Phase 9)"
echo "Fixtures: $total"
echo "Passed:   $pass_count"
echo "Failed:   $fail_count"
echo "─────────────────────────────────"

if [ "$fail_count" -gt 0 ] || [ "$determinism_failed" -ne 0 ]; then
  exit 1
fi
exit 0
