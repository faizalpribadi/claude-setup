# Serena Auto-Init Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hooks/serena-auto-init.sh` — a PostToolUse:Bash hook that automatically creates `.serena/project.yml` in any Go project where `go.mod` exists but `.serena/` does not.

**Architecture:** Pure bash hook, no external dependencies. Detects Go project root by walking up from CWD. Generates `project.yml` directly (no interactive CLI). Runs in background — never blocks Claude. Registered in `settings.json` PostToolUse:Bash alongside existing hooks.

**Tech Stack:** bash, jq, awk, grep, find

**Spec:** `docs/superpowers/specs/2026-03-16-serena-auto-init-design.md`

---

## Chunk 1: Hook Implementation

### Task 1: Create `hooks/serena-auto-init.sh`

**Files:**
- Create: `hooks/serena-auto-init.sh`

- [ ] **Step 1: Create the hook file**

```bash
#!/usr/bin/env bash
# PostToolUse:Bash hook — auto-init .serena/project.yml for Go projects
# Triggers when go.mod is present but .serena/ does not exist yet
# Non-blocking: runs in background, logs to /tmp/serena-auto-init.log

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && CWD=$(pwd)

# Walk up max 3 dirs to find go.mod
SEARCH_DIR="$CWD"
PROJECT_ROOT=""
for _ in 1 2 3; do
  if [ -f "$SEARCH_DIR/go.mod" ]; then
    PROJECT_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

# Not a Go project
[ -z "$PROJECT_ROOT" ] && exit 0

# Already initialized — idempotent
[ -f "$PROJECT_ROOT/.serena/project.yml" ] && exit 0

# Generate project.yml in background
(
  set -e

  MODULE=$(grep '^module' "$PROJECT_ROOT/go.mod" | awk '{print $2}')
  PROJECT_NAME=$(basename "$MODULE")

  # Top-level dirs containing .go files (max 20)
  TOP_DIRS=$(find "$PROJECT_ROOT" -maxdepth 2 -name '*.go' \
    | sed "s|$PROJECT_ROOT/||" \
    | cut -d/ -f1 \
    | sort -u \
    | grep -v '^\.' \
    | head -20 \
    | tr '\n' ' ' \
    | sed 's/ $//')

  # Deps — scoped to require block only
  DEPS=$(awk '/^require/,/^\)/' "$PROJECT_ROOT/go.mod" \
    | grep -oE 'fiber|gorm|google\.golang\.org/grpc|oapi-codegen|go-redis|confluent-kafka|nats-io' \
    | sort -u \
    | tr '\n' ', ' \
    | sed 's/, $//')

  PROMPT="project is a Go module: ${MODULE}"
  [ -n "$TOP_DIRS" ] && PROMPT="${PROMPT}
top-level packages: ${TOP_DIRS}"
  [ -n "$DEPS" ]     && PROMPT="${PROMPT}
dependencies: ${DEPS}"
  PROMPT="${PROMPT}
Always use find_symbol before reading files.
Prefer find_referencing_symbols over grep when tracing callers."

  mkdir -p "$PROJECT_ROOT/.serena"

  cat > "$PROJECT_ROOT/.serena/project.yml" <<EOF
project_name: ${PROJECT_NAME}
languages:
  - go
ignore_all_files_in_gitignore: true
ignored_paths: []
read_only: false
initial_prompt: |
$(echo "$PROMPT" | sed 's/^/  /')
EOF

  echo "[serena-auto-init] initialized $PROJECT_ROOT/.serena/project.yml" \
    >> /tmp/serena-auto-init.log

) >> /tmp/serena-auto-init.log 2>&1 &

exit 0
```

Save to `hooks/serena-auto-init.sh`.

- [ ] **Step 2: Make executable**

```bash
chmod +x hooks/serena-auto-init.sh
```

- [ ] **Step 3: Smoke-test the script in a temp Go project**

```bash
mkdir -p /tmp/test-go-proj
cat > /tmp/test-go-proj/go.mod <<'EOF'
module github.com/acme/my-service

go 1.21

require (
  github.com/gofiber/fiber/v2 v2.52.0
  gorm.io/gorm v1.25.0
)
EOF
mkdir -p /tmp/test-go-proj/internal
touch /tmp/test-go-proj/internal/handler.go

# Simulate hook invocation
echo '{"cwd":"/tmp/test-go-proj"}' | bash hooks/serena-auto-init.sh
sleep 0.3
cat /tmp/test-go-proj/.serena/project.yml
```

Expected output:
```yaml
project_name: my-service
languages:
  - go
ignore_all_files_in_gitignore: true
ignored_paths: []
read_only: false
initial_prompt: |
  project is a Go module: github.com/acme/my-service
  top-level packages: internal
  dependencies: fiber, gorm
  Always use find_symbol before reading files.
  Prefer find_referencing_symbols over grep when tracing callers.
```

- [ ] **Step 4: Verify idempotency**

