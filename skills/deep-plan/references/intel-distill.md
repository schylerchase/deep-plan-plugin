# Intel Distillation Contract

## Status

**Version:** v1 (Phase 13 - Bundle Schema + Export milestone v1.2)
**Loaded by:** `/deep-plan:export-plan` when emitting a handoff bundle with an `INTEL_SUMMARY` section.
**Cross-reference:** `skills/deep-plan/references/handoff-schema.md` defines the handoff bundle and the `## --- BUNDLE SECTION: INTEL_SUMMARY ---` marker. This file defines only the markdown content placed inside that section.

## Purpose

Deep planning intel can be 50-200 KB across `.planning/intel/*.json` and `.planning/research/*.md`. Handoff bundles need the same signal in a compact, readable form. Distillation reduces the intel payload to a **5-10 KB target** while preserving dependencies, high-value files, public APIs, architecture shape, and research conclusions.

This contract is declarative. Implementations may use any parser or language, but the emitted summary must follow the source rules, output order, size tiers, and failure behavior below.

## Source Priority

Read these paths relative to repo root. Missing paths are normal.

| Source | Required | Distilled into |
|--------|----------|----------------|
| `.planning/intel/deps.json` | no | `### Dependencies (top 20)` |
| `.planning/intel/files.json` | no | `### Files (top 30 by size + 10 recent edits)` |
| `.planning/intel/apis.json` | no | `### Public APIs` |
| `.planning/intel/arch.md` | no | `### Architecture overview` |
| `.planning/research/*.md` | no | `### Research summaries` |

Output omits a section when its source is missing, empty, or invalid. Do not emit placeholder text such as "none found".

## Output Composition Order

When present, sections must appear in this order:

```markdown
### Dependencies (top 20)
### Files (top 30 by size + 10 recent edits)
### Public APIs
### Architecture overview
### Research summaries
```

The heading text stays stable even when tier-2 or tier-3 truncation reduces counts. The heading names the default selection rule, not the final count.

## Size Contract

Target size is **5-10 KB** for the complete `INTEL_SUMMARY` markdown body.

| Tier | Trigger | Selection limits | Hard cap |
|------|---------|------------------|----------|
| tier-1 | Default | 20 deps, 30 largest files + 10 recent files, all public APIs, 50 arch lines, all eligible research summaries | 10 KB target |
| tier-2 | tier-1 output exceeds 10 KB | 15 deps, 20 largest files + 5 recent files, public APIs capped at 40 entries, 35 arch lines, 3 research summaries | 10 KB retry target |
| tier-3 | tier-2 output still exceeds 10 KB | 10 deps, 15 total files, public APIs capped at 25 entries, 20 arch lines, 2 research summaries | 15 KB worst-case cap |

Worst-case cap behavior:

- If tier-3 still exceeds 15 KB, truncate from the bottom of the composed output at the last complete line before 15 KB.
- Never cut inside a fenced code block. If the cap would cut inside a fence, drop the whole fenced block.
- Prefer dropping lower-priority tail content over rewriting earlier content. The output order already encodes priority.
- If a single public API entry is larger than 1 KB, keep only its name/signature line and first description sentence before applying the cap.

## Per-File Rules

### deps.json

Select dependencies by usage count, then sort production dependencies before development dependencies. Within each prod/dev group, sort descending by usage count, then ascending by name for deterministic ties.

Default tier-1 limit: **top 20**.

Emit one bullet per dependency:

```markdown
- `{name}` {version} ({prod|dev}, uses: {count}) - {purpose}
```

Field mapping:

| Output field | Preferred source keys | Fallback |
|--------------|-----------------------|----------|
| name | `name`, `package`, `id` | skip entry if absent |
| version | `version`, `range`, `resolved_version` | `unknown` |
| prod/dev marker | `type`, `scope`, `dev`, `is_dev_dependency` | `prod` |
| usage count | `usage_count`, `uses`, `references.length`, `imported_by.length` | `0` |
| purpose | `purpose`, `role`, `description` | derive from dependency name if obvious; otherwise `dependency` |

Secrets exclusion:

