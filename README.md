# deep-plan — Claude Code Plugin

Bridges [GSD](https://discord.gg/gsd-plugin) strategic planning with [Compound Engineering](https://github.com/compound-engineering/claude-code-plugin) implementation planning. Catches build-breaking issues before execution starts.

## Quick Install

If you already have GSD and Compound Engineering installed:

```bash
curl -fsSL https://raw.githubusercontent.com/schylerchase/deep-plan-plugin/main/setup.sh | bash
```

Or manually:

```bash
claude plugin add github:schylerchase/deep-plan-plugin
```

---

## Full Setup Guide

deep-plan requires two plugins that must be installed separately (they have their own licensing). Follow these steps in order.

### Step 1: Install Claude Code

If you don't already have Claude Code:

```bash
npm install -g @anthropic-ai/claude-code
```

Verify: `claude --version`

### Step 2: Install GSD (Get Shit Done)

GSD handles project strategy — milestones, phases, roadmaps, and execution tracking. deep-plan reads GSD's planning artifacts to understand what you're building.

**How to get it:** GSD is distributed through its Discord community.

1. Join the [GSD Discord](https://discord.gg/gsd-plugin)
2. Follow the install instructions in the `#getting-started` channel
3. Verify it's installed:

```bash
ls ~/.claude/get-shit-done/bin/gsd-tools.cjs
```

If that file exists, GSD is installed.

**What GSD provides to deep-plan:**
- `CONTEXT.md` — user decisions from `/gsd-discuss-phase`
- `RESEARCH.md` — technical research from `/gsd-research-phase`
- `ROADMAP.md` — phase ordering and success criteria
- Phase execution and progress tracking via `/gsd-execute-phase`

### Step 3: Install Compound Engineering (CE)

CE provides code-grounded research agents and feasibility review. deep-plan uses CE's subagents to analyze your actual codebase before writing the plan.

```bash
claude plugin add github:compound-engineering/claude-code-plugin
```

Verify:

```bash
grep -q "compound-engineering" ~/.claude/plugins/installed_plugins.json && echo "CE installed" || echo "CE not found"
```

**What CE provides to deep-plan:**
- `repo-research-analyst` — deep codebase analysis (file paths, patterns, integration points)
- `feasibility-reviewer` — catches build/deploy issues before you execute

### Step 4: Install deep-plan

```bash
claude plugin add github:schylerchase/deep-plan-plugin
```

Or use the setup script (checks all prerequisites first):

```bash
curl -fsSL https://raw.githubusercontent.com/schylerchase/deep-plan-plugin/main/setup.sh | bash
```

---

## Usage

```bash
# After /gsd-discuss-phase has generated CONTEXT.md:
/deep-plan              # Auto-detects next phase to plan
/deep-plan 18           # Plan specific phase
/deep-plan 18 --review  # Plan + feasibility review
/deep-plan 18 --skip-research  # Skip CE codebase research (faster)
```

## How It Works

```
/gsd-discuss-phase 18    <- GSD gathers user decisions -> CONTEXT.md
         |
/deep-plan 18            <- CE researches code, structures units, writes plan
         |
/gsd-execute-phase 18    <- GSD executes the CE-quality plan
```

1. Reads GSD artifacts (CONTEXT.md, RESEARCH.md, ROADMAP.md)
2. Runs CE's `repo-research-analyst` for code-grounded findings
3. Asks 0-2 scoping questions informed by GSD's locked decisions
4. Structures implementation units with file paths, test scenarios, risks
5. Writes GSD-compatible PLAN.md with verification criteria
6. Optionally runs `feasibility-reviewer` with `--review` flag

## Why Both GSD and CE?

GSD is great at strategy (what to build, in what order) and CE is great at implementation (how to build it safely). deep-plan connects them:

| | GSD | CE | deep-plan |
|---|---|---|---|
| **Strategy** | Milestones, phases, ordering | - | GSD |
| **User decisions** | discuss-phase -> CONTEXT.md | - | GSD |
| **Code research** | Basic | Deep (file paths, patterns, closures) | CE |
| **Implementation plan** | Task-level | Unit-level with test scenarios | CE |
| **Feasibility check** | - | feasibility-reviewer agent | CE |
| **Execution** | gsd-executor | - | GSD |

## Optional: RTK (Token Savings)

[RTK](https://github.com/schylerchase/rtk) reduces Claude Code token usage by 60-90% on dev operations. Not required, but recommended.

```bash
cargo install rtk
```

## License

MIT
