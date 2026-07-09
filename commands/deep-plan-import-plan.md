---
name: deep-plan-import-plan
description: Import a portable deep-plan handoff bundle into landed phase artifacts after schema validation
argument-hint: "[path] [--dry-run] [--force] [--no-review] [--review]"
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
---

# /deep-plan:import-plan Command

Import a portable handoff bundle produced by `/deep-plan:export-plan`. Validate it against `skills/deep-plan/references/handoff-schema.md`, resolve the receiving phase target, land phase artifacts byte-for-byte, and hand off to later provenance/review phases.

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
-- deep-plan-import-plan [1/8] Prerequisites --
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
-- deep-plan-import-plan [2/8] Argument parsing --
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
-- deep-plan-import-plan [3/8] Reading bundle --
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
-- deep-plan-import-plan [4/8] Parsing bundle sections --
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
-- deep-plan-import-plan [5/8] Validation Contract --
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

### Phase 6: Target Resolution

Print:

```text
-- deep-plan-import-plan [6/8] Target resolution --
```

Always run this phase after the Validation Contract passes. `--dry-run` stops after this phase; non-dry-run proceeds to landing.

Resolve the receiving target from `phase_id`, not `original_paths`:

1. Run `node ~/.claude/get-shit-done/bin/gsd-tools.cjs init plan-phase "$PHASE_ID" 2>/dev/null`.
2. Ignore `expected_phase_dir`; on this GSD build it is `null` and must not drive imports.
3. When the JSON reports the phase already exists, use the returned `phase_dir`.
4. When the phase is absent, construct `PHASE_DIR=.planning/phases/{phase_id}` directly from bundle frontmatter.
5. Derive phase number from the leading number in `phase_id`; derive `PADDED_PHASE` from existing plan files when present, otherwise zero-pad the phase number.
6. Pick the next `{padded_phase}-{NN}-PLAN.md` by applying the `plan-template.md` rule: list existing `{padded_phase}-*-PLAN.md`, extract `NN`, sort numerically, add one, zero-pad to two digits, start at `01` when none exist.
7. Resolve `PLAN_TARGET={phase_dir}/{padded_phase}-{NN}-PLAN.md`.
8. Resolve `CONTEXT_TARGET={phase_dir}/{padded_phase}-CONTEXT.md`.
9. Resolve `RESEARCH_TARGET={phase_dir}/{padded_phase}-RESEARCH.md` only when `RESEARCH` is listed in `sections_included`.

Use `original_paths` only as a fallback clue when `phase_id` cannot be parsed enough to derive the phase number; warn before doing so. Otherwise treat `original_paths` as provenance only. Never path-remap a foreign repository bundle.

Report target collisions before creating directories or writing bytes:

- Without `--force`: `[WARN] Target collision: {path} exists. Real import will refuse unless --force is given.`
- With `--force`: `[WARN] Target collision: {path} exists. --force means real import will overwrite it.`

Check every artifact path that will be written. A next-numbered PLAN usually avoids a plan collision, but an existing CONTEXT or RESEARCH path is still a collision. For non-dry-run without `--force`, any collision is fatal. Print and stop before writing anything:

```text
[FAIL] Target collision: {path} exists. Re-run with --force to overwrite.
Import refused. No files written.
```

Compute local `source_repo_id` as `sha256(git remote get-url origin)[:12]`, or `local-no-origin` when no origin exists. If it differs from the bundle, report:

```text
[WARN] Foreign source_repo_id: bundle has {bundle_source_repo_id}; local repo is {local_source_repo_id}. Import will proceed by phase_id, not original_paths.
```

Record the mismatch details for the Unit 3 `routing.handoff_chain` entry, but do not block and do not remap paths.

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

### Phase 7: Byte-for-Byte Landing

Print:

```text
-- deep-plan-import-plan [7/8] Byte-for-byte landing --
```

Continue only when `--dry-run` is absent, the Validation Contract passed, and target resolution found no fatal collision.

Create `PHASE_DIR` only after collision checks pass. When `--force` is present, overwrite existing target files only after the collision warning above. Then write section bytes captured by the Unit 1 parser:

- Write `SECTION_BYTES[PLAN]` to `PLAN_TARGET`.
- Write `SECTION_BYTES[CONTEXT]` to `CONTEXT_TARGET`.
- Write `SECTION_BYTES[RESEARCH]` to `RESEARCH_TARGET` only when `RESEARCH` is listed in `sections_included`.
- Do not write `INTEL_SUMMARY` as a phase artifact in Unit 2.
- Do not synthesize placeholder files for absent optional sections.
- Do not rewrite any path, frontmatter field, `@` reference, or content inside the landed PLAN bytes. Landing is verbatim; PORT-01 applies only to command-authored references elsewhere, never to imported plan content.

Immediately after each write, assert byte identity against the parsed section bytes:

```text
[OK] Byte identity: {target_path} matches parsed {section_name} section bytes.
```

If a byte-identity assertion fails, stop and report the affected path:

```text
[FAIL] Byte identity: {target_path} differs from parsed {section_name} section bytes.
```

The post-write, pre-amend byte-identity state is the atomic success boundary. Later Unit 3 provenance amend is best-effort metadata and must not be confused with this landing result.

Finish Unit 2 landing with:

