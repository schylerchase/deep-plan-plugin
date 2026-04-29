---
phase: 09-configuration-system
plan: 01
subsystem: documentation

tags: [config, reference, schema, contract, model-routing, single-source-of-truth]

requires:
  - phase: 08-03
    provides: scoring.md threshold map, byte ratios, signal heuristic weights, formula coefficient, advisory token budget, borderline-hint window — the canonical defaults source that config.md forward-references for every fallback value

provides:
  - "skills/deep-plan/references/config.md — full deep_plan.model_routing schema contract: 6 user-facing fields + 2 metadata fields, weight_overrides shape (D-06), context_thresholds shape (D-07), JSON schema block, deep-merge semantics (D-08), deep-merge JS helper, lenient validation contract (D-09/D-10), 8-field resolved-config object shape (D-12), 4 worked examples, schema versioning (D-11), See Also footer"
  - "Stable schema for Phase 10 wizard to write against (inline-during-skill and standalone configure paths)"
  - "Stable schema for Phase 11 PLAN.md frontmatter writer (executor_model + model_recommendation)"
  - "Stable schema for Phase 12 doctor strict-validation (D-10 contract split)"

affects:
  - 09-02 (SKILL.md Step 1 will reference config.md sections via `**Read references/config.md**`)
  - 10 (wizard writes the schema documented here; reads same resolution layer for current-values display)
  - 11 (per-phase executor_model override extends this schema as schema_version 2 candidate)
  - 12 (doctor strict-validates .planning/config.json against this contract; drift detection via gsd_profile_at_setup)

tech-stack:
  added: []
  patterns:
    - "Single source of truth reference doc — scoring.md analog (D-13 progressive disclosure, sibling pattern from Phase 8)"
    - "Defaults-source single-pointer rule — config.md never duplicates scoring.md threshold/weight tables; 5 forward-reference bullets pointing back at scoring.md as canonical source"
    - "Inline-helper-with-explanation pattern — fenced JS deep-merge helper followed by Known edge case + Per-field fallback implication callouts (mirrors scoring.md roundHalfUp1Decimal rhythm)"
    - "Banner-as-decision-artifact reuse — config diagnostic notices ride existing routing-banner caveman exemption (Phase 8 D-11), no new caveman v2 signal added"

key-files:
  created:
    - "skills/deep-plan/references/config.md (262 lines, 12 H2 sections)"
  modified: []

key-decisions:
  - "Defaults-source single-pointer rule honored — config.md authors 5 forward-reference bullets back to scoring.md (bias_thresholds, formula.volume_coefficient, signals, token_budget_advisory, borderline_hint_window) and never re-states the canonical numeric values in standalone tables"
  - "D-05 banner literal `pinned — confirm prompt suppressed` locked verbatim in the mode-pin orthogonality narrative (W1 contract)"
  - "D-08 deep-merge load-bearing example uses bias_thresholds.opus.quality = 7 to demonstrate that opus.balanced/budget and the entire sonnet block stay at defaults — the canonical no-merge-surprises proof"
  - "D-09 lenient validation cap-at-3 spelled out with both literal phrasing (`Capped at 3 lines`) and a worked example (`+5 more, see /deep-plan-doctor`) so verifier greps lock both forms"
  - "D-10 skill-time/doctor-time contract split named explicitly in prose — `skill-time = forgiving` and `doctor-time = thorough`"
  - "D-11 absent-schema_version fallback documented (`treat as 1`) — closes forward-compat gap without requiring migration logic in v1.1"
  - "D-12 8-field resolved-config block shipped as JS-style fenced pseudocode mirroring scoring.md inline-helper rhythm"
  - "No new caveman v2 signal added — banner diagnostic notices ride the existing Routing Decision Banner exemption from Phase 8 D-11 (verified: caveman-rule.md unchanged in this plan)"

patterns-established:
  - "Six-field-plus-two-metadata header structure for resolved-config docs — schema_version + _source as the metadata pair around six user-facing fields"
  - "Per-key prose-after-fenced-JSON pattern — show the example block first, then explain each key in a bullet list so readers can copy the JSON wholesale and audit each key independently"
  - "Worked Examples ordering: defaults → partial override → malformed fallback → full custom — same four-case ladder Phase 10 wizard will narrate in its current-values display"

