#!/bin/bash
# PreCompact hook - saves context before compaction

# Get stdin first (before any other operations)
INPUT=$(cat)

# Try multiple ways to get project directory
# Priority: 1. env var, 2. stdin cwd field
if [ -n "$CLAUDE_PROJECT_DIR" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    PROJECT_DIR="$CLAUDE_PROJECT_DIR"
else
    # Get from stdin - Claude Code always passes 'cwd' in hook input
    # For PreCompact, it's triggered by Compact or Task tool
    PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    
    # Fallback: use pwd (current working directory)
    if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
        PROJECT_DIR=$(pwd)
    fi
fi

# Verify PROJECT_DIR exists and is writable
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    echo "$INPUT"
    exit 0
fi

HANDOFF_FILE="$PROJECT_DIR/.claude-handOFF.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# PreCompact fires only before actual compaction (auto or manual) — always write handoff
# Create handoff file if it doesn't exist
if [ ! -f "$HANDOFF_FILE" ]; then
    cat > "$HANDOFF_FILE" << 'HEADER'
# Claude Code HandOFF

This file saves context before compaction for continuity in next session.

---
HEADER
fi

# Get git context
cd "$PROJECT_DIR" 2>/dev/null || true
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
RECENT_CHANGES=$(git status --short 2>/dev/null | head -20)
RECENT_COMMITS=$(git log --oneline -10 2>/dev/null || echo "no commits")
MODIFIED_FILES=$(git diff --name-only HEAD~5 2>/dev/null | head -20 || echo "")

# Append to handoff file
cat >> "$HANDOFF_FILE" << EOF

## Session: $TIMESTAMP

### Branch
$BRANCH

### Recent Commits (last 10)
$RECENT_COMMITS

### Working Tree Changes
$RECENT_CHANGES

### Recently Modified Files (HEAD~5)
$MODIFIED_FILES

### Context Summary
Auto-saved before compaction
EOF

echo "$INPUT"
