# Setup Wizard Contract

## Status

**Version:** v1 (Phase 10 - Adaptive Model Routing milestone v1.1)
**Loaded by:** `skills/deep-plan/SKILL.md` Step 1 when `.planning/config.json` lacks `deep_plan.model_routing`
**Loaded by:** `/deep-plan-configure` for first-run setup and later reconfiguration
**Writes:** `.planning/config.json` `deep_plan.model_routing`
**Schema source:** `skills/deep-plan/references/config.md`

This file is the shared contract for both setup entry points. Inline setup and `/deep-plan-configure` must ask the same first-run questions, use the same defaults, write the same schema, and preserve unrelated `.planning/config.json` keys.

## Trigger Rules

### Inline `/deep-plan` Setup

Run the inline setup wizard during `SKILL.md` Step 1 only when all of these are true:

- `.planning/` exists and prerequisites passed.
- `.planning/config.json` is missing, or it exists but has no `deep_plan.model_routing` object.
- The user is not running a diagnostic-only command.

Do not run inline setup when `deep_plan.model_routing` exists but is partial or malformed. Phase 9 owns lenient runtime fallback for that case; the wizard must not overwrite an existing user block unless the user explicitly invokes `/deep-plan-configure` or confirms reset.

### Standalone `/deep-plan-configure`

`/deep-plan-configure` always runs in the current project directory:

- If `deep_plan.model_routing` is missing, run the Six-Question First-Run Flow.
- If `deep_plan.model_routing` exists, show the granular edit menu.
- If `.planning/` is missing, stop with: `No .planning/ directory found. Run /gsd-new-project to initialize.`

## Six-Question First-Run Flow

Ask exactly six questions in this order. The recommended option is listed first.

1. **Mode** - choose `confirm`, `auto`, or `silent`.
   - Recommended: `confirm`
   - Reason: preserve transparency; the user sees routing recommendations and warnings before work proceeds.
2. **Pin** - choose no pin (`null`), `opus`, `sonnet`, or `haiku`.
   - Recommended: no pin (`null`)
   - Reason: allow scoring to run; pin remains global in v1.1.
3. **Bias** - choose `balanced`, `quality`, or `budget`.
   - Recommended: `balanced`
   - Reason: bias is a routing preference, not the same as GSD profile.
4. **GSD profile verification** - read current profile and decide what to store.
   - Read `model_profile` first:
     ```bash
     GSD_PROFILE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get model_profile 2>/dev/null)
     ```
   - If empty, fall back to:
     ```bash
     GSD_PROFILE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get workflow.profile 2>/dev/null)
     ```
   - If still empty, offer: run `/gsd-set-profile` or skip.
   - If skipped, write `gsd_profile_at_setup: null`.
5. **Advanced overrides** - choose defaults or provide advanced JSON.
   - Recommended: use defaults.
   - Advanced JSON may include `weight_overrides` and `context_thresholds`.
   - Validate by parsing JSON. If invalid, ask once to retry; if skipped, use defaults.
6. **Confirm write** - display the exact `deep_plan.model_routing` JSON block and ask before writing.
   - If confirmed, write `.planning/config.json`.
   - If declined, stop without file changes.

## Text Mode Fallback

Text mode is active when `--text` is present or GSD `workflow.text_mode` is true:

```bash
TEXT_MODE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get workflow.text_mode 2>/dev/null)
```

When text mode is active, replace every question with a numbered list and ask the user to type a number. Free-form advanced JSON is entered as plain text after selecting the advanced option. Defaults and ordering must match the interactive flow exactly.

Example mode prompt:

```text
Configure deep-plan routing mode:
1. confirm (recommended) - show recommendations and ask before risky scope continues
2. auto - show warnings and continue
3. silent - minimize routing chatter

Type a number:
```

## Granular Edit Menu

When `deep_plan.model_routing` already exists, `/deep-plan-configure` shows a granular edit menu instead of the full setup walk:

1. **Edit mode** - update only `mode`.
2. **Edit pin** - update only `pin`.
3. **Edit bias** - update only `bias`.
4. **Sync GSD profile** - re-read `model_profile`/`workflow.profile` and update only `gsd_profile_at_setup`.
5. **Edit weights** - update `weight_overrides` and/or `context_thresholds` from JSON input.
6. **Reset routing config** - rerun the full Six-Question First-Run Flow.
7. **Cancel** - no changes.

Every edit path displays the final JSON block and asks for confirmation before writing.

## Persisted Schema

The wizard writes this shape under `.planning/config.json`:

```json
{
  "deep_plan": {
    "model_routing": {
      "schema_version": 1,
      "mode": "confirm",
      "pin": null,
      "bias": "balanced",
      "gsd_profile_at_setup": null,
      "weight_overrides": {
        "formula": { "volume_coefficient": 0.3 },
        "signals": {
          "files_modified": 1.5,
          "tasks": 0.3,
          "key_links": 3,
          "artifacts": 1.5,
          "truths": 0.5,
          "novel": 5,
          "checkpoints": 2,
          "unknown_deps": 3
        }
      },
      "context_thresholds": {
        "bias_thresholds": {
          "opus": { "quality": 8, "balanced": 12, "budget": 20 },
          "sonnet": { "quality": 3, "balanced": 4, "budget": 6 }
        },
        "token_budget_advisory": 180000,
        "borderline_hint_window": 0.1
      }
    }
  }
}
```

The defaults mirror `references/config.md`, which points at `references/scoring.md` as the defaults source. Keep this block in sync with those files.

## JSON Write Helper

Use structured JSON updates. Never splice text with regex.

```javascript
const fs = require('fs');
const path = '.planning/config.json';

function readProjectConfig() {
  if (!fs.existsSync(path)) return {};
  return JSON.parse(fs.readFileSync(path, 'utf8'));
}

function writeModelRouting(modelRouting) {
  const config = readProjectConfig();
  config.deep_plan = config.deep_plan && typeof config.deep_plan === 'object'
    ? config.deep_plan
    : {};
  config.deep_plan.model_routing = modelRouting;
  fs.writeFileSync(path, JSON.stringify(config, null, 2) + '\n');
}
```

This helper must preserve unrelated top-level keys such as `model_profile`, `commit_docs`, `workflow`, `hooks`, and project metadata. If parsing fails because `.planning/config.json` is malformed JSON, stop and tell the user to run `/deep-plan-doctor`; do not overwrite the file.

## Output Requirements

- Show a short banner: `Deep Plan Configure - Model Routing Setup`.
- Show the exact JSON block before writing.
- After writing, print the path and the selected `mode`, `pin`, `bias`, and `gsd_profile_at_setup`.
- Mention `/deep-plan-doctor` when the profile is skipped or config parsing fails.
- Do not commit, push, or modify global config files.
