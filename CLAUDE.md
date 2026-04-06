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

## What "Stack" Means for a Claude Code Plugin
## Recommended Stack
### Plugin Component Type: Skill (not Command)
| Decision | Choice | Why |
|----------|--------|-----|
| Primary component format | `skills/<name>/SKILL.md` | Current standard. `commands/` is explicitly documented as legacy. |
| Invocation style | Slash command via skill frontmatter | Skills with `description`, `argument-hint`, and `allowed-tools` frontmatter fields behave identically to commands |
| Secondary components | None for MVP | No agents, hooks, or MCP needed — the skill invokes CE agents via `Task` and GSD tools via `Bash` |
### Manifest
| Field | Value | Required? |
|-------|-------|-----------|
| `name` | `deep-plan` | Yes — kebab-case, unique |
| `version` | `0.1.0` | Recommended |
| `description` | 50-200 chars | Recommended |
| `author.name` | `schylerryan` | Recommended |
| `keywords` | `["gsd", "planning", "ce"]` | Optional, helps discovery |
### Skill Frontmatter Fields
### Supporting Files Structure
- `commands/` — legacy format, skip entirely
- `agents/` — deep-plan delegates to CE agents via `Task`, doesn't define its own
- `hooks/` — no event-driven automation needed
- `.mcp.json` — no external service integration
## File Naming Conventions
| Item | Convention | Example |
|------|------------|---------|
| Plugin name | kebab-case | `deep-plan-plugin` |
| Plugin manifest name field | kebab-case, no `plugin` suffix | `deep-plan` |
| Skill directory | kebab-case matching the slash command name | `deep-plan/` |
| Skill file | Always `SKILL.md` (uppercase) | `SKILL.md` |
| Reference files | kebab-case `.md` | `plan-format.md` |
| Script files (if any) | kebab-case with extension | `validate-context.sh` |
## SKILL.md Writing Conventions
### Description Field (frontmatter)
### SKILL.md Body
- Write in **imperative/infinitive form** — "Extract the phase number from arguments" not "You should extract..."
- Keep body to **1,500–2,000 words** (hard max ~5,000 before context bloat matters)
- Move detailed content to `references/` files — SKILL.md body is always loaded; references are loaded on demand
- Body must **explicitly reference** any files in `references/` so Claude knows they exist
### Progressive Disclosure Tiers
| Tier | What loads | When |
|------|-----------|------|
| Metadata (name + description) | Always | Skill matching |
| SKILL.md body | When skill triggers | Execution |
| `references/*.md` | On demand by Claude | If needed |
| `scripts/` | Can execute without reading | Deterministic ops |
## Distribution and Installation
### Install Command Format
### Scopes
| Scope | Behavior | When Used |
|-------|----------|-----------|
| `user` | Available in all projects | Default for `claude plugin add` |
| `project` | Available in specific project dir | For project-specific installs |
### Install Path
## Development Workflow
### Local Testing
# Test with plugin-dir flag (doesn't install, just loads)
# Or copy/symlink directly to skills dir for live iteration
### No Build Step
### Validation
## What NOT to Do
| Anti-pattern | Why Bad | What to Do Instead |
|--------------|---------|-------------------|
| Use `commands/` for new slash commands | Explicitly deprecated in official docs | Use `skills/<name>/SKILL.md` with invocation frontmatter |
| Write SKILL.md body > 5,000 words | Bloats context window on every trigger | Move detail to `references/` files |
| Hardcode paths in hooks/scripts | Breaks on different install locations | Use `${CLAUDE_PLUGIN_ROOT}` |
| Define agents inside the plugin | CE and GSD already have agents; duplicating creates conflicts | Use `Task` to invoke CE agents, `Bash` for GSD tools |
| Use `allowed-tools: ["*"]` | Grants unnecessary permissions | List only what the skill actually needs |
| Add `commands/` AND `skills/` for same thing | Confusing, redundant | Skills only |
| Write description in first person or without triggers | Skill won't auto-activate on intent | Third person + specific trigger phrases |
## Dependency Declarations
| Dependency | Type | How Referenced in Skill |
|------------|------|------------------------|
| GSD (`get-shit-done`) | Required | `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs"` via `Bash` |
| Compound Engineering plugin | Required | `Task compound-engineering:research:repo-research-analyst(...)` |
| RTK | Optional | README only, skill works without it |
## Confidence Assessment
| Area | Confidence | Basis |
|------|------------|-------|
| Plugin directory structure | HIGH | Verified against `plugin-dev` official docs + 3 installed plugins |
| Skill vs command format | HIGH | Explicit deprecation notice in official `plugin-dev` skill |
| SKILL.md frontmatter fields | HIGH | Verified in `plugin-dev/skills/skill-development/SKILL.md` |
| Writing conventions (imperative, third-person) | HIGH | Explicit rules with examples in official docs |
| Progressive disclosure (SKILL.md + references/) | HIGH | Documented and observed in CE plugin skills |
| Install command format | HIGH | Verified in own README and marketplace config |
| Local dev workflow | MEDIUM | Inferred from install path observation; no explicit docs found |
| Dependency declaration conventions | MEDIUM | Community convention observed in READMEs; no formal spec |
## Sources
- `/Users/schylerryan/.claude/plugins/cache/claude-plugins-official/plugin-dev/unknown/skills/skill-development/SKILL.md` — canonical skill conventions
- `/Users/schylerryan/.claude/plugins/cache/claude-plugins-official/plugin-dev/unknown/skills/plugin-structure/SKILL.md` — plugin directory structure
- `/Users/schylerryan/.claude/plugins/cache/claude-plugins-official/plugin-dev/unknown/skills/plugin-structure/references/manifest-reference.md` — full plugin.json field reference
- `/Users/schylerryan/.claude/plugins/cache/claude-plugins-official/plugin-dev/unknown/commands/create-plugin.md` — plugin creation workflow (allowed-tools format)
- `/Users/schylerryan/.claude/plugins/cache/compound-engineering-plugin/compound-engineering/2.62.1/.claude-plugin/plugin.json` — real production plugin manifest
- `/Users/schylerryan/.claude/plugins/cache/schylerchase-plugins/code-optimizer/0.1.0/` — user's own community plugin as reference
- `/Users/schylerryan/.claude/plugins/installed_plugins.json` — plugin install paths and scopes
- `/Users/schylerryan/.claude/plugins/known_marketplaces.json` — marketplace distribution model
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
