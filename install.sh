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
ok "Claude Code: $(claude --version 2>/dev/null | head -1)"

command -v node >/dev/null 2>&1 || fail "Node.js not found."
ok "Node.js: $(node --version)"

command -v jq >/dev/null 2>&1 || fail "jq not found. Install: brew install jq"
ok "jq: $(jq --version)"

command -v git >/dev/null 2>&1 || fail "git not found."
ok "git found"

command -v bun >/dev/null 2>&1 && HAS_BUN=true || HAS_BUN=false
$HAS_BUN && ok "bun: $(bun --version 2>/dev/null)" || warn "bun not found — statusLine will be skipped"

command -v uvx >/dev/null 2>&1 && HAS_UVX=true || HAS_UVX=false
$HAS_UVX && ok "uvx: $(uvx --version 2>/dev/null | head -1)" || warn "uvx not found — Serena will be skipped"

# ── 2. Directory structure ────────────────────────────────
step "Creating ~/.claude directory structure"

mkdir -p ~/.claude/rules
mkdir -p ~/.claude/hooks
ok "~/.claude/rules/ ready"
ok "~/.claude/hooks/ ready"

# ── 3. CLAUDE.md ──────────────────────────────────────────
step "Installing CLAUDE.md"

[ -f "$SCRIPT_DIR/CLAUDE.md" ] || fail "CLAUDE.md not found in $SCRIPT_DIR"

if [ -f ~/.claude/CLAUDE.md ]; then
  cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak
  warn "Existing CLAUDE.md backed up → ~/.claude/CLAUDE.md.bak"
fi

cp "$SCRIPT_DIR/CLAUDE.md" ~/.claude/CLAUDE.md
ok "CLAUDE.md installed ($(wc -l < ~/.claude/CLAUDE.md | tr -d ' ') lines)"

# ── 4. Rules ──────────────────────────────────────────────
step "Installing rules"

RULES_DIR="$SCRIPT_DIR/rules"
[ -d "$RULES_DIR" ] || fail "rules/ directory not found in $SCRIPT_DIR"

for file in "$RULES_DIR"/*.md; do
  name=$(basename "$file")
  cp "$file" ~/.claude/rules/"$name"
  ok "rules/$name"
done

# ── 5. Hooks ──────────────────────────────────────────────
step "Installing hooks"

HOOKS_DIR="$SCRIPT_DIR/hooks"
[ -d "$HOOKS_DIR" ] || fail "hooks/ directory not found in $SCRIPT_DIR"

for file in "$HOOKS_DIR"/*.sh; do
  name=$(basename "$file")
  cp "$file" ~/.claude/hooks/"$name"
  chmod +x ~/.claude/hooks/"$name"
  ok "hooks/$name (executable)"
done

# ── 6. settings.json (deep merge) ────────────────────────
step "Installing settings.json"

SETTINGS_SRC="$SCRIPT_DIR/settings.json"
[ -f "$SETTINGS_SRC" ] || fail "settings.json not found in $SCRIPT_DIR"

if [ -f ~/.claude/settings.json ]; then
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
  warn "Existing settings.json backed up → ~/.claude/settings.json.bak"

  # Deep merge: repo settings merged ON TOP of existing settings
  # Existing keys not in repo are preserved (model overrides, custom plugins, etc.)
  MERGED=$(jq -s '.[0] * .[1]' ~/.claude/settings.json.bak "$SETTINGS_SRC")
  echo "$MERGED" | jq . > ~/.claude/settings.json
  ok "settings.json deep-merged (existing config preserved)"
else
  cp "$SETTINGS_SRC" ~/.claude/settings.json
  ok "settings.json installed (fresh)"
fi

# ── 7. MCP Servers ────────────────────────────────────────
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

# ── 8. Verify ─────────────────────────────────────────────
step "Verifying installation"

ok "~/.claude/CLAUDE.md ($(wc -l < ~/.claude/CLAUDE.md | tr -d ' ') lines)"

for f in ~/.claude/rules/*.md; do
  ok "~/.claude/rules/$(basename "$f")"
done

for f in ~/.claude/hooks/*.sh; do
  ok "~/.claude/hooks/$(basename "$f") [executable: $([ -x "$f" ] && echo yes || echo NO)]"
done

ok "~/.claude/settings.json"

# ── Done ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           Installation Complete ✓                ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${YELLOW}Next steps:${RESET}"
echo ""
echo -e "  1. Verify in Claude Code:"
echo -e "     ${CYAN}/mcp${RESET}     → serena ✓  context7 ✓  mgrep ✓"
echo -e "     ${CYAN}/memory${RESET}  → CLAUDE.md + 7 rules loaded"
echo -e "     ${CYAN}/hooks${RESET}   → 4 hooks active"
echo ""
echo -e "  2. Install Superpowers (inside Claude Code):"
echo -e "     ${CYAN}/plugin marketplace add obra/superpowers-marketplace${RESET}"
echo -e "     ${CYAN}/plugin install superpowers@superpowers-marketplace${RESET}"
echo ""
echo -e "  3. For each new project:"
echo -e "     ${CYAN}cd your-project${RESET}"
echo -e "     ${CYAN}uvx --from git+https://github.com/oraios/serena serena project create${RESET}"
echo ""
echo -e "  4. Login to mgrep:"
echo -e "     ${CYAN}npx @mixedbread/mgrep login${RESET}"
echo ""
