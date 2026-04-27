# Plan Validation Flow

Loaded on demand from SKILL.md Step 10. Documents the plan-validator Task spawn body, result routing, and retry semantics. Same pipeline reused by Step 11 post-revision validation (see Phase 5 work).

## Spawn the plan-validator agent

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

## Result routing

**On FAIL (any ERROR findings):**

- Display each error with its location.
- Auto-fix what can be fixed (missing fields with sensible defaults, malformed YAML).
- For unfixable errors, ask the user via AskUserQuestion: revise the plan or proceed at risk.
- If revising, update the PLAN.md and re-run validation (one retry).

**On WARN:**

- Display warnings briefly.
- Continue to next step (warnings don't block).

**On PASS:**

- Display: `✓ Plan structure validated — {N} checks passed`.

## Retry semantics

- One retry per validation round (Step 10 initial + Step 11 post-revision).
- After retry exhaustion, surface persistent errors via AskUserQuestion with options: Revert / Accept errors / Stop.
- Phase 5 added the post-revision arm — see Step 11 for the auto-revise + revert mechanism that wraps this same Task spawn.

## Cross-reference

- Step 10 (this flow) runs after first PLAN.md write.
- Step 11 reuses the same Task spawn after a feasibility-driven revision (Phase 5 / PLAN-02).
- The plan-validator agent itself lives at `agents/plan-validator.md` and includes Section 5 rename-drift checks (also Phase 5).