- Do not emit registry auth tokens, resolved private URLs with credentials, environment variable values, license keys, or any key matching `token`, `secret`, `password`, `credential`, `api_key`, `auth`, or `private_key`.
- Dependency names and public version ranges are safe to emit. Redact suspicious values as `[redacted]` rather than preserving them.

### files.json

Select **top 30 by size (LOC)** plus **top 10 by recent edit**, then deduplicate by path while preserving first selection order. Size-selected files appear first; recent-edit additions follow.

Emit one bullet per file:

```markdown
- `{path}` ({loc} LOC, edited {last_edited}) - {purpose}
```

Field mapping:

| Output field | Preferred source keys | Fallback |
|--------------|-----------------------|----------|
| path | `path`, `file`, `name` | skip entry if absent |
| LOC | `loc`, `lines`, `line_count` | `unknown` |
| last-edited | `last_edited`, `mtime`, `modified_at`, `updated_at` | `unknown` |
| purpose | `purpose`, `summary`, `description`, `exports[0].description` | `source file` |

Size ordering uses numeric LOC descending. Recent ordering uses timestamp descending. If timestamps are malformed, those entries sort last in the recent list but may still appear through the size list.

Do not emit file contents from `files.json`. This section is inventory only.

### apis.json

Emit all public API surface in tier-1 because API signatures are signal-dense and often define integration risk. Include functions, classes, exported constants with behavioral meaning, CLI commands, public hooks, and public configuration fields.

Exclude private or internal entries when the source provides a visibility marker such as `private`, `internal`, `_name`, or `@internal`.

Emit one bullet per API:

```markdown
- `{name}{signature}` - {description}
```

Field mapping:

| Output field | Preferred source keys | Fallback |
|--------------|-----------------------|----------|
| name | `name`, `symbol`, `export` | skip entry if absent |
| signature | `signature`, `params`, `type` | empty string |
| description | `description`, `summary`, `doc`, `purpose` | `public API` |
| visibility | `visibility`, `access`, `public`, `internal` | public unless name starts `_` |

Tier-2 caps this section at 40 entries. Tier-3 caps it at 25 entries. Ranking under caps:

1. Explicit `public` exports used by files in scope.
2. CLI commands and exported functions/classes.
3. Types/interfaces/config fields.
4. Constants.

### arch.md

Emit the first **50 lines verbatim** in tier-1. The top of `arch.md` is expected to hold the highest-signal overview, layers, and data flow.

Tier-2 emits first 35 lines. Tier-3 emits first 20 lines.

Rules:

- Preserve markdown text exactly for selected lines.
- Strip trailing blank lines after selection.
- If the selected region contains secrets or credentials, redact values before emission.
- If the file is shorter than the limit, emit the whole file.

### research/*.md

Eligible research files are all markdown files under `.planning/research/`, with these priority names first when present:

1. `ARCHITECTURE.md`
2. `STACK.md`
3. `STRUCTURE.md`

Other research markdown files may follow alphabetically if size budget remains. Skip `CONCERNS.md` and `CONVENTIONS.md` by default for handoff summaries, matching `intel-sources.md`: downstream agents should form their own risk and convention read from live code.

For each selected file, emit:

```markdown
#### {title}

{first paragraph}
```

Title extraction:

- Prefer the first markdown H1 (`# Title`).
- Fallback to filename without extension.

Paragraph extraction:

- Use the first non-empty paragraph after the title.
- Stop at the next blank line, heading, table, list block, or fenced code block.
- Do not include more than 120 words per research file in tier-1.
- Tier-2 keeps 3 research summaries. Tier-3 keeps 2.

## Failure Handling

### Missing Files

Missing intel or research files are not errors. Omit the corresponding output section entirely. Continue with remaining sources.

Example: if `.planning/intel/apis.json` is absent, the output jumps from `### Files...` to `### Architecture overview` when `arch.md` exists.

### Malformed JSON

Malformed `deps.json`, `files.json`, or `apis.json` must not abort bundle export. Skip the malformed source and record a warning in export command output:

```text
[WARN] intel-distill: skipped .planning/intel/deps.json (malformed JSON)
```

