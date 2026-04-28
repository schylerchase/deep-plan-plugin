# Caveman Rule v1+v2 — Deep-Plan Integration

## Status

**Version: v1+v2 (v1 simplified rules + v2 signal overrides)**
Supersedes v0 (see git history for the old 11-stage table).

## The Rule

Exactly **two rules**. That's it.

### Rule 1 — Global mode

Deep-plan chat output uses whatever caveman mode the user has set as default (e.g. `full`, `lite`, `ultra`, `off`). Deep-plan does NOT switch modes per stage. The rule makes no assertion about chat style beyond "user's default mode applies."

### Rule 2 — HARD artifact override

When Claude invokes the Write tool to emit a `.md` file (PLAN.md, SUMMARY.md, CONTEXT.md, or any `.md` artifact), the content MUST be full prose regardless of caveman mode. Articles intact, complete sentences, paragraphs. **Caveman does not bleed into artifacts.**

This override is NON-NEGOTIABLE. If caveman compression appears inside a written `.md` file, the rule is broken.

## Why so simple?

v0 had an 11-row table mapping each deep-plan step to a specific caveman mode (parse_args→full, build_brief→lite, write_plan→off, handoff→ultra, etc.). The first real tuning session ran the full 11-stage flow and produced these findings:

1. **Per-stage mode switching never happened.** Caveman ran at one global mode throughout. Nothing in deep-plan's SKILL.md invokes `Skill caveman <mode>` at stage boundaries. The v0 table was aspirational documentation without an enforcement mechanism.

2. **Mode variations that matter emerged organically, not from the rule.** Insights got prose from the learning output style. Feasibility findings got categorized formatting from content structure. File writes got prose from Claude's Write-tool heuristic. None of these were driven by caveman rule assertions.

3. **The HARD override at stage 8 held implicitly.** The PLAN.md artifact came out as full prose even though caveman `full` was active in chat. The v0 rule called this a HARD override and flagged step 8 — the flag turned out to be the only rule that mattered, and it was already structurally enforced by Claude's tool-use behavior.

4. **Row 11 (handoff → ultra) was wrong.** The completion report needs full prose for the user to make the next decision (execute vs. review vs. refine). Ultra compression would strip the conditional reasoning that drives the decision. Observed reality delivered full prose, not ultra. The rule was wrong; the behavior was right.

The v0 table encoded things Claude already does organically (or wants to do). v1 strips it to the one assertion that actually needs to be enforced: prose in artifact writes.

## Enforcement model

### Rule 1 (global mode)
- **Enforcement:** None needed. User sets mode via `/caveman <level>` or env var. Deep-plan inherits.
- **Eval check:** Smoke test only — fixture has content, parses, non-empty body.

### Rule 2 (HARD artifact override)
- **Enforcement:** Structural. Claude's Write tool heuristic produces prose when writing `.md` files, regardless of caveman mode. No explicit mode switch is required.
- **Eval check:** Fixture asserts the body (post-frontmatter) contains article words at a minimum density (at least 5 of `the`, `an`, `is`, `are`, `was`, `were`). Loose threshold — smoke test, not stylistic judgment.
- **If this ever fails:** investigate Claude's Write-tool behavior change. It's a regression signal for artifact quality, not a caveman rule to fix.

## v2 Signals

