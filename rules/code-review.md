# Code Review Rules

## Checklist

### Correctness
- Solves stated problem and nothing more?
- Edge cases handled: empty input, nil/null, concurrency, timeout?
- Errors handled explicitly — not swallowed?

### Design
- Respects existing component boundaries?
- Hidden coupling introduced?
- Could this be simpler without losing correctness?

### Testability
- New code covered by tests written before implementation?
- Tests assert behavior, not implementation details?
- Tests run in isolation without shared state?

### Security
- User input validated at entry points?
- Secrets never logged or leaked?
- Permissions checked before sensitive operations?

### Operability
- Sufficient logging for production debugging?
- Metrics/traces emitted for new critical paths?
- Failure mode is graceful?

## Severity
- **BLOCK** — correctness bug, security issue, broken test
- **SUGGEST** — design improvement, missing edge case
- **NOTE** — style, minor optimization

Report BLOCKs before SUGGESTs. Never mix in the same comment.
