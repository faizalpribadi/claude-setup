#!/bin/bash

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

if [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Count actual turns (assistant messages) as proxy for context usage
TURNS=$(grep -c '"role":"assistant"' "$TRANSCRIPT" 2>/dev/null || echo "0")

# Warn after 20+ assistant turns (~60% context proxy)
if [ "$TURNS" -gt 20 ]; then
  echo "⚠ Context warning: ${TURNS} turns in this session. Consider running: prepare_for_new_conversation → write_memory session-state.md → open new session."
fi

exit 0
