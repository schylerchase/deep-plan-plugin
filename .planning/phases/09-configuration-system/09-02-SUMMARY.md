---
phase: 09-configuration-system
plan: 02
subsystem: skill-pipeline
tags: [skill, pipeline, integration, tests, config, json, node, bash, eval-harness]

# Dependency graph
requires:
  - phase: 08-scoring-algorithm-foundation
    provides: "references/scoring.md as the defaults source for bias_thresholds, signal weights, formula coefficient, token budget, and borderline-hint window. SKILL.md Step 9.5 with the hardcoded `balanced` bias default that this plan replaces."
  - phase: 09-configuration-system (Plan 01, parallel wave)
    provides: "references/config.md schema doc — referenced by name in Step 1's `**Read references/config.md**` directive. Plan 02 reads its sections (## Worked Examples, ## Resolved-Config Object Shape) by name and trusts the doc for the deep-merge / lenient-validation algorithm."
provides:
  - "Skill-time config resolution wired into SKILL.md Step 1 caveman_setup as a sub-section (Option A — no new top-level <step>)"
  - "tests/eval-config-resolution.sh — 4 fixture cases (absent/partial/malformed/full) + determinism check, exits 0 on all-pass, no npm dependency"
  - "Step 9.5 bias plumb-through: `Default bias to balanced until Phase 9 plumbs ...` replaced with `Read resolved_config.bias from the resolved-config object set in Step 1`. The Phase 8 promise on scoring.md line 82 is now fulfilled end-to-end."
  - "resolveConfig helper inline in the eval harness, sourced from scoring.md defaults, with `_source` rule: defaults / config / merged tracked per-leaf"
affects: [10-setup-wizard, 11-plan-frontmatter, 12-doctor]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Eval-harness inline-fixture pattern — fixtures embedded as bash variables (no skills/deep-plan/fixtures/config/ directory), tested via stdout-pipe parsing of a node -e block"
    - "Bash one-liner config-read pattern matching Step 2 line 118 `text_mode` precedent — single shell line, single config field group, try/catch fallback"
    - "_source 3-state rule: 'defaults' = no leaves from input; 'config' = ALL 22 leaves from input + zero notices (full-custom); 'merged' = some leaves from input OR any notice (partial / fallback)"

key-files:
  created:
    - tests/eval-config-resolution.sh
  modified:
    - skills/deep-plan/SKILL.md

key-decisions:
  - "Total leaves count = 22 (5 top-level + 1 formula + 8 signals + 6 bias_thresholds + 2 token thresholds). This count drives the `_source: config` vs `_source: merged` rule — interpreted from CONTEXT.md D-12 as 'config when full-custom, merged when partial-override'."
  - "Step 9.5 line phrasing tightened from plan's locked text — `Read \\`bias\\` from the \\`resolved_config\\` object` (which broke the verify regex `resolved_config\\.bias`) → `Read \\`resolved_config.bias\\` from the resolved-config object`. Same semantics, regex-compatible token form. Tracked as a Rule 1 deviation."
  - "Comment in eval-config-resolution.sh originally listed forbidden libs as `ajv/joi/zod/yup`; the plan's verify-grep `\\b(ajv|joi|zod|yup)\\b` matched the comment itself. Reworded to `JSON-schema validators (Plan 02 constraint)` so the verify-grep correctly reports zero matches."

patterns-established:
  - "Lazy-load reference doc + inline bash one-liner — SKILL.md Step 1 reads .planning/config.json `deep_plan.model_routing` via a bash one-liner, then defers all deep-merge / lenient-validation logic to references/config.md. Mirrors the Phase 8 scoring.md split: SKILL.md announces, reference doc implements."
  - "DEFAULTS-as-known-drift-surface pattern — eval harness embeds defaults as a JS constant sourced from scoring.md and notes the drift hazard in a comment (per 09-02-PLAN.md <known_drift_surfaces>). v1.2 cleanup target: parse scoring.md programmatically."

requirements-completed: [CONFIG-01, CONFIG-02, CONFIG-03]

# Metrics
duration: 26min
completed: 2026-04-29
---

# Phase 9 Plan 02: Wire Config Resolution Summary

