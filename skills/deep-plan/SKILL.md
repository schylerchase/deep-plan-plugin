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

**Opening banner** — Display after phase is confirmed (end of Step 2):

    ╔═══════════════════════════════════════════════════╗
    ║  Deep Plan — Phase {N}: {phase_name}              ║
    ║  GSD context → CE research → Implementation plan  ║
    ╚═══════════════════════════════════════════════════╝

**Step headers** — Display at the start of every step:

    ── deep-plan [{current}/{total}] {Step Name} ──────────

Total = 12 with `--review`, 11 without (feasibility review skipped).

**Detail lines** — 1-2 lines after each header showing what was found/done. Use ✓/✗ for availability.

**Task tracking** — After phase confirmation, use TaskCreate to create all step tasks upfront (prefixed "Deep Plan:"). Mark each `in_progress` when starting, `completed` when done.

**Subagent attribution** — Before CE agent calls, state what deep-plan pre-fed and what CE will focus on. After return, summarize new findings count.

See `references/progress-templates.md` for full output examples per step.
</progress_protocol>

<step name="caveman_setup">
## Step 1: Caveman Setup

If caveman is installed, read `references/caveman-rule.md` and build an override map for three v2 signals requiring full prose: HIGH feasibility findings, AskUserQuestion blocks, mid-flight scope pivots. If absent, skip silently.

Enforced at: questions (Steps 2, 7), pivots (Step 8), feasibility (Step 11).
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
3. Total tasks = 10 (steps 2-11) without `--review`, 11 (steps 2-12) with `--review`
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

<step name="gather_intel">
## Step 4: Gather GSD Intelligence

**Announce:** `── deep-plan [4/{total}] Gathering codebase intelligence ──`
After gathering, detail: `Intel: {found_list} ({N}/5 files, {fresh/stale/none}) | Research: {found_list} ({warm/cold} start)`

GSD produces codebase analysis that CE would otherwise rediscover from scratch. Gathering this first gives CE a warm start — it spends tokens on depth instead of discovery.

**Check each source in order. Read what exists, skip what doesn't.**

**3a. Intel files (`.planning/intel/`):**

If the directory exists, read these structured files:
- `deps.json` → dependency graph with versions, types, usage pointers
- `files.json` → per-file export inventory with usage counts
- `apis.json` → public API signatures and deprecation markers
- `stack.json` → framework/library versions and roles
- `arch.md` → architecture overview in plain markdown

Check staleness: read `.planning/intel/.last-refresh.json` for `timestamp`. If older than 24 hours, flag: `"⚠️ Intel is {N} days old — CE will verify against live code"`

**3b. Research files (`.planning/research/`):**

If the directory exists, read:
- `ARCHITECTURE.md` → layers, patterns, data flow (highest CE overlap)
- `STACK.md` → tech decisions with confidence ratings
- `STRUCTURE.md` → file/module organization, entry points

Skip these (CE should discover independently for fresh perspective):
- `CONCERNS.md` — CE finding its own pitfalls is more valuable than echoing known ones
- `CONVENTIONS.md` — CE should infer from actual code, not pre-digested summaries

**3c. Scope boundaries (always read):**
- `.planning/REQUIREMENTS.md` → especially "Out of Scope" items (prevents CE from over-researching)
- `.planning/ROADMAP.md` → phase section only (goals, success criteria, dependencies)

**3d. If nothing exists:**

If neither `.planning/intel/` nor `.planning/research/` exist, suggest:
```
No codebase analysis found. For better results, consider running one of:
  /gsd-scan          — quick analysis (2-3 min)
  /gsd-map-codebase  — deep analysis (5-10 min)

Continue without pre-analysis? CE will explore from scratch (higher token usage).
```

**If text_mode is active**, present as a plain-text numbered list instead of AskUserQuestion:
```
1. Continue anyway
2. Run /gsd-scan first
```
Type a number to choose:

Parse the user's response (number or free text describing their choice). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion with options:
- "Continue anyway" — proceed, CE does full cold-start exploration
- "Run /gsd-scan first" — launch scan, then return here

**Compose the intelligence summary:**

