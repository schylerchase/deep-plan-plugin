---
name: deep-plan
description: "This skill should be used when the user asks to 'deep plan', 'plan a phase deeply', 'run deep-plan', or wants CE-quality implementation planning after /gsd-discuss-phase. Bridges GSD context with code-grounded research, implementation units, test scenarios, and optional feasibility review. Produces GSD-compatible PLAN.md files."
argument-hint: "[phase] [--review] [--skip-research]"
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
  - TodoWrite
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

<process>

<step name="parse_args">
## Step 1: Parse Arguments and Auto-Detect Phase

Extract from the invocation:
- `phase` — the phase number (e.g., "18", "11.1")
- `--review` flag — if present, run feasibility review after planning
- `--skip-research` flag — if present, skip CE repo-research-analyst

**If no phase argument provided, auto-detect:**

```bash
# Get full roadmap analysis with disk status
ROADMAP_STATE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze 2>/dev/null)
```

From the roadmap analysis, find the best candidate phase by priority:
1. **Phase with CONTEXT.md but no PLAN.md** — ready for deep-plan right now
2. **Phase with no CONTEXT.md and no PLAN.md** — needs discuss-phase first, suggest it
3. **Current phase from STATE.md** — fallback

Present the detected phase to the user:

```
Detected: Phase {N} — {phase_name}
  Status: {has context / needs context / has plans already}

Use this phase? (or specify a different one)
```

Use AskUserQuestion with options:
- "Yes, plan Phase {N}" — proceed with detected phase
- "Different phase" — ask which one
- If the detected phase has no CONTEXT.md, add: "Run /gsd-discuss-phase {N} first" — launch discuss-phase, then return here

This way users can just type `/deep-plan` with no arguments and the skill figures out what to do.
</step>

<step name="load_gsd_context">
## Step 2: Load GSD Phase Context

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
If PLAN.md files already exist for this phase, ask the user:
- Add another plan (increment plan number)
- Replan from scratch (overwrite)
- Cancel
</step>

<step name="build_planning_brief">
## Step 3: Build Planning Brief

Transform GSD artifacts into a structured planning brief for CE research:

From CONTEXT.md:
- `<domain>` section → **Problem frame** and **scope boundaries**
- `<decisions>` locked items → **Resolved questions** (carry forward as-is)
- `<decisions>` "Claude's Discretion" items → **Open questions** for research to inform
- `<code_context>` → **Seed files** for repo-research-analyst
- `<specifics>` → **Constraints and examples**
- `<deferred>` → **Explicit non-goals** (scope boundaries)

From RESEARCH.md (if exists):
- Technical approach → **Pre-existing research** (do not re-research these topics)
- Risk analysis → **Known risks** to carry into the plan

From ROADMAP.md phase section:
- Phase goal → **Objective**
- Success criteria → **Requirements trace**
- Dependencies → **Prerequisites**

Compose a 2-3 paragraph planning brief summarizing:
1. What the phase delivers and why
2. User decisions that are locked
3. Areas where code research is needed
4. Files and patterns already identified
</step>

<step name="ce_research">
## Step 4: CE Research (unless --skip-research)

If `--skip-research` was passed, skip to Step 5. Otherwise:

Spawn the CE repo-research-analyst with the planning brief:

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

**Merge findings:**
- New file paths and patterns → add to planning context
- Gaps not covered by RESEARCH.md → flag as new findings
- Contradictions with RESEARCH.md → note for user (research may be stale)
- Dead dependencies, stale docs, unused code → note as bonus findings

Announce: "Research complete. Found {N} relevant files, {M} new findings beyond existing GSD research."
</step>

<step name="resolve_questions">
## Step 5: Resolve Planning Questions

Build a question list from:
1. "Claude's Discretion" items from CONTEXT.md that research can now inform
2. Gaps discovered by repo-research-analyst
3. Technical decisions needed for implementation units

For each question:
- If research provides a clear answer → resolve silently
- If the answer materially affects scope, architecture, or risk → ask the user via AskUserQuestion
- If the answer depends on runtime behavior → defer to implementation

Keep user questions focused and minimal (1-2 max). Don't ask about things the user already decided in CONTEXT.md.
</step>

<step name="structure_units">
## Step 6: Structure Implementation Units

Break the phase work into implementation units. Each unit represents one meaningful atomic change.

For each unit, define:

- **Name** — clear, action-oriented
- **Goal** — what this unit accomplishes
- **Requirements** — which ROADMAP requirements or success criteria it advances
- **Dependencies** — what must exist first (other units or external)
- **Files** — repo-relative paths to create, modify, or test
- **Approach** — key decisions, data flow, integration notes (not code)
- **Patterns to follow** — existing code to mirror (from research findings)
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
</step>

<step name="write_plan">
## Step 7: Write GSD PLAN.md

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

Announce: "Plan written to .planning/phases/{phase_dir}/{padded_phase}-{MM}-PLAN.md"
</step>

<step name="feasibility_review">
## Step 8: Feasibility Review (if --review)

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
- Ask if they want the plan revised
- If yes, update the PLAN.md with fixes
- If no, note the finding as a known risk

For MODERATE/LOW findings:
- Summarize briefly
- Note any that should be addressed during execution

Announce: "Feasibility review complete. {N} findings: {high} high, {moderate} moderate, {low} low."
</step>

<step name="handoff">
## Step 9: Handoff

Display summary:

```
## Deep Plan Complete

**Phase:** {N} — {phase_name}
**Plan:** {padded_phase}-{MM}-PLAN.md
**Units:** {count} implementation units
**Test scenarios:** {count} across all units
**Must-haves:** {truths_count} truths, {artifacts_count} artifacts, {links_count} key links
{if review: **Feasibility:** {findings_summary}}

**Next:** Run `/gsd-execute-phase {N}` to execute this plan.
```
</step>

</process>

<success_criteria>
- [ ] GSD CONTEXT.md was read and transformed into planning context
- [ ] CE repo-research-analyst ran (unless --skip-research) and findings merged
- [ ] User was asked only material scoping questions (0-2 max)
- [ ] Implementation units have file paths, test scenarios, and verification
- [ ] Output PLAN.md has valid GSD frontmatter with must_haves
- [ ] PLAN.md is parseable by gsd-executor
- [ ] Feasibility review ran (if --review) and findings presented
</success_criteria>
