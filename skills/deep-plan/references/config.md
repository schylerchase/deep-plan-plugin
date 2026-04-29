# Configuration Contract — Single Source of Truth

## Status

**Version:** v1 (Phase 9 — Adaptive Model Routing milestone v1.1)
**Loaded by:** SKILL.md Step 1 (config resolution; D-13 once-at-startup, D-12 in-memory resolved-config object)
**Loaded on demand:** This file is read once per deep-plan run at Step 1 immediately after caveman setup. Per D-13, the resolved-config object is cached in skill scope for the entire run — no hot-reload on file mtime change.
**Phase 10 dependency:** The setup wizard (`/deep-plan-configure`) writes the schema documented in this file. Wizard prompts and edit menus encode the same field shape; both paths (inline-during-skill and standalone) target this contract.
**Phase 12 dependency:** The doctor command (`/deep-plan-doctor`) strict-validates `.planning/config.json` `deep_plan.model_routing` against this schema. Doctor catches errors that skill-time lenient validation falls past silently (D-10 contract split).

## The Six Resolved-Config Fields

Per D-12 the resolved-config object exposed to all downstream steps has six user-facing fields plus two metadata fields (schema_version, _source). Each is documented below with type, default, and validation rule.

### schema_version

Type: `1` (literal integer). Per D-11 this field is required from day one. Absent → treat as 1 (forward-compat fallback). Forward-compat note: v1.2+ may add fields and bump the version; migration logic is flagged for the v1.2 backlog.

### mode

Type: `"auto" | "confirm" | "silent"`. Default `"confirm"` per D-04 mode×pin orthogonality discussion. Per Phase 8 D-02: auto = banner only, confirm = AskuserQuestion, silent = no advisory output. The `--text` flag overlays mode with numbered-list fallback per Phase 2.

- **D-05 mode-pin orthogonality note:** When `pin` is set AND advisory triggers (180k input + high complexity per Phase 8 D-01), the `mode=confirm` path collapses to `mode=auto` behavior — the confirm prompt is moot because there is no alternative to switch to. The banner appends the literal notice `pinned — confirm prompt suppressed` so the user sees why no prompt fired.

### pin

Type: `null | "opus" | "sonnet" | "haiku"`. Default `null`. Per D-01/D-02/D-03. When set, scoring is bypassed entirely — routing decision = `{model: <pinned>, pinned: true, scoring_skipped: true}`. Banner reads `model=opus pinned=true (scoring skipped)` instead of the score breakdown. Pin is global only in v1.1; per-phase override deferred to Phase 11 PLAN.md `executor_model:` frontmatter.

### bias

Type: `"quality" | "balanced" | "budget"`. Default `"balanced"`. Drives threshold map selection per Phase 8 D-04 (`opus_thresholds = {quality: 8, balanced: 12, budget: 20}`).

- **Defaults:** See `references/scoring.md` ## Threshold Map. Default `bias_thresholds` is `{opus: {quality: 8, balanced: 12, budget: 20}, sonnet: {quality: 3, balanced: 4, budget: 6}}` — sourced from that file, not duplicated here.

### gsd_profile_at_setup

Type: `string | null`. Default `null`. Captured at first wizard run (Phase 10 calls `gsd-tools.cjs config-get model_profile`). Read-only in v1.1: this phase only reads `gsd_profile_at_setup`; Phase 12 doctor compares against the current `model_profile` for drift detection. The wizard skip path saves `null` here and surfaces a `[WARN]` in doctor afterward (per WIZ-03).

### weight_overrides

See `## weight_overrides Shape (D-06)` below for full shape detail.

### context_thresholds

See `## context_thresholds Shape (D-07)` below for full shape detail.

### _source

Type: `"config" | "defaults" | "merged"`. Diagnostic flag — NOT part of the persisted schema. Computed at resolution time. The banner uses it: `routing config: defaults` vs `routing config: customized (3 fields overridden)`. Useful when debugging "why did I get sonnet?" support questions.

