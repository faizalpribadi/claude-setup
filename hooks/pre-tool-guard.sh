#!/bin/bash

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

# Block dangerous commands
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+/|DROP\s+TABLE|DROP\s+DATABASE'; then
  echo '{"decision":"block","reason":"Dangerous destructive command blocked. Confirm explicitly with user before proceeding."}' >&2
  exit 2
fi

# Block manual grep/find when mgrep should be used
if echo "$COMMAND" | grep -qE '^(grep|find)\s+.*\.(go|ts|js|py|java|rs)'; then
  echo '{"decision":"block","reason":"Use mgrep instead of manual grep/find for code search. Call mgrep MCP tool directly."}' >&2
  exit 2
fi

exit 0
