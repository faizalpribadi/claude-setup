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

command -v python3 >/dev/null 2>&1 && HAS_PYTHON=true || HAS_PYTHON=false
$HAS_PYTHON && ok "python3: $(python3 --version 2>/dev/null)" || warn "python3 not found — statusline block % display will be limited"

command -v bun >/dev/null 2>&1 && HAS_BUN=true || HAS_BUN=false
$HAS_BUN && ok "bun: $(bun --version 2>/dev/null)" || warn "bun not found — install: curl -fsSL https://bun.sh/install | bash"

command -v rtk >/dev/null 2>&1 && HAS_RTK=true || HAS_RTK=false
if $HAS_RTK; then
  RTK_VERSION=$(rtk --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  ok "rtk: $RTK_VERSION"
else
  warn "rtk not found — token savings hook will be skipped. Install: https://github.com/rtk-ai/rtk#installation"
fi

command -v ccusage >/dev/null 2>&1 && HAS_CCUSAGE=true || HAS_CCUSAGE=false
if ! $HAS_CCUSAGE; then
  echo -e "  Installing ccusage..."
  if npm install -g ccusage 2>/dev/null; then
    ok "ccusage installed"
    HAS_CCUSAGE=true
  else
    warn "ccusage install failed — statusline will show partial data. Install manually: npm install -g ccusage"
  fi
else
  ok "ccusage: $(ccusage --version 2>/dev/null | head -1)"
fi

command -v uvx >/dev/null 2>&1 && HAS_UVX=true || HAS_UVX=false
$HAS_UVX && ok "uvx: $(uvx --version 2>/dev/null | head -1)" || warn "uvx not found — Serena MCP will be skipped"

command -v gopls >/dev/null 2>&1 && ok "gopls found" || warn "gopls not found — gopls-lsp plugin will be limited. Install: go install golang.org/x/tools/gopls@latest"

# ── 2. Directory structure ────────────────────────────────
step "Creating ~/.claude directory structure"

mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/read-once
ok "~/.claude/hooks/ ready"
ok "~/.claude/commands/ ready"
ok "~/.claude/read-once/ ready"

# ── 3. CLAUDE.md ──────────────────────────────────────────
step "Installing CLAUDE.md"

[ -f "$SCRIPT_DIR/CLAUDE.md" ] || fail "CLAUDE.md not found in $SCRIPT_DIR"

if [ -f ~/.claude/CLAUDE.md ]; then
  cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak
  warn "Existing CLAUDE.md backed up → ~/.claude/CLAUDE.md.bak"
fi

cp "$SCRIPT_DIR/CLAUDE.md" ~/.claude/CLAUDE.md
ok "CLAUDE.md installed ($(wc -l < ~/.claude/CLAUDE.md | tr -d ' ') lines)"

# ── 4. RTK.md ─────────────────────────────────────────────
step "Installing RTK.md"

if [ -f "$SCRIPT_DIR/RTK.md" ]; then
  cp "$SCRIPT_DIR/RTK.md" ~/.claude/RTK.md
  ok "RTK.md installed"
else
  warn "RTK.md not found in $SCRIPT_DIR — skipped"
fi

# ── 5. .claudeignore ─────────────────────────────────────
step "Installing .claudeignore"

if [ -f "$SCRIPT_DIR/.claudeignore" ]; then
  cp "$SCRIPT_DIR/.claudeignore" ~/.claude/.claudeignore
  ok ".claudeignore installed"
else
  warn ".claudeignore not found in $SCRIPT_DIR — skipped"
fi

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

# ── 7. read-once hook ─────────────────────────────────────
step "Installing read-once hook"

READ_ONCE_DIR="$SCRIPT_DIR/read-once"
if [ -d "$READ_ONCE_DIR" ]; then
  cp "$READ_ONCE_DIR/hook.sh" ~/.claude/read-once/hook.sh
  chmod +x ~/.claude/read-once/hook.sh
  ok "read-once/hook.sh (executable)"
else
  warn "read-once/ directory not found in $SCRIPT_DIR — skipped"
fi

# ── 8. Slash commands ────────────────────────────────────
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

# ── 9. settings.json (deep merge) ────────────────────────
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
claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true
claude plugin marketplace add mixedbread-ai/mgrep 2>/dev/null || true
claude plugin marketplace add mksglu/context-mode 2>/dev/null || true
claude plugin marketplace add thedotmack/claude-mem 2>/dev/null || true
claude plugin marketplace add backnotprop/plannotator 2>/dev/null || true
claude plugin marketplace add ast-grep/agent-skill 2>/dev/null || true
claude plugin marketplace add kingbootoshi/cartographer 2>/dev/null || true
claude plugin marketplace add anthropics/healthcare 2>/dev/null || true

# Core plugins
install_plugin "claude-plugins-official" "superpowers"
install_plugin "claude-plugins-official" "gopls-lsp"
install_plugin "Mixedbread-Grep" "mgrep"
install_plugin "context-mode" "context-mode"

# Productivity plugins
install_plugin "thedotmack" "claude-mem"
install_plugin "plannotator" "plannotator"
install_plugin "ast-grep-marketplace" "ast-grep"
install_plugin "cartographer-marketplace" "cartographer"

# ── 12. Verify ────────────────────────────────────────────
step "Verifying installation"

ok "~/.claude/CLAUDE.md ($(wc -l < ~/.claude/CLAUDE.md | tr -d ' ') lines)"
[ -f ~/.claude/.claudeignore ] && ok "~/.claude/.claudeignore" || warn ".claudeignore missing"
[ -f ~/.claude/read-once/hook.sh ] && ok "~/.claude/read-once/hook.sh [executable: $([ -x ~/.claude/read-once/hook.sh ] && echo yes || echo NO)]" || warn "read-once/hook.sh missing"

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
echo -e "${YELLOW}Verify in Claude Code:${RESET}"
echo -e "  ${CYAN}/mcp${RESET}       → context7, mgrep (+ serena if uvx installed)"
echo -e "  ${CYAN}/plugins${RESET}   → superpowers, gopls-lsp, mgrep, context-mode, claude-mem, plannotator, ast-grep, cartographer (8 total)"
echo ""
echo -e "${YELLOW}Available slash commands:${RESET}"
echo -e "  ${CYAN}/plan${RESET}               → plan mode"
echo -e "  ${CYAN}/ask${RESET}                → quick Q&A, minimal overhead"
echo -e "  ${CYAN}/plannotator-annotate${RESET} → annotate a markdown file"
echo -e "  ${CYAN}/plannotator-review${RESET}   → code review current changes"
echo ""
echo -e "${YELLOW}Key behaviors:${RESET}"
echo -e "  ${CYAN}rtk${RESET}        → auto-rewrites bash commands for token savings (60-90%)"
echo -e "  ${CYAN}statusline${RESET} → shows session cost, burn rate + block % remaining"
echo -e "  ${CYAN}mgrep${RESET}      → mandatory replacement for WebSearch + Grep + Glob"
echo ""
echo -e "${YELLOW}Optional — RTK token savings:${RESET}"
echo -e "  ${CYAN}https://github.com/rtk-ai/rtk#installation${RESET}"
echo ""
echo -e "${YELLOW}Optional — Serena MCP (semantic code navigation):${RESET}"
echo -e "  ${CYAN}curl -LsSf https://astral.sh/uv/install.sh | sh${RESET}"
echo -e "  ${CYAN}cd your-project && uvx --from git+https://github.com/oraios/serena serena project create${RESET}"
echo ""