**SKILL.md Step 1 reads `.planning/config.json` `deep_plan.model_routing` via inline bash + node JSON.parse, holds the resolved object as `resolved_config`, and Step 9.5 reads `resolved_config.bias` instead of the hardcoded `balanced` default — bias plumb-through is now end-to-end visible. tests/eval-config-resolution.sh ships 4 fixtures (absent / partial / malformed / full) proving the resolution layer.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-04-29T14:16:12Z
- **Completed:** 2026-04-29T14:42:13Z
- **Tasks:** 2 (both committed atomically)
- **Files modified:** 2 (1 new, 1 modified)
- **SKILL.md line count delta:** 591 → 620 (+29 lines)

## Accomplishments

- Step 1 caveman_setup gains a `### Config resolution` sub-section per PATTERNS.md Option A — single step retains caveman + config setup responsibilities, no `[N/total]` renumbering, Step 2 task-counter math unchanged.
- Inserted bash one-liner reads `.planning/config.json` `deep_plan.model_routing` block with try/catch wrapper; failures (missing file, malformed JSON, key absent) all collapse to `'{}'` so the skill never errors on a missing or broken config.
- House-style `**Read references/config.md** for: ...` directive emitted, matching the existing 4 instances (intel-sources, ce-prompts, plan-template, scoring) at SKILL.md lines 269/319/395/408.
- `resolved_config` held in skill scope; downstream consumers documented inline (Step 9.5 bias + weight_overrides + context_thresholds; Phase 11 frontmatter; Phase 12 doctor drift).
- Step 9.5 line 453 now reads `resolved_config.bias` — the bias plumb-through promised by scoring.md line 82 ("Bias is read from `.planning/config.json` `deep_plan.model_routing.bias` field at Phase 9, not Phase 8") is fulfilled end-to-end.
- New eval harness `tests/eval-config-resolution.sh` covers 4 fixture cases + a 5th determinism assertion (re-run all fixtures, byte-equal output required). Exits 0 on all-pass, exits 1 on any failure or determinism breach.
- All 4 eval suites pass post-edit: eval-scoring.sh (8/8), eval-caveman-rule.sh (6/6), eval-trailer-smoke.sh (1/1), eval-config-resolution.sh (4/4).

## Task Commits

Each task committed atomically:

1. **Task 1: Author tests/eval-config-resolution.sh with 4 fixture cases (TDD)** — `16d1b9c` (test)
2. **Task 2: Insert config-read sub-section into SKILL.md Step 1 + replace Step 9.5 hardcoded balanced default** — `1df6f4b` (feat)

_Note: Plan declares both tasks `tdd="true"`. Task 1 is itself a test harness (the eval-config-resolution.sh is the test) — no separate RED commit because the harness IS the test. Task 2 used the new eval suite as the GREEN gate._

## Files Created/Modified

- **`tests/eval-config-resolution.sh` (NEW, 401 lines, executable):** Golden-fixture eval for the config resolution layer. Embeds 4 fixtures inline as bash variables, invokes a `resolve_config` helper (inline node `-e` block) per fixture, parses the pipe-separated stdout, and asserts each expected field. Re-runs all 4 fixtures for the determinism check. No npm dependency; native node + JSON.parse only.
- **`skills/deep-plan/SKILL.md` (MODIFIED, +29 lines):**
  - Step 1 caveman_setup gained `### Config resolution` sub-section before the trailing `Enforced at:` line (lines 82-110).
  - Step 9.5 line ~453 hardcoded `Default bias to balanced until Phase 9 plumbs ...` replaced with `Read resolved_config.bias from the resolved-config object set in Step 1 (per references/config.md ## Resolved-Config Object Shape) — defaults to balanced when config is absent (_source: "defaults")`.

## Decisions Made

