---
name: deep-plan-doctor
description: Diagnose deep-plan install health and project readiness. Use when deep-plan feels broken, when checking if a fresh install is complete, or before running /deep-plan for the first time in a project. Runs install checks (Claude Code, GSD, CE, deep-plan agents) and project checks (GSD artifacts, phase readiness, warm-start data), prints a structured remediation report, and offers to auto-fix fixable issues.
argument-hint: '[--install | --project]'
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

# /deep-plan-doctor Command

Run a health check on the user's deep-plan install and (if applicable) the current GSD project. Print a structured report with remediation steps and offer to auto-fix issues where possible.

This is a **diagnostic-only** command by default — it reads state and reports, and only applies fixes after explicit user approval in Phase 5.

## Usage

- `/deep-plan-doctor` — run all applicable checks (install + project if in a GSD project dir)
- `/deep-plan-doctor --install` — only run Tier 1 install checks, skip project checks
- `/deep-plan-doctor --project` — only run Tier 2 project checks, skip install checks

## Instructions

### Phase 1: Banner

Print the deep-plan-branded banner so the user knows which tool is running:

```
╔═════════════════════════════════════════════════════╗
║  Deep Plan Doctor — Install + Project Health         ║
║  Claude Code · GSD · CE · deep-plan · phase context  ║
╚═════════════════════════════════════════════════════╝
```

Parse the argument. If `--install`, skip Phase 3. If `--project`, skip Phase 2. Otherwise run both.

### Phase 2: Tier 1 — Install Health

Tier 1 checks work from any working directory (no GSD project required).

For each check, print a result line formatted as:

```
── deep-plan-doctor [N/6] <check name> ──────────────
[OK|WARN|FAIL] <one-line result>
<remediation if not OK>
```

**Check 1/6: Claude Code version**
- Run `claude --version` via Bash.
- Parse major version. Pass if `major >= 2`.
- On FAIL: `Install or upgrade Claude Code: npm install -g @anthropic-ai/claude-code (macOS/Linux) or winget install Anthropic.ClaudeCode (Windows).`

**Check 2/6: GSD installed**
- Test for file `$HOME/.claude/get-shit-done/bin/gsd-tools.cjs` via Bash (`test -f`).
- On FAIL: `GSD is distributed via the GSD Discord community. Join the Discord and follow the install steps in #getting-started. (Not auto-fixable — Discord-gated by design.)`

**Check 3/6: Compound Engineering (CE) installed**
- Run `claude plugin list` via Bash.
- Search output for `compound-engineering@compound-engineering-plugin` or any line matching `compound-engineering`.
- On FAIL: `claude plugin marketplace add EveryInc/compound-engineering-plugin && claude plugin install compound-engineering`