Warnings are command output only. They do not appear inside `INTEL_SUMMARY`, because bundles should remain clean and portable.

### Unsupported JSON Shape

If JSON parses but the expected array/object entries cannot be found, treat that source as empty and warn:

```text
[WARN] intel-distill: skipped .planning/intel/files.json (unsupported shape)
```

Supported shapes:

- Array of entries.
- Object with one of `dependencies`, `deps`, `files`, `apis`, `exports`, `items`, or `entries`.
- Object map keyed by name/path, where each value is an entry.

### Secret Handling

Secrets are explicitly excluded from `INTEL_SUMMARY`, even if present in intel files. Redact suspicious values before size calculation so caps cannot preserve secret material.

Redact values from keys matching this case-insensitive pattern:

```text
token|secret|password|passwd|credential|api[_-]?key|auth|private[_-]?key|session|cookie
```

Also redact URL userinfo (`https://user:pass@example.com`) and PEM/private key blocks. Emit `[redacted]` if the surrounding line is otherwise useful; drop the line if the secret is the only useful content.

## Worked Example

Deep-plan-plugin-style distillation output for `## --- BUNDLE SECTION: INTEL_SUMMARY ---`:

```markdown
### Dependencies (top 20)

- `node` unknown (prod, uses: 6) - command helpers and JSON/YAML parsing in shell-facing workflows
- `bash` unknown (prod, uses: 5) - deterministic eval scripts and command orchestration
- `git` unknown (prod, uses: 4) - source metadata, dirty tree checks, and handoff provenance
- `rg` unknown (prod, uses: 3) - fast repository discovery in command instructions
- `python` unknown (dev, uses: 1) - optional validation snippets in planning support scripts

### Files (top 30 by size + 10 recent edits)

- `skills/deep-plan/SKILL.md` (420 LOC, edited 2026-04-30) - main deep-plan workflow and integration checkpoints
- `skills/deep-plan/references/scoring.md` (360 LOC, edited 2026-04-30) - model routing score contract
- `skills/deep-plan/references/config.md` (300 LOC, edited 2026-04-30) - persisted configuration schema and validation behavior
- `commands/deep-plan-doctor.md` (260 LOC, edited 2026-04-29) - health check command pattern for banners and remediation
- `commands/deep-plan-configure.md` (210 LOC, edited 2026-04-29) - setup wizard and text-mode argument handling
- `skills/deep-plan/references/plan-template.md` (145 LOC, edited 2026-04-30) - PLAN.md frontmatter and body contract

### Public APIs

- `/deep-plan` - creates phase plans from discussion context and codebase intelligence
- `/deep-plan-doctor` - validates installation health, config schema, and project readiness
- `/deep-plan-configure` - writes `.planning/config.json` model routing preferences
- `/deep-plan:export-plan [phase] --target=<target> --out=<path> --minimal` - emits portable handoff bundles
- `deep_plan.model_routing.schema_version` - config schema version, currently literal `1`
- `routing.handoff_chain[]` - optional PLAN.md provenance entries for cross-model handoff

### Architecture overview

# Deep Plan Plugin Architecture

Deep Plan layers GSD phase planning with CE-quality research and validation. Commands live in `commands/`, reference contracts live in `skills/deep-plan/references/`, and the main skill loads references lazily as each workflow step needs them.

Planning artifacts are stored under `.planning/phases/{phase}/`. Cross-model export emits a single markdown bundle under `.planning/handoff/` with YAML frontmatter and line-anchored section markers.

### Research summaries

#### Architecture

The plugin is file-contract driven: command markdown defines operator workflow, reference markdown defines stable schemas, and tests assert deterministic behavior with shell checks.

#### Stack

The project uses markdown command specs, shell evaluation scripts, Node helper snippets where structured parsing is needed, and git metadata for provenance.

#### Structure

Repository structure separates command entry points from skill references so agents can lazy-load only the contracts needed for the current phase.
```

The example is intentionally compact, roughly 5-7 KB when rendered with realistic entries, and fits directly inside the `INTEL_SUMMARY` section defined by `handoff-schema.md`.
