#!/bin/bash
# Fires on PostToolUse for Edit|Write|MultiEdit
# Reminds Claude to write memory after code changes

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Only act on actual file modifications
if [[ "$TOOL" =~ ^(Edit|Write|MultiEdit)$ ]] && [ -n "$FILE" ]; then
  echo "{\"additionalContext\": \"File modified: ${FILE}. After completing this task, call write_memory task-log.md with: date, task description, changed symbols/files, rationale, test results, and next steps. Do not skip this.\"}"
fi

exit 0
