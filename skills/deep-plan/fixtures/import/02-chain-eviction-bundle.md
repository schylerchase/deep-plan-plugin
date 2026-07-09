---
bundle_version: "1.0"
source_model: "codex-fixture"
source_plugin: "deep-plan@0.3.0"
source_repo_id: "fixture000002"
exported_at: "2026-04-30T17:00:00Z"
phase_id: "14-import-fixture-chain-eviction"
phase_name: "Import Fixture Chain Eviction"
target_model_hint: "claude"
sections_included:
  - PLAN
  - CONTEXT
original_paths:
  plan: ".planning/phases/14-import-fixture-chain-eviction/14-01-PLAN.md"
  context: ".planning/phases/14-import-fixture-chain-eviction/14-CONTEXT.md"
---
## --- BUNDLE SECTION: PLAN ---
---
phase: 14-import-fixture-chain-eviction
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
    - model: "claude-opus-4-7"
      plugin: "deep-plan@0.3.0"
      action: "planned"
      ts: "2026-04-30T10:00:00Z"
    - model: "codex"
      plugin: "deep-plan@0.3.0"
      action: "imported"
      ts: "2026-04-30T11:00:00Z"
    - model: "opus"
      plugin: "deep-plan@0.3.0"
      action: "reviewed"
      ts: "2026-04-30T12:00:00Z"
    - model: "sonnet"
      plugin: "deep-plan@0.3.0"
      action: "executed"
      ts: "2026-04-30T13:00:00Z"
    - model: "codex"
      plugin: "deep-plan@0.3.0"
      action: "imported"
      ts: "2026-04-30T14:00:00Z"
---

<objective>
Exercise the five-entry routing.handoff_chain cap when import appends a new provenance entry.
</objective>

<tasks>
<task type="auto">
  <name>Unit 1: Preserve capped chain</name>
  <files>commands/deep-plan-import-plan.md</files>
  <action>
The importer appends a sixth entry, then drops the oldest entry from the front so five entries remain.
  </action>
  <verify>
    <automated>bash tests/eval-phase-14-import.sh</automated>
  </verify>
  <done>Chain cap fixture exercised.</done>
</task>
</tasks>
## --- BUNDLE SECTION: CONTEXT ---
# Phase 14 Import Fixture Chain Eviction Context

<domain>
Fixture context for an import whose PLAN already carries five handoff entries.
</domain>
