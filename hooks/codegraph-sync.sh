#!/usr/bin/env bash
# PostToolUse:Bash hook — auto-sync codegraph after git pull/merge/checkout
# Keeps .codegraph/ index fresh without manual intervention

if ! command -v jq &>/dev/null; then exit 0; fi
if ! command -v codegraph &>/dev/null; then exit 0; fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only trigger on git operations that change working tree
if ! echo "$CMD" | grep -qE 'git (pull|merge|rebase|checkout|switch|reset)'; then
  exit 0
fi

# Find the working directory from hook input or fallback to pwd
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && CWD=$(pwd)

# Walk up to find nearest .codegraph/
SEARCH_DIR="$CWD"
CODEGRAPH_ROOT=""
for _ in 1 2 3 4 5; do
  if [ -d "$SEARCH_DIR/.codegraph" ]; then
    CODEGRAPH_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

if [ -z "$CODEGRAPH_ROOT" ]; then
  # Auto-init: if go.mod exists in CWD but .codegraph/ never initialized
  if [ -f "$CWD/go.mod" ] && [ ! -d "$CWD/.codegraph" ]; then
    (cd "$CWD" && codegraph init . > /tmp/codegraph-init.log 2>&1) &
  fi
  exit 0
fi

# Run sync in background — non-blocking, don't delay Claude
(cd "$CODEGRAPH_ROOT" && codegraph sync . > /tmp/codegraph-sync.log 2>&1) &

exit 0
