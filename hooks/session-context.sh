#!/usr/bin/env bash
# UserPromptSubmit hook: inject session context + rule-based prompt enrichment
# Helps Claude understand project context and invoke correct skills/tools

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')

CWD=$(pwd)
PROJECT=$(basename "$CWD")
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
REMOTE=$(git -C "$CWD" remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//')
GO_MOD=$([ -f "$CWD/go.mod" ] && grep '^module ' "$CWD/go.mod" | awk '{print $2}' || echo "")

CONTEXT="[Session] project=$PROJECT cwd=$CWD"
[ -n "$BRANCH" ] && CONTEXT="$CONTEXT branch=$BRANCH"
[ -n "$REMOTE" ] && CONTEXT="$CONTEXT repo=$REMOTE"
[ -n "$GO_MOD" ] && CONTEXT="$CONTEXT go_module=$GO_MOD"

# --- Rule-based prompt enrichment (zero extra model calls) ---
HINTS=()

# Feature/implementation work → brainstorm first
if echo "$PROMPT" | grep -qiE 'buat|tambah|implement|feature|add|create|new (endpoint|handler|service|repo|migration)'; then
  HINTS+=("[Hint] Implementation task detected: invoke brainstorming skill before writing code")
fi

# Debug/fix → systematic debugging first
if echo "$PROMPT" | grep -qiE 'debug|fix|error|bug|gagal|tidak bisa|broken|panic|nil pointer|crash|fail'; then
  HINTS+=("[Hint] Debug task detected: invoke systematic-debugging skill before proposing fixes")
fi

# Go code work → tool priority reminder
if echo "$PROMPT" | grep -qiE '\.go|func |struct |interface |go\.mod|handler|repository|service|middleware|migration'; then
  HINTS+=("[Hint] Go task: tool priority = gopls-lsp → codegraph → mgrep (avoid plain grep)")
fi

# OpenAPI/codegen work
if echo "$PROMPT" | grep -qiE 'openapi|oapi|codegen|generated|endpoint|spec|swagger'; then
  HINTS+=("[Hint] OpenAPI task: use generated.* types for request/response, never define manually")
fi

# Large output risk → context protection reminder
if echo "$PROMPT" | grep -qiE 'log|docker|kubectl|git log|build output|test output|semua|list all'; then
  HINTS+=("[Hint] Potentially large output: use ctx_execute / ctx_batch_execute, not Bash directly")
fi

# Search task → mgrep reminder
if echo "$PROMPT" | grep -qiE '^(cari|find|search|dimana|where is|locate)\b'; then
  HINTS+=("[Hint] Search task: use mgrep skill (not Grep/Glob/WebSearch directly)")
fi

# Append hints to context if any matched
if [ ${#HINTS[@]} -gt 0 ]; then
  HINT_STR=$(printf '%s | ' "${HINTS[@]}")
  HINT_STR="${HINT_STR% | }"
  CONTEXT="$CONTEXT | $HINT_STR"
fi

jq -n \
  --arg ctx "$CONTEXT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "additionalContext": $ctx
    }
  }'
