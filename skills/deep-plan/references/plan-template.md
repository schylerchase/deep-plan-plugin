# PLAN.md Output Template

Loaded on demand from SKILL.md Step 9. Contains the full GSD-compatible PLAN.md format with substitution variables documented inline.

## Plan numbering

- List existing `{padded_phase}-*-PLAN.md` files in the phase directory.
- Extract the NN portion (digits between `{padded_phase}-` and `-PLAN.md`).
- Sort numerically (NOT lexicographically — lex sort gives `10 < 09` because it compares character by character; numeric sort correctly gives `10 > 09`).
- Next plan number = (max existing as integer) + 1, zero-padded to 2 digits.
- If no existing plans, start at 01.

Reference Bash one-liner:

```bash
NEXT=$(ls "{phase_dir}/{padded_phase}-"*"-PLAN.md" 2>/dev/null \
  | sed -E 's/.*-([0-9]+)-PLAN\.md/\1/' \
  | sort -n | tail -1)
NEXT=$(( ${NEXT:-0} + 1 ))
printf -v NEXT_PADDED "%02d" $NEXT
```

## File path

Write to: `.planning/phases/{padded_phase}-{slug}/{padded_phase}-{MM}-PLAN.md`

## Substitution variables

| Variable | Source |
|----------|--------|
| `{padded_phase}` | Step 2 init JSON |
| `{slug}` | Step 2 init JSON |
| `{MM}` | Plan numbering above |
| `{N}` | Phase number |
| `{phase_name}` | ROADMAP phase header |
| `{phase_dir}` | `.planning/phases/{padded_phase}-{slug}` |
| `{routing_decision.*}` | Step 9.5 routing decision object; Step 9 writes placeholders and Step 9.5 replaces them before Step 10 validation |

## Optional `routing.handoff_chain`

Phase 13 adds an optional `routing.handoff_chain` frontmatter field for cross-model planning handoff. Its absence means the plan has not moved between models or tools.

```yaml
routing:
  handoff_chain:
    - model: "claude-opus-4-7"
      plugin: "deep-plan@1.2.0"
      action: "planned"
      ts: "2026-04-30T12:34:56Z"
    - model: "codex-cli"
      plugin: "codex"
      action: "imported"
      ts: "2026-04-30T13:15:22Z"
```

Entry schema:

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| `model` | yes | string | Model or executor identifier that performed the action. |
| `plugin` | yes | string | Plugin/tool name and version when available, such as `deep-plan@1.2.0`. |
| `action` | yes | enum | One of `planned`, `imported`, `reviewed`, `executed`. |
| `ts` | yes | ISO-8601 UTC string | Timestamp for the handoff event. |

Keep only the last 5 entries. When adding a sixth entry, drop the oldest entry from the front before writing the updated frontmatter. Invalid `action` values or malformed `ts` values are importer/doctor warnings in v1.2; they do not change execution semantics by themselves.

## Full template body

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
executor_model: "{routing_decision.executor_model}"
model_recommendation:
  recommended_model: "{routing_decision.recommended_model}"
  executor_model: "{routing_decision.executor_model}"
  selection_reason: "{routing_decision.selection_reason}"
  bias: "{routing_decision.bias}"
  threshold: {routing_decision.threshold}
  scores:
    volume: {routing_decision.volume_score}
    structure: {routing_decision.structure_score}
    risk: {routing_decision.risk_score}
    combined: {routing_decision.combined_score}
  input_tokens_estimate: {routing_decision.input_tokens_estimate}
  advisory: {routing_decision.advisory}
  reduced_confidence: {routing_decision.reduced_confidence}

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
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
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
After completion, create .planning/phases/{phase_dir}/{padded_phase}-{MM}-SUMMARY.md using the template at @~/.claude/get-shit-done/templates/summary.md
</output>
```

## Notes

- Path-portability rule: use `@~/...` for home-relative paths (PORT-01). Do not use `@$HOME/...`.
- threat_model section is conditional — omit when not applicable.
- All `@-references` in execution_context and context blocks must resolve at execute-plan time. Use tilde or repo-relative paths only.
- Step 9 writes the PLAN.md body, then Step 9.5 computes the routing decision and updates the frontmatter fields above before Step 10 validation. The `executor_model` and `model_recommendation` block must always come from the same in-memory routing decision object.
