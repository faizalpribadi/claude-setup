# Tool Usage Rules

## Symbol & File Search
Never read entire files. Never search manually with bash find/grep.

| Need | Tool |
|------|------|
| Find symbol definition | `serena: find_symbol` |
| Find where symbol is used | `serena: find_referencing_symbols` |
| Overview of codebase structure | `serena: get_symbols_overview` |
| Find string / constant / pattern | `mgrep` |
| Find config keys, env vars, error strings | `mgrep` |
| Edit code at symbol level | `serena: insert_after_symbol`, `replace_symbol_body` |

Rule: symbol-based → serena. Raw string pattern → mgrep. Never open files speculatively.

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
read_memory plan → one task at a time → think_about_task_adherence →
append task-log → run tests → commit
```

## Forbidden
- Opening entire files to find one function
- Using bash grep/find manually when mgrep exists
- Calling context7 after writing code — call it before
