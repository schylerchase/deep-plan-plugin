---
name: deep-plan
description: "This skill should be used when the user asks to 'deep plan', 'plan a phase deeply', 'run deep-plan', or wants CE-quality implementation planning after /gsd-discuss-phase. Bridges GSD context with code-grounded research, implementation units, test scenarios, and optional feasibility review. Produces GSD-compatible PLAN.md files."
argument-hint: "[phase] [--review] [--skip-research] [--text]"
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
  - TodoWrite
  - TaskCreate
  - TaskUpdate
  - AskUserQuestion
  - Skill
  - Task
---

# Deep Plan: GSD Context + CE Implementation Planning

<purpose>
Bridge GSD's strategic context (CONTEXT.md, RESEARCH.md, ROADMAP.md) with CE's code-grounded research and implementation-unit planning. Produces a GSD-compatible PLAN.md with CE-quality detail: implementation units with file paths, test scenarios, risk analysis, and optional feasibility validation.

Use this instead of `/gsd-plan-phase` when you want deeper code analysis before planning.
</purpose>

<when_to_use>
- After `/gsd-discuss-phase` has produced a CONTEXT.md for the target phase
- When the phase involves significant code changes (extraction, refactoring, new features)
- When you want CE-style implementation units with test scenarios
- When you want optional feasibility review to catch deployment/build issues
</when_to_use>

<compatibility>
Chat output follows the user's caveman level; `.md` artifacts always use full prose.

Step 1 detects caveman and builds an override map for three v2 signals forcing full prose (see `references/caveman-rule.md`).

Caveman: optional plugin by Julius Brussee (MIT), installed separately.
</compatibility>

<process>

<progress_protocol>
## Progress Reporting Protocol

Deep-plan must be visually distinguishable from GSD and CE throughout execution. Follow these patterns at every step.

**Opening banner** — Display after phase is confirmed (end of Step 2). Open-bordered style matches GSD (no right border to misalign with long phase names):

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Deep Plan — Phase {N}: {phase_name}
     GSD context → CE research → Implementation plan
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Step headers** — Display at the start of every step:

    ── deep-plan [{current}/{total}] {Step Name} ──────────

Total = 12 with `--review`, 11 without (feasibility review skipped). Step 9.5 (routing decision) is counted as one task; its announce header reads `[9.5/{total}]`.

**Detail lines** — 1-2 lines after each header showing what was found/done. Use ✓/✗ for availability.

**Task tracking** — After phase confirmation, use TaskCreate to create all step tasks upfront (prefixed "Deep Plan:"). Mark each `in_progress` when starting, `completed` when done.

**Subagent attribution** — Before CE agent calls, state what deep-plan pre-fed and what CE will focus on. After return, summarize new findings count.

See `references/progress-templates.md` for full output examples per step.
</progress_protocol>

<step name="caveman_setup">
## Step 1: Caveman Setup

Detect caveman deterministically — do not guess from context:

```bash
CAVEMAN_INSTALLED=$(claude plugin list 2>/dev/null | grep -q "caveman@caveman" && echo yes || echo no)
```

If `CAVEMAN_INSTALLED=yes`, read `references/caveman-rule.md` and build an override map for four v2 signals requiring full prose: HIGH feasibility findings, AskUserQuestion blocks, mid-flight scope pivots, and routing-decision banner output (Step 9.5). If `no`, skip silently — no override map, no further caveman references this run.

Enforced at: questions (Steps 2, 7), pivots (Step 8), routing decision (Step 9.5), feasibility (Step 11).
</step>

<step name="parse_args">
## Step 2: Parse Arguments and Auto-Detect Phase

**Before anything else in this step, check prerequisites:**

Run three checks via Bash (run all three, collect failures, report together):
1. GSD installed: `test -f "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs"`
2. CE installed: `claude plugin list 2>&1 | grep -q compound-engineering`
3. `.planning/` exists: `test -d .planning/`

If any failed, print every failure with its fix command, then stop.

Error format (only print lines for missing prerequisites):
```
deep-plan requires GSD. Install: see GSD Discord #getting-started
deep-plan requires Compound Engineering. Install: claude plugin marketplace add EveryInc/compound-engineering-plugin && claude plugin install compound-engineering
No .planning/ directory found. Run /gsd-new-project to initialize.
```

