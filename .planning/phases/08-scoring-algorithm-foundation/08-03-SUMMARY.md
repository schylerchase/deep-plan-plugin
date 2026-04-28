---
phase: 08-scoring-algorithm-foundation
plan: 03
subsystem: documentation

tags: [scoring, reference, contract, single-source-of-truth, model-routing]

requires:
  - phase: 08-01
    provides: Eight golden fixture filenames in skills/deep-plan/fixtures/scoring/ (cross-referenced by name in scoring.md Worked Examples and Fixtures sections)

provides:
  - "skills/deep-plan/references/scoring.md — full scoring contract: SCORE-01..04 formulas, threshold map, byte-ratio table, 8-signal extraction heuristics, banner format with machine-readable trailer, 3 worked examples, fixtures pointer, See Also cross-references"
  - "Stable schema for Phase 9 to consume thresholds and byte ratios as fallback when model_routing config block is missing"
  - "Documented <signals> override block schema (flat key:value, no YAML wrapper) for Phase 9 wizard validation"

affects:
  - 08-04 (SKILL.md Step 9.5 will reference scoring.md sections)
  - 09 (config defaults — reads opus_thresholds, sonnet_thresholds, byte-ratio table from this file)
  - 10 (wizard — validates <signals> schema documented here)
  - 11 (PLAN.md frontmatter — reads same in-memory routing decision object documented in Banner Format trailer)
  - 12 (telemetry — appends routing decision object documented here)

tech-stack:
  added: []
  patterns:
    - "Single source of truth reference doc — caveman-rule.md analog (D-14 progressive disclosure)"
    - "Machine-readable trailer for stable test assertions (Pitfall 5 mitigation — DEEP_PLAN_ROUTING HTML comment)"
    - "Honest gap documentation — <questions> CONTEXT.md template gap surfaced with banner annotation fallback"

key-files:
  created:
    - "skills/deep-plan/references/scoring.md (300 lines, 11 H2 sections)"
  modified: []

key-decisions:
  - ">=  comparison rule locked for threshold mapping — phase scoring exactly at threshold routes to higher tier (D-04, Pitfall 4 mitigation)"
  - "Number.EPSILON correction recommended for half-up rounding helper — defeats float-binary edge cases like 1.005 * 10 === 10.04999"
  - "Conservative byte-ratio default of 3.0 for unknown extensions — biases toward over-counting tokens, leans toward triggering phase-split advisory rather than missing it"
  - "<signals> override block schema is flat key:value (no YAML wrapper, no nesting) — parseable by same yaml_get awk helper as eval-caveman-rule.sh"
  - "<questions> gap documented honestly — defaults to 0 with banner annotation (no <questions> block; checkpoints defaulted to 0) when CONTEXT.md template lacks the section"
  - "Top contributors ranking by weighted contribution to combined (not raw signal count) — A4 lock per 08-RESEARCH.md Assumptions Log"

patterns-established:
  - "Reference-doc structure mirrors caveman-rule.md: Status → contract sections (numbered rules) → signals → fixtures pointer → See Also"
  - "Per-signal block consolidation when 3+ signals share identical extraction pattern (must_haves length signals; research-derived signals)"
  - "Tag every locked decision (D-NN) inline so reviewer audit greps clean against success criteria"

requirements-completed:
  - SCORE-01
  - SCORE-02
  - SCORE-03
  - SCORE-04

duration: 41min
completed: 2026-04-28
---

# Phase 08 Plan 03: scoring.md Reference Document Summary

**300-line single-source-of-truth reference document containing SCORE-01..04 formulas, bias-adjusted threshold map, heuristic byte-ratio table, eight signal extraction heuristics with hybrid override schema, banner format with machine-readable trailer, three worked examples, and fixtures cross-reference index — mirrors the caveman-rule.md analog and locks the D-14 contract that lets SKILL.md Step 9.5 stay terse.**

## Performance

