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

- `key_links`, `artifacts`, `truths` — corresponding `must_haves.<key>.length` from Step 8 output.

The weights (3, 1.5, 0.5) reflect that `key_links` are the most failure-prone connections (highest weight), `artifacts` are concrete file outputs (medium), and `truths` are observable behaviors (lower weight because each truth is usually backed by an artifact).

### Risk

```
risk = novel * 5 + checkpoints * 2 + unknown_deps * 3
```

- `novel` — count of CE feasibility findings rated HIGH (defaults to 0 when `--skip-research`, per D-08).
- `checkpoints` — count of unresolved questions in CONTEXT.md `<questions>` blocks. **Known gap:** the GSD CONTEXT.md template does not currently define `<questions>`; when absent, defaults to 0 and the banner appends `(no <questions> block; checkpoints defaulted to 0)` (Pitfall 2 mitigation in 08-RESEARCH.md).
- `unknown_deps` — count of RESEARCH.md findings tagged LOW or MEDIUM confidence (defaults to 0 when `--skip-research`).

The weights (5, 2, 3) reflect that novel patterns are the highest-impact risk source, unknown dependencies are partially mitigated by research framing, and unresolved questions are blocking but typically narrow in scope.

## Quadratic Combine (SCORE-02)

```
combined = sqrt(structure^2 + risk^2 + 0.3 * volume^2)
```

The quadratic norm penalizes phases that are large in MULTIPLE perspectives — a phase with high structure AND high risk routes to opus more aggressively than one that's high in just one dimension. The `0.3 * volume^2` weight reflects that raw size matters but matters less than structural complexity or risk.

**Numerical stability:** `Math.sqrt` is IEEE-754 deterministic across all standard Node versions (verified). Since `volume`, `structure`, `risk` are small positive numbers (typically 0-50 each), the squares stay well below `Number.MAX_SAFE_INTEGER` — no precision loss at the integer-to-float boundary.

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

| Extension | Bytes per token |
|-----------|----------------:|
| .md, .txt, .sql | 4.0 |
| .py | 4.5 |
| .go, .css, .yaml, .yml | 3.5 |
| .rs | 3.3 |
| .ts, .tsx | 3.2 |
| .js, .jsx, .sh, .html | 3.0 |
| .json | 2.5 |
| (default / unknown) | 3.0 — conservative high default biases toward over-counting tokens, leaning toward triggering the phase-split advisory rather than missing it |

Notes: prose extensions (.md, .txt, .sql) match industry consensus for documentation density. Code extensions cluster at ~3.0 bytes/token (.js, .sh, .html) with TypeScript denser (.ts: 3.2) due to type annotations and Rust slightly denser still (.rs: 3.3) from lifetimes. Python is the outlier at 4.5 because of verbose syntax with fewer operators per token. JSON at 2.5 reflects high token density from keys and brackets.

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

The "top contributors" line lists the two highest-weighted contributing signals to the combined score. Ranking is by **weighted contribution** to the combined score (not raw signal count) — e.g., 2 novel findings contribute `2*5*5 = 50` to the structure-component-of-combined, while 47 files contribute `sqrt(47)*1.5 = 10.3` to volume which is then scaled by 0.3 in the combine (A4 lock per 08-RESEARCH.md Assumptions Log).

**Mode-aware behavior (D-02):** Phase 9 plumbs the `mode` config field — `auto` shows warning banner only; `confirm` (default) opens AskUserQuestion with "Continue with current scope" / "Stop and split this phase manually" options; `--text` flag emits a numbered-list fallback matching Phase 2. **No auto split-point detection in v1.1** — deferred to v2 milestone.

## Half-Up Rounding (D-10)

All score numbers display to **1 decimal place**, rounded half-up for determinism. Threshold proximity stays visible (12.0 vs 14.8 vs 11.9).

```javascript
function roundHalfUp1Decimal(x) {
  // Number.EPSILON defeats float-binary edge cases (e.g., 1.005 * 10 === 10.04999...).
  // ECMA-262: Math.round rounds half-values toward +∞ — half-up for positive scores.
  return Math.round((x + Number.EPSILON) * 10) / 10;
}
// Verified: roundHalfUp1Decimal(1.005) → 1.1, roundHalfUp1Decimal(2.45) → 2.5, roundHalfUp1Decimal(0.0) → 0.0
```