If all pass, continue silently.

Extract from the invocation:
- `phase` — the phase number (e.g., "18", "11.1")
- `--review` flag — run feasibility review after planning
- `--skip-research` flag — skip CE repo-research-analyst
- `--text` flag — use plain-text numbered lists instead of AskUserQuestion

**Text mode detection (runs once, applies to all prompts):**

Text mode is active if either condition is true:
- `--text` flag was passed in arguments
- `workflow.text_mode` is `true` in GSD config:
  ```bash
  TEXT_MODE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get workflow.text_mode 2>/dev/null)
  ```

Store result as `text_mode` (boolean). When active, all user prompts in this session use plain-text numbered lists instead of AskUserQuestion.

**If no phase argument provided, auto-detect:**

```bash
ROADMAP_STATE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze 2>/dev/null)
```

Find the best candidate phase by priority:
1. **Has CONTEXT.md but no PLAN.md** — ready for deep-plan now
2. **No CONTEXT.md, no PLAN.md** — needs discuss-phase first

If no candidate matches either priority, all phases already have plans:
```
All phases in roadmap have plans. Nothing to plan. Run /gsd-add-phase to add new work.
```
Stop execution.

**Detection priority — why this order:**
1. `Has CONTEXT.md but no PLAN.md` wins because the user explicitly ran discuss-phase to lock decisions; the next step is planning, and that's exactly what deep-plan does.
2. `No CONTEXT.md, no PLAN.md` is the fallback for phases that need discuss-phase first; deep-plan suggests running it rather than planning blind.
3. Phases with both CONTEXT.md and PLAN.md are skipped — they're already planned. Use `--review` or `/gsd-execute-phase` to proceed.
4. The confirmation prompt below always runs after auto-detect; the user can override the choice with "Different phase".

**Scope-mismatch check (runs when phase was auto-detected):**

Compute `task_hint`: any free-text args not consumed by phase number or known flags (`--review`, `--skip-research`, `--text`). Empty string if none.

Fire the scope-check if the phase was auto-detected AND (`task_hint` is non-empty OR the detected phase has no CONTEXT.md). Skip it otherwise (explicit phase arg, or happy path with CONTEXT.md and no hint) — fall straight through to the existing three-option prompt below.

**If text_mode is active**, present as a plain-text numbered list:
```
Detected Phase {N}: {phase_name}. Your request mentions: "{task_hint}"
How should this be scoped?
1. Plan Phase {N} as detected
2. Expand Phase {N} scope to include this work (runs /gsd-discuss-phase)
3. Insert a decimal hotfix phase like {N}.1 (runs /gsd-add-phase)
4. Route to /gsd-quick (tactical fix, no phase needed)
```
Type a number to choose. Parse response (number or free text). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion with four options mirroring the list above.

Routing:
- Option 1 → fall through to the existing three-option confirmation below
- Option 2 → print `Run: /gsd-discuss-phase {N} "{task_hint}"` and stop (no banner, no TaskCreate, no state writes)
- Option 3 → print `Run: /gsd-add-phase` (decimal hotfix flow) and stop
- Option 4 → print `Run: /gsd-quick "{task_hint}"` and stop

**If text_mode is active**, present as a plain-text numbered list instead of AskUserQuestion:
```
1. Yes, plan Phase {N}
2. Different phase
3. Run /gsd-discuss-phase {N} first
```
Type a number to choose:

Parse the user's response (number or free text describing their choice). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion with options:
- "Yes, plan Phase {N}" — proceed with detected phase
- "Different phase" — ask which one
- If no CONTEXT.md: "Run /gsd-discuss-phase {N} first" — launch discuss-phase, then return

**After phase confirmed:**
1. Display the opening banner (see progress protocol)
2. TaskCreate one task per remaining step (prefix "Deep Plan:"), e.g., "Deep Plan: Load GSD context"
3. Total tasks = 11 (steps 2-11 + step 9.5) without `--review`, 12 (steps 2-12 + step 9.5) with `--review`
</step>

<step name="load_gsd_context">
## Step 3: Load GSD Phase Context