- **Duration:** 41 min
- **Started:** 2026-04-28T19:50:48Z
- **Completed:** 2026-04-28T20:31:47Z
- **Tasks:** 2
- **Files modified:** 1 (scoring.md created)

## Accomplishments

- Authored skills/deep-plan/references/scoring.md (300 lines, exactly at the upper bound of the 230-300 done criterion).
- All 11 H2 sections present and ordered per the plan: Status, The Three Perspectives, Quadratic Combine, Threshold Map, Token Estimation, Half-Up Rounding, Signal Extraction, Banner Format, Worked Examples, Fixtures, See Also.
- All four SCORE-01..04 formulas documented verbatim (volume, structure, risk perspectives; quadratic combine; token estimation via byte ratios).
- All 16 decisions D-01..D-16 explicitly tagged in the file (D-04 and D-05/D-06/D-07/D-08 added via post-task fix to satisfy success criteria).
- <signals> override schema documented with flat key:value example, merge rule (replace per-key), validation rule (non-negative integer enforcement per threat model T-08-03-01).
- <questions> CONTEXT.md template gap honestly documented with the 0-fallback rule and banner annotation pattern.
- Banner format spec includes the DEEP_PLAN_ROUTING HTML comment trailer (Pitfall 5 mitigation) for stable test assertions independent of prose evolution.
- Three worked examples cross-reference fixtures 01-haiku-small, 04-borderline-equal, 05-advisory-trigger; the Fixtures section enumerates all eight goldens (01-08) from Plan 01.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author formulas, thresholds, byte ratios, rounding (Sections 1-6)** — `1785714` (feat)
2. **Task 2: Append signal extraction, banner format, examples, fixtures, See Also (Sections 7-11)** — `655c249` (feat)
3. **Post-task fix: Tag explicit D-04..D-08 references for success-criteria coverage** — `806ac94` (fix, Rule 1)

## Files Created/Modified

- `skills/deep-plan/references/scoring.md` (NEW, 300 lines) — full scoring contract per D-14 single-source-of-truth.

## Decisions Made

All decisions in this plan were locked upstream in 08-CONTEXT.md (D-01 through D-16). This plan's job was to document them in the reference file. No new decisions were introduced during execution.

The execution-time judgment calls were:
- Consolidated three repetitive must_haves length signals (key_links, artifacts, truths) into a single grouped block to fit the 300-line ceiling without losing content.
- Consolidated three research-derived signals (novel, checkpoints, unknown_deps) into a single grouped block for the same reason.
- Compressed Worked Example 3 banner output by inlining the trailer instead of rendering the full multi-line banner — keeps the DEEP_PLAN_ROUTING token (verify-required) without consuming a 7-line code fence.
- Trimmed byte-ratio table from a 17-row Notes-column variant to a 9-row grouped variant followed by a single explanatory paragraph; preserves all extension mappings and the conservative default.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Plan-internal inconsistency] Task 1 verify expected `<signals>` token but Task 1 action body excludes it**

- **Found during:** Task 1 verify pass
- **Issue:** The plan's Task 1 `<verify>` block includes `grep -q '<signals>'` but the action body explicitly states "After writing this Task 1 portion, the file should have ~170 lines covering Sections 1-6", and Sections 1-6 contain no <signals> content. The <signals> schema lives in Task 2's Section 7. This is a plan-authoring inconsistency.
- **Fix:** Skipped the <signals> automated check at the Task 1 boundary and proceeded to commit. The full plan-level verification block (which includes `<signals>` count >= 2) ran after Task 2 and passed cleanly with 6 occurrences.
- **Files modified:** none (no code change — interpretation deviation only)
- **Verification:** Plan-level verification block passed all 9 checks post-Task-2.
- **Committed in:** N/A — interpretation, not a code change.

**2. [Rule 1 - Bug] Tasks 1+2 produced 323 lines, exceeded the verify upper bound of 320 and the done-criterion of 300**