Signal-based overrides activate when deep-plan encounters specific interaction types where caveman compression would destroy critical content. Each signal unconditionally switches to full prose (off mode) for its scope. Enforcement prefers output instructions over explicit Skill(caveman off) invocations (per v1 pattern where Claude's Write-tool heuristic produces prose structurally).

### Signal: HIGH Feasibility Finding
- **Trigger:** Feasibility review (Step 11) returns one or more HIGH-severity findings.
- **Detection heuristic:** The feasibility reviewer output contains a finding tagged HIGH or CRITICAL. Any HIGH finding activates this signal.
- **Override mode:** off (full prose)
- **Scope:** The entire feasibility review section output. If any HIGH finding exists, the whole review drops caveman compression -- not per-finding granularity.

### Signal: AskUserQuestion Block
- **Trigger:** Deep-plan presents a question to the user via AskUserQuestion or equivalent prompt.
- **Detection heuristic:** The current output is a question block with a header, question text, and option labels/descriptions. This includes Step 7 (resolve questions), Step 2 (phase confirmation), and any mid-run clarification.
- **Override mode:** off (full prose)
- **Scope:** The full question block -- header, question text, option labels, AND option descriptions. Zero ambiguity on user-facing choices.

### Signal: Mid-Flight Scope Pivot
- **Trigger:** A blocking finding or user decision requires changing the planned scope mid-execution.
- **Detection heuristic:** Deep-plan presents reasoning about why the current scope should change, offers alternative approaches, or asks the user to choose between scope options after discovering a conflict. Distinguished from a normal AskUserQuestion by the presence of conditional reasoning ("Given X, I'd recommend Y because Z").
- **Override mode:** off (full prose)
- **Scope:** All reasoning, tradeoff analysis, and recommendation text for the pivot interaction. The user is making a critical scope decision; all reasoning must be clear.

### Signal: Routing Decision Banner

- **Trigger:** Deep-plan Step 9.5 emits the model-routing decision banner with the three perspective scores, the recommended model, and any phase-split advisory or borderline hint.
- **Detection heuristic:** The output begins with `── deep-plan [9.5/{total}] Routing decision ──` and contains the compact 3-line breakdown defined in Phase 8 D-09 (Volume / Structure / Risk → Combined; Recommendation; optional advisory). The Step 9.5 banner is the only step output that includes the literal sequence `Recommendation:` followed by `(<bias> bias, threshold T)`.
- **Override mode:** off (full prose)
- **Scope:** All three banner lines, the optional advisory text, the optional borderline hint, and the optional `(reduced confidence: --skip-research used)` note. The machine-readable trailer comment (`<!-- DEEP_PLAN_ROUTING: ... -->`) is part of the banner for parsing purposes but does not affect the prose assertion. The banner is a decision artifact, not chatter — users read it to understand which model was chosen and why, and caveman compression would destroy that legibility.

## Fixtures

Six fixtures in `skills/deep-plan/fixtures/caveman/`:

- `01-chat-fragment.md` — fixture_type: chat. Represents caveman-style chat output. Smoke test only.
- `02-write-artifact.md` — fixture_type: artifact_write. Represents a `.md` file body. Asserts prose via article-word count.
- `03-feasibility-high.md` — fixture_type: feasibility_high. Represents a HIGH feasibility finding output. Asserts prose via article-word count (v2 signal override).
- `04-askuserquestion-block.md` — fixture_type: askuserquestion_block. Represents a user-facing question block. Asserts prose via article-word count (v2 signal override).
- `05-mid-flight-pivot.md` — fixture_type: mid_flight_pivot. Represents a scope pivot interaction. Asserts prose via article-word count (v2 signal override).
- `06-routing-decision.md` — fixture_type: routing_decision_banner. Represents the deep-plan Step 9.5 routing decision banner. Asserts prose via article-word count (v2 signal override per Phase 8 D-11).

## Versioning

- **v0** — 11-row stage→mode table with hard override at step 8. Over-engineered per-stage assertions with no enforcement. Invalidated by the first tuning session. See git history of this file.
- **v1** (this doc) — 2 rules. Global mode + HARD artifact override. Matches observed deep-plan behavior.
- **v2** (this doc) — 3 signal-based overrides for edge cases where prose is critical. See `## v2 Signals` above.

## Related follow-ups (NOT in this rule — separate work)

The first tuning session surfaced deep-plan SKILL.md bugs that are independent of caveman:

1. **Progress protocol headers missing** — SKILL.md says every stage must announce `── deep-plan [N/11] ──`. None appeared during the observed run. Separate fix on deep-plan SKILL.md.
2. **Tasks are work-specific, not step-specific** — SKILL.md says create one task per skill step (e.g. "Deep Plan: Load GSD context"). The observed session showed Claude creating work-specific tasks instead. Separate fix on deep-plan SKILL.md.
3. **Pivot-after-blocking-finding interaction** — observed in the session (user picked a scope, verification found the scope was already done, deep-plan offered fresh options). This isn't in any of the 11 stages. Either extend SKILL.md to add this as a formal sub-stage, or accept it as organic.

These are tracked in the local tuning notes at `.planning/caveman-tuning/` (gitignored — not published). They are out of scope for this v1 rule update.

## See Also

- Fixtures: `skills/deep-plan/fixtures/caveman/`
- Eval script: `tests/eval-caveman-rule.sh`
- Deep-plan stages: `skills/deep-plan/SKILL.md` (steps 1-12)
- README section: `Optional: caveman (Token Compression)`

## Credits

Caveman is a Claude Code plugin by Julius Brussee, MIT-licensed. Source repository: `JuliusBrussee/caveman` on GitHub (`https://github.com/JuliusBrussee/caveman`).

This rule doc describes how deep-plan **respects** caveman's modes. Deep-plan does not bundle, modify, or redistribute any caveman code. Users install caveman separately via Claude Code's plugin manager:

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Attribution satisfies MIT license conditions. No caveman source files are vendored into deep-plan — the integration is purely behavioral (deep-plan promises to behave correctly in caveman's presence).