**Announce:** `── deep-plan [3/{total}] Loading GSD context ──`
After reading, detail: `CONTEXT.md {✓/✗} | RESEARCH.md {✓/✗} | ROADMAP.md {✓/✗}`

```bash
INIT=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" init plan-phase "$PHASE" 2>/dev/null)
```

Parse the JSON output for: `phase_dir`, `padded_phase`, `phase_slug`, `has_context`, `has_research`, `context_path`, `research_path`.

**Required:** Read CONTEXT.md from the phase directory.
If CONTEXT.md does not exist:
```
Phase {N} has no CONTEXT.md. Run `/gsd-discuss-phase {N}` first to gather 
implementation decisions, then re-run `/deep-plan {N}`.
```
Stop.

**Optional reads (if they exist):**
- RESEARCH.md from the phase directory
- The phase section from `.planning/ROADMAP.md` (goals, requirements, success criteria)
- `.planning/REQUIREMENTS.md` for requirement definitions

**Check for existing plans:**
If PLAN.md files already exist for this phase:

**If text_mode is active**, present as a plain-text numbered list instead of AskUserQuestion:
```
1. Add another plan (increment plan number)
2. Replan from scratch (overwrite)
3. Cancel
```
Type a number to choose:

Parse the user's response (number or free text describing their choice). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion with options:
- "Add another plan" (increment plan number)
- "Replan from scratch" (overwrite)
- "Cancel"
</step>

<step name="already_done_check">
## Step 3.5: Already-Done Check

**Announce:** `── deep-plan [3.5/{total}] Checking if work is already done ──`

This step skips planning when the phase's success criteria are already satisfied by existing code (LIFE-02). Saves users from re-planning work that was implemented ad-hoc via /quick or other entry points.

**Skip conditions:**
- If `has_plans=true` from Step 2's init data → skip silently (already planned).
- If criterion list from `roadmap get-phase` is empty → skip silently (nothing to check against).

**Evidence gathering (per criterion):**
1. Extract searchable tokens from each criterion text (file paths, function names, behavior keywords).
2. Run lightweight checks: grep for tokens, Read referenced files, ls expected paths.
3. Tag each criterion: `met` (all evidence found), `partial` (some evidence), `not met` (no evidence).

**Routing:**
- **All criteria `met`:** present summary table. Ask via AskUserQuestion (or numbered list in text_mode):
  - "All success criteria for Phase {N} appear satisfied by existing code. Mark phase complete and exit?"
  - Options: `Yes, mark complete` / `No, plan anyway (work may be redundant)` / `Show evidence first`
  - On `Yes`: Edit `.planning/ROADMAP.md` to flip `[ ]` → `[x]` for the phase line. Log: `[step 3.5] Phase {N} marked complete based on existing code evidence`. Exit deep-plan with handoff message.
  - On `No`: continue to Step 4.
  - On `Show evidence first`: print the evidence table, then re-prompt with first two options only.
- **Any `partial` or `not met`:** log `[step 3.5] {met}/{total} criteria show evidence — continuing to plan` and proceed to Step 4. Do not prompt.

**Caveman override:** the AskUserQuestion in this step is a v2 signal — output the summary table and prompt in full prose regardless of caveman level. (Step 1 override map.)
</step>

<step name="gather_intel">
## Step 4: Gather GSD Intelligence

**Announce:** `── deep-plan [4/{total}] Gathering codebase intelligence ──`
After gathering, detail: `Intel: {found_list} ({N}/5 files, {fresh/stale/none}) | Research: {found_list} ({warm/cold} start)`

**Read `references/intel-sources.md`** for the full source list (intel/ files, research/ files, scope boundaries), staleness rules, the no-analysis fallback prompt, and the `gsd_knowledge` composition spec.

Check each source in order. Read what exists, skip what doesn't. If neither `.planning/intel/` nor `.planning/research/` exist, prompt the user per the reference (Continue anyway / Run /gsd-scan first).

After gathering, build the `gsd_knowledge` block per the schema in the reference. This block feeds Step 6 (CE warm-start prompt).
</step>

<step name="build_planning_brief">
## Step 5: Build Planning Brief

