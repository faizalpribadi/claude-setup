# TDD Rules

RED → GREEN → REFACTOR. No shortcuts. No exceptions.

1. Write failing test. Run it. Confirm RED output in terminal.
2. Write minimal code to pass. Confirm GREEN output.
3. Commit.
4. Refactor only after committed green.
5. Delete any code written before its test exists.

Conventions:
- Table-driven tests with subtests
- Never mock infrastructure — use real instances via containers
- Test file next to implementation: `foo.go` → `foo_test.go`
- No test passes until real terminal output is shown

Forbidden:
- Writing implementation before test
- Skipping RED confirmation
- Declaring green without running the test command
