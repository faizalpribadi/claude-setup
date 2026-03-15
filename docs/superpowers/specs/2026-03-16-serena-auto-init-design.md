# Serena Auto-Init Design

**Date:** 2026-03-16
**Status:** Approved
**Scope:** Automate `.serena/project.yml` creation for new Go projects via PostToolUse:Bash hook

---

## Problem

Serena requires `.serena/project.yml` per project. Currently this means:
1. Install `uvx`
2. Run `uvx ... serena project create` interactively
3. Manually write `initial_prompt`

This is a friction point for every new Go project. Without it, serena starts with no project context — `initial_prompt` stays empty and symbol navigation lacks useful context.

---

## Goal

Zero-friction serena initialization: when a developer starts working in any Go project (detected by `go.mod`), `.serena/project.yml` is automatically generated with a meaningful `initial_prompt` — no manual steps required.

---

## Chosen Approach: PostToolUse:Bash Hook

A new hook `serena-auto-init.sh` fires after every Bash command. If `go.mod` is present and `.serena/project.yml` is absent, it generates the config file in the background.

This matches the existing `codegraph-sync.sh` pattern exactly — consistent, non-blocking, zero user action.

---

## Architecture

### Hook: `hooks/serena-auto-init.sh`

**Event:** `PostToolUse:Bash`
**Trigger conditions:**
- `go.mod` found in CWD or up to 3 parent dirs
- `.serena/project.yml` does NOT already exist (idempotent)

**Execution:** Runs in background (`&`) — never blocks Claude. Logs to `/tmp/serena-auto-init.log`.

### `project.yml` Generation (pure bash, no interactive CLI)

Writes `.serena/project.yml` directly. No `serena project create` call needed.

**Fields:**

| Field | Value | Source |
|-------|-------|--------|
| `project_name` | last segment of module path | `grep '^module' go.mod \| awk '{print $2}' \| xargs basename` |
| `languages` | `[go]` | hardcoded |
| `ignore_all_files_in_gitignore` | `true` | hardcoded |
| `ignored_paths` | `[]` | hardcoded |
| `read_only` | `false` | hardcoded |
| `initial_prompt` | auto-generated (see below) | go.mod + dir scan |

### Auto-Generated `initial_prompt`

```
project is a Go module: <full module path>
top-level packages: <immediate subdirs with .go files, max 20>
dependencies: <detected libs from go.mod: fiber, gorm, grpc, oapi-codegen, redis, kafka, nats>
Always use find_symbol before reading files.
Prefer find_referencing_symbols over grep when tracing callers.
```

Generation logic:
- **module path**: `grep '^module' go.mod | awk '{print $2}'`
- **project_name**: `basename <module_path>`
- **top_dirs**: `find . -maxdepth 2 -name '*.go' | cut -d/ -f2 | sort -u | head -20`
- **deps**: grep scoped to the `require (...)` block in go.mod — `awk '/^require/,/^\)/' go.mod | grep -oE 'fiber|gorm|google\.golang\.org/grpc|oapi-codegen|go-redis|confluent-kafka|nats-io' | sort -u`

---

## File Changes

| File | Change |
|------|--------|
| `hooks/serena-auto-init.sh` | **New** — PostToolUse:Bash hook |
| `settings.json` | Add `serena-auto-init.sh` to `PostToolUse.Bash.hooks` array |
| `install.sh` | Copy + chmod new hook to `~/.claude/hooks/` |
| `README.md` | Hook count 11→12, add row to hooks table + project structure |

---

## Error Handling

- `go.mod` not found → silent exit (not a Go project)
- `.serena/project.yml` already exists → silent exit (idempotent)
- Write failure → logged to `/tmp/serena-auto-init.log`, does not surface to Claude

---

## Non-Goals

- Does not modify existing `.serena/project.yml` files
- Does not call `serena project create` or any uvx command
- Does not add Python/Node/other language support (Go only)
- Does not regenerate `initial_prompt` if `project.yml` already exists

---

## Success Criteria

1. First Bash command in a new Go project triggers auto-creation of `.serena/project.yml`
2. Generated `initial_prompt` contains module name, detected dirs, and detected deps
3. Hook is non-blocking (background process)
4. Idempotent — re-running never overwrites existing config
5. Graceful degradation when `uvx` is absent
