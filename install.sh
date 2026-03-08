#!/bin/bash
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✓ $1${RESET}"; }
warn() { echo -e "  ${YELLOW}⚠ $1${RESET}"; }
fail() { echo -e "  ${RED}✗ $1${RESET}"; exit 1; }

echo -e "${BOLD}"
echo "╔══════════════════════════════════════╗"
echo "║   Claude Code Full Setup Installer   ║"
echo "╚══════════════════════════════════════╝"
echo -e "${RESET}"

# ── 1. Prerequisites ──────────────────────────────────────
step "Checking prerequisites"

command -v claude >/dev/null 2>&1 || fail "Claude Code not found. Install: npm install -g @anthropic-ai/claude-code"
ok "Claude Code found"

command -v node >/dev/null 2>&1 || fail "Node.js not found."
ok "Node.js: $(node --version)"

command -v jq >/dev/null 2>&1 || fail "jq not found. Install: brew install jq"
ok "jq: $(jq --version)"

command -v git >/dev/null 2>&1 || fail "git not found."
ok "git found"

command -v bun >/dev/null 2>&1 && HAS_BUN=true || HAS_BUN=false
$HAS_BUN && ok "bun: $(bun --version 2>/dev/null)" || warn "bun not found — statusLine and reflexion hook will be limited"

command -v uvx >/dev/null 2>&1 && HAS_UVX=true || HAS_UVX=false
$HAS_UVX && ok "uvx: $(uvx --version 2>/dev/null | head -1)" || warn "uvx not found — Serena will be skipped"

# ── 2. Directory structure ────────────────────────────────
step "Creating ~/.claude directory structure"

mkdir -p ~/.claude/rules
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands
ok "~/.claude/rules/ ready"
ok "~/.claude/hooks/ ready"
ok "~/.claude/commands/ ready"

# ── 3. CLAUDE.md ──────────────────────────────────────────
step "Installing CLAUDE.md"

[ -f "$SCRIPT_DIR/CLAUDE.md" ] || fail "CLAUDE.md not found in $SCRIPT_DIR"

if [ -f ~/.claude/CLAUDE.md ]; then
  cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak
  warn "Existing CLAUDE.md backed up → ~/.claude/CLAUDE.md.bak"
fi

cp "$SCRIPT_DIR/CLAUDE.md" ~/.claude/CLAUDE.md
ok "CLAUDE.md installed ($(wc -l < ~/.claude/CLAUDE.md | tr -d ' ') lines)"

# ── 4. .claudeignore ─────────────────────────────────────
step "Installing .claudeignore"

if [ -f "$SCRIPT_DIR/.claudeignore" ]; then
  cp "$SCRIPT_DIR/.claudeignore" ~/.claude/.claudeignore
  ok ".claudeignore installed"
else
  warn ".claudeignore not found in $SCRIPT_DIR — skipped"
fi

# ── 5. Rules ──────────────────────────────────────────────
step "Installing rules"

RULES_DIR="$SCRIPT_DIR/rules"
[ -d "$RULES_DIR" ] || fail "rules/ directory not found in $SCRIPT_DIR"

