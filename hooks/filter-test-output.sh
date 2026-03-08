#!/bin/bash
# PreToolUse hook — filter test output to show only failures
# Saves thousands of tokens when running large test suites

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only filter known test runners
if [[ "$cmd" =~ ^(go\ test|npm\ test|pytest|yarn\ test|pnpm\ test|make\ test) ]]; then
  # Append filter: show only FAIL/ERROR lines with 5 lines context, cap at 100 lines
  filtered_cmd="$cmd 2>&1 | grep -A 5 -E '(FAIL|ERROR|error:|panic:|--- FAIL)' | head -100"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$filtered_cmd\"}}}"
else
  echo "{}"
fi