- **`_source` 3-state interpretation locked.** CONTEXT.md D-12 declares `_source: "config" | "defaults" | "merged"` but does not formally specify the rule. Fixture (b) (partial override, zero notices) requires `merged` per the plan's behavior block — so the lockable rule is: `defaults` when no leaves came from input, `config` only when ALL 22 leaves came from input AND zero notices were emitted, `merged` otherwise. The `totalLeaves` counter in resolveConfig captures this; comments in the helper document it.
- **Inline fixtures over filesystem fixtures.** Plan permitted either option; chose inline bash variables. Pro: harness is fully self-contained; no `skills/deep-plan/fixtures/config/` directory to seed. Con: harder to add a 5th fixture without editing the harness — accepted because the schema surface is small (8-10 leaves).
- **Comment rewording.** The original comment header listed forbidden libs as `ajv/joi/zod/yup`; the verify-grep `\b(ajv|joi|zod|yup)\b` matched the comment itself. Reworded to `JSON-schema validators (Plan 02 constraint)` so the verify-grep reports zero matches without losing the intent. Tracked as Rule 1 deviation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] _source rule corrected to distinguish full-config from partial-merge**
- **Found during:** Task 1 (first eval run after writing the harness)
- **Issue:** Initial resolveConfig returned `_source: "config"` for fixture (b) (partial override, zero notices). Plan behavior spec line 244 requires `_source: "merged"` for partial overrides. The original logic only checked `notices.length`; the corrected logic requires `leavesFromInput === totalLeaves` for `config`.
- **Fix:** Added `totalLeaves` counter incremented on every `resolveLeaf` call; updated `_source` computation to require ALL leaves from input AND zero notices for `config`.
- **Files modified:** tests/eval-config-resolution.sh
- **Verification:** Fixture (b) now correctly resolves `_source: merged` while fixture (d) (all 22 leaves provided) correctly resolves `_source: config`. All 4 fixtures pass.
- **Committed in:** 16d1b9c (Task 1 commit; the fix landed in the same commit as the harness because the bug was a same-task internal error)

**2. [Rule 1 - Bug] Verify-grep collision in eval harness comment**
- **Found during:** Task 1 verify block
- **Issue:** The plan's verify check `test "$(grep -E '\b(ajv|joi|zod|yup)\b' tests/eval-config-resolution.sh | wc -l)" -eq 0` failed because the file's own header comment listed `ajv/joi/zod/yup` as the forbidden libs. Comment text triggered the negative grep.
- **Fix:** Reworded the dependency comment to `No JSON-schema validators (Plan 02 constraint)` — same intent, no literal lib names that match the negative grep.
- **Files modified:** tests/eval-config-resolution.sh
- **Verification:** Plan verify block exits 0; ALL VERIFY CHECKS PASS.
- **Committed in:** 16d1b9c (Task 1 commit)

