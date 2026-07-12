# BCQuality Review Integration — Design

## Context

`profile-al-development` currently produces AL code review findings from two independent places:

1. **`/develop`** (`skills/develop/SKILL.md`, Step 6) — spawns 4 specialist reviewer agents in parallel (Security, AL Expert, Performance, Test Coverage), each following prompts in `reviewer-prompts.md`. Findings are triaged into CRITICAL/HIGH/MINOR in Step 7 and written to `.dev/<task-slug>/03-code-review.md` in Step 8.
2. **`review-checklists`** (`skills/review-checklists/SKILL.md`) — an always-loaded, non-agent checklist the orchestrating manager applies inline before presenting any code output to the user (used by `/develop`, `/fix`, and any other workflow that produces AL code).

The `bcquality` plugin (installed from `github.com/microsoft/BCQuality`, marketplace `bcquality`) ships one bridge skill, `bcquality:bcquality-al-review`, which drives BCQuality's Entry protocol over its curated AL/BC knowledge base and returns a structured findings-report:

```json
{
  "outcome": "completed | not-applicable | no-knowledge | partial | failed",
  "outcome-reason": "string (required for partial/failed)",
  "findings": [
    {
      "id": "string",
      "severity": "blocker | major | minor | info",
      "message": "string",
      "location": { "file": "string", "line": 0 },
      "references": [{ "path": "string" }],
      "confidence": "high | medium | low"
    }
  ]
}
```

Goal: fold BCQuality's curated, citation-backed findings into both existing review surfaces, without duplicating logic or special-casing its output shape more than necessary.

## Integration point 1: `/develop` — 5th parallel reviewer

**`skills/develop/reviewer-prompts.md`** gains a new section, **BCQuality Reviewer**, alongside the existing 4. Its mission is deliberately thin — the skill itself does the analysis:

> You are the BCQuality reviewer. Obtain a unified diff of every AL file changed in this task (`git diff` scoped to those files, including untracked new files via `git diff --no-index /dev/null <file>` or equivalent) and invoke the `bcquality:bcquality-al-review` skill once with that diff as the `pr-diff` input — this covers every changed file in a single call. Only if a diff cannot be produced (e.g. no git repository present), fall back to one `file-path` invocation per changed file and merge the returned findings-reports by concatenating their `findings[]` arrays. Do not perform your own analysis — BCQuality's knowledge base is the source of truth for this reviewer. Return the findings-report JSON produced by the skill (or the merged reports), unmodified.

**`skills/develop/SKILL.md`, Step 6** changes:
- "Spawn exactly 4 reviewer agents" → "Spawn exactly 5 reviewer agents": Security, AL Expert, Performance, Test Coverage, **BCQuality**.
- Same parallel `Agent` tool batch, same file list, same `sonnet` model as the other 4.

**`skills/develop/SKILL.md`, Step 7** changes — severity normalization rule, added as a new subsection:

| BCQuality `severity` | Mapped to |
|---|---|
| `blocker` | CRITICAL |
| `major` | HIGH |
| `minor` | MINOR |
| `info` | Not tabled — folded into the report's prose "Observations" section |

- Each row contributed by BCQuality gets a `Source` column value of `BCQuality`, and — where BCQuality supplied `references[]` — the primary knowledge-file path is appended in the Fix Recommendation cell (e.g. `... (see microsoft/knowledge/performance/setloadfields-ordering.md)`), so the user can trace the finding back to a specific rule.
- The 4 existing reviewers' rows are unaffected; they get a `Source` column value matching their own name (`Security`, `AL Expert`, `Performance`, `Test Coverage`) for consistency.
- **Agent findings** (BCQuality findings with `references: []` and an `id` prefixed `agent:`) are — per BCQuality's own contract — always capped at `minor` severity, so they always land in the MINOR table regardless of how the finding reads. No override needed; this falls out of the mapping table above.

## Integration point 2: `review-checklists` — shared gate

**`skills/review-checklists/SKILL.md`**, under **Checklist: Code Implementations**, gains a new first step (runs before the existing checklist items):

> **Invoke `bcquality:bcquality-al-review`** against the changed file(s) — `file-path` input for a single file, `pr-diff` for a multi-file change. Any `blocker` or `major` finding is added to the checklist as a failing item, using the same "send back with specific feedback" treatment as any other checklist failure (cite the finding's `message` and, if present, the primary `references[0].path`). `minor`/`info` findings are noted in the review output but do not block.

This runs once, inline, by the orchestrating manager — not as a spawned agent — matching how the rest of `review-checklists` already operates. It is the mechanism by which `/fix` and any other lightweight workflow gets BCQuality coverage without adopting `/develop`'s full 5-reviewer flow.

## Failure handling (applies to both integration points)

| `outcome` | Handling |
|---|---|
| `completed` (empty `findings`) | Clean pass — no findings to add. |
| `not-applicable` | Treated as a clean pass; not logged as an error. |
| `no-knowledge` | Treated as a clean pass; not logged as an error. |
| `partial` | Per BCQuality's contract, `findings` are still usable for the evaluated subset — include them, and note `outcome-reason` in the report so the user knows coverage was incomplete. Does not block the workflow. |
| `failed` | Per BCQuality's contract, ignore `findings` entirely. Log `outcome-reason` in the report (Step 8 for `/develop`; inline note for `review-checklists`) so it's visible that BCQuality didn't run, but do **not** block the workflow — the other 4 reviewers / the rest of the checklist still gate as before. |

BCQuality is additive: its unavailability or failure never blocks a workflow that would otherwise pass.

## Files touched

All under `~/claude-configs/profile-al-development/`:

- `skills/develop/reviewer-prompts.md` — add BCQuality Reviewer section
- `skills/develop/SKILL.md` — Step 6 (5 agents) and Step 7 (severity mapping table) edits
- `skills/review-checklists/SKILL.md` — add BCQuality invocation step to Code Implementations checklist
- `.claude-plugin/plugin.json` — bump version (minor: new feature, no breaking change)

## Out of scope

- No changes to `/test`, `/plan`, or any workflow other than `/develop` and the shared `review-checklists` gate.
- No vendoring of BCQuality's content into `profile-al-development` — it stays a separate, independently-installed plugin (per the earlier "install as its own plugin" decision).
- No changes to BCQuality itself (its knowledge base, skills, or `entry.md` routing) — this design only wires the existing bridge skill into the two review surfaces.
