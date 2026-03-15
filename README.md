<div align="center">

# Claude Code Setup

<img src="assets/my-claude-code.jpg" alt="Claude Code Config Pack" width="600" />

Opinionated configuration pack for Claude Code — enforcing engineering discipline, token efficiency, and workflow consistency.

</div>

## Quick Start

```bash
git clone <this-repo>
cd claude-setup
chmod +x install.sh
./install.sh
```

The installer:
- Deep-merges `settings.json` (preserves your model, custom plugins)
- Backs up existing `CLAUDE.md` and `settings.json`
- Installs hooks, read-once hook, commands, RTK.md, and `.claudeignore`
- Normalizes all hook paths to `$HOME` (portable across users)
- Installs ccusage if not found (`npm install -g ccusage`)
- Sets up MCP servers (context7, mgrep, serena)
- Installs plugins (8 total — see Plugins section)
- Env vars managed via `settings.json` (no `.zshrc` modification)

## Project Structure

```
.
├── CLAUDE.md              # Global behavior contract (tool priority, rules, constraints)
├── RTK.md                 # RTK token savings reference
├── .claudeignore          # Exclude node_modules, builds, media, secrets from context
├── settings.json          # Hooks + plugins + statusLine + env vars
├── env.sh                 # Env vars reference (fallback — settings.json is primary)
├── install.sh             # Smart installer with deep-merge + plugin setup
├── commands/
│   ├── plan.md                   # /plan → plan mode (Opus model)
│   ├── ask.md                    # /ask  → minimal overhead Q&A
│   ├── plannotator-annotate.md   # /plannotator-annotate → annotate markdown
│   └── plannotator-review.md     # /plannotator-review  → code review UI
├── hooks/
│   ├── rtk-rewrite.sh         # PreToolUse:Bash — rewrite commands via RTK (token savings)
│   ├── ctx-guard.sh           # PreToolUse:Bash — block high-output commands (docker logs, git log, etc.)
│   ├── websearch-guard.sh     # PreToolUse:WebSearch — hard block WebSearch → mgrep --web
│   ├── webfetch-guard.sh      # PreToolUse:WebFetch — hard block WebFetch → ctx_fetch_and_index
│   ├── read-guard.sh          # PreToolUse:Read — advisory hint for .go files (try serena first)
│   ├── session-context.sh     # UserPromptSubmit — inject context + rule-based prompt enrichment
│   ├── context-bar.sh         # StatusLine — ccusage burn rate + block session % remaining
│   ├── pre-compact.sh         # PreCompact — save git status to .claude-handOFF.md
│   ├── filter-test-output.sh  # PostToolUse:Bash — compress test output to failures only
│   ├── codegraph-sync.sh      # PostToolUse:Bash — auto-sync + auto-init .codegraph/ after git ops
│   └── statusline.sh          # Legacy statusline (superseded by context-bar.sh)
├── read-once/
│   └── hook.sh                # PreToolUse:Read — prevent redundant re-reads (80-95% savings)
├── promptfoo/
│   ├── promptfooconfig.yaml          # promptfoo main config
│   ├── tests/
│   │   └── session-context-hints.yaml  # Tests for session-context.sh hint injection
│   └── test-session-context.sh       # Bash test script (no API key needed)
└── docs/
    └── superpowers/
        └── plans/             # Implementation plans created during setup sessions
```

## Environment Variables

Managed via `settings.json` `"env"` block (no `.zshrc` changes needed):

```bash
ENABLE_TOOL_SEARCH=auto:5              # Defer MCP tools until 5% context threshold
DISABLE_NON_ESSENTIAL_MODEL_CALLS=1    # Suppress background model calls
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=40     # Compact at 40% context, not 95%
MAX_THINKING_TOKENS=8000               # Reduce hidden thinking tokens
DO_NOT_TRACK=1                         # Disable analytics tracking
ANTHROPIC_TELEMETRY_DISABLED=1        # Disable telemetry
```

## Plugins (8 total)

| Plugin | Source | Purpose |
|--------|--------|---------|
| `superpowers` | claude-plugins-official | Core SDLC skills (brainstorming, TDD, debugging, plans) |
| `gopls-lsp` | claude-plugins-official | Go symbol navigation via LSP |
| `mgrep` | Mixedbread-Grep | AI-powered code + web search (replaces Grep/WebSearch) |
| `context-mode` | context-mode | Context window protection via sandbox execution |
| `claude-mem` | thedotmack | Cross-session memory with timeline and smart search |
| `plannotator` | plannotator | Interactive plan annotation and code review UI |
| `ast-grep` | ast-grep-marketplace | Structural code search/refactor via AST patterns |
| `cartographer` | cartographer-marketplace | Codebase mapping → docs/CODEBASE_MAP.md |

