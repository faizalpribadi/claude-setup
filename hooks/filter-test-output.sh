#!/usr/bin/env bash
# PostToolUse:Bash hook — compress large command output to save context tokens
# Covers: tests, build errors, docker/kubectl logs, git log, migrations

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // ""')
LINE_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')

# Only compress if output > 80 lines
if [ "$LINE_COUNT" -le 80 ]; then
  exit 0
fi

compress_and_respond() {
  local label="$1"
  local compressed="$2"
  jq -n \
    --arg output "$compressed" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "toolResponseOverride": $output
      }
    }'
  exit 0
}

# --- Test commands ---
if echo "$CMD" | grep -qE 'go test|npm test|pytest|jest|cargo test|make test|bun test'; then
  FAILURES=$(echo "$OUTPUT" | grep -E '(FAIL|--- FAIL|Error:|panic:|FAILED|✗|✕)' | head -20)
  PASSES=$(echo "$OUTPUT" | grep -E '(ok |--- PASS|PASS|✓|✔|passed)' | tail -5)
  SUMMARY=$(echo "$OUTPUT" | grep -E '(FAIL|ok |coverage:|Tests:|passed|failed)' | tail -10)
  compress_and_respond "test" "[RTK filter: ${LINE_COUNT} lines → compressed]
=== FAILURES ===
${FAILURES:-none}
=== SUMMARY ===
${SUMMARY}
=== PASSES (last 5) ===
${PASSES:-none}"
fi

# --- Go build ---
if echo "$CMD" | grep -qE '^go build|make build'; then
  ERRORS=$(echo "$OUTPUT" | grep -E '(\.go:[0-9]+|undefined|cannot|does not|imported|syntax error)' | head -30)
  compress_and_respond "build" "[RTK filter: ${LINE_COUNT} lines → compressed]
=== BUILD ERRORS ===
${ERRORS:-none}"
fi

# --- Docker / container logs ---
if echo "$CMD" | grep -qE 'docker logs|docker-compose logs|podman logs'; then
  ERRORS=$(echo "$OUTPUT" | grep -iE '(error|fatal|panic|exception|failed|critical)' | tail -20)
  TAIL=$(echo "$OUTPUT" | tail -15)
  compress_and_respond "docker-logs" "[RTK filter: ${LINE_COUNT} lines → compressed]
=== ERRORS/WARNINGS ===
${ERRORS:-none}
=== LAST 15 LINES ===
${TAIL}"
fi

# --- kubectl logs ---
if echo "$CMD" | grep -qE 'kubectl logs|kubectl describe'; then
  ERRORS=$(echo "$OUTPUT" | grep -iE '(error|fatal|panic|backoff|crashloop|oomkilled)' | tail -20)
  TAIL=$(echo "$OUTPUT" | tail -15)
  compress_and_respond "kubectl" "[RTK filter: ${LINE_COUNT} lines → compressed]
=== ERRORS ===
${ERRORS:-none}
=== LAST 15 LINES ===
${TAIL}"
fi

# --- git log ---
if echo "$CMD" | grep -qE 'git log'; then
  HEAD=$(echo "$OUTPUT" | head -40)
  compress_and_respond "git-log" "[RTK filter: ${LINE_COUNT} lines → compressed, showing first 40]
${HEAD}"
fi

# --- Migrations ---
if echo "$CMD" | grep -qE 'migrate|goose|flyway|liquibase'; then
  ERRORS=$(echo "$OUTPUT" | grep -iE '(error|failed|panic)' | head -10)
  TAIL=$(echo "$OUTPUT" | tail -10)
  compress_and_respond "migrate" "[RTK filter: ${LINE_COUNT} lines → compressed]
=== ERRORS ===
${ERRORS:-none}
=== LAST 10 LINES ===
${TAIL}"
fi

# --- Generic fallback: any other command >80 lines ---
TAIL=$(echo "$OUTPUT" | tail -30)
ERRORS=$(echo "$OUTPUT" | grep -iE '(error|Error|ERROR|fatal|panic)' | head -10)
compress_and_respond "generic" "[RTK filter: ${LINE_COUNT} lines → compressed]
=== ERRORS (if any) ===
${ERRORS:-none}
=== LAST 30 LINES ===
${TAIL}"
