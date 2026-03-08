#!/bin/bash

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

# Block dangerous destructive commands
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+/|DROP\s+TABLE|DROP\s+DATABASE'; then
  echo '{"decision":"block","reason":"Dangerous destructive command blocked. Confirm explicitly with user before proceeding."}' >&2
  exit 2
fi

# Block manual file reading tools — use built-in Read tool instead
if echo "$COMMAND" | grep -qE '^\s*(cat|head|tail)\s+'; then
  echo '{"decision":"block","reason":"Use the built-in Read tool instead of cat/head/tail."}' >&2
  exit 2
fi

# Block manual text processing — use built-in Edit tool instead
if echo "$COMMAND" | grep -qE '^\s*(sed|awk)\s+'; then
  echo '{"decision":"block","reason":"Use the built-in Edit tool instead of sed/awk."}' >&2
  exit 2
fi

# Block manual search tools — use built-in Grep/Glob or mgrep instead
if echo "$COMMAND" | grep -qE '^\s*(grep|rg|find)\s+'; then
  echo '{"decision":"block","reason":"Use the built-in Grep/Glob tools or mgrep MCP tool instead of manual grep/rg/find."}' >&2
  exit 2
fi

exit 0
