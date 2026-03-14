#!/bin/bash
# Custom statusline: ccusage statusline + block session remaining %
# Claude Code pipes JSON to stdin

STDIN_DATA=$(cat)

# Get ccusage statusline output
CCUSAGE_OUT=$(echo "$STDIN_DATA" | ccusage statusline --visual-burn-rate emoji-text 2>/dev/null)

# Get active block session remaining %
BLOCK_INFO=$(ccusage blocks --json 2>/dev/null | python3 -c "
import sys, json, math
from datetime import datetime, timezone
try:
    data = json.load(sys.stdin)
    blocks = data.get('blocks', [])
    active = next((b for b in blocks if b.get('isActive') and not b.get('isGap')), None)
    if not active:
        sys.exit(0)
    now = datetime.now(timezone.utc)
    start = datetime.fromisoformat(active['startTime'].replace('Z', '+00:00'))
    end   = datetime.fromisoformat(active['endTime'].replace('Z', '+00:00'))
    total_secs = (end - start).total_seconds()
    elapsed_secs = (now - start).total_seconds()
    remaining_secs = max(0, total_secs - elapsed_secs)
    remaining_pct = math.ceil(remaining_secs / total_secs * 100)
    remaining_mins = int(remaining_secs / 60)
    h = remaining_mins // 60
    m = remaining_mins % 60
    if remaining_pct > 50:
        c = '\033[32m'
    elif remaining_pct > 20:
        c = '\033[33m'
    else:
        c = '\033[31m'
    reset = '\033[0m'
    cost = active.get('costUSD', 0)
    print(f'{c}session {remaining_pct}%{reset} ({h}h{m:02d}m left, \${cost:.2f})')
except Exception:
    pass
")

if [ -n "$BLOCK_INFO" ] && [ -n "$CCUSAGE_OUT" ]; then
    echo "$CCUSAGE_OUT | 📊 $BLOCK_INFO"
elif [ -n "$CCUSAGE_OUT" ]; then
    echo "$CCUSAGE_OUT"
elif [ -n "$BLOCK_INFO" ]; then
    echo "📊 $BLOCK_INFO"
fi
