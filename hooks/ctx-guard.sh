#!/usr/bin/env bash
# PreToolUse:Bash hook — blocks known high-output commands
# Forces use of ctx_execute(language="shell", code="...") to protect context window

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

block() {
  local reason="$1"
  jq -n --arg reason "$reason" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "block",
        "permissionDecisionReason": $reason
      }
    }'
  exit 0
}

# docker logs (unbounded)
if echo "$CMD" | grep -qE 'docker logs [^|]*$' && ! echo "$CMD" | grep -qE '\-\-tail [0-9]+|\-n [0-9]+'; then
  block "High-output command blocked. Use: ctx_execute(language=\"shell\", code=\"$CMD\") — or add --tail 50 to limit output."
fi

# kubectl logs (unbounded)
if echo "$CMD" | grep -qE 'kubectl logs [^|]*$' && ! echo "$CMD" | grep -qE '\-\-tail [0-9]+'; then
  block "High-output command blocked. Use: ctx_execute(language=\"shell\", code=\"$CMD\") — or add --tail 50 to limit output."
fi

# git log without --oneline or -n limit
if echo "$CMD" | grep -qE '^git log$|^git log [^|]*$' && ! echo "$CMD" | grep -qE '\-\-oneline|\-[0-9]+|\-n [0-9]+|head'; then
  block "git log without limit blocked. Use: ctx_execute(language=\"shell\", code=\"$CMD\") — or add --oneline -20 to limit output."
fi

# journalctl unbounded
if echo "$CMD" | grep -qE 'journalctl' && ! echo "$CMD" | grep -qE '\-n [0-9]+|--lines|head'; then
  block "journalctl without limit blocked. Use: ctx_execute(language=\"shell\", code=\"$CMD\") — or add -n 50."
fi

# cat on .log files
if echo "$CMD" | grep -qE '^cat .*\.log'; then
  block "cat on log file blocked. Use: ctx_execute(language=\"shell\", code=\"$CMD\") to process output in sandbox."
fi

exit 0
