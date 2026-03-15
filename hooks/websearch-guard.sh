#!/usr/bin/env bash
# PreToolUse:WebSearch — hard block direct WebSearch, enforce mgrep --web
# Prevents context flooding from raw web search results

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
QUERY=$(echo "$INPUT" | jq -r '.tool_input.query // ""')

jq -n --arg q "$QUERY" \
  '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "block",
    "permissionDecisionReason": ("WebSearch blocked. Use mgrep skill instead: mgrep --web \"" + $q + "\"")}}'

exit 0
