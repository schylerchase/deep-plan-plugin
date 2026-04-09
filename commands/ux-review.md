---
name: ux-review
description: 'UX review with optional fix workflow. Scans frontend files, produces a severity-rated findings report with numbered IDs, then offers to fix all, critical-only, or specific issues.'
argument-hint: '[path-or-file]'
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# /ux-review Command

Run a UX quality evaluation against frontend code, then optionally fix the issues found.

## Usage

- `/ux-review` — review frontend files in the current working directory
- `/ux-review src/components/` — review a specific directory
- `/ux-review src/pages/Dashboard.tsx` — review a specific file

## Instructions

### Phase 1: Review

1. **Parse the argument.** If a path is provided, use it as the target. If no argument, use the current working directory.

2. **Spawn the ux-reviewer agent** with this prompt:

   ```
   Review the frontend UI/UX quality of files at: {target_path}
   
   Follow your full review process — discover files, detect design system,
   evaluate against red flags, check state design, accessibility, and
   interaction patterns. Produce the structured findings report with
   numbered IDs (C1, C2, W1, W2, M1, M2, etc.) for each finding.
   
   Be specific with file paths and line numbers. Focus on actionable findings.
   ```

3. **Present the agent's report** to the user. Add a brief summary line at the top:

   ```
   UX Review complete: {critical} critical, {warning} warning, {minor} minor findings.
   ```

### Phase 2: Fix Offer

4. **After presenting the report**, use AskUserQuestion to ask what they want to fix:

   Question: "What would you like to fix?"
   Options:
   - **Fix all** — "Fix every finding in priority order (critical -> warning -> minor)"
   - **Critical only** — "Fix only critical issues ({count} findings)"
   - **Pick specific** — "I'll tell you which IDs to fix (e.g., C1, W3, M2)"
   - **Skip** — "Just wanted the report, no fixes needed"

5. **If "Pick specific"** is selected, ask a follow-up:

   "Which findings do you want to fix? Enter the IDs separated by commas (e.g., C1, C2, W3):"
   
   Use AskUserQuestion with a free-text option, or ask inline.

### Phase 3: Execute Fixes

6. **Process the selected findings** in this order: critical first, then warning, then minor.

7. **For each finding to fix:**
   - Read the target file (if not already read)
   - Apply the fix described in the finding's detail block
   - Keep changes minimal and surgical — fix only what the finding describes
   - After each fix, briefly note what was changed: `Fixed {ID}: {one-line summary}`

8. **After all fixes are applied**, present a summary:

   ```
   ## Fixes Applied
   
   | ID | Issue | Status |
   |----|-------|--------|
   | C1 | {name} | Fixed |
   | C2 | {name} | Fixed |
   | W3 | {name} | Skipped — requires design decision |
   
   {count} fixes applied. {skipped_count} skipped (noted above).
   ```

9. **If any findings could not be auto-fixed** (require design decisions, architectural changes, or user input), note them clearly:

   ```
   These findings need your input:
   - {ID}: {issue} — {why it can't be auto-fixed}
   ```

### Guidelines for Fixing

- **CSS fixes** (contrast, focus states, spacing): Apply directly. These are safe, reversible, low-risk.
- **HTML structure fixes** (semantic elements, aria attributes, form wrapping): Apply directly. Low risk.
- **JavaScript behavior fixes** (button disable, validation, loading states): Apply directly but test mentally for side effects.
- **Architecture fixes** (adding entire loading/error/empty states, restructuring forms): These often require design decisions. Note them as "needs input" rather than guessing.
- **Copy/content fixes** (rewording empty states, error messages): Suggest the fix but ask before applying — copy is subjective.

Never introduce new dependencies. Never restructure code beyond what the finding requires. One finding = one surgical fix.
