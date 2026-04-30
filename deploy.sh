#!/usr/bin/env bash
set -euo pipefail

DEEP_PLAN_SOURCE="${DEEP_PLAN_SOURCE:-https://github.com/schylerchase/deep-plan-plugin}"
CE_SOURCE="${CE_SOURCE:-https://github.com/EveryInc/compound-engineering-plugin}"
CAVEMAN_SOURCE="${CAVEMAN_SOURCE:-https://github.com/JuliusBrussee/caveman}"
GSD_DIR="${GSD_DIR:-$HOME/.claude/get-shit-done}"

INSTALL_CLAUDE=1; INSTALL_CODEX=1; INSTALL_RTK=1; BRIDGE_GSD=1
ASSUME_YES=0; DRY_RUN=0; UPGRADE=0
passed=0; warned=0; failed=0

usage() {
  cat <<'USAGE'
Usage: ./deploy.sh [options]

Bootstrap Deep Plan, CE, Caveman, GSD bridge, and RTK for Claude Code and Codex.

Options: --claude-only --codex-only --skip-rtk --skip-gsd-bridge
         --upgrade --yes --dry-run -h|--help

Env: DEEP_PLAN_SOURCE CE_SOURCE CAVEMAN_SOURCE GSD_DIR
USAGE
}

note() { printf '\n==> %s\n' "$1"; }
ok() { printf '  [OK] %s\n' "$1"; passed=$((passed + 1)); }
warn() { printf '  [WARN] %s\n' "$1"; warned=$((warned + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; failed=$((failed + 1)); }

ask() {
  local prompt="$1"
  local reply=""
  if [[ "$ASSUME_YES" == 1 ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    return 1
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$|^[Yy][Ee][Ss]$ ]]
}

run() {
  printf '  $'
  printf ' %q' "$@"
  printf '\n'
  if [[ "$DRY_RUN" == 1 ]]; then
    return 0
  fi
  "$@"
}

try_run() {
  local label="$1"
  shift
  if run "$@"; then
    ok "$label"
  else
    fail "$label"
    return 1
  fi
}

run_when_allowed() {
  local prompt="$1"
  shift
  if ask "$prompt"; then
    try_run "$prompt" "$@" || true
  else
    warn "Skipped: $prompt"
  fi
}

parse_args() {
  while (($#)); do
    case "$1" in
      --claude-only) INSTALL_CODEX=0 ;;
      --codex-only) INSTALL_CLAUDE=0 ;;
      --skip-rtk) INSTALL_RTK=0 ;;
      --skip-gsd-bridge) BRIDGE_GSD=0 ;;
      --upgrade) UPGRADE=1 ;;
      --yes) ASSUME_YES=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -h|--help) usage; exit 0 ;;
      *) fail "Unknown option: $1"; usage; exit 2 ;;
    esac
    shift
  done
}

ensure_claude_cli() {
  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code CLI: $(claude --version 2>/dev/null | head -1)"
    return 0
  fi
  warn "Claude Code CLI not found."
  if command -v npm >/dev/null 2>&1; then
    run_when_allowed "Install Claude Code CLI with npm" npm install -g @anthropic-ai/claude-code
  else
    fail "Install Claude Code manually: npm install -g @anthropic-ai/claude-code"
  fi
}

ensure_codex_cli() {
  if command -v codex >/dev/null 2>&1; then
    ok "Codex CLI: $(codex --version 2>/dev/null | tail -1)"
    return 0
  fi
  warn "Codex CLI not found."
  if command -v npm >/dev/null 2>&1; then
    run_when_allowed "Install Codex CLI with npm" npm install -g @openai/codex
  else
    fail "Install Codex CLI manually, then rerun this script."
  fi
}

claude_has_plugin() {
  local plugin="$1"
  claude plugin list 2>/dev/null | grep -q "$plugin"
}

install_claude_plugin() {
  local label="$1"
  local source="$2"
  local marketplace="$3"
  local plugin="$4"
  if claude_has_plugin "$plugin"; then
    ok "Claude plugin installed: $label"
    return 0
  fi
  if run claude plugin marketplace add "$source"; then
    ok "Claude marketplace registered: $marketplace"
  else
    warn "Marketplace add did not complete; attempting update for $marketplace"
  fi
  run claude plugin marketplace update "$marketplace" >/dev/null 2>&1 || \
    warn "Marketplace update unavailable for $marketplace"
  try_run "Claude plugin installed: $label" claude plugin install "$plugin"
}

codex_config_has() {
  local pattern="$1"
  grep -q "$pattern" "$HOME/.codex/config.toml" 2>/dev/null
}

enable_codex_plugin() {
  local label="$1"
  local plugin_key="$2"
  local config="$HOME/.codex/config.toml"
  if codex_config_has "\\[plugins\\.\"$plugin_key\"\\]"; then
    ok "Codex plugin enabled: $label"
    return 0
  fi
  printf '  $ enable Codex plugin %s in %s\n' "$plugin_key" "$config"
  if [[ "$DRY_RUN" == 1 ]]; then
    ok "Codex plugin enabled: $label"
    return 0
  fi
  mkdir -p "$(dirname "$config")"
  {
    printf '\n[plugins."%s"]\n' "$plugin_key"
    printf 'enabled = true\n'
  } >> "$config"
  ok "Codex plugin enabled: $label"
}