- **Found during:** Post-Task-2 line count check
- **Issue:** Initial draft of Task 2 sections (Signal Extraction with 8 individual signal blocks, full Banner Format with separate Caveman/trailer subsections, full Worked Example 3 banner output) totaled 385 lines combined with Task 1, then 323 after first compression pass. Verification block requires 230-320; done criterion requires 230-300.
- **Fix:** Three-pass compression — (a) consolidated three must_haves length signals into single grouped block, (b) consolidated three research-derived signals into a single grouped block, (c) inlined the Worked Example 3 banner trailer instead of rendering the full code fence, (d) compressed Caveman exemption + machine-readable trailer into a single subsection, (e) shortened weight-rationale prose for Risk perspective. Final length 300 lines, exactly at the done-criterion ceiling.
- **Files modified:** skills/deep-plan/references/scoring.md
- **Verification:** `wc -l skills/deep-plan/references/scoring.md` reports 300; all required tokens still present (opus_thresholds 3, sonnet_thresholds 2, Number.EPSILON 3, <signals> 6, DEEP_PLAN_ROUTING 3, fixture refs 9).
- **Committed in:** Task 2 commit `655c249` (compressions integrated into the same commit).

**3. [Rule 1 - Coverage gap] Decisions D-04, D-05, D-06, D-07, D-08 were substantively present but not tagged with explicit "D-NN" inline labels**

- **Found during:** Success criteria audit after Task 2
- **Issue:** The plan's success criteria explicitly require all 16 decisions D-01..D-16 addressed. D-04 (>= comparison rule), D-05 (Step 9.5 placement), D-06 (in-memory routing object), D-07 (banner-as-verification), D-08 (always runs including --skip-research) were documented in substance — the >= rule is locked in the Threshold Map section, the in-memory object is explained in the Status block, etc. — but reviewer-audit greps for "D-04" through "D-08" returned zero. Per the plan's success criteria phrasing ("D-02/D-05/D-06/D-07/D-08/D-11 referenced via 'see SKILL.md Step 9.5' or by-name in the Banner Format / Signal Extraction sections"), explicit tagging was the cleanest way to satisfy the audit.
- **Fix:** Added inline tags — "D-04, locked per 08-RESEARCH.md Pitfall 4" in Threshold Map; "(D-05 pipeline placement, D-06 in-memory routing object, D-07 banner-as-verification, D-08 always-runs including --skip-research)" in Status section.
- **Files modified:** skills/deep-plan/references/scoring.md
- **Verification:** All 16 decisions D-01..D-16 now greppable in the file.
- **Committed in:** `806ac94` (separate fix commit for traceability).

---

**Total deviations:** 3 auto-fixed (1 plan-internal inconsistency interpretation, 1 line-budget compression, 1 coverage-gap fix).
**Impact on plan:** All auto-fixes preserve the plan's intent and meet the success criteria. The plan's content was correct; the auto-fixes addressed a verification ambiguity, the compression-budget tension between Task 1's "~170 lines" target and the file's 300-line ceiling, and the implicit assumption that all D-NN tags would be inlined verbatim.

## Issues Encountered

None during execution. The worktree base hard-reset stripped the `.planning/` directory at the start (which is expected behavior — `.planning/` was added in commits beyond the worktree base `5485243`). Read planning context from the main repo at `/users/schylerryan/Desktop/Github/deep-plan-plugin/.planning/` and re-created `.planning/phases/08-scoring-algorithm-foundation/` in the worktree to write this SUMMARY.md.

## Output Required by Plan

Per the plan's `<output>` block, this summary records:

### Exact section headings list (for Plan 04 cross-references)

```
## Status
## The Three Perspectives
## Quadratic Combine (SCORE-02)
## Threshold Map (SCORE-03)
## Token Estimation (SCORE-04)
## Half-Up Rounding (D-10)
## Signal Extraction (D-13, D-15, D-16)
## Banner Format (D-09, D-10, D-12)
## Worked Examples
## Fixtures
## See Also
```