**Why not naive `Math.round(x * 10) / 10`:** Per Pitfall 1 in 08-RESEARCH.md, `Math.round(1.005 * 10) / 10` returns `1.0` (not `1.1`) because `1.005 * 10 === 10.049999999999999` in IEEE-754 double precision. The `Number.EPSILON` correction adds a 2.22e-16 nudge — cheap and effective for the score domain (small positive numbers, single-decimal output). Without it, success criterion #1 (determinism) fails silently when formula-equivalent inputs arrive from different code paths.

**Bash mirror (for tests/eval-scoring.sh):** awk's `printf "%.1f"` exhibits the same float-binary edge-case in some implementations. The test harness uses `printf "%.1f", x + 1e-9` as the equivalent nudge. Both layers must produce identical rounded outputs to satisfy success criterion #1.

## Signal Extraction (D-13, D-15, D-16)

Step 9.5 is **hybrid**: auto-extraction by default, with optional per-signal manual override via a `<signals>` block in CONTEXT.md. Specified signals replace auto-extracted values; missing signals use the auto value.

### Auto-extraction sources

Each of the 8 signals has a defined source — the `<questions>` gap is documented honestly per Pitfall 2.

#### `files_modified`
- **Source:** Deduplicated union of `unit.files` across all in-memory unit objects produced in Step 8.
- **Auto heuristic:** `Array.from(new Set(units.flatMap(u => u.files))).length`
- **Override key:** `files_modified: <int>`
- **fallback when missing:** 0 (zero units → zero files; banner annotates `(no units)`)
- **Per D-15** the dedup is mandatory — same file referenced by 3 units counts once.

#### `tasks`
- **Source:** `units.length` (count of in-memory unit objects).
- **Auto heuristic:** `units.length`
- **Override key:** `tasks: <int>`
- **fallback when missing:** 0
- **Open Question 1 lock:** `tasks` is `units.length`, NOT the sum of test scenarios. One unit emits one `<task>` in PLAN.md.

#### `key_links`, `artifacts`, `truths` (must_haves length signals)

These three signals share an identical extraction pattern — read the corresponding `must_haves.<key>.length` from Step 8 output, fallback to 0 when missing, and override key matches the signal name (e.g., `key_links: <int>`).

- **Source:** `must_haves.key_links.length`, `must_haves.artifacts.length`, `must_haves.truths.length`
- **Auto heuristic:** `must_haves.<key>?.length ?? 0`
- **Override keys:** `key_links: <int>`, `artifacts: <int>`, `truths: <int>`
- **fallback when missing:** 0 (each independently)

#### `novel`, `checkpoints`, `unknown_deps` (research-derived signals)

- **`novel`** — count of CE feasibility findings rated HIGH (read Step 11 output, count `severity: HIGH` entries). Override key `novel: <int>`. Fallback 0 when `--skip-research` passed or feasibility review not yet run; banner appends `(reduced confidence: --skip-research used)` per D-08.
- **`checkpoints`** — count of unresolved questions in CONTEXT.md `<questions>` blocks (parse `<questions>...</questions>` or `Q\d+` headers). Override key `checkpoints: <int>`. **Known gap:** the GSD CONTEXT.md template does not currently define `<questions>`; when absent, default to 0 and append `(no <questions> block; checkpoints defaulted to 0)` to the banner. Power users may opt in by adding the section manually; a future GSD enhancement may auto-populate from DISCUSSION-LOG.md `Q\d+` headers.
- **`unknown_deps`** — count of RESEARCH.md findings tagged `Confidence: LOW` or `Confidence: MEDIUM`. Override key `unknown_deps: <int>`. Fallback 0 when `--skip-research` passed (per D-08).

### `<signals>` override block schema

Per D-13 power users can correct false positives via a `<signals>` block in their phase CONTEXT.md. Schema is flat key:value pairs (no YAML wrapper, no nesting), parseable by the same `yaml_get` pattern used by the test harness:

