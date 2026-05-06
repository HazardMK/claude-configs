---
description: AL data access and error handling patterns
globs: ["**/*.al"]
---

# AL Data Access Rules

## Before Any Data Access

Before every record retrieval operation (`Get`, `FindFirst`, `FindLast`, `FindSet`, `FindLast`), set both:

1. **`SetLoadFields`** — load only the fields you will actually use. Reading a full record to access one field is a defect.
2. **`ReadIsolation`** — specify the appropriate isolation level explicitly. Do not rely on the default. Common choices: `ReadIsolation::ReadUncommitted` for read-only reporting, `ReadIsolation::ReadCommitted` for transactional reads, `ReadIsolation::UpdLock` when the record will be modified.

Both must be set before every retrieval, not just some.

## FlowFields

Prefer `SetAutoCalcFields` before retrieval when you need FlowField values — it calculates them in the same SQL operation, avoiding extra round trips.

Use `CalcFields` only when you already have the record in memory and need to (re-)calculate a specific FlowField outside of a retrieval operation.

## Error Messages

- Use `ErrorInfo` to construct error messages — it allows actions, URLs, and structured context that plain `Error()` cannot provide.
- Use `FieldCaption` (not hardcoded field names) so errors respect translations.
- Define error text as a `Label` constant with a `Comment` documenting `%1`/`%2` substitutions.
- Every error message must be actionable — state what went wrong AND what the user should do.

## Integration Events

Raise `[IntegrationEvent(false, false)]` events at meaningful extension points — typically `OnBefore...` and `OnAfter...` around the core operation. Keep the event procedure body empty.
