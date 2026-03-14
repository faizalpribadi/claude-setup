#!/usr/bin/env bash
# PostToolUse hook: filter/compress long test output to save context tokens
# Triggers on Bash tool after test commands produce large output

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // ""')

# Only process test commands
if ! echo "$CMD" | grep -qE 'go test|npm test|pytest|jest|cargo test|make test|bun test'; then
  exit 0
fi

LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')

# Only compress if output > 80 lines
if [ "$LINE_COUNT" -le 80 ]; then
  exit 0
fi

FAILURES=$(echo "$OUTPUT" | grep -E '(FAIL|--- FAIL|Error:|panic:|FAILED|✗|✕)' | head -20)
PASSES=$(echo "$OUTPUT" | grep -E '(ok |--- PASS|PASS|✓|✔|passed)' | tail -5)
SUMMARY=$(echo "$OUTPUT" | grep -E '(FAIL|ok |coverage:|Tests:|passed|failed)' | tail -10)

COMPRESSED="[RTK filter: ${LINE_COUNT} lines → compressed]
=== FAILURES ===
${FAILURES:-none}
=== SUMMARY ===
${SUMMARY}
=== PASSES (last 5) ===
${PASSES:-none}"

jq -n \
  --arg output "$COMPRESSED" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "toolResponseOverride": $output
    }
  }'