**Announce:** `── deep-plan [5/{total}] Building planning brief ──`
After composing, detail: `Locked decisions: {N} | Open questions: {N} | Seed files: {N}`

Transform GSD artifacts into a structured planning brief. This brief serves two purposes: (1) it becomes context for CE research, and (2) it frames the implementation units.

From CONTEXT.md:
- `<domain>` section → **Problem frame** and **scope boundaries**
- `<decisions>` locked items → **Resolved questions** (carry forward as-is)
- `<decisions>` "Claude's Discretion" items → **Open questions** for research to inform
- `<code_context>` → **Seed files** for repo-research-analyst
- `<specifics>` → **Constraints and examples**
- `<deferred>` → **Explicit non-goals** (scope boundaries)

From phase RESEARCH.md (if exists):
- Technical approach → **Pre-existing research** (do not re-research these topics)
- Risk analysis → **Known risks** to carry into the plan

From ROADMAP.md phase section:
- Phase goal → **Objective**
- Success criteria → **Requirements trace**
- Dependencies → **Prerequisites**

Compose a 2-3 paragraph planning brief summarizing:
1. What the phase delivers and why
2. User decisions that are locked
3. Areas where code research is needed (subtract what GSD intel already covers)
4. Files and patterns already identified
</step>

<step name="ce_research">
## Step 6: CE Research (unless --skip-research)

**Announce:** `── deep-plan [6/{total}] CE deep research ({warm/cold} start) ──`
- Warm: `Pre-fed: {summary} → CE focusing on: integration points, gaps, risks`
- Cold: `No GSD intel to pre-feed → CE exploring from scratch`

If `--skip-research` was passed, skip to Step 7.

**Decide warm vs cold:** if `gsd_knowledge` block from Step 4 is non-empty → warm-start. Otherwise → cold-start.

**Read `references/ce-prompts.md`** for the full Task spawn body (warm + cold variants), confidence-tag rules, merge rules, and post-CE announce templates. Substitute `{N}`, `{phase_name}`, `{planning_brief}`, `{gsd_knowledge block from Step 3}`, and `{files from code_context}` from in-memory state, then spawn the agent.

**After CE returns:** apply the confidence tags + merge rules from the reference. Display the post-CE announce line per warm/cold variant.
</step>

<step name="resolve_questions">
## Step 7: Resolve Planning Questions

**Announce:** `── deep-plan [7/{total}] Resolving planning questions ──`
After resolving, detail: `Auto-resolved: {N} | Asking user: {N} | Deferred: {N}`

Build a question list from:
1. "Claude's Discretion" items from CONTEXT.md that research can now inform
2. Gaps discovered by repo-research-analyst
3. Technical decisions needed for implementation units

For each question:
- If research provides a clear answer → resolve silently
- If the answer materially affects scope, architecture, or risk → ask the user (see below)
- If the answer depends on runtime behavior → defer to implementation

**If text_mode is active**, present each question as a plain-text numbered list instead of AskUserQuestion. For fixed-option questions:
```
{Question text}
1. {option 1}
2. {option 2}
...
```
Type a number to choose:

For open-ended questions, prompt for free text input. Parse the user's response (number or free text describing their choice). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion for each question with the appropriate options.

Keep user questions focused and minimal (1-2 max). Don't ask about things the user already decided in CONTEXT.md.

*Caveman override: If override map active (Step 1), output question blocks in full prose.*
</step>

<step name="structure_units">
## Step 8: Structure Implementation Units

**Announce:** `── deep-plan [8/{total}] Structuring implementation units ──`
After structuring, detail: `Units: {N} | Test scenarios: {N} | Must-haves: {truths}/{artifacts}/{links}`

Break the phase work into implementation units. Each unit represents one meaningful atomic change.

For each unit, define:

- **Name** — clear, action-oriented
- **Goal** — what this unit accomplishes
- **Requirements** — which ROADMAP requirements or success criteria it advances
- **Dependencies** — what must exist first (other units or external)
- **Files** — repo-relative paths to create, modify, or test
- **Approach** — key decisions, data flow, integration notes (not code). Carry forward CE confidence tags on any findings referenced (e.g., "integration via event bus [HIGH]" or "likely uses shared state [MEDIUM]")
- **Patterns to follow** — existing code to mirror (from research findings, with confidence tag)
- **Test scenarios** — specific test cases by category:
  - Happy path: core functionality with expected inputs/outputs
  - Edge cases: boundary values, empty inputs, concurrent access
  - Error paths: invalid input, failures, timeouts
  - Integration: cross-layer scenarios mocks won't prove
