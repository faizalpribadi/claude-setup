# Architecture Rules

## Boundaries First
Define what this component owns and does NOT own before any design.
Every proposed module must answer: what is its single responsibility?

## Tradeoffs — Surface Before Recommending
- Consistency vs latency
- Simplicity vs extensibility  
- Build vs buy
- Sync vs async

## Distributed Systems Checklist
Flag if present in any design:
- Dual writes without saga/outbox pattern
- Missing idempotency on mutations
- Implicit coupling between services
- Missing retry/backoff strategy
- No circuit breaker on external calls

## Design Output
Save to `SPEC.md` before writing any plan:
- Problem statement (1 paragraph)
- Proposed boundaries
- Tradeoffs accepted
- Risks and mitigations
- Out of scope (explicit)

Prefer reversible decisions. Complexity requires justification from present requirements only.
