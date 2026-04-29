---
id: SEED-001
status: dormant
planted: 2026-04-29
planted_during: v1.1 — Adaptive Model Routing (Phase 9 mid-execution)
trigger_when: v1.1 milestone complete (model routing + scoring infrastructure shipped)
scope: medium
---

# SEED-001: Build `/deep-plan-autonomous` — spec-sheet-in, front-to-back implementation, summary at end

## Why This Matters

Today, `deep-plan` is a single skill invocation that produces a plan. To go from "I have a spec" to "feature is shipped" the user still walks the GSD pipeline by hand: discuss → plan → execute → verify, command by command. For workflows where the spec is already crystallized (a written spec sheet, a feature description, a contract), the per-step ceremony is friction — the user knows what they want, they just want it built.

`/deep-plan-autonomous` would mirror the `gsd-autonomous` pattern but scoped to a single deep-plan invocation:
- **Input:** a spec sheet (file path, inline markdown, or pasted block)
- **Pipeline:** research → plan → execute → verify, end-to-end
- **Output:** a summary of what was built, what was decided, and what (if anything) was deferred

The value compounds with v1.1's routing work: by the time this lands, deep-plan can already pick the right model per phase based on scoring + GSD profile. An autonomous runner consumes that routing infrastructure rather than reinventing it — the spec sheet is just the entry point that drives the same routed pipeline without manual handoffs.

## When to Surface

**Trigger:** v1.1 milestone complete (model routing + scoring give the routing infrastructure this consumes)

This seed should be presented during `/gsd-new-milestone` when the milestone scope matches any of these conditions:
- Building a v1.2 (or later) feature focused on **deep-plan UX surface area** — wizard, onboarding, autonomous flows, spec-driven invocation
- Closing the loop on **autonomous execution patterns** that the v1.1 routing work enables but doesn't yet expose
- Any milestone whose theme touches **spec → ship** workflows or single-command pipelines for deep-plan users

Do NOT surface if the next milestone is purely defensive (bug fixes, doctor improvements, telemetry consolidation) — autonomous flows need a clean baseline, not a hardening pass.

## Scope Estimate

**Medium** — likely 2–3 phases:
1. **Spec-sheet parser** — accept file path, inline markdown, or pasted block; normalize to a CONTEXT.md-shaped artifact deep-plan can consume
2. **Pipeline orchestration** — chain research → plan → execute → verify with the same routing decisions Phase 11 wires up; honor the auto-mode budget cap from the GSD profile
3. **Summary surface** — at-end report: files touched, decisions made, deferred items, routing trace (which phases ran on which model and why)

Could expand to Large if the spec-sheet parser needs to handle multiple input shapes (PRDs, GitHub issues, Figma exports) or if the auto-mode needs adjustment beyond v1.1's defaults. Lean Medium for the first iteration — ship the markdown-spec path, add input adapters later.

## Breadcrumbs

Related code and decisions in the current codebase:

- `skills/deep-plan/SKILL.md` — the skill being autonomized; Step 1 (config resolution, Phase 9-02) and Step 9.5 (routing decision, Phase 8) are the integration points an autonomous runner would chain through
- `~/.claude/get-shit-done/workflows/autonomous.md` — pattern source; the discuss → plan → execute → verify loop with blocker handling and re-read of ROADMAP after each phase is the shape `/deep-plan-autonomous` should mirror
- `skills/deep-plan/references/scoring.md` — Phase 8 deliverable; the routing decisions an autonomous runner inherits per phase
- `skills/deep-plan/references/config.md` — Phase 9-01 deliverable; `deep_plan.model_routing` schema the runner reads at startup
- Phase 10 (Setup Wizard) and Phase 11 (PLAN.md & Feasibility Routing Integration) — once these land, the `auto` mode + budget cap behavior is fully specified, which is what `/deep-plan-autonomous` would consume
- `.planning/REQUIREMENTS.md` — CONFIG-01..03 + the SCORING-* / WIZARD-* / ROUTING-* sets define the boundary this seed sits on top of

## Notes

- User raised this mid-Phase 9 (during Wave 1 execution of plans 09-01 / 09-02) as a "when done" follow-up — captured as seed rather than todo because the trigger is milestone-scoped, not task-scoped, and the dependency on v1.1 routing is real (without it, the autonomous runner has nothing to route through).
- The spec-sheet input format is intentionally underspecified here — let the v1.2 milestone discuss-phase nail down whether this is a single .md template, a pasted block, or something more structured.
- Keep the summary surface lean for v1: files changed + decisions + deferred items. Routing-trace + cost telemetry can land in a later iteration once Phase 12's logging is in place.