- **Verification** — how to know the unit is complete (outcomes, not commands)

**Generate GSD must_haves from test scenarios:**
- `truths` → one truth per critical test scenario ("User can X", "Y produces Z")
- `artifacts` → one artifact per created/modified file with a searchable `contains` token
- `key_links` → traceability from source to destination with search patterns

**Ordering:** Dependencies first. Pure functions/constants before stateful units (hooks, classes, services) before composition layers (components, handlers, modules). Infrastructure before features.

*Caveman override: If scope pivot detected (Step 1 override map), output pivot reasoning in full prose.*
</step>

<step name="write_plan">
## Step 9: Write GSD PLAN.md

**Read `references/plan-template.md`** for: numeric plan-numbering rules, the file-path convention, substitution-variable table, and the full PLAN.md template body (frontmatter + objective + execution_context + context + tasks + threat_model + verification + success_criteria + output).

Substitute live values per the variable table in the reference. Write to `.planning/phases/{padded_phase}-{slug}/{padded_phase}-{MM}-PLAN.md`.

Path-portability rule: tilde paths only (`@~/...`); never `@$HOME/...` (PORT-01).

**Announce:** `── deep-plan [9/{total}] Plan written ──`
Detail: `.planning/phases/{phase_dir}/{padded_phase}-{MM}-PLAN.md` — `Units: {N} | Test scenarios: {N} | Must-haves: {truths} truths, {artifacts} artifacts, {links} links`
</step>

<step name="scoring">
## Step 9.5: Model Routing Decision

**Read `references/scoring.md`** for: signal extraction heuristics, the three perspective formulas, the byte-ratio table, the threshold map, the half-up rounding helper with Number.EPSILON correction, the banner format with machine-readable trailer, and the worked-examples / golden-fixture index.

This step always runs, including when `--skip-research` was passed. Missing CE-derived signals fall back to 0 per D-08 — `novel` and `unknown_deps` default to 0 when feasibility/research output is absent, and the banner appends `(reduced confidence: --skip-research used)`.

**Extract the 8 signals from in-memory pipeline state:**

1. Read the `units` array produced by Step 8 and the `must_haves` object produced by Step 8.
2. For each signal in `references/scoring.md` ## Signal Extraction:
   - Compute the auto value per the heuristic listed for that signal.
   - For `files_modified`, deduplicate paths across all `unit.files` arrays (D-15) — same file referenced by 3 units counts once.
   - For `checkpoints`, parse CONTEXT.md for the `<questions>` block. If absent, default to 0 and remember to annotate the banner.
3. Read CONTEXT.md once for the optional `<signals>` override block (D-13). Parse with the awk-based flat-key:value extractor pattern from `tests/eval-caveman-rule.sh`. Validate each value is a non-negative integer; reject non-numeric or negative values per signal and remember to annotate the banner.
4. Merge: each key in `<signals>` REPLACES the auto value; missing keys leave the auto value in place.

**Compute the three perspectives and the combined score per the formulas in `references/scoring.md`.** Do NOT inline the formulas here — call them out by name (volume, structure, risk, combined) and trust the reference doc for the math.

**Apply the threshold map from `references/scoring.md` to the rounded combined score** to determine the recommended model. Use `>=` comparison (locked rule from Pitfall 4 mitigation). Default bias to `balanced` until Phase 9 plumbs the `deep_plan.model_routing.bias` config field.

**Estimate input tokens** by walking the deduplicated `files_modified` set, calling `wc -c` (or equivalent) on each path, and dividing by the per-extension byte ratio from the table in `references/scoring.md`. Sum the per-file estimates. The default ratio for unknown extensions is 3.0 — conservative high, biases toward triggering the advisory rather than missing it.

