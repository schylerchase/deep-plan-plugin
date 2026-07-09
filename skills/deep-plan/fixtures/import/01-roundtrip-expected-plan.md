---
phase: 14-import-fixture-roundtrip
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - commands/deep-plan-import-plan.md
autonomous: true
requirements:
  - HANDOFF-09
routing:
  handoff_chain:
    - model: "codex-fixture"
      plugin: "deep-plan@0.3.0"
      action: "planned"
      ts: "2026-04-30T12:00:00Z"
---

<objective>
Exercise import byte preservation when apparent bundle section markers appear inside embedded plan content.
</objective>

<context>
This fixture is intentionally adversarial. A parser that splits with grep or a naive string search will stop the PLAN section too early.

```text
These lines are content inside the PLAN.md section:
## --- BUNDLE SECTION: CONTEXT ---
## --- BUNDLE SECTION: RESEARCH ---
## --- BUNDLE SECTION: INTEL_SUMMARY ---
```

After the fence closes, this text must still belong to the PLAN section until the real CONTEXT marker at column zero.
</context>

<tasks>
<task type="auto">
  <name>Unit 1: Preserve fenced decoys</name>
  <files>commands/deep-plan-import-plan.md</files>
  <action>
The importer must land this PLAN body exactly as parsed, including the fenced decoy markers above.
  </action>
  <verify>
    <automated>bash tests/eval-phase-14-import.sh</automated>
  </verify>
  <done>Fixture parsed without splitting on fenced decoys.</done>
</task>
</tasks>
