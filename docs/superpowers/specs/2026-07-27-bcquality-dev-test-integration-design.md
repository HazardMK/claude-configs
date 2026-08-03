# BCQuality Dev/Test Integration — Design (Phase 2)

## Context

The first BCQuality integration (`2026-07-12-bcquality-review-integration-design.md`) wired Microsoft's BCQuality (`github.com/microsoft/BCQuality`, skill `bcquality:bcquality-al-review`) into two **review-only, after-the-fact** surfaces:

1. `/develop` Step 6/7 — a 5th parallel reviewer alongside Security/AL Expert/Performance/Test Coverage, run on the full diff once development is already finished.
2. `review-checklists` — a shared inline gate (`/develop`, `/fix`) called once before presenting code.

BCQuality's findings were only ever seen after a whole module (or fix) was already written, and `/test` never invoked BCQuality at all — its `testing` knowledge domain (test isolation, assertion patterns, AL Test Framework conventions) was unused. This phase closes both gaps: development and testing should also *follow* BCQuality guidance while the work is happening, not just get graded on it afterward.

BCQuality's own contract explicitly forbids using its skill to *generate* code ("do not use this skill to generate AL code — it only reviews"), and the first design explicitly ruled out vendoring its knowledge base into prompts. So "follow BCQuality guidelines during development" means **shifting the existing review skill left** — invoking it incrementally, per file, right after each file compiles — not injecting raw knowledge content into the developer prompt. This mirrors the discipline `al-developer-prompt.md` already applies to compilation ("compile after every file, fix immediately, do not proceed until clean").

All new touchpoints reuse the conventions established in phase 1: same skill name, same input keys (`file-path` / `pr-diff`), same severity mapping table, same outcome handling. BCQuality remains a separate, independently-installed plugin — no vendoring, no MCP entry.

## Integration point 1: `/develop` — per-file dev-time check

**`skills/develop/al-developer-prompt.md`** gains a new step in the per-file loop, immediately after "compile after creating the file / fix compilation errors immediately" and before moving to the next file:

> Once (and only once) the file compiles cleanly, invoke `bcquality:bcquality-al-review` with `file-path` set to that single file. `blocker`/`major` findings — fix immediately in this file, the same discipline as a compilation error, then re-invoke the check before moving to the next file. `minor`/`info` findings — note them in the Developer Report; non-blocking. `outcome: not-applicable | no-knowledge | failed` — skip silently and proceed. `outcome: partial` — act on the findings returned, note `outcome-reason`.

This is additive to, not a replacement for, the existing Step 6/7 full-diff 5th-reviewer pass in `develop/SKILL.md` — that pass still runs, and catches cross-file issues a single-file check can't see. The Developer Report template gains a "BCQuality Status" section (findings fixed/noted, any outcome issues) alongside the existing "Compilation Status" section, so the manager has an audit trail without re-deriving it from the per-file checks.

## Integration point 2: `/test` — Step 7.5 gate on test files

**`skills/test/SKILL.md`** gains a new **Step 7.5: BCQuality Check on Test Files**, inserted after Step 7 (all `bc-test` passing) and before Step 8.5 (the mutation-testing adversary). This is a manager-level inline call — not a spawned agent — the same pattern `review-checklists` already uses, not the 5-reviewer pattern:

- Obtain a diff of all test AL files created in this task (fallback: one `file-path` invocation per test file, merged, same fallback rule as the BCQuality Reviewer in `reviewer-prompts.md`) and invoke `bcquality:bcquality-al-review` once with `pr-diff`.
- Apply the same severity mapping table as `develop/SKILL.md` Step 7 (`blocker`→CRITICAL, `major`→HIGH, `minor`→MINOR, `info`→prose).
- `blocker`/`major` findings — dispatch to the owning test engineer by codeunit ID range, reusing the exact dispatch mechanism Step 8 already uses for `bc-test` failures. Re-run `bc-test` and re-run the BCQuality check until clean.
- `minor`/`info` — note for the test plan; non-blocking.
- Outcome handling identical to the table below.

Only once Step 7.5 is clean does Step 8.5 (the mutation/assertion adversary) run — that step is unchanged; it addresses a distinct concern (mutation survival, assertion strength) with no overlap to reconcile against BCQuality's rule-based findings.

The Step 9 test plan template gains a line recording the BCQuality outcome (e.g. "BCQuality: clean" or "BCQuality: N findings addressed"), and the "Key Rules" list gains a rule making Step 7.5 mandatory, mirroring the existing "the adversary always runs" framing for Step 8.5.

No changes to `test-engineer-prompts.md`: the 4 engineer prompts have no per-file compile loop today, so there's no natural per-engineer insertion point for a per-file check (unlike `al-developer-prompt.md`). The manager-level Step 7.5 gate is the right level — consistent with how `bc-test` itself only runs in aggregate (Step 7), not per-file per-engineer.

## Failure handling (applies to both integration points, reused verbatim from phase 1)

| `outcome` | Handling |
|---|---|
| `completed` (empty `findings`) | Clean pass — no findings to add. |
| `not-applicable` | Treated as a clean pass; not logged as an error. |
| `no-knowledge` | Treated as a clean pass; not logged as an error. |
| `partial` | `findings` are still usable for the evaluated subset — act on them, and note `outcome-reason` so the user knows coverage was incomplete. Does not block. |
| `failed` | Ignore `findings` entirely. Log `outcome-reason` so it's visible BCQuality didn't run, but do **not** block — the rest of the workflow gates as before. |

BCQuality is additive: its unavailability or failure never blocks a workflow that would otherwise pass.

## Files touched

All under `~/claude-configs/`:

- `docs/superpowers/specs/2026-07-27-bcquality-dev-test-integration-design.md` — this doc
- `profile-al-development/skills/develop/al-developer-prompt.md` — per-file BCQuality check + Developer Report template update
- `profile-al-development/skills/test/SKILL.md` — Step 7.5, Step 9 template update, Key Rules update
- `profile-al-development/README.md` — BCQuality Integration section (install/registration + touchpoint list)
- `profile-al-development/.claude-plugin/plugin.json` — version bump (minor) + description update

## Out of scope

- No changes to BCQuality itself (its knowledge base, skills, or `entry.md` routing).
- No vendoring of BCQuality's content into `profile-al-development` — it stays a separate, independently-installed plugin.
- No changes to `reviewer-prompts.md`, `develop/SKILL.md` Step 6/7, `review-checklists/SKILL.md`, `verify-tests/SKILL.md`, `.mcp.json`, or `test-engineer-prompts.md` — all already correct from phase 1, or (for `verify-tests`/`test-engineer-prompts.md`) not the right insertion point for this phase.
