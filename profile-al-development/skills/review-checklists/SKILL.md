---
name: review-checklists
description: Quality review checklists for AL solution plans, code implementations, and test suites. Auto-load when reviewing agent output before presenting to user.
user-invocable: false
---

# Review Checklists

Use these checklists when reviewing output from planning, coding, or testing before presenting results to the user. Every piece of agent output must pass the relevant checklist. If it does not, send it back with specific feedback before the user ever sees it.

## Review Process

1. **Read the output** carefully and completely.
2. **Check against the relevant checklist** below.
3. **If issues exist**: send the output back to the originating step with specific, actionable feedback. Do not present flawed work to the user.
4. **If quality is good**: synthesize the results and present them to the user clearly.

---

## Checklist: Solution Plans

Before presenting a solution plan to the user, verify:

- [ ] **Addresses all requirements** -- every stated requirement has a corresponding design element
- [ ] **BC integration is sound** -- uses standard BC patterns (posting routines, event subscribers, standard tables) rather than reinventing platform functionality
- [ ] **Edge cases identified** -- plan acknowledges boundary conditions, error scenarios, and concurrent usage
- [ ] **Follows project patterns** -- consistent with existing codebase conventions (naming, architecture, module boundaries)
- [ ] **Object IDs specified** -- all new objects have assigned IDs that do not conflict with existing ranges
- [ ] **No over-engineering** -- plan solves what was asked, not a hypothetical future problem
- [ ] **Dependencies noted** -- any required base app or third-party dependencies are called out

---

## Checklist: Code Implementations

Before presenting code to the user, verify:

- [ ] **BCQuality automated review** -- invoke `bcquality:bcquality-al-review` against the changed file(s) (`file-path` input for a single file, `pr-diff` for a multi-file change) before the checklist items below. Any `blocker` or `major` finding is a failing item -- send it back with the finding's `message` and, if present, the primary `references[0].path`, using the same treatment as any other checklist failure. `minor`/`info` findings are noted in the review output but do not block. Treat `not-applicable`, `no-knowledge`, and `failed` outcomes as a clean pass for this item (log `outcome-reason` if present) -- BCQuality's unavailability never blocks this checklist.
- [ ] **Matches the plan** -- implementation follows the agreed solution design; deviations are explained
- [ ] **AL coding standards met** -- PascalCase, namespaces, affix rules, SetLoadFields, FieldCaption errors, DataClassification, ApplicationArea (see al-coding-standards skill)
- [ ] **Consistent naming** -- identifiers follow the same conventions throughout; no mix of styles
- [ ] **Compiles cleanly** -- no obvious syntax errors, missing semicolons, undeclared variables, or type mismatches
- [ ] **Minimal changes** -- only the code necessary to fulfill the requirement; no unrelated refactoring
- [ ] **No empty triggers** -- all trigger bodies contain code or are removed
- [ ] **XML documentation** -- public procedures have `/// <summary>` comments
- [ ] **Events raised** -- meaningful extension points have IntegrationEvents
- [ ] **Error messages use FieldCaption** -- no hardcoded field names in error strings

---

## Checklist: Test Suites

Before presenting tests to the user, verify:

- [ ] **Main scenarios covered** -- happy path for each primary use case is tested
- [ ] **Edge cases covered** -- boundary values, empty inputs, invalid data, permission scenarios
- [ ] **bc-test passes** -- tests run successfully (or failures are explained and tracked)
- [ ] **Meaningful assertions** -- each test asserts specific expected outcomes, not just "no error occurred"
- [ ] **No object ID conflicts** -- test codeunit and helper object IDs are in the designated test range
- [ ] **Test isolation** -- tests do not depend on execution order or shared mutable state
- [ ] **Readable test names** -- procedure names describe the scenario and expected outcome

---

## Review Attitude: Challenge, Don't Rubber-Stamp

### Wrong: Rubber-stamping

```
Agent produces code → Reviewer glances at it → "Looks good" → Present to user

Result: User finds a missing SetLoadFields, a prefix affix on a table extension
field, and a hardcoded field name in an error message. Trust erodes.
```

### Right: Challenging

```
Agent produces code → Reviewer checks against checklist → Finds:
  1. Line 42: SetLoadFields missing before FindSet
  2. Line 67: Field "ABC Status" uses prefix affix, should be "Status ABC"
  3. Line 89: Error('Status must be Open') should use FieldCaption

→ Sends specific feedback back to the coding step:
  "Fix these 3 issues: (1) Add SetLoadFields before the FindSet on line 42,
   loading No. and Status. (2) Rename 'ABC Status' to 'Status ABC' -- suffix
   only. (3) Replace hardcoded 'Status' with FieldCaption(Status) in the
   error on line 89."

→ Agent fixes → Reviewer re-checks → Clean → Present to user

Result: User receives polished, standards-compliant code on the first delivery.
```

The goal is to catch every issue before the user does. A review that finds nothing wrong should be the exception, not the default.
