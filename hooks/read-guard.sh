#!/usr/bin/env bash
# PreToolUse:Read — advisory hint for .go files: try serena first
# Does NOT hard block — Read is needed for editing. Soft advisory only.

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only advise on .go files
if [[ "$FILE" != *.go ]]; then
  exit 0
fi

# Return advisory context — not a block
jq -n --arg f "$FILE" \
  '{"hookSpecificOutput": {"hookEventName": "PreToolUse",
    "additionalContext": ("Go file detected: try serena first — find_symbol or get_symbols_overview on \"" + ($f | split("/") | last) + "\" before reading the full file.")}}'

exit 0
