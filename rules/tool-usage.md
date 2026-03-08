# Tool Usage Rules

## Symbol & File Search

| Need | Tool |
|------|------|
| Find symbol definition | `serena: find_symbol` |
| Find where symbol is used | `serena: find_referencing_symbols` |
| Overview of codebase structure | `serena: get_symbols_overview` |
| Semantic/AI-powered code search | `mgrep` |
| Simple regex pattern search | Built-in `Grep` tool |
| Find files by name/pattern | Built-in `Glob` tool |
| Edit code at symbol level | `serena: replace_symbol_body`, `insert_after_symbol` |

Rule: symbol-based → serena. Semantic search → mgrep. Simple regex → built-in Grep. Never use bash grep/rg/find/cat.

## Library & Framework Documentation
Never guess API signatures. Never use training memory for library APIs.

- Any external package, any language → resolve via `context7` first
- Includes standard library — APIs change between versions
- Sequence: context7 resolve → confirm API → write code

## Discovery vs Implementation
Never mix in the same session.

Discovery (no code written):
```
get_symbols_overview → find_symbol → find_referencing_symbols →
mgrep → write_memory discovery + plan → close session
```

Implementation (scoped to plan only):
```
read_memory plan → one task at a time →
append task-log → run tests → commit
```
