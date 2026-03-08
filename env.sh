# Claude Code Environment Variables
# Add to ~/.zshrc or source this file

export ENABLE_TOOL_SEARCH=auto:5              # defer MCP tools at 5% context (default 10%)
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1   # suppress background model calls
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50    # compact at 50% context, not 95%
export MAX_THINKING_TOKENS=8000              # reduce hidden thinking (default: 31999)