**Determine the phase-split advisory:** strict AND gate (D-01) — `input_tokens > 180000 AND combined >= opus_thresholds[bias]`. Determine the borderline hint (D-12): if combined is within ±10% of either threshold, prepare the appropriate bias-bump suggestion.

**Build the in-memory routing-decision object** (D-06) with snake_case field names per the convention in `references/scoring.md`:

- `volume_score`, `structure_score`, `risk_score`, `combined_score` — rounded to 1 decimal via the half-up helper
- `recommended_model` — one of `opus`, `sonnet`, `haiku`
- `bias` — the active bias used for threshold mapping
- `threshold` — the threshold value compared against (e.g., 12 for opus/balanced)
- `input_tokens_estimate` — integer
- `advisory` — boolean
- `borderline_hint` — string or null
- `reduced_confidence` — boolean (true when `--skip-research` was passed)
- `signals` — the merged signal values (post-override)
- `signal_overrides_rejected` — array of any `<signals>` keys whose values were rejected for invalidity

**Hold this object in scope.** Do NOT write it to a sidecar file (D-06). Phase 11 will read it from in-memory state to populate PLAN.md frontmatter; Phase 8 emits it only via the banner below.

**Emit the banner** using the format specified in `references/scoring.md` ## Banner Format. The banner has 3 required lines plus optional advisory / borderline / reduced-confidence lines plus the machine-readable trailer comment. The full banner is reproduced below for verification (per success criterion #5 — three perspective scores visible):

```
── deep-plan [9.5/{total}] Routing decision ──
Volume: {V.V} | Structure: {S.S} | Risk: {R.R} → Combined: {C.C}
Recommendation: {model} ({bias} bias, threshold {T})
{advisory line if D-01 triggered}
{borderline hint if D-12 triggered}
{(reduced confidence: --skip-research used) if applicable}
<!-- DEEP_PLAN_ROUTING: model={model} combined={C.C} volume={V.V} structure={S.S} risk={R.R} bias={bias} threshold={T} advisory={true|false} -->
```

**Phase-split advisory mode-aware behavior (D-02):**

When `advisory: true`, behavior depends on the active mode (locked for Phase 9 to provide; default `confirm` until then):

**If `mode: auto`**, render the advisory line as part of the banner and continue planning uninterrupted.

**If text_mode is active** (per Step 2 detection), present as a plain-text numbered list:
```
{advisory message — D-03 diagnostic detail with input tokens, combined score, top 2 contributing signals by weighted contribution}
1. Continue with current scope
2. Stop and split this phase manually
```
Type a number to choose. Parse response (number or free text). If invalid, re-prompt.

**Otherwise** (mode: confirm, no --text flag), use AskUserQuestion with two options mirroring the list above.

If the user chooses "Stop and split this phase manually", print `Run: /gsd-add-phase to split this phase` and stop the deep-plan run cleanly. The PLAN.md from Step 9 has already been written — the user can revisit it after splitting.

**Announce:** `── deep-plan [9.5/{total}] Routing decision ──`
Detail: `Volume: {V} | Structure: {S} | Risk: {R} → Combined: {C} | Model: {model} ({bias} bias){advisory_suffix}`

*Caveman override: routing-decision banner is always full prose regardless of caveman mode (Step 1 override map). New v2 signal — see `references/caveman-rule.md` Signal: Routing Decision Banner.*
</step>

<step name="plan_validation">
## Step 10: Plan Validation

**Announce:** `── deep-plan [10/{total}] Validating plan structure ──`
Detail: `Spawning plan-validator against PLAN.md...`

This step always runs. It catches format errors that would break gsd-executor — frontmatter schema, task XML structure, must_haves validity, and @-reference resolution.

**Validation lifecycle:** deep-plan validates plans twice when `--review` is active:
1. Step 10 (this step) — initial validation after first write
2. Step 11 — post-revision validation if feasibility findings trigger a plan update
Both stages use the same plan-validator agent and follow the same retry-on-error pattern (1 retry, then surface to user).

**Read `references/validation-flow.md`** for the full Task spawn body, FAIL/WARN/PASS result routing, and retry semantics. Substitute `{path to written PLAN.md}` and `{project root path}` from in-memory state.