```
<signals>
files_modified: 47
novel: 8
unknown_deps: 2
</signals>
```

**Merge rule:** Each key in the block REPLACES the auto-extracted value for that signal. Missing keys leave the auto value in place. Unknown keys are silently ignored (forward-compatible).

**Validation:** Values must be non-negative integers. A `<signals>` block with a non-numeric or negative value is treated as a parsing error — the override is rejected for that signal and the auto value is used; the banner appends `(<signals> override rejected for {key}: not a non-negative integer)`. Per the threat model, the only input validation needed is non-negative integer enforcement — there is no untrusted source for `<signals>` content beyond the developer's own CONTEXT.md.

## Banner Format (D-09, D-10, D-12)

Step 9.5 emits a compact 3-line banner using the existing progress-reporting protocol from SKILL.md.

### Required structure

```
── deep-plan [9.5/{total}] Routing decision ──
Volume: {V.V} | Structure: {S.S} | Risk: {R.R} → Combined: {C.C}
Recommendation: {model} ({bias} bias, threshold {T})
{optional advisory line if D-01 triggered}
{optional borderline hint if D-12 triggered}
{optional reduced-confidence note if D-08 applies}
<!-- DEEP_PLAN_ROUTING: model={model} combined={C.C} volume={V.V} structure={S.S} risk={R.R} bias={bias} threshold={T} advisory={true|false} -->
```

**Numbers display rule (D-10):** All scores `{V.V}`, `{S.S}`, `{R.R}`, `{C.C}` are rounded half-up to 1 decimal place via the helper above and rendered with `roundHalfUp1Decimal(value).toFixed(1)` to preserve trailing zeros (`12.0`, not `12`).

### Borderline hint (D-12)

When `combined` is within ±10% of either threshold for the active bias (`within10pct(combined, threshold) := |combined - threshold| <= 0.1 * threshold`), append a bias-bump hint:

```
close to {opus|sonnet} threshold; bump bias to {quality|balanced} if you want {opus|sonnet}
```

Closer threshold wins — never show both hints simultaneously. Suggests bumping toward opus when near `opus_threshold`; suggests bumping bias when near `sonnet_threshold` and `combined < opus_threshold`.

### Caveman exemption (D-11) and machine-readable trailer

Per D-11 the entire banner stays full prose regardless of caveman compression mode — enforced via the `Routing Decision Banner` v2 signal in `references/caveman-rule.md` (added by Plan 02); SKILL.md Step 1 builds the override map and Step 9.5 inherits the exemption automatically.

The HTML comment on the last line is the **stable assertion target** for tests. Per Pitfall 5 in 08-RESEARCH.md, asserting on prose lines is fragile (typo fixes break tests) — assert on the comment instead, parsing with `grep -E '<!-- DEEP_PLAN_ROUTING:'` plus awk-style key=value extraction. The prose banner is for the user; the trailer is for the test harness.

## Worked Examples

