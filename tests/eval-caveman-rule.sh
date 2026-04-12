#!/usr/bin/env bash
#
# eval-caveman-rule.sh — v1 eval for the caveman deep-plan rule.
#
# v1 (session-01 informed):
#   The rule has been simplified from 11 stage-specific assertions to 2 rules:
#     - Rule 1: global mode (chat uses user's default caveman mode, no per-stage switch)
#     - Rule 2: HARD artifact override (.md file writes MUST be prose)
#
#   This eval checks fixtures by `fixture_type`:
#     - chat: smoke test — frontmatter parses, body non-empty
#     - artifact_write: prose detection — body contains >=5 article words
#
# Dependencies: bash, grep, awk, find. No jq, no yq, no python.
#
# Exit codes:
#   0 — all fixtures passed
#   1 — one or more fixture assertions failed
#   3 — fixtures directory does not exist
#   4 — a fixture is missing a required frontmatter field
#   5 — a fixture has an unknown fixture_type

set -euo pipefail

# ── Resolve repo-relative paths from script location ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/skills/deep-plan/fixtures/caveman"

# ── Minimum article word count for prose detection ──
# Deliberately loose — this is a smoke test, not a stylistic judgment.
PROSE_ARTICLE_THRESHOLD=5

# ── Frontmatter parser: extract a key's value from between --- fences ──
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

# ── Prose detection: count article words in body ──
# Returns 0 (true) if body has >= PROSE_ARTICLE_THRESHOLD article words
# Returns 1 (false) otherwise
is_prose() {
  local body="$1"
  local count
  count=$(printf '%s' "$body" | grep -oE '\b(the|The|an|An|is|are|was|were)\b' | wc -l | tr -d ' ')
  [ "$count" -ge "$PROSE_ARTICLE_THRESHOLD" ]
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
  hard="$(yaml_get "$fixture" hard_override)"
  body="$(body_of "$fixture")"

  if [ -z "$fixture_type" ]; then
    echo "ERROR: fixture $name missing required field fixture_type" >&2
    exit 4
  fi
  if [ -z "$hard" ]; then
    echo "ERROR: fixture $name missing required field hard_override" >&2
    exit 4
  fi

  case "$fixture_type" in
    chat)
      # Smoke test: body exists, non-empty
      if [ -n "$body" ]; then
        printf '[PASS] %-24s type=chat           hard=%-5s  (body exists, rule defers to user caveman mode)\n' \
          "$name" "$hard"
        pass_count=$((pass_count + 1))
      else
        printf '[FAIL] %-24s type=chat           hard=%-5s  empty body\n' \
          "$name" "$hard"
        fail_count=$((fail_count + 1))
      fi
      ;;
    artifact_write)
      # Prose assertion (HARD override)
      if is_prose "$body"; then
        article_count=$(printf '%s' "$body" | grep -oE '\b(the|The|an|An|is|are|was|were)\b' | wc -l | tr -d ' ')
        printf '[PASS] %-24s type=artifact_write hard=%-5s  (prose detected, %d articles >= %d threshold)\n' \
          "$name" "$hard" "$article_count" "$PROSE_ARTICLE_THRESHOLD"
        pass_count=$((pass_count + 1))
      else
        article_count=$(printf '%s' "$body" | grep -oE '\b(the|The|an|An|is|are|was|were)\b' | wc -l | tr -d ' ')
        printf '[FAIL] %-24s type=artifact_write hard=%-5s  (prose NOT detected, %d articles < %d threshold — HARD override VIOLATED)\n' \
          "$name" "$hard" "$article_count" "$PROSE_ARTICLE_THRESHOLD"
        fail_count=$((fail_count + 1))
      fi
      ;;
    *)
      printf '[FAIL] %-24s type=%s  hard=%-5s  unknown fixture_type\n' \
        "$name" "$fixture_type" "$hard"
      fail_count=$((fail_count + 1))
      exit 5
      ;;
  esac
done <<< "$fixture_list"

# ── Summary block ──
echo "─────────────────────────────────"
echo "Caveman Rule Eval (v1)"
echo "Fixtures: $total"
echo "Passed:   $pass_count"
echo "Failed:   $fail_count"
echo "─────────────────────────────────"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
