---
name: deep-plan-configure
description: Configure deep-plan adaptive model routing for the current GSD project. Runs the first-run setup wizard when `.planning/config.json` lacks `deep_plan.model_routing`, and shows a granular edit menu for existing configs.
argument-hint: "[--text | --reset]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# /deep-plan-configure Command

Configure `.planning/config.json` `deep_plan.model_routing` for this project.

This command is project-local. It never edits global Claude, Codex, GSD, or shell configuration files.

## Usage

- `/deep-plan-configure` - setup or edit model routing for the current project
- `/deep-plan-configure --text` - use numbered-list prompts
- `/deep-plan-configure --reset` - rerun the first-run wizard even when config exists

## Instructions

### Phase 1: Prerequisites and Mode

Print:

```text
Deep Plan Configure - Model Routing Setup
```

Check prerequisites:

```bash
test -d .planning
test -f "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs"
```

If `.planning/` is missing, stop with:

```text
No .planning/ directory found. Run /gsd-new-project to initialize.
```

Set `TEXT_MODE=true` when `--text` is present or GSD config says `workflow.text_mode=true`:

```bash
TEXT_MODE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get workflow.text_mode 2>/dev/null)
```

Read `skills/deep-plan/references/setup-wizard.md` and `skills/deep-plan/references/config.md` before asking questions. `setup-wizard.md` is the shared contract; `config.md` is the schema source.

### Phase 2: Detect Existing Config

Read `.planning/config.json` with structured JSON parsing:

```bash
CONFIG_HAS_MODEL_ROUTING=$(node -e "
const fs = require('fs');
const path = process.cwd() + '/.planning/config.json';
try {
  if (!fs.existsSync(path)) {
    process.stdout.write('no');
    process.exit(0);
  }
  const c = JSON.parse(fs.readFileSync(path, 'utf8'));
  const block = c?.deep_plan?.model_routing;
  process.stdout.write(block && typeof block === 'object' && !Array.isArray(block) ? 'yes' : 'no');
} catch (e) {
  process.stdout.write('error');
}
")
```

If `CONFIG_HAS_MODEL_ROUTING=error`, stop without writing:

```text
.planning/config.json is not parseable JSON. Run /deep-plan-doctor before configuring.
```

If `--reset` is present, ignore existing config and run Phase 3.

If `CONFIG_HAS_MODEL_ROUTING=no`, run Phase 3.

If `CONFIG_HAS_MODEL_ROUTING=yes`, run Phase 4.

### Phase 3: First-Run Wizard

Run the Six-Question First-Run Flow from `references/setup-wizard.md`.

Ask exactly:

1. `mode`: `confirm` recommended, `auto`, `silent`
2. `pin`: no pin (`null`) recommended, `opus`, `sonnet`, `haiku`
3. `bias`: `balanced` recommended, `quality`, `budget`
4. GSD profile verification: capture current profile, run `/gsd-set-profile`, or skip
5. Advanced overrides: defaults recommended, or paste JSON for `weight_overrides` / `context_thresholds`
6. Confirm write: display exact JSON before writing

When `TEXT_MODE=true`, render every question as a numbered list with the recommended option first. Do not use `AskUserQuestion` in text mode.

For GSD profile verification, read `model_profile` first and `workflow.profile` second:

```bash
GSD_PROFILE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get model_profile 2>/dev/null)
if [ -z "$GSD_PROFILE" ]; then
  GSD_PROFILE=$(node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" config-get workflow.profile 2>/dev/null)
fi
```

If no profile is set and the user skips, write `gsd_profile_at_setup: null` and print:

```text
[WARN] No GSD profile captured. /deep-plan-doctor will surface this until you rerun /deep-plan-configure.
```

### Phase 4: Granular Edit Menu

When config exists, show this granular edit menu:

```text
1. Edit mode
2. Edit pin
3. Edit bias
4. Sync GSD profile
5. Edit weights
6. Reset routing config
7. Cancel
```

Route choices:

- **Edit mode** updates only `mode`.
- **Edit pin** updates only `pin`.
- **Edit bias** updates only `bias`.
- **Sync GSD profile** updates only `gsd_profile_at_setup`.
- **Edit weights** updates only `weight_overrides` and/or `context_thresholds` from JSON input.
- **Reset routing config** runs the Phase 3 first-run wizard.
- **Cancel** exits with no changes.

Every edit path displays the final `deep_plan.model_routing` JSON block and asks for confirmation before writing.

### Phase 5: Write Config

Use structured JSON parse/update/write. It must preserve unrelated top-level keys and update only `deep_plan.model_routing`.

Use this helper shape:

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

The written block must include:

- `schema_version`
- `mode`
- `pin`
- `bias`
- `gsd_profile_at_setup`
- `weight_overrides`
- `context_thresholds`

### Phase 6: Confirmation

After writing, print:

```text
Configured deep-plan model routing.
File: .planning/config.json
mode: {mode}
pin: {pin}
bias: {bias}
gsd_profile_at_setup: {value}
```

Then suggest:

```text
Next: /deep-plan-doctor --project
```

## Output Discipline

- Keep prompts short.
- Always show the final JSON before writing.
- Never overwrite malformed `.planning/config.json`; stop and point at `/deep-plan-doctor`.
- Never commit, push, or modify global configuration.
- Keep inline setup and this command in sync through `references/setup-wizard.md`.
