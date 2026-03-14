# Claude Code Environment Variables
# NOTE: These are now managed via settings.json "env" block (preferred).
# Source this file only for shells where Claude Code isn't managing the env.

export ENABLE_TOOL_SEARCH=auto:5              # defer MCP tools at 5% context (default 10%)
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1   # suppress background model calls
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=40    # compact at 40% context, not 95%
export MAX_THINKING_TOKENS=8000              # reduce hidden thinking (default: 31999)
