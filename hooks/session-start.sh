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

HAS_SERENA=""
[ -d "$CWD/.serena" ] && HAS_SERENA=" (serena project detected)"

# Plain text — works reliably across all Claude Code versions
cat <<EOF
=== SESSION START RITUAL${HAS_SERENA} ===
Before responding, run these steps in order:
1. list_memories
2. read_memory "task-log.md"
3. read_memory "session-state.md" (skip if not found)
4. activate_project
5. check_onboarding_performed
6. initial_instructions
Complete all steps first, then respond to the user.
EOF
