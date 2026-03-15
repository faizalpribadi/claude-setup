# Promptfoo + Serena MCP Setup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add promptfoo for prompt regression testing and serena MCP for token-efficient code navigation.

**Architecture:** Two independent additions — promptfoo as a standalone CLI eval tool under `~/.claude/promptfoo/`, and serena as a user-scoped MCP server registered via `claude mcp add`.

**Tech Stack:** promptfoo (Node.js CLI), serena (Python/uvx, oraios/serena), Claude API (claude-sonnet-4-6)

---

## Chunk 1: Promptfoo Installation and Config

### Task 1: Install promptfoo globally

**Files:**
- No files created — global npm install

- [ ] **Step 1: Install promptfoo**

```bash
npm install -g promptfoo
```

- [ ] **Step 2: Verify installation**

```bash
promptfoo --version
```
Expected: version string like `0.x.x`

- [ ] **Step 3: Verify binary path**

```bash
which promptfoo
```
Expected: `/usr/local/bin/promptfoo` or similar (not "not found")

---

### Task 2: Create promptfoo directory and config

**Files:**
- Create: `~/.claude/promptfoo/promptfooconfig.yaml`
- Create: `~/.claude/promptfoo/tests/session-context-hints.yaml`

- [ ] **Step 1: Create directory**

```bash
mkdir -p ~/.claude/promptfoo/tests
```

- [ ] **Step 2: Create main config**

Create `~/.claude/promptfoo/promptfooconfig.yaml`:

```yaml
# Promptfoo config for evaluating ~/.claude session-context hints
# and CLAUDE.md rule effectiveness
description: "Claude Code setup prompt evaluation"

providers:
  - id: anthropic:messages:claude-sonnet-4-6
    config:
      temperature: 0

# Prompt template for API-based tests (uses vars.systemPrompt and vars.prompt)
prompts:
  - "{{prompt}}"

defaultTest:
  options:
    provider: anthropic:messages:claude-sonnet-4-6

tests:
  - file: tests/session-context-hints.yaml
```

- [ ] **Step 3: Verify session-context.sh is executable (prerequisite for hint tests)**

```bash
test -x ~/.claude/hooks/session-context.sh && echo "OK" || echo "MISSING or not executable"
```
Expected: `OK` — if not, run `chmod +x ~/.claude/hooks/session-context.sh` before continuing.

- [ ] **Step 4: Create session-context hint tests**

Create `~/.claude/promptfoo/tests/session-context-hints.yaml`:

```yaml
# Tests that verify session-context.sh hint injection works correctly
# These test the SCRIPT OUTPUT (no API cost) via shell assertions

- description: "Go task hint triggers on .go mention"
  vars:
    prompt: "refactor this handler.go file"
  assert:
    - type: javascript
      value: |
        // Simulate session-context.sh output check
        const { execSync } = require('child_process');
        const result = execSync(`echo '{"prompt":"${vars.prompt}"}' | ~/.claude/hooks/session-context.sh`).toString();
        return result.includes('gopls') || result.includes('Go task');

- description: "Debug hint triggers on fix/error keywords"
  vars:
    prompt: "fix this bug in the service"
  assert:
    - type: javascript
      value: |
        const { execSync } = require('child_process');
        const result = execSync(`echo '{"prompt":"${vars.prompt}"}' | ~/.claude/hooks/session-context.sh`).toString();
        return result.includes('systematic-debugging') || result.includes('Debug task');

- description: "Implementation hint triggers on add/implement"
  vars:
    prompt: "implement a new endpoint for user registration"
  assert:
    - type: javascript
      value: |
        const { execSync } = require('child_process');
        const result = execSync(`echo '{"prompt":"${vars.prompt}"}' | ~/.claude/hooks/session-context.sh`).toString();
        return result.includes('brainstorm') || result.includes('Implementation task');

- description: "OpenAPI hint triggers on codegen"
  vars:
    prompt: "update the openapi spec for this endpoint"
  assert:
    - type: javascript
      value: |
        const { execSync } = require('child_process');
        const result = execSync(`echo '{"prompt":"${vars.prompt}"}' | ~/.claude/hooks/session-context.sh`).toString();
        return result.includes('generated') || result.includes('OpenAPI task');

- description: "Large output hint triggers on log/docker"
  vars:
    prompt: "check docker logs for the service"
  assert:
    - type: javascript
      value: |
        const { execSync } = require('child_process');
        const result = execSync(`echo '{"prompt":"${vars.prompt}"}' | ~/.claude/hooks/session-context.sh`).toString();
        return result.includes('ctx_execute') || result.includes('large output');

- description: "Search hint triggers on find/cari"
  vars:
    prompt: "cari function untuk handle JWT"
  assert:
    - type: javascript
      value: |
        const { execSync } = require('child_process');
        const result = execSync(`echo '{"prompt":"${vars.prompt}"}' | ~/.claude/hooks/session-context.sh`).toString();
        return result.includes('mgrep') || result.includes('Search task');
```

- [ ] **Step 6: Run script-only eval to verify setup (no API cost)**

```bash
cd ~/.claude/promptfoo && promptfoo eval --no-cache --filter-pattern "session-context" --output json 2>&1 | tail -5
```
Expected: JSON output containing `"totalTests": 6` and `"totalPass": 6` (or specific failure messages if any hint patterns don't match).

- [ ] **Step 7: Commit**

```bash
cd ~/.claude && git add promptfoo/ docs/superpowers/plans/2026-03-15-promptfoo-serena-setup.md
git commit -m "feat: add promptfoo eval setup for CLAUDE.md and session-context testing"
```

---

## Chunk 2: Serena MCP Installation

### Task 3: Register serena as user-scoped MCP server

**Files:**
- Modify: `~/.claude/mcp.json` (via `claude mcp add`, not manual edit)

- [ ] **Step 1: Add serena via claude mcp add**

```bash
claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd
```
Expected: "MCP server serena added" confirmation

- [ ] **Step 2: Verify mcp.json updated**

```bash
cat ~/.claude/mcp.json
```
Expected: serena entry added alongside codegraph

- [ ] **Step 3: Restart Claude Code and verify**

After restart, run in a new session:
```
/mcp
```
Expected: serena listed as active MCP server

- [ ] **Step 4: Test serena in a Go project**

Navigate to your Go project directory and ask Claude:
```
find the NewUserRepository constructor
```
Claude should use serena tools (not codegraph or grep) for symbol lookup.

- [ ] **Step 5: Commit mcp.json update**

```bash
cd ~/.claude && git add mcp.json
git commit -m "feat: add serena MCP for token-efficient code navigation"
```

---

## Usage Reference

```bash
# Run all promptfoo evals
cd ~/.claude/promptfoo && promptfoo eval

# Run only script-level tests (no API cost)
cd ~/.claude/promptfoo && promptfoo eval --filter-pattern "session-context"

# View results in browser
cd ~/.claude/promptfoo && promptfoo view

# Check serena MCP status
claude mcp list
```

**When to run promptfoo:**
- After modifying `~/.claude/hooks/session-context.sh`
- After modifying `~/.claude/CLAUDE.md`
- Before pushing to claude-setup repo
