---
name: deep-plan-update
description: Check for and install the latest Claude Code deep-plan plugin release from the configured marketplace
argument-hint: "[--check | --yes | --scope=user|project|local|managed]"
allowed-tools: Read, Bash, AskUserQuestion
---

# /deep-plan-update Command

Check whether the Claude Code `deep-plan@deep-plan-plugin` install is behind the configured marketplace, then optionally update it.

This command is for the **Claude Code plugin distribution**. It does not edit project `.planning/` files, global settings, hooks, or shell configuration.

## Usage

- `/deep-plan-update` — check versions, show result, ask before updating
- `/deep-plan-update --check` — check only, never update
- `/deep-plan-update --yes` — update without an interactive confirmation
- `/deep-plan-update --scope=user` — pass scope to `claude plugin update` (`user` is the Claude default)
- `/deep-plan-update --scope=project`
- `/deep-plan-update --scope=local`
- `/deep-plan-update --scope=managed`

## Instructions

### Phase 1: Banner

Print:

```text
Deep Plan Update - Claude Code Plugin
```

Check that Claude Code is available:

```bash
claude --version
claude plugin --help
```

If either command fails, stop with:

```text
Claude Code plugin tooling is unavailable. Install or upgrade Claude Code, then retry.
```

### Phase 2: Argument Parsing

Parse `$ARGUMENTS`:

- `--check`: only report installed/latest versions.
- `--yes`: skip confirmation and run the update.
- `--scope=user|project|local|managed`: optional scope for `claude plugin update`. Default: `user`.

Reject invalid scopes with:

```text
Invalid scope. Expected one of: user, project, local, managed.
```

### Phase 3: Refresh Marketplace Metadata

Run:

```bash
claude plugin marketplace update deep-plan-plugin
```

If that fails, continue with cached marketplace metadata and print:

```text
[WARN] Could not refresh deep-plan-plugin marketplace metadata; using cached metadata if present.
```

### Phase 4: Resolve Installed and Latest Versions

Resolve installed version from:

```bash
claude plugin list
```

Find the `deep-plan@deep-plan-plugin` block and read its `Version:` line.

Resolve latest version from the marketplace manifest. Search these candidate paths:

```text
$CLAUDE_CONFIG_DIR/plugins/marketplaces/deep-plan-plugin/.claude-plugin/marketplace.json
$HOME/.claude/plugins/marketplaces/deep-plan-plugin/.claude-plugin/marketplace.json
```

Parse the JSON and find `plugins[]` entry where `name == "deep-plan"`. Read its `version`.

If latest cannot be found, print:

```text
[WARN] Could not determine latest deep-plan marketplace version.
Installed: {installed}
Run manually: claude plugin marketplace update deep-plan-plugin && claude plugin update deep-plan@deep-plan-plugin
```

Then exit unless `--yes` was provided. With `--yes`, continue to Phase 6 because `claude plugin update` can still resolve the latest release.

### Phase 5: Compare Versions and Confirm

Compare semver-like versions. Strip a leading `v` and ignore any commit-hash versions by treating them as unknown.

If installed equals latest:

```text
Deep Plan is up to date.
Installed: {installed}
Latest:    {latest}
```

Exit.

If installed is newer than latest:

```text
Deep Plan appears ahead of the marketplace release.
Installed: {installed}
Latest:    {latest}

This looks like a local/dev install. No update applied.
```

Exit unless `--yes` was provided.

If latest is newer:

```text
Deep Plan update available.
Installed: {installed}
Latest:    {latest}

Update command:
claude plugin update deep-plan@deep-plan-plugin --scope {scope}
```

If `--check` is present, exit here.

If `--yes` is absent, ask:

> Question: "Update deep-plan now?"
>
> Options:
> - **Yes, update** — "Run Claude Code plugin update for deep-plan"
> - **No, cancel** — "Leave the installed version unchanged"

When text-mode or no interactive question tool is available, render this as a numbered list and wait for a reply.

### Phase 6: Update

Run:

```bash
claude plugin update deep-plan@deep-plan-plugin --scope {scope}
```

If the scoped command fails because older Claude Code does not accept the `plugin@marketplace` form for update, retry:

```bash
claude plugin update deep-plan --scope {scope}
```

If update succeeds, print:

```text
Deep Plan updated to latest available release.
Restart Claude Code to load the new plugin files.
Verify: /deep-plan-doctor --install
```

If update fails, print the command output and:

```text
Update failed. Try:
claude plugin marketplace update deep-plan-plugin
claude plugin update deep-plan@deep-plan-plugin --scope {scope}
```

## Output Discipline

- Never update without either `--yes` or explicit user confirmation.
- Never edit `~/.claude/settings.json`; Claude Code owns plugin installation state.
- Never modify project files.
- Keep the final answer focused on installed version, latest version, and whether an update was applied.
