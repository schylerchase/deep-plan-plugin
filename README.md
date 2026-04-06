# deep-plan — Claude Code Plugin

Bridges [GSD](https://discord.gg/gsd) strategic planning with [Compound Engineering](https://github.com/compound-engineering/claude-code-plugin) implementation planning.

## Install

```bash
claude plugin add github:schylerchase/deep-plan-plugin
```

## Prerequisites

| Dependency | License | Required? | Install |
|------------|---------|-----------|---------|
| [GSD](https://discord.gg/gsd) | Unlicensed | **Yes** | Join Discord for install instructions |
| [Compound Engineering](https://github.com/compound-engineering/claude-code-plugin) | MIT | **Yes** | `claude plugin add github:compound-engineering/claude-code-plugin` |
| [RTK](https://github.com/samuelint/rtk) | MIT | Optional | `cargo install rtk` (60-90% token savings) |

## Usage

```bash
# After /gsd-discuss-phase has generated CONTEXT.md:
/deep-plan              # Auto-detects next phase to plan
/deep-plan 18           # Plan specific phase
/deep-plan 18 --review  # Plan + feasibility review
/deep-plan 18 --skip-research  # Skip CE codebase research (faster)
```

## What it does

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
5. Writes GSD-compatible PLAN.md (frontmatter with must_haves)
6. Optionally runs `feasibility-reviewer` with `--review` flag

## Why both GSD and CE?

| | GSD | CE | deep-plan |
|---|---|---|---|
| **Strategy** | Milestones, phases, ordering | - | GSD |
| **User decisions** | discuss-phase -> CONTEXT.md | brainstorm -> requirements | GSD |
| **Code research** | Basic | Deep (file paths, line counts, closures) | CE |
| **Implementation plan** | Task-level | Unit-level with test scenarios | CE |
| **Feasibility check** | - | feasibility-reviewer agent | CE |
| **Execution** | gsd-executor | ce:work | GSD |
| **Progress tracking** | STATE.md, verification | - | GSD |

## License

MIT
