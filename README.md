# deep-plan — Claude Code Plugin

Bridges [GSD](https://discord.gg/gsd-plugin) strategic planning with [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) implementation planning. Catches build-breaking issues before execution starts.

## Quick Install

If you already have GSD and Compound Engineering installed:

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/schylerchase/deep-plan-plugin/main/setup.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/schylerchase/deep-plan-plugin/main/setup.ps1 | iex
```

**Or manually (all platforms):**
```bash
claude plugin marketplace add schylerchase/deep-plan-plugin
claude plugin install deep-plan
```

### Troubleshooting

**Windows — `No ED25519 host key is known for github.com`**

Fresh Windows installs often hit this because SSH has never connected to GitHub before. Two fixes:

**Option A — Use the explicit HTTPS URL (easiest):**
```bash
claude plugin marketplace add https://github.com/schylerchase/deep-plan-plugin
claude plugin install deep-plan
```

**Option B — Trust GitHub's SSH host key (PowerShell):**
```powershell
ssh-keyscan -t ed25519,rsa github.com >> "$env:USERPROFILE\.ssh\known_hosts"
```

Then re-run the install.

---

## Full Setup Guide

deep-plan requires two plugins that must be installed separately (they have their own licensing). Follow these steps in order.

### Step 1: Install Claude Code

If you don't already have Claude Code:

**macOS / Linux:**
```bash
npm install -g @anthropic-ai/claude-code
```

**Windows:**
```powershell
winget install Anthropic.ClaudeCode
```
Requires [Git for Windows](https://git-scm.com/downloads/win) (provides Git Bash, which Claude Code uses internally).

Verify (all platforms): `claude --version`

### Step 2: Install GSD (Get Shit Done)

GSD handles project strategy — milestones, phases, roadmaps, and execution tracking. deep-plan reads GSD's planning artifacts to understand what you're building.

**How to get it:** GSD is distributed through its Discord community.

1. Join the [GSD Discord](https://discord.gg/gsd-plugin)
2. Follow the install instructions in the `#getting-started` channel
3. Verify it's installed:

**macOS / Linux:**
```bash
ls ~/.claude/get-shit-done/bin/gsd-tools.cjs
```

**Windows (PowerShell):**
```powershell
Test-Path "$env:USERPROFILE\.claude\get-shit-done\bin\gsd-tools.cjs"
```

If that file exists (or returns `True`), GSD is installed.

**What GSD provides to deep-plan:**
- `CONTEXT.md` — user decisions from `/gsd-discuss-phase`
- `RESEARCH.md` — technical research from `/gsd-research-phase`
- `ROADMAP.md` — phase ordering and success criteria
- Phase execution and progress tracking via `/gsd-execute-phase`

### Step 3: Install Compound Engineering (CE)

CE provides code-grounded research agents and feasibility review. deep-plan uses CE's subagents to analyze your actual codebase before writing the plan.

```bash
claude plugin marketplace add EveryInc/compound-engineering-plugin
claude plugin install compound-engineering
```

Verify:

**macOS / Linux:**
```bash
grep -q "compound-engineering" ~/.claude/plugins/installed_plugins.json && echo "CE installed" || echo "CE not found"
```

**Windows (PowerShell):**
```powershell
if (Select-String -Quiet "compound-engineering" "$env:USERPROFILE\.claude\plugins\installed_plugins.json") { "CE installed" } else { "CE not found" }
```

**What CE provides to deep-plan:**
- `repo-research-analyst` — deep codebase analysis (file paths, patterns, integration points)
- `feasibility-reviewer` — catches build/deploy issues before you execute

**What deep-plan provides on its own:**
- `plan-validator` — validates PLAN.md structure against GSD executor expectations (frontmatter, task XML, must_haves, @-references)
- `ux-reviewer` — evaluates frontend code for UX quality (state design, accessibility, interaction patterns, visual design)
- `frontend-design` — UX-first design methodology skill (information architecture, state design, accessibility, performance)
- `/ux-review` — command that runs the reviewer and offers to fix findings

### Step 4: Install deep-plan

```bash
claude plugin marketplace add schylerchase/deep-plan-plugin
claude plugin install deep-plan
```

Or use the setup script (checks all prerequisites first):

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/schylerchase/deep-plan-plugin/main/setup.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/schylerchase/deep-plan-plugin/main/setup.ps1 | iex
```

---

## Usage

### Implementation Planning

```bash
# After /gsd-discuss-phase has generated CONTEXT.md:
/deep-plan              # Auto-detects next phase to plan
/deep-plan 18           # Plan specific phase
/deep-plan 18 --review  # Plan + feasibility review
/deep-plan 18 --skip-research  # Skip CE codebase research (faster)
```

### UX Review

```bash
/ux-review                    # Review frontend files in current directory
/ux-review src/components/    # Review a specific directory
/ux-review src/pages/App.tsx  # Review a specific file
```

Scans frontend code for UX issues across six dimensions — state design, accessibility, interaction patterns, information architecture, visual design, and performance. Produces a severity-rated findings report (Critical/Warning/Minor) with numbered IDs, then offers to fix them:

- **Fix all** — applies every fix in priority order
- **Critical only** — fixes only the critical issues
- **Pick specific** — you choose which IDs to fix (e.g., C1, W3, M2)
- **Skip** — just the report, no changes

## How It Works

```
/gsd-discuss-phase 18    <- GSD gathers user decisions -> CONTEXT.md
         |
/deep-plan 18            <- CE researches code, structures units, writes plan
         |
/gsd-execute-phase 18    <- GSD executes the CE-quality plan
```

1. **Reads GSD artifacts** (CONTEXT.md, RESEARCH.md, ROADMAP.md) — extracts locked decisions, scope boundaries, and seed files
2. **Gathers codebase intelligence** — reads GSD's intel files (`deps.json`, `files.json`, `apis.json`, `arch.md`) and research docs (`ARCHITECTURE.md`, `STACK.md`) so CE doesn't rediscover what GSD already knows
3. **Runs CE's `repo-research-analyst`** with a targeted prompt — when GSD intel exists, CE skips architecture/dependency discovery and focuses on deep code tracing, integration points, gaps, and risk signals
4. **Asks 0-2 scoping questions** informed by GSD's locked decisions — only asks about things that materially affect scope or architecture
5. **Structures implementation units** with file paths, test scenarios, patterns to follow, and verification criteria
6. **Writes GSD-compatible PLAN.md** with must-haves (behavioral truths, artifact checks, traceability links)
7. **Validates plan structure** with the `plan-validator` agent — catches frontmatter errors, broken @-references, and invalid task XML before execution
8. **Optionally runs `feasibility-reviewer`** with `--review` flag — catches build/deploy issues before execution starts

### Progress Reporting

deep-plan brands every step so you always know it's driving, not GSD or CE independently:

```
╔═══════════════════════════════════════════════════╗
║  Deep Plan — Phase 18: Extract Auth Middleware     ║
║  GSD context → CE research → Implementation plan  ║
╚═══════════════════════════════════════════════════╝

── deep-plan [2/11] Loading GSD context ──────────────
CONTEXT.md ✓ | RESEARCH.md ✓ | ROADMAP.md (phase section) ✓

── deep-plan [3/11] Gathering codebase intelligence ──
Intel: deps.json ✓ files.json ✓ apis.json ✗ arch.md ✓ (3/5 files, fresh)
Research: ARCHITECTURE.md ✓ STACK.md ✓ (warm start)

── deep-plan [5/11] CE deep research (warm start) ────
Pre-fed: architecture overview, 47 deps, 12 file exports
CE focusing on: integration points, gaps in GSD analysis
Launching repo-research-analyst...

── deep-plan [5/11] CE research complete ─────────────
4 new findings beyond GSD analysis | 1 gap | 2 risk signals

── deep-plan [8/11] Plan written ─────────────────────
.planning/phases/18-extract-auth/18-01-PLAN.md
Units: 4 | Test scenarios: 16 | Must-haves: 8 truths, 6 artifacts, 4 links

── deep-plan [9/11] Validation complete ──────────────
Result: PASS | Errors: 0 | Warnings: 0
```

Each step also creates a task in Claude Code's task list, so you can track progress even when text scrolls by. The step counter adapts: `[N/11]` with `--review`, `[N/10]` without.

### Warm-Start vs Cold-Start

If you've run `/gsd-scan` or `/gsd-map-codebase` before planning, deep-plan operates in **warm-start mode**: it pre-feeds GSD's analysis to CE, so CE spends tokens on depth (actual function signatures, runtime data flow, integration closures) instead of breadth (file tree enumeration, dependency listing, architecture overview).

Without prior analysis, deep-plan falls back to **cold-start mode**: CE explores from scratch, which works fine but uses more tokens. The skill will suggest running `/gsd-scan` first if no analysis exists.

## What You Get

deep-plan produces a PLAN.md that GSD's executor can run directly. Each plan contains:

**Implementation units** — atomic changes ordered by dependency:
```
Unit 1: Extract validation constants
  Goal: Move hardcoded values to a shared constants file
  Files: src/constants.ts (create), src/validator.ts (modify)
  Patterns to follow: see src/config.ts for existing constant patterns
  Test scenarios:
    - Happy path: imported constants match original values
    - Edge case: constants used across multiple modules resolve correctly
    - Integration: validator produces identical output after extraction
  Verification: all existing tests pass, no hardcoded values remain in validator
```

**Must-haves** — machine-checkable assertions for GSD's verifier:
- `truths` — behavioral assertions ("User can submit form with validation")
- `artifacts` — file existence with searchable content tokens
- `key_links` — traceability from source to destination (e.g., "constant defined in X, imported in Y")

**Threat model** — STRIDE analysis when the phase touches auth, user input, or external APIs (omitted otherwise).

## Why Both GSD and CE?

GSD is great at strategy (what to build, in what order) and CE is great at implementation (how to build it safely). deep-plan connects them:

| | GSD | CE | deep-plan |
|---|---|---|---|
| **Strategy** | Milestones, phases, ordering | - | GSD |
| **User decisions** | discuss-phase -> CONTEXT.md | - | GSD |
| **Codebase intel** | File maps, deps, APIs, arch | - | Pre-fed to CE |
| **Code research** | Basic | Deep (file paths, patterns, closures) | CE (targeted) |
| **Implementation plan** | Task-level | Unit-level with test scenarios | CE |
| **Verification** | - | - | Must-haves (truths, artifacts, links) |
| **Plan validation** | - | - | plan-validator agent (format + structure) |
| **UX review** | - | - | ux-reviewer agent + frontend-design skill |
| **Feasibility check** | - | feasibility-reviewer agent | CE |
| **Execution** | gsd-executor | - | GSD |

## Optional: RTK (Token Savings)

[RTK](https://github.com/schylerchase/rtk) reduces Claude Code token usage by 60-90% on dev operations. Not required, but recommended.

```bash
cargo install rtk
```

## License

MIT