install_codex_marketplace() {
  local label="$1"
  local source="$2"
  local plugin_key="$3"
  local marketplace="${plugin_key#*@}"
  if codex_config_has "\\[plugins\\.\"$plugin_key\"\\]"; then
    ok "Codex plugin enabled: $label"
  else
    if codex_config_has "^\\[marketplaces\\.$marketplace\\]"; then
      ok "Codex marketplace already registered: $label"
    elif run codex plugin marketplace add "$source"; then
      ok "Codex marketplace added: $label"
    else
      fail "Codex marketplace add failed: $label"
      return 1
    fi
    enable_codex_plugin "$label" "$plugin_key"
  fi
  if [[ "$UPGRADE" == 1 ]]; then
    run codex plugin marketplace upgrade "$marketplace" || warn "Codex upgrade failed for $label"
  fi
}

ensure_gsd() {
  note "GSD"
  if [[ -f "$GSD_DIR/bin/gsd-tools.cjs" ]]; then
    ok "GSD found: $GSD_DIR"
  else
    warn "GSD not found at $GSD_DIR"
    printf '  Manual: install GSD from its Discord community, then rerun this script.\n'
  fi
  if [[ "$INSTALL_CODEX" == 1 && "$BRIDGE_GSD" == 1 ]]; then
    bridge_gsd_to_codex
  fi
}

bridge_gsd_to_codex() {
  local codex_gsd="$HOME/.codex/get-shit-done"
  if [[ ! -f "$GSD_DIR/bin/gsd-tools.cjs" ]]; then
    return 0
  fi
  if [[ -e "$codex_gsd" ]]; then
    ok "Codex GSD path already exists: $codex_gsd"
    return 0
  fi
  run mkdir -p "$HOME/.codex"
  try_run "Codex GSD bridge created" ln -s "$GSD_DIR" "$codex_gsd"
}

ensure_rtk() {
  note "RTK"
  if command -v rtk >/dev/null 2>&1; then
    ok "RTK CLI: $(rtk --version 2>/dev/null | head -1)"
  elif command -v cargo >/dev/null 2>&1; then
    run_when_allowed "Install RTK with cargo" cargo install rtk
  else
    warn "RTK not found and cargo is unavailable."
    printf '  Manual: install Rust/cargo, then run: cargo install rtk\n'
  fi
  command -v rtk >/dev/null 2>&1 || return 0
  [[ "$INSTALL_CLAUDE" == 1 ]] && configure_rtk_claude
  [[ "$INSTALL_CODEX" == 1 ]] && configure_rtk_codex
}

configure_rtk_claude() {
  if [[ -f "$HOME/.claude/hooks/rtk-rewrite.sh" ]]; then
    ok "Claude RTK hook present"
  else
    run_when_allowed "Configure RTK for Claude Code" rtk init --global --auto-patch
  fi
}

configure_rtk_codex() {
  if [[ -f "$HOME/.codex/RTK.md" ]]; then
    ok "Codex RTK instructions present"
  else
    run_when_allowed "Configure RTK for Codex" rtk init --global --codex
  fi
}

configure_claude() {
  note "Claude Code"
  ensure_claude_cli
  command -v claude >/dev/null 2>&1 || return 0
  install_claude_plugin "Compound Engineering" "$CE_SOURCE" "compound-engineering-plugin" "compound-engineering@compound-engineering-plugin"
  install_claude_plugin "Caveman" "$CAVEMAN_SOURCE" "caveman" "caveman@caveman"
  install_claude_plugin "Deep Plan" "$DEEP_PLAN_SOURCE" "deep-plan-plugin" "deep-plan@deep-plan-plugin"
  if [[ "$UPGRADE" == 1 ]]; then
    run claude plugin marketplace update deep-plan-plugin || warn "Claude deep-plan marketplace update failed"
    run claude plugin update deep-plan@deep-plan-plugin || warn "Claude deep-plan plugin update failed"
  fi
}

configure_codex() {
  note "Codex"
  ensure_codex_cli
  command -v codex >/dev/null 2>&1 || return 0
  install_codex_marketplace "Compound Engineering" "$CE_SOURCE" "compound-engineering@compound-engineering-plugin"
  install_codex_marketplace "Caveman" "$CAVEMAN_SOURCE" "caveman@caveman-repo"
  install_codex_marketplace "Deep Plan" "$DEEP_PLAN_SOURCE" "deep-plan@deep-plan-plugin"
}

summary() {
  note "Summary"
  printf '  OK:       %d\n' "$passed"
  printf '  Warnings: %d\n' "$warned"
  printf '  Failures: %d\n' "$failed"
  if (( failed > 0 )); then
    printf '\nBootstrap finished with failures. Fix the listed items, then rerun ./deploy.sh.\n'
    exit 1
  fi
  printf '\nBootstrap complete. Restart Claude Code and Codex so new plugins and config load.\n'
  printf 'Verify Claude: /deep-plan-doctor --install\n'
  printf 'Verify Codex: ask Codex to run the deep-plan-doctor skill.\n'
}

main() {
  parse_args "$@"
  printf '\nDeep Plan deploy bootstrap\n'
  printf 'Sources:\n'
  printf '  deep-plan: %s\n' "$DEEP_PLAN_SOURCE"
  printf '  CE:        %s\n' "$CE_SOURCE"
  printf '  Caveman:   %s\n' "$CAVEMAN_SOURCE"
  [[ "$INSTALL_CLAUDE" == 1 ]] && configure_claude
  [[ "$INSTALL_CODEX" == 1 ]] && configure_codex
  ensure_gsd
  [[ "$INSTALL_RTK" == 1 ]] && ensure_rtk
  summary
}

main "$@"
