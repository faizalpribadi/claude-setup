#!/usr/bin/env bash
# PreToolUse:WebFetch — hard block direct WebFetch, enforce ctx_fetch_and_index
# Prevents raw HTML/doc content from flooding context window

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
URL=$(echo "$INPUT" | jq -r '.tool_input.url // ""')

jq -n --arg url "$URL" \
  '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "block",
    "permissionDecisionReason": ("WebFetch blocked. Use ctx_fetch_and_index(url=\"" + $url + "\") to fetch and index without flooding context.")}}'

exit 0