requirements-completed:
  - CONFIG-01
  - CONFIG-02
  - CONFIG-03

duration: 16min
completed: 2026-04-29
---

# Phase 09 Plan 01: config.md Schema Reference Summary

**262-line single-source-of-truth reference document containing the deep_plan.model_routing schema contract — six user-facing fields with type/default/validation rules, weight_overrides and context_thresholds shapes, full JSON schema, deep-merge semantics with the canonical bias_thresholds.opus.quality worked example, lenient validation contract with cap-at-3 banner format, eight-field resolved-config object shape, four end-to-end worked examples covering defaults/partial-override/malformed-fallback/full-custom, and a See Also footer cross-referencing scoring.md, SKILL.md Step 1, REQUIREMENTS.md, CONTEXT.md, PATTERNS.md, and caveman-rule.md.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-04-29T14:09:05Z
- **Completed:** 2026-04-29T14:25:09Z
- **Tasks:** 1
- **Files modified:** 1 (config.md created)

## Accomplishments

- Authored skills/deep-plan/references/config.md (262 lines, within the 240-380 done criterion).
- All 12 H2 sections present and ordered per the plan: Status, The Six Resolved-Config Fields, weight_overrides Shape (D-06), context_thresholds Shape (D-07), JSON Schema, Override Merge Semantics (D-08), Deep-Merge Helper, Lenient Validation Contract (D-09, D-10), Resolved-Config Object Shape (D-12), Worked Examples, Schema Versioning (D-11), See Also.
- All 13 D-NN decisions from CONTEXT.md addressed in the file (D-01 through D-13 each appear at least once and substantively, with D-12 cited 5 times across schema/resolved-config/worked-examples sections).
- D-05 literal banner string `pinned — confirm prompt suppressed` present verbatim in the mode-pin orthogonality narrative — locks the W1 contract that the verifier and Phase 10 wizard will assert against.
- D-08 deep-merge canonical worked example shipped with the load-bearing `bias_thresholds.opus.quality = 7` partial override demonstrating that opus.balanced/budget and the entire sonnet block stay at defaults.
- D-09 lenient validation contract spelled out with banner notice format (`config: used default for {dotted.path} (malformed: expected {type}, got {actual})`), 3-line cap rule, and worked summary line example (`+5 more, see /deep-plan-doctor`).
- D-10 skill-time/doctor-time split named explicitly with the `skill-time = forgiving` and `doctor-time = thorough` callouts.
- D-11 schema versioning documented with `schema_version: 1` requirement, absent-treats-as-1 fallback, and v1.2 migration backlog flag.
- D-12 8-field resolved-config object block shipped as JS-style fenced pseudocode with all eight fields (schema_version, mode, pin, bias, gsd_profile_at_setup, weight_overrides, context_thresholds, _source) and the per-source computation rule.
- Defaults-source single-pointer rule honored — 5 forward-reference bullets pointing at scoring.md as the canonical source for bias_thresholds, formula.volume_coefficient, signals, token_budget_advisory, and borderline_hint_window. No standalone re-stated threshold tables in config.md outside the JSON schema block, the D-08 worked example, and the inline-on-same-line-as-pointer bullets (per the action body's defaults_source_constraints).
- caveman-rule.md NOT modified — banner diagnostic notices ride the existing Routing Decision Banner exemption from Phase 8 D-11. `git diff --name-only HEAD -- skills/deep-plan/references/caveman-rule.md` returns empty, confirming the no-new-caveman-signal constraint.

## Task Commits

This plan was a single task; one atomic commit:

1. **Task 1: Author config.md schema spec, resolved-config shape, deep-merge, lenient validation, worked examples, See Also** — `f11402d` (feat)

## Files Created/Modified

- `skills/deep-plan/references/config.md` (NEW, 262 lines) — full deep_plan.model_routing schema contract per D-13 single-source-of-truth.

## Decisions Made

All decisions in this plan were locked upstream in 09-CONTEXT.md (D-01 through D-13). This plan's job was to document them in the reference file. No new decisions were introduced during execution.

The execution-time judgment calls were:

- **Inlined a numeric example for the cap-summary phrase** — the plan's behavior assertion required `\+[0-9]+ more.*deep-plan-doctor` to match. The plan's draft prose used the literal `+N more` (placeholder N, no digits). Added a worked instance `+5 more, see /deep-plan-doctor` aside the `+N more` placeholder so both the literal-N variant (for readers) and the digit-bearing variant (for the regex assertion) appear in the file. No semantic change — N is still parameterized, the worked example just exemplifies the parameter.
- **Restructured the context_thresholds prose into 3 Defaults bullets** — to satisfy the `>= 5` Defaults-bullet count without padding the doc. The plan's PATTERNS.md guidance (lines 142-150) explicitly anticipates 3 forward-reference bullets in context_thresholds (one per sub-key). Ship those plus 1 in bias and 1 in weight_overrides = 5 total, exactly meeting the floor. Each bullet inlines the literal default value on the same line as the scoring.md pointer (per the defaults_source_constraints clarification at plan lines 148-156).
- **Deep-merge helper used `falls back` regex-friendly phrasing** — Test 7 grep is `skill-time.*forgiving|lenient.*runtime`. Used `skill-time = forgiving:` exactly so the assertion fires on the literal phrase rather than relying on the alternate `lenient.*runtime` branch. Both branches still match (the doc says "validation at skill-time is **lenient**" earlier), but the explicit `skill-time = forgiving` line is the load-bearing match.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Initial draft's cap-summary phrasing did not include a literal digit, causing Test 6 first regex to fail**

- **Found during:** Task 1 verify pass (running the plan's grep assertion `\+[0-9]+ more.*deep-plan-doctor`).
- **Issue:** The first draft used `+N more, see /deep-plan-doctor` (literal capital-N as placeholder). The plan's verify regex requires `[0-9]+` — at least one digit — so the assertion failed with no match.
- **Fix:** Added a worked example sentence after the placeholder bullet: "For example, when 8 fields are malformed the banner shows the first 3 notice lines plus the literal summary line `+5 more, see /deep-plan-doctor`." Both forms now appear: the `+N more` placeholder for readers (parameterized) and `+5 more` for the regex assertion (concrete).
- **Files modified:** `skills/deep-plan/references/config.md` (one-line edit before commit).
- **Verification:** All 20 plan grep assertions now pass cleanly. Re-ran the full verify block; line count stayed at 262 (within the 240-380 bound).
- **Committed in:** `f11402d` (the fix was integrated into the single Task 1 commit, not a separate fix commit, because it was caught pre-commit during the verify pass).

---

**Total deviations:** 1 auto-fixed (Rule 1 bug — verify regex would have failed without the digit-bearing example).
**Impact on plan:** No content drift. The fix preserves the `+N more` parameterized banner format while adding a worked example that satisfies the `[0-9]+` regex assertion. Both readers and the verifier are happy.

## Issues Encountered

None during execution. The worktree's `.planning/` directory is gitignored (per the project's .gitignore) and was not present in the worktree at the start. Read planning context (PLAN.md, CONTEXT.md, PATTERNS.md, PROJECT.md, REQUIREMENTS.md, scoring.md) from the main repo at `/Users/schylerryan/Desktop/Github/deep-plan-plugin/.planning/`. Created `.planning/phases/09-configuration-system/` in the worktree to write this SUMMARY.md and force-added it (per the established Phase 8 pattern in commit `54116a1`) so the orchestrator can merge it back.

## Output Required by Plan

Per the plan's `<output>` block, this summary records:

### Line count

262 lines (within the 240-380 done criterion; close to the 250-350 target band).

### Sections shipped

```
## Status
## The Six Resolved-Config Fields
## weight_overrides Shape (D-06)
## context_thresholds Shape (D-07)
## JSON Schema
## Override Merge Semantics (D-08)
## Deep-Merge Helper
## Lenient Validation Contract (D-09, D-10)
## Resolved-Config Object Shape (D-12)
## Worked Examples
## Schema Versioning (D-11)
## See Also
```

12 H2 sections. Plan 02's SKILL.md edit can name any of these section titles in its `**Read references/config.md**` cross-reference (e.g., "for deep-merge semantics, see ## Override Merge Semantics (D-08)").

### Forward-reference for Plan 02

Plan 02 reads this file and references it from SKILL.md Step 1 via the `**Read references/config.md**` directive — terse pointer in the SKILL body that delegates schema, deep-merge rules, lenient fallback narrative, and resolved-config object shape to this reference doc.

The exact prose Plan 02 should drop into Step 1 (per PATTERNS.md line 181):

```markdown
**Read `references/config.md`** for: the JSON schema, default values sourced from `references/scoring.md`, the deep-merge rules per D-08, lenient field-level fallback narrative per D-09, and the resolved-config object shape per D-12.
```

### Schema fields locked for downstream phases

Phase 10 wizard, Phase 11 frontmatter writer, and Phase 12 doctor all read this contract. The following field names and types are now stable:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `schema_version` | `1` (literal) | `1` | Required from day one; absent → treat as 1 |
| `mode` | `"auto" \| "confirm" \| "silent"` | `"confirm"` | D-04 mode×pin orthogonality |
| `pin` | `null \| "opus" \| "sonnet" \| "haiku"` | `null` | D-01/D-02/D-03; bypasses scoring entirely when set |
| `bias` | `"quality" \| "balanced" \| "budget"` | `"balanced"` | Drives threshold map; defaults from scoring.md |
| `gsd_profile_at_setup` | `string \| null` | `null` | Phase 10 wizard captures; Phase 12 doctor drifts |
| `weight_overrides` | object with `formula` + `signals` sub-blocks | `{}` (materialized to scoring.md defaults) | D-06 two-block shape |
| `context_thresholds` | object with `bias_thresholds` + `token_budget_advisory` + `borderline_hint_window` | `{}` (materialized to scoring.md defaults) | D-07 three-key shape |
| `_source` | `"config" \| "defaults" \| "merged"` | computed | Diagnostic; not persisted |

Phase 10 wizard MUST write the first 6 user-facing fields (schema_version through context_thresholds). `_source` is computed at resolution time, not written. `gsd_profile_at_setup` is captured by the wizard from `gsd-tools.cjs config-get model_profile`.

### Confirmation: caveman-rule.md unchanged

`git diff --name-only HEAD -- skills/deep-plan/references/caveman-rule.md` returns empty. No new caveman v2 signal was added — the banner diagnostic notices documented in this file ride the existing `Signal: Routing Decision Banner` exemption locked in Phase 8 D-11. Future plans (Phase 10 wizard, Phase 12 doctor) inherit this exemption automatically.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 09-02 (SKILL.md Step 1 wiring):** config.md exists at the canonical path with all 12 sections; Plan 02 can write `**Read references/config.md**` once at the top of the Step 1 body (after caveman setup, before Step 2) and never inline a schema field or default value.
- **Phase 10 (wizard):** Schema is stable. Wizard prompts encode the same field shape; the wizard skip path saves `gsd_profile_at_setup: null`. Wizard validates user input against the schema in this file.
- **Phase 11 (PLAN.md frontmatter writer):** Schema is the canonical source for the `executor_model` field semantics. v1.2 schema-bump candidate (`default_executor_model` field) is flagged in the Schema Versioning section.
- **Phase 12 (doctor):** Schema strict-validation contract is locked. Doctor reads this file as the source of truth for valid field names and types; the D-10 skill-time/doctor-time split tells doctor implementers exactly what skill-time leniency they must catch.

## Self-Check: PASSED

- FOUND: `skills/deep-plan/references/config.md` (262 lines)
- FOUND: `.planning/phases/09-configuration-system/09-01-SUMMARY.md` (this file)
- FOUND: commit `f11402d` (Task 1 — feat(09-01))
- VERIFIED: caveman-rule.md unchanged in this plan
- VERIFIED: All 20 grep assertions from the plan's `<verify>` automated block pass

---

*Phase: 09-configuration-system*
*Completed: 2026-04-29*
