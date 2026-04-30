---
name: deep-plan-export-plan
description: Export phase artifacts as portable handoff bundle for cross-model planning workflows
argument-hint: "[phase] [--target=<model>] [--out=<path>] [--minimal]"
allowed-tools: Read, Write, Bash, Glob, AskuserQuestion
---

# /deep-plan:export-plan Command

Export a phase's planning artifacts into a single portable handoff bundle. The bundle is meant for cross-model workflows: plan in one tool, execute or review in another.

This command is project-local. It reads `.planning/phases/`, optional `.planning/intel/` and `.planning/research/`, writes `.planning/handoff/`, and appends project-local telemetry.

## Usage

- `/deep-plan:export-plan 13`
- `/deep-plan:export-plan 13 --target=codex`
- `/deep-plan:export-plan 13 --minimal`
- `/deep-plan:export-plan 13 --out=/tmp/phase-13.handoff.md`
- `/deep-plan:export-plan` to auto-detect the latest unexported phase

## Instructions

### Phase 1: Banner

Print:

```text
╔══════════════════════════════════════════════════╗
║   Deep Plan - Export Bundle                     ║
║   Phase artifacts -> portable handoff format    ║
╚══════════════════════════════════════════════════╝
```

Then verify prerequisites:

```bash
test -d .planning
test -d .planning/phases
test -f skills/deep-plan/references/handoff-schema.md
test -f skills/deep-plan/references/intel-distill.md
```

If `.planning/` or `.planning/phases/` is missing, stop with:

```text
No .planning/phases directory found. Run from a GSD project root.
```

### Phase 2: Argument Parsing

Parse `$ARGUMENTS`:

- Positional `[phase]`: optional phase number such as `13`, or a phase id such as `13-bundle-schema-export`.
- `--target=codex|claude|generic`: optional, default `generic`.
- `--out=<path>`: optional output path.
- `--minimal`: optional flag. Include only `PLAN` and `CONTEXT`.

Reject invalid `--target` values with:

```text
Invalid target. Expected one of: codex, claude, generic.
```

Detect text mode with:

```bash
TEXT_MODE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get workflow.text_mode 2>/dev/null || echo false)
```

When text mode is active, render any choice as a numbered list instead of `AskuserQuestion`.

### Phase 3: Phase Resolution

Print:

```text
-- deep-plan-export-plan [3/6] Phase resolution --
```

If `[phase]` is provided:

1. If it is numeric, find exactly one directory matching `.planning/phases/{phase}-*`.
2. If it contains a hyphen, use `.planning/phases/{phase}`.
3. If no directory matches, stop with `Phase {phase} not found in .planning/phases`.

If `[phase]` is omitted:

1. List `.planning/phases/*/`.
2. Sort by numeric phase prefix descending.
3. Pick the newest phase directory that has at least one `*-PLAN.md` and no matching `.planning/handoff/{phase_dir}.handoff.md`.
4. If multiple candidates remain ambiguous, ask the user to choose.

Resolve:

- `PHASE_DIR`: directory path, such as `.planning/phases/13-bundle-schema-export`
- `PHASE_ID`: basename, such as `13-bundle-schema-export`
- `PHASE_NUM`: numeric prefix, such as `13`
- `PADDED_PHASE`: zero-padded numeric prefix when source files use it
- `PLAN_PATH`: highest-numbered `*-PLAN.md` in the phase directory
- `CONTEXT_PATH`: `{phase_dir}/{phase_num}-CONTEXT.md`
- `RESEARCH_PATH`: `{phase_dir}/{phase_num}-RESEARCH.md`, optional

Use the highest plan number when multiple plan files exist. If `PLAN_PATH` is missing, stop with:

```text
Phase {phase} has no PLAN.md - run /gsd-plan-phase {phase} first.
```

If `CONTEXT_PATH` is missing, stop with:

```text
Phase {phase} has no CONTEXT.md - run /gsd-discuss-phase {phase} first.
```

### Phase 4: Artifact Reading

Print:

```text
-- deep-plan-export-plan [4/6] Reading artifacts --
```

Read:

- `PLAN_PATH` verbatim
- `CONTEXT_PATH` verbatim
- `RESEARCH_PATH` verbatim when present and `--minimal` is absent
- `.planning/intel/deps.json`
- `.planning/intel/files.json`
- `.planning/intel/apis.json`
- `.planning/intel/arch.md`
- `.planning/research/*.md`

Skip research and intel reads when `--minimal` is present.

Malformed intel JSON is a warning, not an abort:

```text
[WARN] intel-distill: skipped {path} (malformed JSON)
```

### Phase 5: Bundle Composition

Print:

```text
-- deep-plan-export-plan [5/6] Composing bundle --
```

Before composing the final bundle, update the source `PLAN.md` frontmatter with `routing.handoff_chain` so the bundle's `PLAN` section remains byte-identical to the post-export source plan.