```bash
BEFORE=$(cat /tmp/test-go-proj/.serena/project.yml)
echo '{"cwd":"/tmp/test-go-proj"}' | bash hooks/serena-auto-init.sh
sleep 0.1
AFTER=$(cat /tmp/test-go-proj/.serena/project.yml)
[ "$BEFORE" = "$AFTER" ] && echo "idempotency: OK" || echo "idempotency: FAIL — file was overwritten"
```

- [ ] **Step 5: Verify graceful exit for non-Go dirs**

```bash
echo '{"cwd":"/tmp"}' | bash hooks/serena-auto-init.sh
echo "exit code: $?"
# Expected: exit 0, no .serena/ created in /tmp
```

- [ ] **Step 6: Commit**

```bash
git add hooks/serena-auto-init.sh
git commit -m "feat: add serena-auto-init PostToolUse hook for Go projects"
```

---

## Chunk 2: Registration + Deployment

### Task 2: Register hook in `settings.json`

**Files:**
- Modify: `settings.json` (PostToolUse:Bash hooks array)

- [ ] **Step 1: Add serena-auto-init.sh to PostToolUse:Bash in settings.json**

Current PostToolUse:Bash hooks array:
```json
"hooks": [
  {"type": "command", "command": "~/.claude/hooks/filter-test-output.sh"},
  {"type": "command", "command": "~/.claude/hooks/codegraph-sync.sh"}
]
```

Add after codegraph-sync.sh:
```json
{"type": "command", "command": "~/.claude/hooks/serena-auto-init.sh"}
```

Final array:
```json
"hooks": [
  {"type": "command", "command": "~/.claude/hooks/filter-test-output.sh"},
  {"type": "command", "command": "~/.claude/hooks/codegraph-sync.sh"},
  {"type": "command", "command": "~/.claude/hooks/serena-auto-init.sh"}
]
```

- [ ] **Step 2: Validate JSON**

```bash
jq . settings.json > /dev/null && echo "settings.json: valid JSON"
```

Expected: `settings.json: valid JSON`

- [ ] **Step 3: Commit**

```bash
git add settings.json
git commit -m "feat: register serena-auto-init hook in settings.json"
```

### Task 3: Deploy to `~/.claude`

**Files:**
- Deploy: `~/.claude/hooks/serena-auto-init.sh`
- Deploy: `~/.claude/settings.json` (updated)

- [ ] **Step 1: Copy hook to ~/.claude/hooks/**

```bash
cp hooks/serena-auto-init.sh ~/.claude/hooks/serena-auto-init.sh
chmod +x ~/.claude/hooks/serena-auto-init.sh
```

- [ ] **Step 2: Merge settings.json into ~/.claude/settings.json**

```bash
jq -s '.[0] * .[1]' ~/.claude/settings.json settings.json > /tmp/merged.json \
  && mv /tmp/merged.json ~/.claude/settings.json
```

- [ ] **Step 3: Verify hook appears in deployed settings**

```bash
jq '.hooks.PostToolUse[0].hooks | map(.command)' ~/.claude/settings.json
```

Expected output includes `"~/.claude/hooks/serena-auto-init.sh"`.

- [ ] **Step 4: End-to-end test against a real Go project**

```bash
# Use a temp project with go.mod
rm -rf /tmp/e2e-go-proj
mkdir -p /tmp/e2e-go-proj/cmd
cat > /tmp/e2e-go-proj/go.mod <<'EOF'
module github.com/test/e2e-service

go 1.22

require (
  github.com/gofiber/fiber/v2 v2.52.0
)
EOF
touch /tmp/e2e-go-proj/cmd/main.go

# Invoke hook directly (simulates PostToolUse:Bash)
echo '{"cwd":"/tmp/e2e-go-proj"}' | ~/.claude/hooks/serena-auto-init.sh
sleep 0.3
cat /tmp/e2e-go-proj/.serena/project.yml
```

Expected: `project.yml` with `project_name: e2e-service`, `languages: [go]`, `initial_prompt` containing module + dirs.

---

## Chunk 3: Documentation

### Task 4: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update hook count 11 → 12 in README header**

In the "Hooks (11 total)" heading, change to "Hooks (12 total)".

- [ ] **Step 2: Add row to hooks table**

After the `codegraph-sync.sh` row, add:
```markdown
| `serena-auto-init.sh` | PostToolUse:Bash | Auto-generate `.serena/project.yml` from `go.mod` + dir scan when serena not yet initialized |
```

- [ ] **Step 3: Add entry to project structure tree**

After `codegraph-sync.sh` line in the tree:
```
│   └── serena-auto-init.sh    # PostToolUse:Bash — auto-init .serena/project.yml for Go projects
```

- [ ] **Step 4: Commit all**

```bash
git add README.md
git commit -m "docs: update README for serena-auto-init hook (12 total)"
```

- [ ] **Step 5: Push**

```bash
git push
```
