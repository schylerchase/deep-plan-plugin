# GSD Intelligence Sources

Loaded on demand from SKILL.md Step 4. Documents which files to read, in what priority, and how to compose the `gsd_knowledge` block.

## Why this exists

GSD produces codebase analysis that CE would otherwise rediscover from scratch. Gathering this first gives CE a warm start — it spends tokens on depth instead of discovery.

**Check each source in order. Read what exists, skip what doesn't.**

## 4a. Intel files (`.planning/intel/`)

If the directory exists, read these structured files:

- `deps.json` → dependency graph with versions, types, usage pointers
- `files.json` → per-file export inventory with usage counts
- `apis.json` → public API signatures and deprecation markers
- `stack.json` → framework/library versions and roles
- `arch.md` → architecture overview in plain markdown

Check staleness: read `.planning/intel/.last-refresh.json` for `timestamp`. If older than 24 hours, flag: `"⚠️ Intel is {N} days old — CE will verify against live code"`

## 4b. Research files (`.planning/research/`)

If the directory exists, read:

- `ARCHITECTURE.md` → layers, patterns, data flow (highest CE overlap)
- `STACK.md` → tech decisions with confidence ratings
- `STRUCTURE.md` → file/module organization, entry points

Skip these (CE should discover independently for fresh perspective):

- `CONCERNS.md` — CE finding its own pitfalls is more valuable than echoing known ones
- `CONVENTIONS.md` — CE should infer from actual code, not pre-digested summaries

## 4c. Scope boundaries (always read)

- `.planning/REQUIREMENTS.md` → especially "Out of Scope" items (prevents CE from over-researching)
- `.planning/ROADMAP.md` → phase section only (goals, success criteria, dependencies)

## 4d. If nothing exists

If neither `.planning/intel/` nor `.planning/research/` exist, suggest:

```
No codebase analysis found. For better results, consider running one of:
  /gsd-scan          — quick analysis (2-3 min)
  /gsd-map-codebase  — deep analysis (5-10 min)

Continue without pre-analysis? CE will explore from scratch (higher token usage).
```

**If text_mode is active**, present as a plain-text numbered list instead of AskUserQuestion:

```
1. Continue anyway
2. Run /gsd-scan first
```

Type a number to choose:

Parse the user's response (number or free text describing their choice). If invalid, re-prompt.

**Otherwise**, use AskUserQuestion with options:

- "Continue anyway" — proceed, CE does full cold-start exploration
- "Run /gsd-scan first" — launch scan, then return here

## Compose the intelligence summary

Build a structured `gsd_knowledge` block from everything gathered:

```
## Known Codebase Intelligence (from GSD)

### Architecture
{from ARCHITECTURE.md or arch.md — layers, key patterns, data flow}

### Dependencies  
{from deps.json — name, version, role for each relevant dep}

### File Structure
{from files.json or STRUCTURE.md — key files, their exports, organization}

### API Surface
{from apis.json — relevant method signatures and stability}

### Tech Stack
{from stack.json or STACK.md — frameworks, versions, roles}

### Scope Boundaries
- Out of scope: {from REQUIREMENTS.md}
- Deferred: {from CONTEXT.md <deferred> section}

### Freshness
- Intel: {fresh / stale / not available}
- Research: {available / not available}
```
