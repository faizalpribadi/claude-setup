#!/bin/bash
# Unit tests for session-context.sh hint injection
# No API key required — tests shell script output directly
# Usage: bash ~/.claude/promptfoo/test-session-context.sh

HOOK="$HOME/.claude/hooks/session-context.sh"
PASS=0; FAIL=0

check() {
  local desc="$1"
  local prompt="$2"
  local expected="$3"
  local result
  result=$(echo "{\"prompt\":\"$prompt\"}" | "$HOOK" 2>/dev/null)
  if echo "$result" | grep -q "$expected"; then
    echo "✓ $desc"
    PASS=$((PASS+1))
  else
    echo "✗ $desc"
    echo "  expected: '$expected'"
    echo "  got: $result"
    FAIL=$((FAIL+1))
  fi
}

echo "=== session-context.sh hint tests ==="

check "Go hint triggers on .go mention"       "refactor this handler.go file"           "gopls"
check "Debug hint triggers on fix keyword"    "fix this bug in the service"             "systematic-debugging"
check "Implement hint triggers on implement"  "implement a new endpoint"                "brainstorm"
check "OpenAPI hint triggers on openapi"      "update the openapi spec for endpoint"    "generated"
check "Large output hint triggers on docker"  "check docker logs for the service"       "ctx_execute"
check "Search hint triggers on cari"          "cari function untuk handle JWT"          "mgrep"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