## weight_overrides Shape (D-06)

Per D-06 `weight_overrides` is an object with two optional sub-blocks targeting different layers of the scoring math. Both sub-blocks are independently optional; per-field fallback to scoring.md defaults applies to any sub-key absent from user config.

```json
"weight_overrides": {
  "formula": { "volume_coefficient": 0.3 },
  "signals": {
    "files_modified": 1.5,
    "tasks": 0.3,
    "key_links": 3,
    "artifacts": 1.5,
    "truths": 0.5,
    "novel": 5,
    "checkpoints": 2,
    "unknown_deps": 3
  }
}
```

Then in prose:

- `formula` overrides the `0.3` constant in the quadratic combine `sqrt(structure² + risk² + V × volume²)`. Rare; advanced users tuning aggregate weighting.
- `signals` overrides the per-signal heuristic weights from Phase 8 D-16. More common — "novel patterns matter more in my codebase" or "I want files_modified to count for less".
- **Defaults:** See `references/scoring.md` ## Quadratic Combine for `formula.volume_coefficient` (default 0.3); see ## Signal Extraction for per-signal weights — sourced from that file, not duplicated here.

## context_thresholds Shape (D-07)

Per D-07 `context_thresholds` is one block with three semantically related keys. Each is a "threshold" in the routing decision pipeline. Keeping them in one block makes the config readable as a single "thresholds" concern.

```json
"context_thresholds": {
  "bias_thresholds": {
    "opus":   { "quality": 8, "balanced": 12, "budget": 20 },
    "sonnet": { "quality": 3, "balanced": 4,  "budget": 6 }
  },
  "token_budget_advisory": 180000,
  "borderline_hint_window": 0.10
}
```

Per-key prose:

- **Defaults:** See `references/scoring.md` ## Threshold Map for `bias_thresholds`. Phase 9 reads the table on-demand; default values `{opus: {quality: 8, balanced: 12, budget: 20}, sonnet: {quality: 3, balanced: 4, budget: 6}}` are sourced from that file, not duplicated here.
- **Defaults:** See `references/scoring.md` ## Token Estimation for `token_budget_advisory` (default 180000) — phase-split advisory trigger per Phase 8 D-01, sourced from that file, not duplicated here.
- **Defaults:** See `references/scoring.md` ## Banner Format for `borderline_hint_window` (default 0.10) — banner appends bias-bump hint when combined is within ±N% of a threshold per Phase 8 D-12, sourced from that file, not duplicated here.

## JSON Schema

Below is the full `deep_plan.model_routing` block as it appears in `.planning/config.json`. All fields are optional from the user's perspective — the resolved-config object backfills missing fields with defaults from `references/scoring.md`.

```json
{
  "deep_plan": {
    "model_routing": {
      "schema_version": 1,
      "mode": "confirm",
      "pin": null,
      "bias": "balanced",
      "gsd_profile_at_setup": null,
      "weight_overrides": {
        "formula": { "volume_coefficient": 0.3 },
        "signals": { "files_modified": 1.5, "tasks": 0.3, "novel": 5, "checkpoints": 2, "unknown_deps": 3 }
      },
      "context_thresholds": {
        "bias_thresholds": {
          "opus":   { "quality": 8, "balanced": 12, "budget": 20 },
          "sonnet": { "quality": 3, "balanced": 4,  "budget": 6 }
        },
        "token_budget_advisory": 180000,
        "borderline_hint_window": 0.10
      }
    }
  }
}
```

## Override Merge Semantics (D-08)

Per D-08 override merge is **deep per-field** — last-write wins through nested objects, not whole-block replacement. This honors success criterion #2 ("no merge surprises, last-write wins per field") across nested structures.

Canonical worked example. If config defines:

```json
"context_thresholds": { "bias_thresholds": { "opus": { "quality": 7 } } }
```

then only `bias_thresholds.opus.quality` is overridden (user-supplied value 7 wins). The resolved object retains everything else at default:

