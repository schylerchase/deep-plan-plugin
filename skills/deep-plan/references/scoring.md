# Scoring Contract — Single Source of Truth

## Status

**Version:** v1 (Phase 8 — Adaptive Model Routing milestone v1.1)
**Loaded by:** SKILL.md Step 9.5 (model routing decision)
**Loaded on demand:** This file is read once per deep-plan run, only when Step 9.5 executes. Per D-14, all formulas, thresholds, byte ratios, signal extraction heuristics, and worked examples live here — SKILL.md Step 9.5 must NOT inline any formula or threshold value.
**Phase 9 dependency:** When `.planning/config.json` lacks a `deep_plan.model_routing` block, Phase 9 falls back to the defaults in this file. The schema below is stable across versions; field names will not be renamed without a major version bump.

## The Three Perspectives

Per SCORE-01, three perspective scores are computed per phase from in-memory pipeline metadata:

### Volume

```
volume = sqrt(files_modified) * 1.5 + tasks * 0.3
```

- `files_modified` — deduplicated unique paths across all in-memory unit objects produced in Step 8 (per D-15). Deterministic, no file I/O.
- `tasks` — count of in-memory unit objects (`units.length`). One unit emits one `<task>` in PLAN.md; this is the natural unit of measurement (per Open Question 1 in 08-RESEARCH.md, locked here).

The square-root flattens large file counts so that adding files 50 → 60 has less impact than going 5 → 10. Empirically calibrated for plan size variance.

### Structure

```
structure = key_links * 3 + artifacts * 1.5 + truths * 0.5
```

- `key_links` — `must_haves.key_links.length` from Step 8 output.
- `artifacts` — `must_haves.artifacts.length` from Step 8 output.
- `truths` — `must_haves.truths.length` from Step 8 output.

The weights (3, 1.5, 0.5) reflect that `key_links` are the most failure-prone connections (highest weight), `artifacts` are concrete file outputs (medium), and `truths` are observable behaviors (lower weight because each truth is usually backed by an artifact).

### Risk

```
risk = novel * 5 + checkpoints * 2 + unknown_deps * 3
```

- `novel` — count of CE feasibility findings rated HIGH. When `--skip-research` was passed, defaults to 0 per D-08.
- `checkpoints` — count of unresolved questions in CONTEXT.md `<questions>` blocks. **Known gap:** the GSD CONTEXT.md template does not currently define a `<questions>` section. When the section is absent, defaults to 0 and Step 9.5 banner appends `(no <questions> block; checkpoints defaulted to 0)`. This honest annotation matches Pitfall 2 mitigation in 08-RESEARCH.md.
- `unknown_deps` — count of RESEARCH.md findings tagged LOW or MEDIUM confidence. When `--skip-research` was passed, defaults to 0 per D-08.

The weights (5, 2, 3) reflect that novel patterns are the highest-impact risk source (HIGH severity by definition), unknown dependencies are real but partially mitigated by research framing, and unresolved questions are blocking but typically narrow in scope.

## Quadratic Combine (SCORE-02)

```
combined = sqrt(structure^2 + risk^2 + 0.3 * volume^2)
```

The quadratic norm penalizes phases that are large in MULTIPLE perspectives — a phase with high structure AND high risk routes to opus more aggressively than one that's high in just one dimension. The `0.3 * volume^2` weight reflects that raw size matters but matters less than structural complexity or risk.

**Numerical stability:** `Math.sqrt` is IEEE-754 deterministic across all standard Node versions (verified — see 08-RESEARCH.md). Since `volume`, `structure`, `risk` are all small positive numbers (typically 0-50 each), the squares stay well below `Number.MAX_SAFE_INTEGER` and there is no precision loss at the integer-to-float boundary.

## Threshold Map (SCORE-03)

The combined score maps to a recommended model via bias-adjusted thresholds:

| Bias | opus threshold | sonnet threshold |
|------|---------------:|-----------------:|
| quality | 8 | 3 |
| balanced (default) | 12 | 4 |
| budget | 20 | 6 |

```
opus_thresholds   = { quality: 8,  balanced: 12, budget: 20 }
sonnet_thresholds = { quality: 3,  balanced: 4,  budget: 6 }
```

**Mapping rule:**

```
if combined >= opus_thresholds[bias]   → opus
elif combined >= sonnet_thresholds[bias] → sonnet
else                                    → haiku
```

**Comparison rule (locked, per 08-RESEARCH.md Pitfall 4):** Use `>=` (greater-than-or-equal). A phase scoring exactly at a threshold value maps to the higher-tier model. This matches the natural-language framing "score is at least this complex." Worked example: a phase with combined = 12.0 under balanced bias routes to opus, not sonnet (see fixture `04-borderline-equal.md`).

**Bias selection:** Bias is read from `.planning/config.json` `deep_plan.model_routing.bias` field at Phase 9 (not Phase 8). Phase 8 defaults bias to `balanced` until Phase 9 plumbs the config; the default is encoded in this file as the canonical fallback.

