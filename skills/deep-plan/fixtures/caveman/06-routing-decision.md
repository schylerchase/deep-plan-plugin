---
fixture_type: routing_decision_banner
hard_override: true
rule_version: v2
origin: phase-8-D-11
caveman_mode: lite
deep_plan_step: 9.5
---

# Fixture: Routing decision banner output (v2 signal override per Phase 8 D-11)

This fixture represents the output of deep-plan Step 9.5 when it emits the model-routing decision banner. When the banner is being rendered, the v2 signal override forces the entire banner block into full prose regardless of the active caveman mode. The rationale is that the banner is a decision artifact rather than chatter — users read the three perspective scores and the recommended model to understand why a model was chosen, and caveman compression would destroy that legibility.

-- Representative routing decision banner --

── deep-plan [9.5/12] Routing decision ──

Volume: 6.2 | Structure: 9.5 | Risk: 11.0 → Combined: 14.8

Recommendation: opus (balanced bias, threshold 12).

Phase split advisory: the input is approximately 187k tokens and the combined complexity score 14.8 is greater than the opus threshold 12, so the algorithm recommends splitting this phase before execution begins.

Top contributors to the score were the unique file count of 47 across the implementation units, and 8 novel patterns flagged by the feasibility review. The reduced confidence note does not apply because research was performed normally during this run.

<!-- DEEP_PLAN_ROUTING: model=opus combined=14.8 volume=6.2 structure=9.5 risk=11.0 bias=balanced threshold=12 advisory=true -->

-- End sample --

The eval script checks that this body contains at least 5 article words (the, an, is, are, was, were), confirming the v2 signal override produced full prose rather than caveman-compressed fragments. Per Phase 8 D-09, the banner format is a compact 3-line breakdown plus optional advisory; per D-11, this exemption applies regardless of which caveman mode the user has set as default. The machine-readable trailer comment is parseable by tests but does not contribute to the prose assertion.