- `bias_thresholds.opus.balanced = 12` (default, falls back to scoring.md value)
- `bias_thresholds.opus.budget = 20` (default, falls back to scoring.md value)
- `bias_thresholds.sonnet.{quality, balanced, budget} = {3, 4, 6}` (entire sonnet block at defaults from scoring.md)
- `token_budget_advisory = 180000` (default)
- `borderline_hint_window = 0.10` (default)

This is the load-bearing example for D-08. Without deep-merge, setting one quality threshold would null the rest. Deep-merge guarantees a partial override never wipes an unrelated field.

## Deep-Merge Helper

```javascript
function deepMergeConfig(defaults, overrides) {
  // Recursively merge overrides into defaults. For each key in overrides:
  // - if both values are plain objects, recurse
  // - otherwise, override wins (last-write-wins on leaves)
  // - keys absent from overrides fall through to defaults verbatim
  if (overrides == null) return defaults;
  const out = { ...defaults };
  for (const k of Object.keys(overrides)) {
    if (
      defaults[k] && typeof defaults[k] === 'object' && !Array.isArray(defaults[k]) &&
      overrides[k] && typeof overrides[k] === 'object' && !Array.isArray(overrides[k])
    ) {
      out[k] = deepMergeConfig(defaults[k], overrides[k]);
    } else {
      out[k] = overrides[k];
    }
  }
  return out;
}
```

**Known edge case — array values:** No field in the v1 schema is an array. If a v1.2+ field introduces one, decide explicitly: replace-on-override (current behavior of the helper above) or concat-merge. Document the choice in the migration note for that field.

**Per-field fallback implication:** Lenient validation (D-09) runs AFTER the deep-merge, on each leaf. If a leaf value fails type validation, fall back to the default for that one leaf only — surrounding nested structure stays merged. The banner notice names the dotted path (e.g., `weight_overrides.signals.tasks`) so users can locate the malformed field in their config.

## Lenient Validation Contract (D-09, D-10)

Per D-09 validation at skill-time is **lenient**: each field that fails type validation falls back to the plugin default for that field, and the banner appends a one-line notice. The skill continues without halting.

Banner notice format (one line per malformed field):

```
config: used default for {dotted.path} (malformed: expected {type}, got {actual})
```

Example:

```
config: used default for weight_overrides.formula.volume_coefficient (malformed: expected number, got string)
```

Cap and summary rules:

- **Capped at 3 lines.** When more than 3 fields fail validation, show the first 3 in full and append: `+N more, see /deep-plan-doctor` where N is the remaining count. For example, when 8 fields are malformed the banner shows the first 3 notice lines plus the literal summary line `+5 more, see /deep-plan-doctor`.
- **Summary line ALWAYS appended when total > 3:** the summary is the only path the user has to see counts beyond 3 from the skill itself.

Per D-10 the skill-time/doctor-time contract split is intentional:

- **skill-time = forgiving:** power users can experiment without breakage. A typo in a sub-key falls back to default, the skill does not halt.
- **doctor-time = thorough:** `/deep-plan-doctor` (Phase 12) runs strict validation — full schema check, unknown-field detection, type errors as failures. Different contract, different ergonomics.

## Resolved-Config Object Shape (D-12)

Per D-12 the in-memory resolved-config object exposed to all downstream steps is a single JS-style object with eight fields. Every field is non-optional in the RESOLVED object — defaults backfill anything the user didn't set in `.planning/config.json`.

```javascript
{
  schema_version: 1,
  mode: "auto" | "confirm" | "silent",
  pin: null | "opus" | "sonnet" | "haiku",
  bias: "quality" | "balanced" | "budget",
  gsd_profile_at_setup: string | null,
  weight_overrides: { formula: {...}, signals: {...} },
  context_thresholds: { bias_thresholds: {...}, token_budget_advisory: number, borderline_hint_window: number },
  _source: "config" | "defaults" | "merged"  // diagnostic flag, not part of persisted schema
}
```

**`_source` computation:**