**Announce (after validation):** `── deep-plan [10/{total}] Validation complete ──`
Detail: `Result: {PASS/WARN/FAIL} | Errors: {N} | Warnings: {N}`
</step>

<step name="feasibility_review">
## Step 11: Feasibility Review (if --review)

**Announce (before review):** `── deep-plan [11/{total}] Feasibility review ──`
Detail: `Launching feasibility-reviewer against PLAN.md...`

If `--review` flag was passed:

Spawn the CE feasibility reviewer:

```
Task compound-engineering:document-review:feasibility-reviewer(
  "Review this plan for feasibility — will the proposed technical approach 
  survive contact with reality?
  
  Plan: {path to written PLAN.md}
  Codebase: {project root}
  
  Focus on:
  1. Will the implementation order work given actual code dependencies?
  2. Are there build/deployment issues the plan misses?
  3. Are file paths and code references accurate?
  4. Are the risks realistic and mitigations sufficient?
  
  Be critical. Flag anything that would fail during implementation."
)
```

Route findings by severity:

**HIGH severity findings — auto-revise:**
The user already opted into `--review`; HIGH findings exist precisely to trigger revision. Skip the permission prompt and revise automatically.
- Log: `[step 11] HIGH finding(s) detected — auto-revising plan: {brief summary}`
- Update the PLAN.md with fixes. Save the original content in a `pre_revision_plan` variable before the Edit call so revert is possible if validation persistently fails.
- Re-run plan-validator on the revised plan to catch any cross-reference drift introduced by the revision (renamed task files, stale artifact paths, broken key_links).
- On validation FAIL: auto-fix what can be fixed, then attempt one more revision pass. If errors persist, present three options via AskUserQuestion: "Revert to pre-revision plan", "Accept errors and proceed", "Stop and fix manually".
- On validation PASS or WARN: log `[step 11] Auto-revision validated — proceeding`.

**MODERATE severity findings — surface as warnings, do not block:**
- Display each MODERATE finding with its location and recommendation.
- Log: `[step 11] {N} MODERATE finding(s) — surfaced as warnings, not blocking`.
- These should be addressed during execution but do not gate plan output.

**LOW severity findings — summarize briefly:**
- One-line per finding for the audit trail.
- No execution-time gating.

**Announce (after review):** `── deep-plan [11/{total}] Feasibility review complete ──`
Detail: `{N} findings: {high} HIGH | {moderate} MODERATE | {low} LOW`

*Caveman override: If any HIGH finding present (Step 1 override map), output entire feasibility review in full prose.*
</step>

<step name="handoff">
## Step 12: Handoff

**Announce:** `── deep-plan [12/{total}] Complete ──`
Mark all remaining Deep Plan tasks as completed.

Display summary:

```
## Deep Plan Complete

**Phase:** {N} — {phase_name}
**Plan:** {padded_phase}-{MM}-PLAN.md
**Units:** {count} implementation units
**Test scenarios:** {count} across all units
**Must-haves:** {truths_count} truths, {artifacts_count} artifacts, {links_count} key links
**Validation:** {PASS/WARN/FAIL} ({error_count} errors, {warning_count} warnings)
{if review: **Feasibility:** {findings_summary}}

**Next:** Run `/gsd-execute-phase {N}` to execute this plan.
```
</step>

</process>

<success_criteria>
- [ ] GSD CONTEXT.md was read and transformed into planning context
- [ ] GSD intel/research artifacts were gathered and composed into warm-start context (if available)
- [ ] CE repo-research-analyst received targeted prompt (warm-start or cold-start) and findings merged
- [ ] CE was NOT asked to re-discover information GSD already provided
- [ ] User was asked only material scoping questions (0-2 max)
- [ ] Implementation units have file paths, test scenarios, and verification
- [ ] Output PLAN.md has valid GSD frontmatter with must_haves
- [ ] PLAN.md is parseable by gsd-executor
- [ ] Plan-validator agent ran and returned PASS or WARN (errors were fixed before proceeding)
- [ ] Feasibility review ran (if --review) and findings presented
- [ ] Every step displayed a branded `── deep-plan [N/M]` header with detail lines
- [ ] TaskCreate tasks were created upfront and marked completed per step
</success_criteria>
