#!/bin/bash
# Fires on PostToolUse for Edit|Write|MultiEdit
# Reminds Claude to write memory after code changes — once per session

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

LOCK_FILE="/tmp/claude-memory-reminder-${SESSION_ID}"

# Only remind once per session to avoid noise
if [ -f "$LOCK_FILE" ]; then
  exit 0
fi

# Only act on actual file modifications
if [[ "$TOOL" =~ ^(Edit|Write|MultiEdit)$ ]] && [ -n "$FILE" ]; then
  touch "$LOCK_FILE"
  find /tmp -name "claude-memory-reminder-*" -mtime +1 -delete 2>/dev/null
  echo "{\"additionalContext\": \"File modified: ${FILE}. After completing this task, call write_memory task-log.md with: date, task description, changed symbols/files, rationale, test results, and next steps.\"}"
fi

exit 0
