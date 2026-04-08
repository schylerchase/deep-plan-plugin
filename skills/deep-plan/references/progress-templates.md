# Deep Plan Progress Templates

Reference examples for the progress reporting protocol. These show what the user should see at each step during a deep-plan run.

## Full Warm-Start Example (with --review)

Phase 18 with GSD intel available and feasibility review enabled:

```
╔═══════════════════════════════════════════════════╗
║  Deep Plan — Phase 18: Extract Auth Middleware     ║
║  GSD context → CE research → Implementation plan  ║
╚═══════════════════════════════════════════════════╝

── deep-plan [2/10] Loading GSD context ──────────────
CONTEXT.md ✓ | RESEARCH.md ✓ | ROADMAP.md (phase section) ✓

── deep-plan [3/10] Gathering codebase intelligence ──
Intel: deps.json ✓ files.json ✓ apis.json ✗ arch.md ✓ (3/5 files, fresh)
Research: ARCHITECTURE.md ✓ STACK.md ✓ (warm start)

── deep-plan [4/10] Building planning brief ──────────
Locked decisions: 4 | Open questions: 2 | Seed files: 6

── deep-plan [5/10] CE deep research (warm start) ────
Pre-fed: architecture overview, 47 deps, 12 file exports
CE focusing on: integration points, code internals, gaps in GSD analysis
Launching repo-research-analyst...

── deep-plan [5/10] CE research complete ─────────────
4 new findings beyond GSD analysis | 1 gap | 2 risk signals

── deep-plan [6/10] Resolving planning questions ─────
Auto-resolved: 2 | Asking user: 1 | Deferred: 0

── deep-plan [7/10] Structuring implementation units ──
Units: 4 | Test scenarios: 16 | Must-haves: 8/6/4

── deep-plan [8/10] Plan written ─────────────────────
.planning/phases/18-extract-auth/18-01-PLAN.md
Units: 4 | Test scenarios: 16 | Must-haves: 8 truths, 6 artifacts, 4 links

── deep-plan [9/10] Feasibility review ───────────────
Launching feasibility-reviewer against PLAN.md...

── deep-plan [9/10] Feasibility review complete ──────
3 findings: 1 HIGH | 1 MODERATE | 1 LOW

── deep-plan [10/10] Complete ────────────────────────

## Deep Plan Complete

**Phase:** 18 — Extract Auth Middleware
**Plan:** 18-01-PLAN.md
**Units:** 4 implementation units
**Test scenarios:** 16 across all units
**Must-haves:** 8 truths, 6 artifacts, 4 links
**Feasibility:** 1 high (addressed), 1 moderate, 1 low

**Next:** Run `/gsd-execute-phase 18` to execute this plan.
```

## Cold-Start Variant (no GSD intel, no --review)

Phase 5 with no prior analysis:

```
╔═══════════════════════════════════════════════════╗
║  Deep Plan — Phase 5: Add User Preferences API    ║
║  GSD context → CE research → Implementation plan  ║
╚═══════════════════════════════════════════════════╝

── deep-plan [2/9] Loading GSD context ───────────────
CONTEXT.md ✓ | RESEARCH.md ✗ | ROADMAP.md (phase section) ✓

── deep-plan [3/9] Gathering codebase intelligence ───
Intel: not available | Research: not available (cold start)
Suggested: /gsd-scan for faster future planning

── deep-plan [4/9] Building planning brief ───────────
Locked decisions: 2 | Open questions: 3 | Seed files: 4

── deep-plan [5/9] CE deep research (cold start) ─────
No GSD intel to pre-feed — CE exploring from scratch
Launching repo-research-analyst...

── deep-plan [5/9] CE research complete ──────────────
23 relevant files | 12 findings (Tip: /gsd-scan before planning = faster)

── deep-plan [6/9] Resolving planning questions ──────
Auto-resolved: 3 | Asking user: 0 | Deferred: 1

── deep-plan [7/9] Structuring implementation units ──
Units: 3 | Test scenarios: 9 | Must-haves: 5/4/3

── deep-plan [8/9] Plan written ──────────────────────
.planning/phases/05-user-prefs-api/05-01-PLAN.md
Units: 3 | Test scenarios: 9 | Must-haves: 5 truths, 4 artifacts, 3 links

── deep-plan [9/9] Complete ──────────────────────────
```

## Task Tracking Pattern

After phase confirmation in Step 1, create these tasks:

```
TaskCreate: "Deep Plan: Load GSD context"
TaskCreate: "Deep Plan: Gather codebase intelligence"
TaskCreate: "Deep Plan: Build planning brief"
TaskCreate: "Deep Plan: CE deep research"
TaskCreate: "Deep Plan: Resolve planning questions"
TaskCreate: "Deep Plan: Structure implementation units"
TaskCreate: "Deep Plan: Write PLAN.md"
TaskCreate: "Deep Plan: Feasibility review"       # only if --review
TaskCreate: "Deep Plan: Handoff"
```

As each step starts, mark it `in_progress`. When done, mark `completed`.

Use `activeForm` on TaskCreate for spinner text, e.g.:
- `activeForm: "Loading GSD context"`
- `activeForm: "Running CE deep research"`
- `activeForm: "Writing PLAN.md"`

## Key Principle

Every piece of output should make it obvious that **deep-plan is orchestrating**, not GSD or CE running independently. The branded `── deep-plan [N/M]` prefix is the primary signal. The detail lines show **what deep-plan specifically contributed** (pre-feeding CE, merging findings, resolving questions) vs what would happen in a regular GSD or CE run.