## MCP Servers

| Server | Purpose |
|--------|---------|
| `context7` | Up-to-date library docs (Fiber, gRPC-Go, GORM, etc.) — fetched before implementing |
| `mgrep` | Semantic search: code (`mgrep "query"`) and web (`mgrep --web "query"`) |
| `serena` | LSP-powered symbol navigation (find_symbol, get_symbols_overview, find_referencing_symbols) |

### Serena MCP — Semantic Code Navigation

Serena provides LSP-backed symbol search across your entire codebase without reading files. It starts automatically via Claude Code MCP and is invoked by Claude explicitly.

**Setup for your project:**
```bash
# Install uv (required)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Initialize Serena for your project (run once in your project root)
cd your-project
uvx --from git+https://github.com/oraios/serena serena project create

# This creates .serena/project.yml — add an initial_prompt for project context:
```

**`.serena/project.yml` initial_prompt example (Go monorepo):**
```yaml
initial_prompt: |
  project is a Go microservices monorepo.
  Services: api-gateway, users, providers, ...
  Patterns: Fiber framework, GORM, gRPC, oapi-codegen for OpenAPI types.
  Always use find_symbol before reading files.
  Prefer find_referencing_symbols over grep when tracing callers.
```

**Key Serena tools:**
- `find_symbol` — find any function/struct/interface by name across all files
- `get_symbols_overview` — list all top-level symbols in a file without reading it
- `find_referencing_symbols` — find all callers of a function/type (like LSP references)
- `replace_symbol_body` — surgical symbol-level edits without touching the whole file

## Hooks (11 total)

| Hook | Event | Behavior |
|------|-------|----------|
| `rtk-rewrite.sh` | PreToolUse:Bash | Auto-rewrite commands via RTK (60-90% token savings) |
| `ctx-guard.sh` | PreToolUse:Bash | Block high-output commands: `docker logs`, `kubectl logs`, `git log`, `journalctl`, `cat *.log` — forces `ctx_execute` instead |
| `websearch-guard.sh` | PreToolUse:WebSearch | **Hard block** direct WebSearch — redirects to `mgrep --web "query"` |
| `webfetch-guard.sh` | PreToolUse:WebFetch | **Hard block** direct WebFetch — redirects to `ctx_fetch_and_index(url=...)` |
| `read-guard.sh` | PreToolUse:Read | Advisory hint for `.go` files — suggests serena before reading full file |
| `session-context.sh` | UserPromptSubmit | Inject project/branch/cwd/go_module + rule-based hints (see below) |
| `context-bar.sh` | StatusLine | ccusage burn rate + block session % remaining |
| `pre-compact.sh` | PreCompact | Save git status to `.claude-handOFF.md` before compaction |
| `filter-test-output.sh` | PostToolUse:Bash | Compress test output to FAIL/ERROR lines only |
| `codegraph-sync.sh` | PostToolUse:Bash | Auto-sync `.codegraph/` index after git ops; **auto-init** if `go.mod` present |
| `read-once/hook.sh` | PreToolUse:Read | Block redundant re-reads within a session (80-95% savings) |

### session-context.sh — Rule-Based Prompt Enrichment

On every prompt, this hook injects project context and appends task-specific hints with zero model calls:

```
[Session] project=my-service cwd=/Users/.../my-service branch=main go_module=my-service
  | [Hint] Go task: tool priority = serena → gopls-lsp → codegraph → mgrep
  | [Hint] Debug task: invoke systematic-debugging skill before proposing fixes
```

**Hint rules (keyword-triggered):**

| Trigger keywords | Hint injected |
|-----------------|---------------|
| `implement`, `buat`, `tambah`, `feature`, `add`, `create` | Use brainstorming skill before writing code |
| `debug`, `fix`, `error`, `bug`, `broken`, `panic`, `crash` | Use systematic-debugging skill before fixes |
| `.go`, `func`, `struct`, `interface`, `handler`, `repository` | Tool priority: serena → gopls-lsp → codegraph → mgrep |
| `openapi`, `oapi`, `codegen`, `swagger`, `spec` | Use generated types, never define manually |
| `log`, `docker`, `kubectl`, `git log`, `build output` | Use ctx_execute, not Bash directly |
| `cari`, `find`, `search`, `where is`, `locate` | Use mgrep skill (not Grep/Glob/WebSearch) |

## Slash Commands (4 total)

