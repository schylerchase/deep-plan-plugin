---
name: deep-plan-import-plan
description: Import a portable deep-plan handoff bundle into landed phase artifacts after schema validation
argument-hint: "[path] [--dry-run] [--force] [--no-review] [--review]"
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
---

# /deep-plan:import-plan Command

Import a portable handoff bundle produced by `/deep-plan:export-plan`. Validate it against `skills/deep-plan/references/handoff-schema.md`, resolve the receiving phase target, and hand off to later landing/provenance/review phases.

This command is project-local. In `--dry-run`, it reads the bundle and `.planning/`, reports validation, target collisions, and foreign-repo warnings, writes nothing, and spawns no subagent.

## Usage

`/deep-plan:import-plan [path] [--dry-run] [--force] [--no-review] [--review]`

## Instructions

### Phase 1: Banner

Print:

```text
╔════════════════════════════════════════════════════════════════╗
║   Deep Plan - Import Bundle                                  ║
║   Portable handoff format -> landed phase artifacts          ║
╚════════════════════════════════════════════════════════════════╝
```

Then print:

```text
-- deep-plan-import-plan [1/7] Prerequisites --
```

Verify before reading the bundle:

```bash
test -d .planning
test -f skills/deep-plan/references/handoff-schema.md
```

If `.planning/` is missing, stop: `No .planning directory found. Run from a GSD project root.`

If `handoff-schema.md` is missing, stop: `handoff-schema.md not found. Reinstall or repair the deep-plan plugin before importing.`

Do not write any file before this prerequisite gate passes.

### Phase 2: Argument Parsing

Print:

```text
-- deep-plan-import-plan [2/7] Argument parsing --
```

Parse `$ARGUMENTS`:

- Positional `[path]`: required readable bundle path, resolved relative to repo root when relative.
- `--dry-run`: validate, resolve target, report collision and foreign-repo warnings, write nothing, spawn no reviewer.
- `--force`: allow overwrite later; in `--dry-run`, report that real import would overwrite.
- `--no-review`: skip later feasibility review; ignored by `--dry-run`.
- `--review`: force later feasibility review onto opus; ignored by `--dry-run`.

Reject: unknown flags (`Unknown argument: {flag}`), missing path (print usage), multiple positional paths, unreadable path (`Bundle not readable: {bundle_path}`), and `--review` with `--no-review` (`Choose either --review or --no-review, not both.`).

### Phase 3: Bundle Reading and Frontmatter Split

Print:

```text
-- deep-plan-import-plan [3/7] Reading bundle --
```

Read the bundle file verbatim. Split YAML frontmatter only on leading delimiter lines: first line exactly `---`, closing delimiter the next line exactly `---`, frontmatter between them, body bytes immediately after the newline following the closing delimiter.

If either delimiter is missing or malformed, record Validation Contract check 1 as a hard failure and stop before section parsing:

```text
[FAIL] Frontmatter parse: malformed frontmatter delimiters.
```

Parse frontmatter as YAML and require a mapping. Unknown fields are allowed. If parsing fails or the result is not a mapping, stop before section parsing:

```text
[FAIL] Frontmatter parse: malformed frontmatter.
```

### Phase 4: Fence-Aware Section Parsing

Print:

```text
-- deep-plan-import-plan [4/7] Parsing bundle sections --
```

Parse body section markers using `skills/deep-plan/references/handoff-schema.md` as source of truth. Recognized marker lines are exactly:

```markdown
## --- BUNDLE SECTION: PLAN ---
## --- BUNDLE SECTION: CONTEXT ---
## --- BUNDLE SECTION: RESEARCH ---
## --- BUNDLE SECTION: INTEL_SUMMARY ---
```

Walk the body line by line while preserving original bytes:

1. Maintain `in_fence=false`.
2. Toggle `in_fence` on lines beginning at column zero with triple backticks or triple tildes; fence lines remain content.
3. Count a marker only when `in_fence=false` and the marker starts at column zero.
4. Treat leading-whitespace marker-looking lines and in-fence marker-looking lines as content.
5. Record the first occurrence of each real marker.
6. For later duplicate real markers outside fences, warn, do not switch sections, and preserve the duplicate marker line as content in the currently active section.
7. Preserve every byte after each winning marker line until the next winning marker line, including frontmatter, indentation, blank lines, duplicate marker lines, in-fence decoys, and trailing newlines.

This fence awareness is load-bearing. The round-trip fixture embeds decoy `## --- BUNDLE SECTION: ... ---` lines inside a fenced block; a naive grep or split would end the PLAN section too early.

Record `ACTUAL_SECTIONS` as unique winning markers in encounter order, `DUPLICATE_SECTION_WARNINGS` as duplicate real markers seen outside fences, and `SECTION_BYTES[...]` for winning markers only. Do not consume or trust section content until the Validation Contract passes.

### Phase 5: Validation Contract

Print:

```text
-- deep-plan-import-plan [5/7] Validation Contract --
```

Apply all nine checks from `handoff-schema.md` in this order. Report each as `[OK]`, `[WARN]`, or `[FAIL]`. Fatal failures prevent writes and prevent reviewer spawn.