**Check 4/6: CE agents discoverable**
- Check if `repo-research-analyst` and `feasibility-reviewer` agents exist (these are CE's core agents that deep-plan spawns).
- If the context doesn't allow agent introspection, mark as `[WARN] Could not introspect agents — test by running /deep-plan --review on a phase to verify CE agent availability.`
- On FAIL: `CE is installed but agents aren't discoverable. Try: claude plugin update compound-engineering, or restart Claude Code.`

**Check 5/6: deep-plan agents discoverable**
- Check if `plan-validator` and `ux-reviewer` agents exist (bundled with deep-plan in agents/).
- On FAIL: `deep-plan is running but its agents aren't discoverable. Try: claude plugin update deep-plan, or restart Claude Code.`

**Check 6/6: deep-plan skills loaded**
- Verify the `deep-plan` skill and `frontend-design` skill appear loaded (these are the plugin's two skills). If skill listing is not directly introspectable, note this check as `[WARN]` with the same "restart Claude Code" remediation as above.

After Tier 1, print a summary line:

```
── Tier 1 complete: {pass}/6 passing ──────────────
```

If **Check 1, 2, or 3 failed** (these are install-blocking), ask:

> Question: "Your install has {count} critical issue(s). Continue to project checks?"
>
> Options:
> - **Stop — install is broken** — "I'll stop here so you can fix the install first"
> - **Continue anyway** — "Run project checks even though install has issues"

If the user stops, skip to Phase 4 (print the report with the install issues).

### Phase 3: Tier 2 — Project Health

Only run if Tier 1 passed, or user chose to continue anyway, or `--project` was passed.

**Detect GSD project:**
- Glob or Read for `.planning/ROADMAP.md` in the current working directory.
- If not found, print `[SKIP] Not inside a GSD project — no project checks to run.` and jump to Phase 4.

If found, run these checks with the same `[N/5]` output format:

**Check 1/5: ROADMAP.md parses**
- Read `.planning/ROADMAP.md`.
- Look for at least one phase heading (e.g., `## Phase 18:` or similar — match common GSD roadmap formats).
- On FAIL: `ROADMAP.md exists but may be malformed. Run /gsd-health for diagnosis.`

**Check 2/5: Identify next phase to plan**
- Scan ROADMAP.md for the first uncompleted/unplanned phase (look for unchecked boxes, phase entries without a PLAN.md reference, or whatever convention the roadmap uses).
- Report: `Next phase: {N} — {title}` or `[OK] All phases complete, nothing to plan.`
- This is informational, never fails — but captures the phase number used by subsequent checks.

**Check 3/5: CONTEXT.md exists for target phase**
- Using the phase number from Check 2, look for `CONTEXT.md` under `.planning/phases/{phase_dir}/` (try common dir patterns: `{N}-*`, `phase-{N}-*`).
- If Check 2 reported nothing to plan, mark this check `[OK] No target phase`.
- On FAIL: `CONTEXT.md required before planning phase {N}. Run /gsd-discuss-phase {N} first.`

**Check 4/5: RESEARCH.md freshness**
- Check for `RESEARCH.md` in the same phase directory.
- If missing: `[WARN] No RESEARCH.md — deep-plan will operate in cold-start mode (more tokens, slower). Run /gsd-research-phase {N} for warm-start.`
- If present, check modification time via `stat` or `ls -l`. If older than 14 days: `[WARN] RESEARCH.md is {age} days old — consider re-running /gsd-research-phase {N}.`
- Otherwise: `[OK] RESEARCH.md present and fresh`

**Check 5/5: GSD warm-start intel**
- Glob for `.planning/intel/deps.json`, `files.json`, `apis.json`, `arch.md`.
- Report: `{present}/4 intel files present`.
- If 0: `[WARN] No intel — warm-start unavailable. Run /gsd-scan or /gsd-map-codebase for faster CE research.`
- If any present: `[OK] Warm-start available ({present}/4 files)`

### Phase 4: Remediation Report

Compile all findings into a structured summary:

```
── deep-plan-doctor Summary ──────────────────────────

Install Health: {tier1_pass}/6  — {HEALTHY|ISSUES|BROKEN}
Project Health: {tier2_pass}/{tier2_total}  — {HEALTHY|ISSUES|SKIPPED}

Critical issues: {count}  (install-blocking)
Warnings:        {count}  (functional but suboptimal)
───────────────────────────────────────────────────────
```

Classify findings as:
- **Critical** — any `[FAIL]` from Tier 1 checks 1–3, or Tier 2 checks 1/3.
- **Warning** — any `[WARN]` at any tier.

Then for each non-OK check, print:

```
[FAIL|WARN] {check_name}
    Problem: {what's wrong}
    Fix:     {exact command or manual steps}
    Type:    {auto-fixable | manual}
```

If all checks passed, skip straight to the "all clear" message in Phase 5.

### Phase 5: Offer Remediation

If any fixable issues exist, ask:

> Question: "I found {count} fixable issue(s). How would you like to proceed?"
>
> Options:
> - **Auto-fix everything fixable** — "Run fix commands for issues that don't require manual input"
> - **Walk me through each fix** — "Ask before applying each fix"
> - **Just show me the commands** — "Print fix commands, I'll run them myself"
> - **Done** — "Thanks, I'll handle it from here"

**Auto-fixable issues** (safe to run via Bash with user approval):
- `claude plugin marketplace add <owner/repo>`
- `claude plugin install <name>`
- `claude plugin update <name>`

**Manual-only issues** (always print the steps, never auto-run):
- GSD install (Discord-gated)
- `/gsd-discuss-phase` (requires interactive user decisions)
- `/gsd-research-phase` (takes significant time and token budget)
- `/gsd-scan` or `/gsd-map-codebase` (user may want to choose which)

If all checks pass, end with:

```
── All checks passed. deep-plan is ready to run. ───
Next: /deep-plan {N}              (auto-detect phase)
      /deep-plan {N} --review     (plan + feasibility review)
```

## Output Discipline

- Always print the banner first — users need to see which tool is running.
- Always print the step counter `[N/6]` (Tier 1) or `[N/5]` (Tier 2) so progress is visible even when output scrolls.
- Be terse in `[OK]` lines, verbose in `[FAIL]` lines — users who need the fix want the fix inline, not buried.
- Use the structured text format above as the product; avoid emoji, color escapes, or noise.

## Not In Scope

This command does NOT:
- Install Claude Code itself (bootstrapping problem — cannot install the runtime from inside the runtime)
- Install GSD (Discord-gated by design — would require external steps the command can't take)
- Run `/deep-plan` itself — use that command directly once doctor reports healthy
- Modify `PLAN.md`, `CONTEXT.md`, `RESEARCH.md`, or any other GSD artifacts
- Touch `.planning/` files beyond reading (per the deep-plan "read-only GSD" constraint)
- Commit, push, or otherwise affect git state
