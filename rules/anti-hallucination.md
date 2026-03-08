# Anti-Hallucination Rules

## Before Editing Any Symbol
- Is collected context sufficient?
- Is this within current task scope only?

If either fails: gather more context via serena or mgrep. Do not proceed on assumptions.

## Before Declaring Done
- Run the actual verification command.
- Report real terminal output — not what you expect it to say.

## When Uncertain About Code Behavior
Use tools in order:
1. `serena: find_symbol` — find actual implementation
2. `serena: find_referencing_symbols` — trace actual call graph
3. `mgrep` — find actual usage patterns
4. `context7` — verify actual library API

Silence is better than hallucination. Stop and ask if tools don't resolve the uncertainty.

## Checkpoint Triggers
Stop and save state if any of these are true:
- Context window >60%
- Three consecutive tool calls returned unexpected results
- Conflicting implementations found — unclear which is authoritative