Build a structured `gsd_knowledge` block from everything gathered:
```
## Known Codebase Intelligence (from GSD)

### Architecture
{from ARCHITECTURE.md or arch.md — layers, key patterns, data flow}

### Dependencies  
{from deps.json — name, version, role for each relevant dep}

### File Structure
{from files.json or STRUCTURE.md — key files, their exports, organization}

### API Surface
{from apis.json — relevant method signatures and stability}

### Tech Stack
{from stack.json or STACK.md — frameworks, versions, roles}

### Scope Boundaries
- Out of scope: {from REQUIREMENTS.md}
- Deferred: {from CONTEXT.md <deferred> section}

### Freshness
- Intel: {fresh / stale / not available}
- Research: {available / not available}
```
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
Before launching CE, state what was pre-fed from GSD and what CE will focus on:
- Warm: `Pre-fed: {summary — e.g., architecture, 47 deps, 12 exports} → CE focusing on: integration points, gaps, risks`
- Cold: `No GSD intel to pre-feed → CE exploring from scratch`

If `--skip-research` was passed, skip to Step 6. Otherwise:

**Compose the CE prompt based on what GSD intelligence is available:**

**If GSD intel/research exists (warm start):**

```
Task compound-engineering:research:repo-research-analyst(
  "Analyze the codebase for Phase {N}: {phase_name}.
  
  Planning brief: {planning_brief}
  
  ## Already Known (from GSD analysis — do NOT re-research these)
  {gsd_knowledge block from Step 3}
  
  ## What I Need From You (focus tokens here)
  1. Deep code tracing: actual function signatures, data flow, and closures 
     for the seed files — GSD mapped structure but not internals
  2. Integration points: how the files in scope actually connect at runtime 
     (imports, callbacks, event chains, shared state)
  3. Gaps and contradictions: anything the GSD analysis missed or got wrong
     (it may be stale — verify against live code)
  4. Test infrastructure: existing test patterns, frameworks, fixtures 
     relevant to this phase
  5. Risk signals: build/deploy issues, version conflicts, breaking changes
     that GSD's static analysis wouldn't catch
  
  Seed files to examine: {files from code_context}
  
  Do NOT spend tokens on: dependency listing, file tree enumeration, 
  architecture overview, or tech stack identification — these are already known.
  
  Return: code-level findings, integration map, gaps found, test patterns, risks."
)
```

**If no GSD intel exists (cold start):**

```
Task compound-engineering:research:repo-research-analyst(
  "Analyze the codebase for Phase {N}: {phase_name}.
  
  Planning brief: {planning_brief}
  
  Seed files to examine: {files from code_context}
  
  Focus on:
  1. Current file organization and patterns relevant to this phase
  2. Dependencies and integration points
  3. Existing code that will be modified or extended
  4. Testing infrastructure and conventions
  5. Build/deployment considerations
  
  Return: technology context, architectural patterns, relevant files with line counts,
  risks or gaps not covered in the existing research."
)
```

**Merge and rate findings:**

Tag each CE finding with a confidence level:
- **HIGH** — verified against live code (file exists, signature confirmed, test ran)
- **MEDIUM** — inferred from patterns (naming conventions, similar code, dependency graph)
- **LOW** — speculative (based on docs, comments, or assumptions not yet verified)

Include all findings regardless of confidence. The rating is informational — it helps the user gauge which findings to trust during execution.

- New file paths and patterns → add to planning context (with confidence tag)
- Gaps not covered by GSD research → flag as new findings (with confidence tag)
- Contradictions with GSD intel → note for user (intel may be stale)
- Dead dependencies, stale docs, unused code → note as bonus findings

**Announce (after CE returns):** `── deep-plan [6/{total}] CE research complete ──`
- Warm: `{N} findings ({high} high, {med} medium, {low} low) | {gaps} gaps | {risks} risk signals`
- Cold: `{N} relevant files | {M} findings ({high}/{med}/{low}) (Tip: /gsd-scan before planning = faster)`
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

**Ordering:** Dependencies first. Pure functions/constants before hooks before components. Infrastructure before features.

*Caveman override: If scope pivot detected (Step 1 override map), output pivot reasoning in full prose.*
</step>

<step name="write_plan">
## Step 9: Write GSD PLAN.md

Determine the plan number:
- Check existing `{padded_phase}-*-PLAN.md` files
- Next plan number = max existing + 1, zero-padded to 2 digits

Write to: `.planning/phases/{padded_phase}-{slug}/{padded_phase}-{MM}-PLAN.md`