## Token Estimation (SCORE-04)

Estimate input token count via per-extension byte ratios:

```
input_tokens = Σ ( file_size_bytes / ratio_for_extension )
```

### Heuristic byte-ratio table

**Calibrate against Anthropic count_tokens API for high-stakes phases.** The values below are best-effort heuristics — Anthropic does not publish per-extension ratios. See Pitfall 3 in 08-RESEARCH.md for sources and methodology.

| Extension | Bytes per token | Notes |
|-----------|----------------:|-------|
| .md | 4.0 | English prose; matches industry consensus for documentation |
| .txt | 4.0 | Same as prose |
| .ts | 3.2 | TypeScript — denser than JS due to type annotations |
| .tsx | 3.2 | Same as TypeScript |
| .js | 3.0 | JavaScript code |
| .jsx | 3.0 | Same as JavaScript |
| .py | 4.5 | Python — verbose syntax, fewer operators per token than JS |
| .go | 3.5 | Go — middle ground; many short identifiers |
| .rs | 3.3 | Rust — heavy with type annotations and lifetimes |
| .json | 2.5 | Dense; many short tokens (keys, brackets) |
| .yaml | 3.5 | Mixed; depends on content |
| .yml | 3.5 | Same as YAML |
| .sh | 3.0 | Shell scripts — similar to JS code density |
| .sql | 4.0 | SQL keywords behave like prose for tokenization |
| .html | 3.0 | Tag-heavy markup |
| .css | 3.5 | Property-value pairs |
| (default / unknown) | 3.0 | **Conservative high default** — biases toward over-counting tokens, leans toward triggering the phase-split advisory rather than missing it |

### Phase-Split Advisory (D-01)

Triggered when **BOTH** conditions hold (strict AND, no OR):

```
input_tokens > 180000  AND  combined >= opus_thresholds[bias]
```

The strict AND keeps signal-to-noise high — token-only or complexity-only triggers were considered and rejected per D-01.

**Advisory message format (D-03):**

```
Phase split advisory: input ~{tokens}k tokens AND complexity {combined} ≥ {opus_threshold} — recommend splitting.
Top contributors: {N} unique files | {N} novel patterns from feasibility review.
```

The "top contributors" line lists the two highest-weighted contributing signals to the combined score. Ranking is by **weighted contribution** to the combined score (not raw signal count) — e.g., 2 novel findings contribute `2*5*5 = 50` to the structure-component-of-combined, while 47 files contribute `sqrt(47)*1.5 = 10.3` to volume which is then scaled by 0.3 in the combine. This is the correct A4 lock per 08-RESEARCH.md Assumptions Log.

**Mode-aware behavior (D-02):** The advisory is rendered differently based on the active mode (locked for Phase 9 to provide):

- `mode: auto` → warning banner only; planning continues uninterrupted.
- `mode: confirm` (default) → AskuserQuestion prompt with options ("Continue with current scope" / "Stop and split this phase manually") before continuing.
- `--text` flag → numbered-list fallback (same pattern as Phase 2).

**No auto split-point detection in v1.1** — deferred to v2 milestone.

## Half-Up Rounding (D-10)

All score numbers display to **1 decimal place**, rounded half-up for determinism. Threshold proximity stays visible (12.0 vs 14.8 vs 11.9).

### Recommended pattern

```javascript
function roundHalfUp1Decimal(x) {
  // Add Number.EPSILON to defeat float-binary edge cases (e.g., 1.005 * 10 === 10.04999...).
  // ECMA-262: Math.round rounds half-values toward +∞ — half-up for positive scores.
  return Math.round((x + Number.EPSILON) * 10) / 10;
}
```

**Verification:**
- `roundHalfUp1Decimal(1.005)` → `1.1` ✓
- `roundHalfUp1Decimal(2.45)` → `2.5` ✓
- `roundHalfUp1Decimal(0.0)` → `0.0` ✓

### Why not naive `Math.round(x * 10) / 10`

Per Pitfall 1 in 08-RESEARCH.md: `Math.round(1.005 * 10) / 10` returns `1.0`, not `1.1`, because `1.005 * 10 === 10.049999999999999` in IEEE-754 double precision. A user would see `combined: 1.0` in the banner one run and `combined: 1.1` in another with formula-equivalent inputs from a slightly different code path. Success criterion #1 (determinism) fails silently.

The `Number.EPSILON` correction adds a 2.22e-16 nudge — cheap and effective for the score domain (small positive numbers, single-decimal output).

### Bash mirror (for tests/eval-scoring.sh)

awk's `printf "%.1f"` exhibits the same float-binary edge-case in some implementations. The test harness uses an equivalent nudge:

```bash
printf "%.1f", x + 1e-9
```

Both layers must produce identical rounded outputs to satisfy success criterion #1.