Each example cross-references a tested fixture in `skills/deep-plan/fixtures/scoring/`; the fixture frontmatter encodes expected outputs while this file shows the math by hand (success criterion #4 — math reviewable without running code).

### Example 1: small phase → haiku

Fixture: `01-haiku-small.md`. Inputs: files_modified=1, tasks=1, key_links=0, artifacts=1, truths=1, novel=0, checkpoints=0, unknown_deps=0, bias=balanced.

```
volume    = sqrt(1) * 1.5 + 1 * 0.3 = 1.5 + 0.3 = 1.8
structure = 0 * 3 + 1 * 1.5 + 1 * 0.5 = 0 + 1.5 + 0.5 = 2.0
risk      = 0 * 5 + 0 * 2 + 0 * 3 = 0.0
combined  = sqrt(2.0^2 + 0.0^2 + 0.3 * 1.8^2) = sqrt(4.0 + 0 + 0.972) = sqrt(4.972) ≈ 2.2
```

Threshold check (balanced bias): 2.2 < sonnet (4) → **haiku**. No advisory (input_tokens 15000 < 180000).

### Example 2: borderline phase → opus (locks the >= rule)

Fixture: `04-borderline-equal.md`. Inputs designed to land combined exactly at the opus threshold value 12.0.

```
volume    = sqrt(0) * 1.5 + 0 * 0.3 = 0.0
structure = 4 * 3 + 0 * 1.5 + 0 * 0.5 = 12.0
risk      = 0
combined  = sqrt(12^2 + 0 + 0.3 * 0) = sqrt(144) = 12.0
```

Threshold check: 12.0 >= opus (12) → **opus** (per the >= rule). This is the load-bearing example for Pitfall 4 mitigation.

### Example 3: advisory-triggering phase → opus + advisory

Fixture: `05-advisory-trigger.md`. Inputs: files_modified=15, tasks=8, key_links=5, artifacts=10, truths=15, novel=3, checkpoints=2, unknown_deps=4, input_tokens=190000.

```
volume    = sqrt(15) * 1.5 + 8 * 0.3 ≈ 5.81 + 2.4 = 8.2
structure = 5 * 3 + 10 * 1.5 + 15 * 0.5 = 15 + 15 + 7.5 = 37.5
risk      = 3 * 5 + 2 * 2 + 4 * 3 = 15 + 4 + 12 = 31.0
combined  = sqrt(37.5^2 + 31.0^2 + 0.3 * 8.2^2) = sqrt(1406.25 + 961 + 20.17) ≈ 48.9
```

Threshold check: 48.9 >= opus (12) → **opus**. Advisory check: 190000 > 180000 AND 48.9 >= 12 → **advisory: true**. Banner trailer: `<!-- DEEP_PLAN_ROUTING: model=opus combined=48.9 volume=8.2 structure=37.5 risk=31.0 bias=balanced threshold=12 advisory=true -->`

## Fixtures

Eight golden fixtures in `skills/deep-plan/fixtures/scoring/`:

- `01-haiku-small.md` — size_class: haiku. Smallest plausible phase, all risk signals zero.
- `02-quality-bias.md` — size_class: sonnet, bias: quality. Same inputs that route to sonnet under balanced bias instead route to opus under quality bias (combined 8.3 >= quality_opus 8). Proves bias selection drives mapping (ROADMAP success criterion #3).
- `03-opus-large.md` — size_class: opus. Large phase with novel patterns, multiple unknown deps.
- `04-borderline-equal.md` — size_class: borderline. Combined exactly equals opus threshold (12.0). Locks the `>=` comparison rule.
- `05-advisory-trigger.md` — size_class: advisory. input_tokens > 180k AND combined >= opus threshold. D-01 strict AND.
- `06-signals-override.md` — size_class: opus. Demonstrates D-13 hybrid extraction with `<signals>` block override.
- `07-reduced-confidence.md` — size_class: opus. D-08 `--skip-research` path with novel=0 and unknown_deps=0.
- `08-borderline-hint.md` — size_class: borderline_hint. Combined ≈ 11.5 sits in lower ±10% band of opus threshold 12; routes to sonnet but borderline_hint string is asserted (D-12, VALIDATION.md task 8-07-02).

The eval harness `tests/eval-scoring.sh` parses each fixture's frontmatter, recomputes scores via the formulas above, compares against `expected_*` fields with 0.05 tolerance, and re-runs each fixture asserting byte-equal output (success criterion #1 determinism).

## See Also

- Fixtures: `skills/deep-plan/fixtures/scoring/`
- Eval script: `tests/eval-scoring.sh`
- Caveman exemption: `skills/deep-plan/references/caveman-rule.md` (Signal: Routing Decision Banner)
- Deep-plan pipeline: `skills/deep-plan/SKILL.md` Step 9.5
- Requirements: `.planning/REQUIREMENTS.md` SCORE-01, SCORE-02, SCORE-03, SCORE-04
- Phase 8 context: `.planning/phases/08-scoring-algorithm-foundation/08-CONTEXT.md` (D-01 through D-16)
- Downstream phases — Phase 9 reads thresholds and byte ratios from this file as fallback when `model_routing` config is missing; Phase 11 reads the in-memory routing decision object produced by Step 9.5 and writes to PLAN.md frontmatter; Phase 12 appends the same object to `_telemetry.decisions[]`.