| Command | Purpose |
|---------|---------|
| `/plan` | Enter plan mode (switches to Opus for architecture planning) |
| `/ask` | Quick Q&A, minimal overhead |
| `/plannotator-annotate` | Open annotation UI for a markdown file |
| `/plannotator-review` | Open code review UI for current changes |

## Tool Priority for Go Codebase

Enforced via CLAUDE.md — Claude picks tools in this order:

1. `serena` — find_symbol, get_symbols_overview, find_referencing_symbols (symbol nav across files)
2. `gopls-lsp` — hover, diagnostics, type info
3. `codegraph_*` — callers, callees, impact analysis (if `.codegraph/` exists)
4. `ast-grep` — structural search/refactor
5. `mgrep` — string/regex/fuzzy search fallback

Plain `grep` is never used when any of the above apply.

## Mandatory Search Rules

All search is routed through `mgrep` (enforced via CLAUDE.md):
- Web search: `mgrep --web "query"` — never built-in WebSearch
- Code search: `mgrep "query"` — never built-in Grep or Glob

## Token Optimization Summary

| Strategy | Savings |
|----------|---------|
| RTK hook (`rtk-rewrite.sh`) | 60-90% on git/test/build commands |
| read-once hook | 80-95% on repeated file reads within a session |
| ctx-guard hook | Prevents unbounded command output flooding context |
| `.claudeignore` (exclude node_modules, builds) | Prevents irrelevant files in searches |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=40` | Earlier compaction, cleaner context |
| `MAX_THINKING_TOKENS=8000` | ~75% reduction in hidden thinking cost |
| `ENABLE_TOOL_SEARCH=auto:5` | Defer MCP tool defs until 5% context threshold |
| `filter-test-output.sh` | Test suite 500+ lines → ~20 lines |
| `context-mode` plugin | Large output sandboxed, not streamed to context |

## Prerequisites

Required:
- `claude` — Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- `node` — Node.js
- `jq` — JSON processor (`brew install jq`)
- `git`

Recommended (automatic token savings):
- `rtk` — Rust Token Killer: https://github.com/rtk-ai/rtk#installation
- `python3` — for statusline block % calculation
- `bun` — faster JS execution: `curl -fsSL https://bun.sh/install | bash`

Optional (semantic code navigation):
- `uvx` — for Serena MCP: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `gopls` — for gopls-lsp plugin: `go install golang.org/x/tools/gopls@latest`
- `codegraph` — for codegraph-sync hook: see codegraph docs

## Testing Hooks (No API Key Required)

The `promptfoo/` directory contains tests for hook behavior using shell script execution:

```bash
# Run all session-context.sh tests
cd promptfoo && bash test-session-context.sh

# Run via promptfoo (requires promptfoo installed)
npm install -g promptfoo
cd promptfoo && promptfoo eval --filter-pattern "session-context"
```

Tests verify that hint injection fires correctly for Go, debug, implementation, OpenAPI, large-output, and search prompts — without any API calls.

## Manual Setup

```bash
cp CLAUDE.md RTK.md ~/.claude/
cp .claudeignore ~/.claude/.claudeignore
cp hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
cp read-once/hook.sh ~/.claude/read-once/hook.sh && chmod +x ~/.claude/read-once/hook.sh
cp commands/*.md ~/.claude/commands/
jq -s '.[0] * .[1]' ~/.claude/settings.json settings.json > /tmp/merged.json && mv /tmp/merged.json ~/.claude/settings.json
```

MCP servers:
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
claude mcp add --scope user mgrep -- npx -y @mixedbread/mgrep mcp
# Optional: serena (requires uvx)
claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd
```

## Validation Checklist

- [ ] `context-bar` statusline shows burn rate + session % remaining
- [ ] Bash commands auto-rewritten via RTK (run `rtk gain` to verify savings)
- [ ] `docker logs <container>` without `--tail` is blocked by ctx-guard
- [ ] `mgrep "query"` returns semantic results
- [ ] First prompt injects `[Session] project=... branch=... cwd=...`
- [ ] Go prompt appends `[Hint] Go task: tool priority = serena → gopls-lsp → codegraph → mgrep`
- [ ] `go test` output compressed to failures only
- [ ] `/compact` saves git status to `.claude-handOFF.md`
- [ ] Re-reading unchanged files shows read-once advisory in logs
- [ ] `/plan`, `/ask`, `/plannotator-annotate`, `/plannotator-review` available
- [ ] `/mcp` shows: context7, mgrep (+ serena if uvx installed)
- [ ] `/plugins` shows 8 plugins active