- `"defaults"` — `.planning/config.json` `deep_plan.model_routing` block was absent or top-level malformed.
- `"config"` — block was present and every field validated cleanly.
- `"merged"` — block was present but at least one field fall back to default (lenient validation kicked in on at least one field).

## Worked Examples

### Example 1: Config absent → all defaults

`.planning/config.json` has no `deep_plan` key. Resolved object: `_source: "defaults"`, all six user-facing fields at defaults from scoring.md (`mode = "confirm"`, `pin = null`, `bias = "balanced"`, `gsd_profile_at_setup = null`, `weight_overrides = {}` materialized to defaults, `context_thresholds = {}` materialized to defaults). Banner notice: none.

### Example 2: Partial override → deep merge

`.planning/config.json` contains `deep_plan.model_routing.bias = "quality"` and `deep_plan.model_routing.context_thresholds.bias_thresholds.opus.quality = 7`. Resolved object: `_source: "merged"`, `bias = "quality"` (override applied), `bias_thresholds.opus.quality = 7` (override applied), all other `bias_thresholds` keys (`opus.balanced`, `opus.budget`, and the entire `sonnet.{quality, balanced, budget}` block) at defaults from scoring.md, `token_budget_advisory = 180000` (default), `borderline_hint_window = 0.10` (default). Banner notice: none (no malformed fields).

### Example 3: Malformed field → lenient fallback

`.planning/config.json` contains `weight_overrides.formula.volume_coefficient = "high"`. Resolved object: `_source: "merged"`, `volume_coefficient = 0.3` (fallback default per scoring.md), all other fields validated cleanly. Banner notice (one line):

```
config: used default for weight_overrides.formula.volume_coefficient (malformed: expected number, got string)
```

### Example 4: Full custom config → all overrides applied

`.planning/config.json` contains every field — `schema_version`, `mode`, `pin`, `bias`, `gsd_profile_at_setup`, `weight_overrides` (both sub-blocks), `context_thresholds` (all three sub-keys including nested `bias_thresholds`). Resolved object: `_source: "config"`, every field at user-supplied value, no fallback, no banner notice.

## Schema Versioning (D-11)

- `schema_version: 1` is required from day one.
- **Absent schema_version:** treat as 1 (forward-compat fallback; Phase 9 does no migration). When the field is missing or omitted from user config, the resolved object materializes `schema_version: 1` and proceeds without warning.
- **schema_version > 1:** Phase 9 still resolves — unknown fields silently ignored, known fields validated per the rules above. Doctor (Phase 12) flags as `[WARN]` for upgrade reminder.
- **Migration logic:** flagged for the v1.2 backlog. Phase 11 is the most likely v1.2 schema-change candidate (`default_executor_model` field hypothesized).

## See Also

- Defaults source: `skills/deep-plan/references/scoring.md` (single source of truth for threshold tables, signal weights, byte ratios, advisory token budget, borderline-hint window)
- Deep-plan pipeline: `skills/deep-plan/SKILL.md` Step 1 (config resolution insertion point per D-13)
- Requirements: `.planning/REQUIREMENTS.md` CONFIG-01, CONFIG-02, CONFIG-03
- Phase 9 context: `.planning/phases/09-configuration-system/09-CONTEXT.md` (D-01 through D-13)
- Phase 9 patterns: `.planning/phases/09-configuration-system/09-PATTERNS.md` (analog mapping to scoring.md)
- Caveman exemption: `skills/deep-plan/references/caveman-rule.md` Signal: Routing Decision Banner — banner diagnostic notices ride this existing exemption; NO new caveman signal needed for Phase 9.
- Downstream phases — Phase 10 wizard writes this schema; Phase 11 may extend with `default_executor_model` (schema_version 2 candidate); Phase 12 doctor strict-validates against this file (D-10 contract split). The `gsd_profile_at_setup` field captured at Phase 10 setup feeds Phase 12 doctor's drift-detection check (current `model_profile` vs `gsd_profile_at_setup`).
