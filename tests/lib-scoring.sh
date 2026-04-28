#!/usr/bin/env bash
#
# lib-scoring.sh — shared helpers for the deep-plan scoring algorithm tests.
#
# Sourced by:
#   - tests/eval-scoring.sh         (golden-fixture eval, Phase 8 SCORE-01..04)
#   - tests/eval-trailer-smoke.sh   (trailer schema parity smoke test)
#
# Why a library: previously eval-trailer-smoke.sh extracted yaml_get and
# compute_scores from eval-scoring.sh via `awk '/^yaml_get\(\) \{/,/^\}/'`.
# That regex coupled the smoke test to a precise text shape (function name,
# brace placement, no `function` keyword) that has nothing to do with the
# contract being tested. Benign reformatting of eval-scoring.sh — adding a
# space before `()`, switching to `function NAME { }` syntax, or refactoring
# to add a column-0 `}` line inside the function body — would silently break
# the smoke test. Centralizing the helpers here removes the brittle coupling.
#
# Public API (functions defined when this file is sourced):
#   yaml_get FILE KEY        — extract a value from --- frontmatter
#   body_of FILE             — emit everything after the second --- fence
#   validate_int FIELD VAL FIXTURE
#                            — assert VAL is a non-negative integer; exit 4 on failure
#   compute_scores FIXTURE   — emit volume|structure|risk|combined|model|advisory|borderline_hint
#
# Public constants:
#   SCORE_TOLERANCE=0.05     — tolerance for numeric score comparison
#
# Dependencies: bash, awk, grep. No jq, no yq, no python.
#
# This file is intentionally library-only. It declares functions and a single
# constant; sourcing it has no side effects. Do not add a top-level execution
# block here — both callers do their own iteration.

# ── Tolerance for numeric comparison: both sides print to 1 decimal, so 0.05 is the
#    smallest meaningful diff that still allows for awk float-rounding edge cases.
SCORE_TOLERANCE="0.05"

# ── Frontmatter parser: extract a key's value from between --- fences.
#    Note: gated on `---` frontmatter — does NOT match keys inside body-level
#    blocks like <signals>...</signals>. See SKILL.md Step 9.5 for the body-level
#    extractor a real implementation must use for <signals>.
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

# ── Extract body (everything after the second --- fence).
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

# ── validate_int: assert value is a non-negative integer per the spec
#    (references/scoring.md "Validation: Values must be non-negative integers").
#    Empty string is allowed (treated as missing → caller decides fallback).
#    Aborts the run with exit 4 on violation, matching the existing exit-code
#    convention for fixture validation failures.
validate_int() {
  local field="$1"
  local value="$2"
  local fixture="$3"
  # Empty values pass through (some fixtures legitimately omit input_tokens, etc.)
  [ -z "$value" ] && return 0
  if ! printf '%s' "$value" | grep -Eq '^[0-9]+$'; then
    echo "ERROR: fixture $(basename "$fixture") has invalid value for $field: '$value' (must be non-negative integer)" >&2
    exit 4
  fi
}

# ── compute_scores: read inputs from frontmatter, compute three perspective scores +
#    quadratic combine + threshold-mapped model + D-01 advisory + D-12 borderline_hint.
#    Emits a 7-field pipe-delimited tuple: volume|structure|risk|combined|model|advisory|borderline_hint
#
#    Float-precision nudge: `+ 1e-9` inside printf "%.1f" defeats the float-binary edge-case
#    where awk stores values like 0.15*10 as 1.49999... rather than exactly 1.5, so plain
#    %.1f rounds down. NOTE: 1e-9 is ~7 orders of magnitude larger than Number.EPSILON
#    (2.22e-16); the bash and JS layers are NOT arithmetically equivalent, only empirically
#    aligned for the current 8 fixtures. See references/scoring.md ## Half-Up Rounding.
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

  # Validate the 8 signal inputs + input_tokens per spec (non-negative integers).
  # bias is a string ("quality" | "balanced" | "budget") so it's not validated here —
  # the case statement below silently falls back to balanced for unknown values.
  validate_int "files_modified" "$files_modified" "$fixture"
  validate_int "tasks"          "$tasks"          "$fixture"
  validate_int "key_links"      "$key_links"      "$fixture"
  validate_int "artifacts"      "$artifacts"      "$fixture"
  validate_int "truths"         "$truths"         "$fixture"
  validate_int "novel"          "$novel"          "$fixture"
  validate_int "checkpoints"    "$checkpoints"    "$fixture"
  validate_int "unknown_deps"   "$unknown_deps"   "$fixture"
  validate_int "input_tokens"   "$input_tokens"   "$fixture"

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
  # The opus hint only fires when combined < opus_thresh (user is BELOW the line and could
  # bump bias to reach opus). At or above the threshold, the user already routes to opus,
  # so suggesting "bump bias to quality if you want opus" is misleading. Mirrors the
  # sonnet branch which already had a `c < ot` guard.
  # If within ±10% of opus_thresh AND combined < opus_thresh → opus borderline hint
  # Else if within ±10% of sonnet_thresh AND combined < opus_thresh → analogous sonnet hint
  # Else empty string
  local borderline_hint=""
  if awk -v c="$combined" -v t="$opus_thresh" 'BEGIN { d = t - c; exit !(d > 0 && d <= 0.1 * t) }'; then
    borderline_hint="close to opus threshold; bump bias to quality if you want opus"
  elif awk -v c="$combined" -v t="$sonnet_thresh" -v ot="$opus_thresh" 'BEGIN { d = c - t; if (d < 0) d = -d; exit !(d <= 0.1 * t && c < ot) }'; then
    borderline_hint="close to sonnet threshold; bump bias to balanced if you want sonnet"
  fi

  echo "$volume|$structure|$risk|$combined|$model|$advisory|$borderline_hint"
}