Plan 04's SKILL.md edit can name any of these section titles in its `**Read references/scoring.md**` cross-reference (e.g., "for signal extraction heuristics, see ## Signal Extraction").

### Final byte-ratio table values (for Phase 9 config defaults)

| Extension | Bytes per token |
|-----------|----------------:|
| .md, .txt, .sql | 4.0 |
| .py | 4.5 |
| .go, .css, .yaml, .yml | 3.5 |
| .rs | 3.3 |
| .ts, .tsx | 3.2 |
| .js, .jsx, .sh, .html | 3.0 |
| .json | 2.5 |
| (default / unknown) | 3.0 (conservative high — biases toward over-counting tokens) |

Phase 9 should copy this table verbatim into `model_routing.byte_ratios` config defaults.

### `<signals>` block schema (for Phase 9 wizard validation)

Flat key:value pairs, no YAML wrapper, no nesting. Validation rules:
- Keys allowed: `files_modified`, `tasks`, `key_links`, `artifacts`, `truths`, `novel`, `checkpoints`, `unknown_deps`.
- Values: non-negative integers. Non-numeric or negative values are rejected per signal; banner appends `(<signals> override rejected for {key}: not a non-negative integer)`.
- Merge rule: each present key REPLACES the auto-extracted value; missing keys leave the auto value in place; unknown keys silently ignored (forward-compatible).

Example:
```
<signals>
files_modified: 47
novel: 8
unknown_deps: 2
</signals>
```

### Confirmation: no fixtures from Plan 01 needed renaming or recomputation

This plan only references the eight Plan 01 fixtures by filename in the `## Fixtures` and `## Worked Examples` sections. The fixture filenames `01-haiku-small.md`, `02-quality-bias.md`, `03-opus-large.md`, `04-borderline-equal.md`, `05-advisory-trigger.md`, `06-signals-override.md`, `07-reduced-confidence.md`, `08-borderline-hint.md` are preserved exactly as Plan 01 defined them. No fixture frontmatter was inspected during this execution because Plan 01 fixtures are produced by a parallel wave-1 worktree that has not yet merged. The cross-references in scoring.md point to the canonical fixture filenames the eval harness will load — no recomputation of expected outputs was needed because this plan does not produce expected outputs, only documents the formulas that consume them.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 04 (SKILL.md Step 9.5 wiring):** scoring.md exists at the canonical path with all 11 sections; Plan 04 can write `**Read references/scoring.md**` once at the top of the Step 9.5 body and never inline a formula or threshold value.
- **Phase 9 (config plumbing):** Stable schema published. Phase 9 reads `opus_thresholds`, `sonnet_thresholds`, `byte_ratios` from this file as fallback when `.planning/config.json` lacks the `deep_plan.model_routing` block.
- **Phase 10 (wizard):** `<signals>` schema documented. Wizard validates against the schema in this file.
- **Phase 11 (PLAN.md frontmatter writer):** Banner trailer schema (`<!-- DEEP_PLAN_ROUTING: ... -->`) is the documented format Phase 11 reads to inject `executor_model` + `model_recommendation` into PLAN.md frontmatter.
- **Phase 12 (telemetry):** Same in-memory routing decision object documented in Banner Format is what Phase 12 appends to `_telemetry.decisions[]`.

## Self-Check: PASSED

- FOUND: `skills/deep-plan/references/scoring.md` (300 lines)
- FOUND: `.planning/phases/08-scoring-algorithm-foundation/08-03-SUMMARY.md`
- FOUND: commit `1785714` (Task 1)
- FOUND: commit `655c249` (Task 2)
- FOUND: commit `806ac94` (post-task fix)

---

*Phase: 08-scoring-algorithm-foundation*
*Completed: 2026-04-28*