Append this entry, keeping only the last 5 entries:

```yaml
- model: "{source_model}"
  plugin: "{source_plugin}"
  action: "planned"
  ts: "{exported_at}"
```

Then re-read `PLAN_PATH` verbatim.

Compute bundle frontmatter:

```yaml
bundle_version: "1.0"
source_model: "{CLAUDE_CODE_MODEL or CODEX_MODEL or OPENAI_MODEL or claude-opus-4-7}"
source_plugin: "deep-plan@{version from .claude-plugin/plugin.json, or unknown}"
source_repo_id: "{sha256(git remote origin url) first 12 chars, or local-no-origin}"
exported_at: "{UTC ISO-8601 timestamp}"
phase_id: "{PHASE_ID}"
phase_name: "{human-readable name from ROADMAP.md or PHASE_ID}"
target_model_hint: "{target}"
sections_included:
  - PLAN
  - CONTEXT
  - RESEARCH          # only when source exists and --minimal is absent
  - INTEL_SUMMARY    # only when distillation emits non-empty content
original_paths:
  plan: "{PLAN_PATH}"
  context: "{CONTEXT_PATH}"
  research: "{RESEARCH_PATH when included}"
```

For `--minimal`, `sections_included` is only `PLAN` and `CONTEXT`, and the bundle has no `RESEARCH` or `INTEL_SUMMARY` section. Without `--minimal`, optional sections are still omitted when their source material is absent or malformed per `intel-distill.md`.

Distill intel according to `skills/deep-plan/references/intel-distill.md`. The output must use this order when source material exists:

```markdown
### Dependencies (top 20)
### Files (top 30 by size + 10 recent edits)
### Public APIs
### Architecture overview
### Research summaries
```

Compose the bundle exactly:

```markdown
---
{bundle frontmatter}
---

## --- BUNDLE SECTION: PLAN ---
{verbatim PLAN.md content}

## --- BUNDLE SECTION: CONTEXT ---
{verbatim CONTEXT.md content}

## --- BUNDLE SECTION: RESEARCH ---
{verbatim RESEARCH.md content, if included}

## --- BUNDLE SECTION: INTEL_SUMMARY ---
{distilled intel summary, if included}
```

The content starts immediately after each marker line. The `PLAN` and `CONTEXT` section bodies must preserve bytes from the source files, including frontmatter, indentation, blank lines, and trailing newlines. Validators must ignore marker-looking lines inside fenced code blocks when checking byte identity.

### Phase 6: Write, Telemetry, Output

Print:

```text
-- deep-plan-export-plan [6/6] Bundle written --
```

Create `.planning/handoff/` when missing.

Output path:

- `--out=<path>` when provided
- otherwise `.planning/handoff/{PHASE_ID}.handoff.md`

Write the bundle to the output path.

Append to `.planning/config.json` `_telemetry.handoff[]`, preserving unrelated keys:

```json
{
  "phase_id": "{PHASE_ID}",
  "direction": "export",
  "target": "{target}",
  "ts": "{exported_at}",
  "bundle_path": "{repo-relative output path}"
}
```

If `.planning/config.json` is malformed, do not rewrite it. Print:

```text
[WARN] .planning/config.json malformed; bundle written but _telemetry.handoff was skipped. Run /deep-plan-doctor.
```

Finish with:

```text
Bundle ready: {output_path} ({size} KB)

Receiving model usage:
  Codex CLI:    codex chat < {output_path}
  Claude Code:  /deep-plan:import-plan {output_path}
  Other:        Paste bundle contents into chat with: "Implement this plan."
```

## Validation Checklist

After writing, verify:

```bash
test -f "$OUTPUT_PATH"
grep -q 'bundle_version: "1.0"' "$OUTPUT_PATH"
grep -q 'BUNDLE SECTION: PLAN' "$OUTPUT_PATH"
grep -q 'BUNDLE SECTION: CONTEXT' "$OUTPUT_PATH"
grep -q 'target_model_hint:' "$OUTPUT_PATH"
grep -q '_telemetry.handoff' skills/deep-plan/references/config.md
grep -q 'handoff_chain' "$PLAN_PATH"
```

For non-minimal bundles, also verify:

```bash
grep -q 'BUNDLE SECTION: INTEL_SUMMARY' "$OUTPUT_PATH"
```

For `--minimal`, verify the opposite:

```bash
! grep -q 'BUNDLE SECTION: RESEARCH' "$OUTPUT_PATH"
! grep -q 'BUNDLE SECTION: INTEL_SUMMARY' "$OUTPUT_PATH"
```

## Output Discipline

- Keep the banner and step headers stable.
- Treat bundle export as successful even when optional intel is absent.
- Never modify global Claude, Codex, GSD, or shell configuration.
- Never overwrite malformed `.planning/config.json`; warn and leave it untouched.