for file in "$RULES_DIR"/*.md; do
  name=$(basename "$file")
  cp "$file" ~/.claude/rules/"$name"
  ok "rules/$name"
done

# ── 6. Hooks ──────────────────────────────────────────────
step "Installing hooks"

HOOKS_DIR="$SCRIPT_DIR/hooks"
[ -d "$HOOKS_DIR" ] || fail "hooks/ directory not found in $SCRIPT_DIR"

for file in "$HOOKS_DIR"/*.sh; do
  name=$(basename "$file")
  cp "$file" ~/.claude/hooks/"$name"
  chmod +x ~/.claude/hooks/"$name"
  ok "hooks/$name (executable)"
done

# ── 7. Slash commands ────────────────────────────────────
step "Installing slash commands"

COMMANDS_DIR="$SCRIPT_DIR/commands"
if [ -d "$COMMANDS_DIR" ]; then
  for file in "$COMMANDS_DIR"/*.md; do
    name=$(basename "$file")
    cp "$file" ~/.claude/commands/"$name"
    ok "commands/$name → /${name%.md}"
  done
else
  warn "commands/ directory not found — skipped"
fi

# ── 8. settings.json (deep merge) ────────────────────────
step "Installing settings.json"

SETTINGS_SRC="$SCRIPT_DIR/settings.json"
[ -f "$SETTINGS_SRC" ] || fail "settings.json not found in $SCRIPT_DIR"

if [ -f ~/.claude/settings.json ]; then
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
  warn "Existing settings.json backed up → ~/.claude/settings.json.bak"

  # Deep merge: repo settings merged ON TOP of existing settings
  MERGED=$(jq -s '.[0] * .[1]' ~/.claude/settings.json.bak "$SETTINGS_SRC")
  echo "$MERGED" | jq . > ~/.claude/settings.json
  ok "settings.json deep-merged (existing config preserved)"
else
  cp "$SETTINGS_SRC" ~/.claude/settings.json
  ok "settings.json installed (fresh)"
fi

# ── 9. Environment variables ─────────────────────────────
step "Configuring environment variables"

ENV_MARKER="# Claude Code"
ZSHRC="$HOME/.zshrc"

if grep -q "$ENV_MARKER" "$ZSHRC" 2>/dev/null; then
  ok "Environment variables already present in ~/.zshrc"
else
  cat >> "$ZSHRC" << 'ENVEOF'

# Claude Code
export ENABLE_TOOL_SEARCH=auto:5              # defer MCP tools at 5% context (default 10%)
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1   # suppress background model calls
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50    # compact at 50% context, not 95%
export MAX_THINKING_TOKENS=8000              # reduce hidden thinking (default: 31999)
ENVEOF
  ok "Environment variables added to ~/.zshrc"
fi

# ── 10. MCP Servers ───────────────────────────────────────
step "Installing MCP servers"

install_mcp() {
  local name="$1" cmd="$2"
  echo -e "  Installing ${BOLD}$name${RESET}..."
  if eval "$cmd" 2>/dev/null; then
    ok "$name installed"
  else
    warn "$name failed or already exists"
  fi
}

install_mcp "context7" \
  "claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp"

install_mcp "mgrep" \
  "claude mcp add --scope user mgrep -- npx -y @mixedbread/mgrep mcp"

if $HAS_UVX; then
  install_mcp "serena" \
    "claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd"
else
  warn "Skipping serena (uvx not found). Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

# ── 11. Plugins ───────────────────────────────────────────
step "Installing plugins"

install_plugin() {
  local marketplace="$1" plugin="$2"
  echo -e "  Installing ${BOLD}$plugin${RESET}..."
  if claude plugin install "$plugin@$marketplace" 2>/dev/null; then
    ok "$plugin installed"
  else
    warn "$plugin failed or already exists"
  fi
}

# Add marketplaces
claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
claude plugin marketplace add JetBrains/go-modern-guidelines 2>/dev/null || true
claude plugin marketplace add NeoLabHQ/context-engineering-kit 2>/dev/null || true

install_plugin "claude-plugins-official" "gopls-lsp"
install_plugin "superpowers-marketplace" "superpowers"
install_plugin "goland-claude-marketplace" "modern-go-guidelines"
install_plugin "context-engineering-kit" "reflexion"
install_plugin "context-engineering-kit" "kaizen"
install_plugin "context-engineering-kit" "sadd"

# ── 12. Verify ────────────────────────────────────────────
step "Verifying installation"

ok "~/.claude/CLAUDE.md ($(wc -l < ~/.claude/CLAUDE.md | tr -d ' ') lines)"
[ -f ~/.claude/.claudeignore ] && ok "~/.claude/.claudeignore" || warn ".claudeignore missing"

for f in ~/.claude/rules/*.md; do
  ok "~/.claude/rules/$(basename "$f")"
done

for f in ~/.claude/hooks/*.sh; do
  ok "~/.claude/hooks/$(basename "$f") [executable: $([ -x "$f" ] && echo yes || echo NO)]"
done

for f in ~/.claude/commands/*.md; do
  ok "~/.claude/commands/$(basename "$f") → /${f%.md}"
done

ok "~/.claude/settings.json"

# ── Done ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           Installation Complete                  ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${YELLOW}Activate environment:${RESET}"
echo -e "  ${CYAN}source ~/.zshrc${RESET}"
echo ""
echo -e "${YELLOW}Verify in Claude Code:${RESET}"
echo -e "  ${CYAN}/mcp${RESET}       → serena, context7, mgrep"
echo -e "  ${CYAN}/context${RESET}   → check context consumption"
echo -e "  ${CYAN}/cost${RESET}      → track token usage"
echo ""
echo -e "${YELLOW}Available slash commands:${RESET}"
echo -e "  ${CYAN}/plan${RESET}      → switch to Opus + plan mode"
echo -e "  ${CYAN}/ask${RESET}       → quick Q&A, minimal overhead"
echo ""
echo -e "${YELLOW}CEK commands (on-demand):${RESET}"
echo -e "  ${CYAN}/reflexion:reflect${RESET}   → self-refine after implementation"
echo -e "  ${CYAN}/reflexion:memorize${RESET}  → persist insights to CLAUDE.md"
echo -e "  ${CYAN}/kaizen:why${RESET}          → 5 Whys root cause analysis"
echo -e "  ${CYAN}/do-in-parallel${RESET}      → dispatch parallel subagents"
echo -e "  ${CYAN}/do-and-judge${RESET}        → implement + judge verification"
echo ""
echo -e "${YELLOW}For new Go projects:${RESET}"
echo -e "  ${CYAN}cd your-project${RESET}"
echo -e "  ${CYAN}uvx --from git+https://github.com/oraios/serena serena project create${RESET}"
echo ""
