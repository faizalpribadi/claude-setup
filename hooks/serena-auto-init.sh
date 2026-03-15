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
    | tr '\n' ',' \
    | sed 's/,$//')

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
