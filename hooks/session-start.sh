#!/bin/bash

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

LOCK_FILE="/tmp/claude-ritual-${SESSION_ID}"

# Only inject once per session
if [ -f "$LOCK_FILE" ]; then
  exit 0
fi

touch "$LOCK_FILE"
find /tmp -name "claude-ritual-*" -mtime +1 -delete 2>/dev/null

if [ -d "$CWD/.serena" ]; then
  cat <<EOF
=== SESSION START RITUAL (serena project detected) ===
Before responding, run these steps in order:
1. list_memories
2. read_memory "task-log.md"
3. read_memory "session-state.md" (skip if not found)
4. activate_project
5. check_onboarding_performed
6. initial_instructions
Complete all steps first, then respond to the user.
EOF
else
  cat <<EOF
=== SESSION START RITUAL ===
Before responding, run these steps in order:
1. list_memories (if available)
2. read_memory "task-log.md" (if relevant)
Then respond to the user.
EOF
fi
