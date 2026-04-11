# Caveman Rule v0 — Deep-Plan Stage Weighting

## Purpose

Decide which caveman compression mode applies during each stage of /deep-plan.
Caveman modes:
- `off` — normal prose, no compression
- `lite` — drop filler words only
- `full` — drop articles + fragment-style (default)
- `ultra` — extreme compression, status-only

## Decision Table

| Step | Stage              | Mode  | Rationale (one line)                              |
|------|--------------------|-------|---------------------------------------------------|
| 1    | parse_args         | full  | Bulk detection output                             |
| 2    | load_gsd_context   | full  | Bulk file reading + availability report           |
| 3    | gather_intel       | full  | Bulk intel file listing                           |
| 4    | build_planning_brief | lite | Synthesis nuance matters                         |
| 5    | ce_research        | full  | Subagent runs; main thread mostly waits           |
| 6    | resolve_questions  | lite  | User-facing AskUserQuestion needs nuance          |
| 7    | structure_units    | lite  | Design decisions need nuance                      |
| 8    | write_plan         | off   | PLAN.md is an artifact (HARD OVERRIDE)            |
| 9    | plan_validation    | full  | Status reporting                                  |
| 10   | feasibility_review | lite  | Critical triage; off on HIGH findings             |
| 11   | handoff            | ultra | Status-only summary                               |

## Hard Overrides

These overrides are NON-NEGOTIABLE and supersede any other consideration.

1. **Step 8 (write_plan): mode MUST be `off`**
   Rationale: The PLAN.md being written is an artifact consumed by gsd-executor
   and read by humans. Artifacts must be normal prose. This applies to the
   content being written into the file — the chat surrounding the write may
   use a different mode if the rule says so, but the artifact text itself
   stays prose.

2. **Step 10 (feasibility_review) on HIGH severity findings: mode SHOULD drop to `off`**
   Rationale: When a HIGH-severity finding is being reported to the user, the
   words matter and compression risks ambiguity. Default for step 10 is `lite`,
   but escalate to `off` if any HIGH finding is present in the review output.
   (v0 rule: leave at lite. Track for v1 tuning.)

## Parse Contract for Eval Script

The eval script looks at fixture frontmatter for `stage` and `expected_mode`,
then asks this rule what mode that `stage` should produce. The rule answer
function is the table above, indexed by `stage`. Hard overrides win.

Mapping function (pseudocode for eval-caveman-rule.sh):

```
mode_for_stage(stage):
  case stage of
    parse_args            -> full
    load_gsd_context      -> full
    gather_intel          -> full
    build_planning_brief  -> lite
    ce_research           -> full
    resolve_questions     -> lite
    structure_units       -> lite
    write_plan            -> off    # HARD
    plan_validation       -> full
    feasibility_review    -> lite
    handoff               -> ultra
    *                     -> ERROR unknown stage
```

## Versioning

- **v0** (this doc): static decision table, no signal-based dispatch
- **v1** (future): signal-based — detect HIGH findings, artifact writes, etc.
- **v2** (future): tunable per-user via plugin config

## See Also

- Fixtures: `skills/deep-plan/fixtures/caveman/`
- Eval script: `tests/eval-caveman-rule.sh`
- Deep-plan stages: `skills/deep-plan/SKILL.md` (steps 1-11)
