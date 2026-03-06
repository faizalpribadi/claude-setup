# Plan Writing Rules

## Each Task Must Include
- Affected component name (explicit)
- Exact file path + symbol to create or modify
- Full verification command (exact, not "run tests")
- Expected output of verification

## Plan Structure
```
## Plan: <feature name>

### Prerequisites
- Clean git state
- SPEC.md approved
- Discovery memory read

### Tasks

#### Task 1: <description>
- Component: <name>
- File: <exact/path/to/file>
- Symbol: <FunctionName or TypeName>
- Action: create | modify | delete
- Verify: `<exact command>` → expected: <output>
```

## Constraints
- Max 2 components touched per task
- Schema/migration changes = separate dedicated task
- Each task independently reviewable
- No task larger than 30 minutes of focused work

## Before Writing Plan
- SPEC.md approved
- Discovery memory read
- Use `find_symbol` to verify all named symbols exist before referencing them