**3. [Rule 1 - Bug] Step 9.5 phrasing reworded for verify-regex compatibility**
- **Found during:** Task 2 verify block
- **Issue:** Plan's locked text on line 545 reads `Read \`bias\` from the \`resolved_config\` object` — `bias` and `resolved_config` are on opposite sides of the word `object`. The plan's own verify-regex `awk '/<step name="scoring">/,/<\/step>/' skills/deep-plan/SKILL.md | grep -E 'resolved_config\.bias|resolved.config.*bias'` requires either the literal token `resolved_config.bias` or `bias` AFTER `resolved_config` on the same line. The plan-locked phrasing satisfies neither — `bias` only appears BEFORE `resolved_config` on that line.
- **Fix:** Reworded to `Read \`resolved_config.bias\` from the resolved-config object set in Step 1 (per references/config.md ## Resolved-Config Object Shape) — defaults to balanced when config is absent (_source: "defaults")`. The token `resolved_config.bias` is now a literal access expression on a single line; semantics unchanged; verify regex passes.
- **Files modified:** skills/deep-plan/SKILL.md
- **Verification:** Plan verify block T5a exits 0; all 17 verify checks pass.
- **Committed in:** 1df6f4b (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All three fixes were essential to make the plan's own verify block exit 0. No scope creep. No new files beyond what the plan specified. The first fix corrected a logic error in the harness; the second and third were collisions between plan-specified text and plan-specified verify regexes — preserved semantics, adjusted text.

## Known Limitations / Future Cleanup

Per 09-02-PLAN.md `<known_drift_surfaces>`, the eval harness embeds DEFAULTS as a hardcoded constant sourced from `skills/deep-plan/references/scoring.md`:

- **Hazard:** if Phase 8's scoring.md changes a default value (e.g., `volume_coefficient` from 0.3 to 0.4), the harness silently passes against stale data. The eval suite would not catch the inconsistency between the scoring contract (scoring.md) and the config-resolution contract (eval-config-resolution.sh DEFAULTS).
- **v1.1 disposition:** accepted. The contract surface is small (8-10 numeric defaults), changes during v1.1 milestone are unlikely once Phase 8 shipped, and an inconsistent value would surface during Phase 12 doctor's drift detection.
- **v1.2 cleanup candidate:** parse `references/scoring.md` once at harness startup, generate DEFAULTS programmatically, and cross-check against the embedded snapshot. This eliminates the silent-staleness path. Track as a v1.2 backlog item.
- **Phase 12 doctor responsibility:** the doctor's drift detection should compare the embedded DEFAULTS in eval-config-resolution.sh against scoring.md and emit a warning if they diverge.

## Issues Encountered

- **Worktree did not contain phase 09 planning files.** The worktree was created from main at commit `b7e805d`, but `.planning/` is gitignored — so the phase 09 planning files (`09-02-PLAN.md`, `09-CONTEXT.md`, `09-PATTERNS.md`, etc.) lived only in the main repo's working tree, not in the worktree. Resolved by copying the files from `/Users/schylerryan/Desktop/Github/deep-plan-plugin/.planning/phases/09-configuration-system/` into the worktree's `.planning/` directory before reading. This is a known limitation of the gitignored-planning + parallel-worktree pattern — the orchestrator should either un-ignore `.planning/` or copy artifacts into worktrees as part of agent spawn.
- **RTK hook collision with `git diff --name-only` in subshell.** The `$()` form `$(git diff --name-only HEAD -- skills/deep-plan/references/caveman-rule.md)` triggered RTK's command rewriter, which prepended `rtk` and produced `rtk: not a git command`. Bypassed by using `rtk proxy git diff ...` for the verify check. This is an RTK rewrite pattern issue, not a plan issue.

## Threat Flags

No new security-relevant surface introduced beyond the threat model in 09-02-PLAN.md. The bash one-liner uses `try/catch` per T-09-07 mitigation; the resolveConfig helper does per-field type validation per T-09-08 mitigation. No new caveman v2 signal added per the plan's hard rule (T-09-12 mitigation rides on the existing routing-banner exemption).

## Self-Check: PASSED

Verified:
- `tests/eval-config-resolution.sh` exists and is executable: FOUND (401 lines, exit code 0 on run)
- `skills/deep-plan/SKILL.md` modified — line count 620: FOUND
- Commit `16d1b9c` (test): FOUND in `git log --all`
- Commit `1df6f4b` (feat): FOUND in `git log --all`
- All 4 eval suites pass: eval-scoring.sh 8/8, eval-caveman-rule.sh 6/6, eval-trailer-smoke.sh 1/1, eval-config-resolution.sh 4/4
- `skills/deep-plan/references/caveman-rule.md` unchanged: VERIFIED via empty `git diff`
- Step 2 total-task counter unchanged: VERIFIED via `grep 'Total tasks = 11'` PASS
- All 17 task-2 verify checks pass: VERIFIED piecemeal

## User Setup Required

None — no external service configuration required. The new bash one-liner reads `.planning/config.json` if present and falls back to defaults silently when absent. Phase 10 will ship the wizard that writes the config schema; until then, the resolved-config object is always `_source: defaults`.

## Forward Pointer for Phase 10

Phase 10 wizard writes the schema this plan reads. The wizard's edit menu (mode/pin/bias/profile-sync/weights/reset) maps directly to the 6 resolved-config fields documented in references/config.md:
- `mode` → user picks auto / confirm / silent (default: confirm per CONTEXT.md D-04)
- `pin` → user picks null / opus / sonnet / haiku (default: null per D-01)
- `bias` → user picks quality / balanced / budget (default: balanced per scoring.md)
- `gsd_profile_at_setup` → wizard captures via `gsd-sdk query config-get model_profile` (default: null in Phase 9; populated in Phase 10)
- `weight_overrides` → power-user only; wizard exposes a "reset to defaults" button per D-08
- `context_thresholds` → power-user only; same reset behavior

Phase 12 doctor reads the same schema for strict validation (D-10 split — skill-time lenient, doctor-time strict).

## Next Phase Readiness

- Phase 10 (setup wizard) is unblocked: the schema this plan reads is now stable, the resolved-config object shape is documented in references/config.md (Plan 01) and consumed by SKILL.md Step 1 (this plan).
- Phase 11 (PLAN.md frontmatter writer) can now read `resolved_config.gsd_profile_at_setup` from in-memory state — the field is held in scope per D-13.
- Phase 12 (doctor) can now run drift detection against `resolved_config.gsd_profile_at_setup` vs current `gsd-sdk query config-get model_profile`.
- No blockers. Plan 01 (references/config.md schema doc) lands in parallel; this plan references it by name and trusts its sections — once Plan 01 merges, the `**Read references/config.md**` directive in SKILL.md Step 1 has a target file.

---
*Phase: 09-configuration-system*
*Completed: 2026-04-29*