| # | Check | Rule | Failure behavior |
|---|-------|------|------------------|
| 1 | Frontmatter parse | YAML frontmatter must parse as a mapping. | Reject as malformed frontmatter. |
| 2 | Required fields | Require `bundle_version`, `source_model`, `source_plugin`, `source_repo_id`, `exported_at`, `phase_id`, `phase_name`, `target_model_hint`, `sections_included`, and `original_paths`. | Reject and report every missing field name. |
| 3 | Version | `bundle_version` must be semver; `1.0` is supported. | Reject invalid semver and unsupported major versions; warn for newer minor versions. |
| 4 | Target hint | `target_model_hint` must be `claude`, `codex`, or `generic`. | Reject and report the invalid value. |
| 5 | Section set | `sections_included` must be an array matching `ACTUAL_SECTIONS` exactly; unknown names count as extra sections. | Reject and report missing or extra sections. |
| 6 | Required sections | `PLAN` and `CONTEXT` markers must exist and section bodies must be non-empty. | Reject the bundle. |
| 7 | Optional sections | `RESEARCH` and `INTEL_SUMMARY` may be absent only when omitted from `sections_included`. | Accept absence; do not synthesize placeholder content. |
| 8 | Duplicate markers | If a marker appears more than once outside fences, only the first marker wins; later duplicates are content. | Warn about duplicate markers; preserve bytes as content. |
| 9 | Original paths | `original_paths.plan` and `original_paths.context` must be strings. | Reject the bundle. |

Use these failure messages where applicable:

```text
[FAIL] Required fields: missing {field_names}
[FAIL] Version: bundle_version must be semver, got {value}
[FAIL] Version: unsupported bundle_version {value}; supported major is 1
[WARN] Version: newer minor bundle_version {value}; reading known 1.0 fields only
[FAIL] Target hint: invalid target_model_hint {value}; expected claude, codex, or generic
[FAIL] Section set: missing {missing_sections}; extra {extra_sections}
[FAIL] Required sections: PLAN and CONTEXT must be present and non-empty
[WARN] Duplicate markers: {section_names}; first marker wins, later marker lines preserved as content
[FAIL] Original paths: original_paths.plan and original_paths.context must be strings
```

If any `[FAIL]` exists after check 9, print and stop:

```text
Import validation failed. No files written. No feasibility reviewer spawned.
```

### Phase 6: Dry-Run Target Scan

Print:

```text
-- deep-plan-import-plan [6/7] Dry-run target scan --
```

Always run this scan for `--dry-run`. For non-dry-run execution, run the same scan before later landing.

Resolve the receiving target from `phase_id`, not `original_paths`:

1. Run `node ~/.claude/get-shit-done/bin/gsd-tools.cjs init plan-phase "$PHASE_ID" 2>/dev/null`.
2. Use returned `phase_dir` when present; otherwise construct `.planning/phases/{phase_id}`.
3. Derive phase number from the leading number in `phase_id`; derive padded prefix from existing plan files or by zero-padding the phase number.
4. Pick the next `{padded_phase}-{NN}-PLAN.md` by max existing plan number plus one, starting at `01`.
5. Resolve CONTEXT as `{phase_dir}/{phase_number}-CONTEXT.md`; resolve RESEARCH only when listed in `sections_included`.

Report target collisions:

- Without `--force`: `[WARN] Target collision: {path} exists. Real import will refuse unless --force is given.`
- With `--force`: `[WARN] Target collision: {path} exists. --force means real import will overwrite it.`

Compute local `source_repo_id` as `sha256(git remote get-url origin)[:12]`, or `local-no-origin` when no origin exists. If it differs from the bundle, report:

```text
[WARN] Foreign source_repo_id: bundle has {bundle_source_repo_id}; local repo is {local_source_repo_id}. Import will proceed by phase_id, not original_paths.
```

For `--dry-run`, finish after this scan:

```text
Dry run complete.
Validated bundle: {bundle_path}
Resolved PLAN target: {plan_target}
Resolved CONTEXT target: {context_target}
Files written: 0
Feasibility reviewers spawned: 0
```

Then stop. `--dry-run` must not call Write, create directories, amend `.planning/config.json`, or spawn `compound-engineering:ce-feasibility-reviewer` or any other subagent.

### Phase 7: Landing Hand-Off

Print:

```text
-- deep-plan-import-plan [7/7] Landing --
```

If `--dry-run` is absent, continue only after the Validation Contract and target scan have succeeded. Landing, provenance amend, and feasibility review are implemented by later import phases. Until those phases are present, do not invent landing behavior.

## Validation Checklist

After editing this command file, verify:

```bash
grep -q "import-plan" commands/deep-plan-import-plan.md
grep -q "Validation Contract" commands/deep-plan-import-plan.md
grep -q "AskUserQuestion" commands/deep-plan-import-plan.md
grep -qi "fence" commands/deep-plan-import-plan.md
grep -q "Files written: 0" commands/deep-plan-import-plan.md
grep -q "Feasibility reviewers spawned: 0" commands/deep-plan-import-plan.md
```

For `--dry-run`, inspect that the command runs all nine Validation Contract checks, reports target collisions and foreign `source_repo_id` warnings, writes nothing, creates no directories, and spawns no feasibility reviewer or subagent.

## Output Discipline

- Keep the banner and `-- deep-plan-import-plan [N/TOTAL]` step headers stable.
- Treat `skills/deep-plan/references/handoff-schema.md` as the source of truth for validation behavior.
- Never rewrite imported plan content during validation or dry-run.
- Never use `original_paths` as the primary target resolver; use `phase_id`.
- Never modify `.planning/`, global Claude, Codex, GSD, or shell configuration during `--dry-run`.
