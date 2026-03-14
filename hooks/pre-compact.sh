#!/bin/bash
# PreCompact hook - saves context before compaction

HANDOFF_FILE="$CLAUDE_PROJECT_DIR/.claude-handOFF.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# Get session info from stdin if available
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

# Only run on manual /compact or when context is getting full
if [ "$TOOL_NAME" = "Compact" ] || [ "$TOOL_NAME" = "Task" ]; then
    # Get recent file changes from git
    RECENT_CHANGES=$(git status --short 2>/dev/null | head -20)
    
    # Append to handoff file
    cat >> "$HANDOFF_FILE" << EOF

---
## Session: $TIMESTAMP

### Files Changed
$RECENT_CHANGES

### Context Summary
Auto-saved before compaction
EOF
fi

echo "$INPUT"
