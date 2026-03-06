# Memory & Session Rules

## After Every Completed Task — append, never overwrite
```
write_memory "task-log.md"
---
[YYYY-MM-DD] Task: <one-line description>
Changed: <symbols / files modified>
Why: <decision rationale>
Tests: <command + actual output>
Next: <remaining work>
---
```

## Before Closing Any Long Session
```
prepare_for_new_conversation
write_memory "session-state.md"
```

## Discovery Phase — write before closing session
```
write_memory "feature-<n>-discovery.md"
  - Affected symbols and files
  - Dependency chain (caller → callee)
  - Risk areas
  - Recommended entry points

write_memory "feature-<n>-plan.md"
  - Tasks in order
  - Each: component + symbol + file path + verification command
```

## Context Management
CLAUDE.md survives compaction. Task context does not — write it to memory.
At context >60%: save state to memory before anything else.