```text
Import landing complete.
PLAN: {plan_target}
CONTEXT: {context_target}
RESEARCH: {research_target_or_not_included}
Pre-amend byte identity: verified
```

### Phase 8: Best-Effort Provenance Amend

Print:

```text
-- deep-plan-import-plan [8/8] Best-effort provenance amend --
```

Run this as a separate, auditable step after the Unit 2 byte-identity assertion. This frontmatter mutation does not violate the import invariant: import landed PLAN content byte-for-byte first; provenance is appended afterward as metadata.

Amend the landed `PLAN_TARGET` frontmatter:

1. Parse the landed PLAN frontmatter as YAML.
2. Create `routing` and `routing.handoff_chain` when missing.
3. Append one `imported` entry:

   ```yaml
   - model: "{importing_model}"
     plugin: "deep-plan@{version}"
     action: "imported"
     ts: "{UTC ISO-8601 timestamp}"
   ```

4. `importing_model` is the model/tool executing import. Use the active host model identifier when available; otherwise use `unknown-importer`.
5. `{version}` comes from `.claude-plugin/plugin.json`; if unavailable, use `unknown`.
6. Keep only the last five `routing.handoff_chain` entries. When appending a sixth entry, drop the oldest entry from the front before writing.
7. A `--no-review` import records nothing extra in the chain. Do not add a skipped-review signal.
8. Unit 4 will append a second entry with `action: reviewed` and the actual reviewer model when feasibility review runs. A reviewed import therefore consumes two of the five slots.

If the chain amend fails after successful landing, print:

```text
[WARN] Provenance amend failed: plan landed without routing.handoff_chain provenance.
Import landing remains complete; amend failed. No rollback performed.
```

Then stop with failure scoped to the amend step only. Do not delete or rewrite landed PLAN, CONTEXT, or RESEARCH files.

Mirror the import event into `.planning/config.json` `_telemetry.handoff[]` after the chain amend succeeds:

```json
{
  "phase_id": "{PHASE_ID}",
  "direction": "import",
  "source": "{source_model from bundle frontmatter}",
  "ts": "{same UTC ISO-8601 timestamp as imported chain entry}",
  "bundle_path": "{repo-relative bundle path}"
}
```

Use the Step 9.5 structured JSON parse-update-write pattern:

1. Parse `.planning/config.json` as JSON.
2. Create `_telemetry` when missing.
3. Create `_telemetry.handoff` as an array when missing.
4. Append the import object.
5. Preserve all existing `_telemetry.handoff` entries and unrelated keys.
6. Write the updated JSON back only after the parse/update succeeds.

If `.planning/config.json` is malformed, do not rewrite it. Print:

```text
[WARN] .planning/config.json malformed; import landed and handoff_chain was amended but _telemetry.handoff was skipped. Run /deep-plan-doctor.
```

Finish Unit 3 with:

```text
Provenance amend complete.
routing.handoff_chain: imported entry appended, max 5 retained
_telemetry.handoff: import event appended
```

## Validation Checklist

After editing this command file, verify:

```bash
grep -q "import-plan" commands/deep-plan-import-plan.md
grep -q "Validation Contract" commands/deep-plan-import-plan.md
grep -q "AskUserQuestion" commands/deep-plan-import-plan.md
grep -qi "fence" commands/deep-plan-import-plan.md
grep -q "init plan-phase" commands/deep-plan-import-plan.md
grep -q "force" commands/deep-plan-import-plan.md
grep -q "source_repo_id" commands/deep-plan-import-plan.md
grep -qi "byte" commands/deep-plan-import-plan.md
grep -q "handoff_chain" commands/deep-plan-import-plan.md
grep -q "_telemetry.handoff" commands/deep-plan-import-plan.md
grep -qi "best-effort" commands/deep-plan-import-plan.md
grep -q "imported" commands/deep-plan-import-plan.md
grep -q "Files written: 0" commands/deep-plan-import-plan.md
grep -q "Feasibility reviewers spawned: 0" commands/deep-plan-import-plan.md
```

For `--dry-run`, inspect that the command runs all nine Validation Contract checks, reports target collisions and foreign `source_repo_id` warnings, writes nothing, creates no directories, and spawns no feasibility reviewer or subagent.

For Unit 2, inspect that the command ignores `expected_phase_dir`, resolves from `phase_id`, refuses target collisions unless `--force` is given, warns and proceeds on foreign `source_repo_id`, writes PLAN and CONTEXT byte-for-byte, writes RESEARCH only when included, and records the post-write pre-amend byte-identity state as the atomic success boundary.

For Unit 3, inspect that provenance is a separate best-effort step after byte identity, appends an `imported` `routing.handoff_chain` entry capped to five with oldest dropped first, documents the future `reviewed` second entry, appends `_telemetry.handoff`, skips malformed config writes with a warning, records no skipped-review marker for `--no-review`, and never rolls back landed files on amend failure.

## Output Discipline

- Keep the banner and `-- deep-plan-import-plan [N/TOTAL]` step headers stable.
- Treat `skills/deep-plan/references/handoff-schema.md` as the source of truth for validation behavior.
- Never rewrite imported plan content during validation or dry-run.
- Never use `original_paths` as the primary target resolver; use `phase_id`.
- Never modify `.planning/`, global Claude, Codex, GSD, or shell configuration during `--dry-run`.
- Treat landed bytes as the atomic success boundary; provenance amend failures warn and never roll back landing.
