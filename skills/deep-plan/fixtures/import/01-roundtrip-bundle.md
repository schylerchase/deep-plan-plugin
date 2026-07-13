---
bundle_version: "1.0"
source_model: "codex-fixture"
source_plugin: "deep-plan@0.3.0"
source_repo_id: "f14eb0e00001"
exported_at: "2026-04-30T16:20:00Z"
phase_id: "14-import-fixture-roundtrip"
phase_name: "Import Fixture Roundtrip"
target_model_hint: "codex"
sections_included:
  - PLAN
  - CONTEXT
original_paths:
  plan: ".planning/phases/14-import-fixture-roundtrip/14-01-PLAN.md"
  context: ".planning/phases/14-import-fixture-roundtrip/14-CONTEXT.md"
---
## --- BUNDLE SECTION: PLAN ---
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
## --- BUNDLE SECTION: CONTEXT ---
# Phase 14 Import Fixture Roundtrip Context

<domain>
Fixture context for the minimal bundle. This section starts only at the real column-zero marker above.
</domain>

<decisions>
- The PLAN fixture contains fenced decoy section markers.
- The bundle omits RESEARCH and INTEL_SUMMARY because it models a --minimal export.
</decisions>
