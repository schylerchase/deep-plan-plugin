<!-- GSD:project-start source:PROJECT.md -->
## Project

**Deep Plan Plugin**

A Claude Code plugin that bridges GSD's strategic phase context with CE-style implementation planning. It reads GSD artifacts (CONTEXT.md, RESEARCH.md, ROADMAP.md), runs Compound Engineering analysis with feasibility review, and produces implementation plans that catch build-breaking issues GSD planning alone misses. Published as a community-installable plugin at github:schylerchase/deep-plan-plugin.

**Core Value:** Catch implementation-breaking issues before execution starts — the plan should never produce code that doesn't build.

### Constraints

- **Single file**: Skill must remain a single SKILL.md — Claude Code plugin architecture
- **Read-only GSD**: deep-plan reads GSD artifacts but should not modify GSD state (except marking phases complete)
- **No dependencies**: Plugin has no runtime dependencies beyond Claude Code itself
- **Community-friendly**: Must work for anyone with GSD installed, not just icarus-calculator
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

Claude Code plugin — no runtime, no build step, no package manager. Structure only:

- **Manifest:** `.claude-plugin/plugin.json` — required for plugin discovery
- **Skills:** `skills/deep-plan/SKILL.md` — implementation planning skill
- **Skills:** `skills/frontend-design/SKILL.md` — UX-first frontend design methodology
- **Commands:** `commands/ux-review.md` — UX review with severity-rated findings and fix workflow
- **References:** `skills/deep-plan/references/` — progressive disclosure for detailed content
- **Full research:** `.planning/research/STACK.md` — complete stack analysis with confidence ratings
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

- Skill body uses imperative form ("Extract the phase" not "You should extract")
- SKILL.md body stays focused on flow and decisions; verbose templates, prompts, and reference data live in `references/` (lazy-loaded)
- File naming: kebab-case for everything except `SKILL.md` (uppercase)
- Commands use same frontmatter conventions as skills (`name`, `description`, `allowed-tools`)
<!-- GSD:conventions-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

## Integration Awareness

Deep-plan composes with four optional/required tools. Behavioral contracts:

- **GSD (required)**: Read-only. Never modify CONTEXT.md, RESEARCH.md, or ROADMAP.md beyond flipping `[ ]` → `[x]` on phase completion. Plugin reads `.planning/intel/` and `.planning/research/` for warm-start context. Prereq check at SKILL.md Step 2.
- **Compound Engineering (required)**: Spawn `repo-research-analyst` for code research (Step 6) and `feasibility-reviewer` for `--review` flag (Step 11). Warm-start when GSD intel exists, cold-start otherwise. Prompt bodies in `skills/deep-plan/references/ce-prompts.md`.
- **Caveman (optional)**: Detect via `claude plugin list | grep caveman@caveman` at Step 1. When present, build override map for v2 signals (HIGH feasibility findings, AskUserQuestion blocks, mid-flight pivots) forcing full prose. Hard rule: `.md` artifacts written via Write tool always use full prose regardless of caveman mode. Spec: `skills/deep-plan/references/caveman-rule.md`.
- **RTK (optional)**: When installed, prefer `rtk <cmd>` over raw shell for git/grep/find/cat/read/wc operations to reduce token consumption 60-90%. Hook at `~/.claude/hooks/rtk-rewrite.sh` rewrites transparently — no skill code change needed.

Doctor command (`/deep-plan-doctor`) verifies all four. Required tools fail the install check; optional tools surface as `[INFO]`.
