---
fixture_type: chat
hard_override: false
rule_version: v1
origin: tuning-session-01
---

# Fixture: Chat output during deep-plan (any stage)

Representative chat during deep-plan execution. Caveman runs at whatever mode the user has set as default (e.g. `full`). No per-stage mode switching is asserted — that was the v0 hypothesis, and the first real tuning session invalidated it.

This fixture is a smoke test: it verifies chat-style content parses and the rule accepts it as "caveman default mode applies." No prose-vs-fragment detection is performed on chat fixtures because caveman mode is a user setting, not a per-stage rule.

── Representative chat snippet (generic sample) ──

Read 4 files (ctrl+o to expand)
Phase 2 currently on disk has existing CONTEXT.md and 2 PLANs.
M1 marked complete. M2 defining requirements.
Need clarify before proceeding.

Hold up. Conflict found.
STATE.md (prev answer): M2 defining requirements, 0 phases
ROADMAP.md on disk: M1 Phase 2 already complete (2 plans, 2 summaries)

Ambiguity blocker. Deep-plan on done phase wastes work.
Deep-plan on M2 phase impossible without roadmap + CONTEXT.

User answered: add 3rd plan to M1 Phase 2.
Scope undefined. Read artifacts to find candidates.

Read artifacts. Found deferred work.
- Item A deferred: task 2 skipped via approval gate in original plan
- Item B deferred: out-of-scope carryover from prior phase
- Also open from research: multiple candidates for further cleanup

Need pick scope for 3rd plan.

User answered: scope picked. Launch deeper research.

5 load-bearing facts shape plan:
1. Zero test coverage for half the merge targets. Silent breakage risk HIGH.
2. Post-loop aggregate emit pattern. Counts events across all items, pushes ONE finding after loop.
3. Pass count depends on runtime env. Dev = 3 passes. Prod = interleaving.

Plan written. Mark task done. Launch feasibility review.

── End snippet ──

What the eval checks: fixture exists, frontmatter parses, body is non-empty. Nothing more — chat style is the user's choice, not a rule assertion.