**Format:**

```yaml
---
phase: {padded_phase}-{slug}
plan: {MM}
type: execute
wave: 1
depends_on: [{existing_plans_if_any}]
files_modified:
  - {all files from all units}
autonomous: true
requirements: [{requirement IDs from ROADMAP}]

must_haves:
  truths:
    - "{truth from test scenarios}"
  artifacts:
    - path: "{file}"
      provides: "{what it provides}"
      contains: "{search token}"
  key_links:
    - from: "{source}"
      to: "{destination}"
      via: "{how they connect}"
      pattern: "{search pattern}"
---

<objective>
{Phase goal from ROADMAP}

Purpose: {Why this matters — from CONTEXT.md domain section}

Output: {Deliverables — list of concrete outcomes}
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/{phase_dir}/{padded_phase}-CONTEXT.md
{@file references for all seed files from research}

<interfaces>
{Key code contracts from research findings — actual code signatures,
 data shapes, integration points the executor needs to understand}
</interfaces>
</context>

<tasks>

{For each implementation unit:}

<task type="auto">
  <name>Unit {N}: {unit name}</name>
  <read_first>
    {files from unit's "Patterns to follow"}
  </read_first>
  <files>{files from unit}</files>
  <action>
**Goal:** {unit goal}

**Requirements:** {unit requirements}

**Approach:**
{unit approach — key decisions, not code}

**Patterns to follow:**
{existing code references}

**Test scenarios:**
{all test scenarios with category prefixes}
  </action>
  <verify>
    <automated>{verification commands where possible}</automated>
  </verify>
  <acceptance_criteria>
    {verification outcomes from unit}
  </acceptance_criteria>
  <done>Unit {N} complete — {completion summary}</done>
</task>

</tasks>

<threat_model>
{Only include if the phase touches auth, user input, external APIs, or data persistence.
 Use STRIDE framework: Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation.
 Otherwise omit this section entirely.}
</threat_model>

<verification>
{Consolidated verification checklist from all units}
</verification>

<success_criteria>
{Success criteria from ROADMAP phase section}
</success_criteria>

<output>
After completion, create .planning/phases/{phase_dir}/{padded_phase}-{MM}-SUMMARY.md using the template at @$HOME/.claude/get-shit-done/templates/summary.md
</output>
```

**Announce:** `── deep-plan [9/{total}] Plan written ──`
Detail: `.planning/phases/{phase_dir}/{padded_phase}-{MM}-PLAN.md` — `Units: {N} | Test scenarios: {N} | Must-haves: {truths} truths, {artifacts} artifacts, {links} links`
</step>

<step name="plan_validation">
## Step 10: Plan Validation

**Announce:** `── deep-plan [10/{total}] Validating plan structure ──`
Detail: `Spawning plan-validator against PLAN.md...`

This step always runs. It catches format errors that would break gsd-executor — frontmatter schema, task XML structure, must_haves validity, and @-reference resolution.

Spawn the plan-validator agent:

```
Task deep-plan:plan-validator(
  "Validate this PLAN.md for GSD executor compatibility.
  
  Plan: {path to written PLAN.md}
  Project root: {project root path}
  
  Check all 6 dimensions: frontmatter schema, must_haves structure, 
  task XML, @-references, consistency, and executor compatibility.
  
  Return the validation report with PASS/WARN/FAIL result."
)
```

**On FAIL (any ERROR findings):**
- Display each error with its location
- Auto-fix what can be fixed (missing fields with sensible defaults, malformed YAML)
- For unfixable errors, ask the user: revise the plan or proceed at risk
- If revising, update the PLAN.md and re-run validation

**On WARN:**
- Display warnings briefly
- Continue to next step (warnings don't block)

**On PASS:**
- Display: `✓ Plan structure validated — {N} checks passed`

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

Present findings to the user. For HIGH severity findings:

**If text_mode is active**, present as a plain-text numbered list instead of AskUserQuestion:
```
HIGH finding: {description}
1. Yes, revise the plan
2. No, accept the risk
```
Type a number to choose:

Parse the user's response (number or free text describing their choice). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion to ask if they want the plan revised.

- If yes, update the PLAN.md with fixes
- If no, note the finding as a known risk

For MODERATE/LOW findings:
- Summarize briefly
- Note any that should be addressed during execution

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
