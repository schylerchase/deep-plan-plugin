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
