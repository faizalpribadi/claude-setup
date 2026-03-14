@RTK.md

## Bash Hook
All Bash commands pass through rtk-rewrite.sh (PreToolUse). Commands may be rewritten before execution — this is expected.

## Constraints
- Thinking budget: 8000 tokens — avoid deep reasoning for simple tasks
- Autocompact at 40% — prioritize concise outputs, avoid verbose exploration
- Non-essential model calls disabled — no speculative reads or unnecessary tool calls

## Search — MANDATORY Rules
- NEVER use built-in `WebSearch` or `Grep` tools directly
- ALL web searches: use `mgrep --web "query"` via the mgrep skill
- ALL local file/code searches: use `mgrep "query"` via the mgrep skill
- mgrep is the single replacement for WebSearch + Grep + Glob

## Tool Priority for Go Codebase
1. `gopls-lsp` — symbol definition, references, hover
2. `codegraph_*` — callers, callees, impact analysis (if `.codegraph/` exists)
3. `ast-grep` — structural search/refactor
4. `mgrep` — semantic/fuzzy search fallback
Avoid plain grep if any of the above apply.

## Context Protection — MANDATORY Rules
- NEVER use `Bash` for commands producing >20 lines of output
- NEVER use `Read` for analysis — use `ctx_execute_file` instead (Read only when editing)
- NEVER use `WebFetch` — use `ctx_fetch_and_index` instead
- Large output commands (test, build, logs, git log): use `ctx_execute` or `ctx_batch_execute`
- Bash is ONLY for: git, mkdir, rm, mv, navigation, short-output commands

## External Docs
For any external library (Fiber, gRPC-Go, GORM, etc): use context7 to fetch up-to-date docs before implementing.

## Session Memory
Use `search(query="...")` MCP tool before asking user for context that may exist in past sessions.

## CodeGraph
If `.codegraph/` exists: prefer `codegraph_search`, `codegraph_callers`, `codegraph_impact` over grep for symbol navigation.
