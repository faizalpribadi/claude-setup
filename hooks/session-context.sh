#!/usr/bin/env bash
# UserPromptSubmit hook: inject session context (branch, project, cwd)
# Helps Claude understand project context without repeated questions

if ! command -v jq &>/dev/null; then exit 0; fi

CWD=$(pwd)
PROJECT=$(basename "$CWD")
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
REMOTE=$(git -C "$CWD" remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//')
GO_MOD=$([ -f "$CWD/go.mod" ] && grep '^module ' "$CWD/go.mod" | awk '{print $2}' || echo "")

CONTEXT="[Session] project=$PROJECT cwd=$CWD"
[ -n "$BRANCH" ] && CONTEXT="$CONTEXT branch=$BRANCH"
[ -n "$REMOTE" ] && CONTEXT="$CONTEXT repo=$REMOTE"
[ -n "$GO_MOD" ] && CONTEXT="$CONTEXT go_module=$GO_MOD"

# Output as JSON to inject into context
jq -n \
  --arg ctx "$CONTEXT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "additionalContext": $ctx
    }
  }'
