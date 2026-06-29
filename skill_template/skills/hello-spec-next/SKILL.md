---
name: hello-spec-next
description: Continue a hello-spec-v2 OpenSpec-style SDD proposal by exactly one safe step, with either an explicit change name/path or a safely resolved current change from cwd/context/unique active change. Use when the user wants to continue, advance, 推进, 继续当前提案, create the next artifact, or says hello-spec-next after hello-spec-start, even if they omit the proposal name. Auto-creates only lightweight placeholders, enters grill-spec gate mode by applying the OpenSpec grill-spec instructions with grill-with-docs/domain-modeling behavior, never skips to tasks/plan before the gate is complete, never uses openspec-propose or openspec-ff-change, and never enters apply or edits business code.
---

# hello-spec-next

## Purpose

Move a `hello-spec-v2` proposal to the next safe point without losing human gates.

Use this after `hello-spec-start`. This skill is intentionally single-step for
business artifacts. At `grill-spec`, it does not merely print a handoff command:
it enters gate mode, runs the clarification workflow under the OpenSpec
instructions, and still stops before `tasks` / `plan`.

## Inputs

- `$1`: optional change name or absolute proposal directory.
- `$ARGUMENTS`: optional instruction such as "continue p3-pack-card-runtime",
  "继续当前提案", or "推进下一个".

If the change cannot be uniquely identified, stop and ask for the change name or
absolute proposal path (never guess by similarity or recency — see `## NEVER`).

## Change Resolution Contract

This is a state-changing workflow: resolving the wrong change can write files to
the wrong proposal. Treat change resolution as a contract, not a convenience.

Accepted resolution sources, in strict priority order:

1. Explicit absolute change dir:
   `/abs/repo/openspec/changes/<change>`.
2. Explicit change name argument:
   `hello-spec-next <change>`, where `<change>` matches an existing directory
   under the locked repo's `openspec/changes/`.
3. Current working directory is inside:
   `<repo>/openspec/changes/<change>/...`.
4. Current turn text or immediately preceding start/next output contains exactly
   one stable resume token:
   - `CHANGE_NAME=<change>`
   - `Change: <change>`
   - `hello-spec-next <change>`
   - `cd <repo root> && hello-spec-next <change>`
5. Locked repo has exactly one active change directory under
   `openspec/changes/` whose `openspec status --change "<change>" --json`
   verifies `schemaName == hello-spec-v2`.

Resolution rules:

- Lock `REPO_ROOT` before using any repo-local candidate. Prefer the nearest
  ancestor containing `openspec/`; if cwd is outside a repo or multiple repos are
  implied by the text, stop and ask for an absolute proposal path.
- Only one candidate may survive. If zero candidates survive, stop with
  `Stopped at: missing_change_context`. If multiple candidates survive, stop with
  `Stopped at: ambiguous_change_context` and list candidate names plus their
  source (`cwd`, `context`, or `active-change`). Never narrow by fuzzy match,
  newest dir, recency, or sibling-repo scan (see `## NEVER`).
- Before any file write, report the resolved identity in the first status update:

  ```text
  已锁定任务：hello-spec-next；CHANGE_NAME=<change>（source=<explicit-path|explicit-name|cwd|context|sole-active-change>）；本轮只安全推进 hello-spec-v2 的下一个 artifact，不进入 apply，不改业务代码。
  ```

Intent semantics:

- Status-only requests such as "看一下状态" or "where is this change" only report
  status and do not write files.
- Progress requests such as "continue", "next", "推进", or `hello-spec-next
  <change>` authorize advancing the current ready artifact by exactly one safe
  step.
- A generic progress request authorizes creating the current ready Business
  Artifact. When the ready artifact is `grill-spec`, it authorizes entering
  `grill-spec gate mode`, not generating `tasks` / `plan`.
- Explicit requests for a named artifact may create only that artifact if it is
  the current ready artifact. Do not skip ahead to satisfy the named request.

## Artifact Classes

### Auto Placeholder

These are inbox/placeholder files. They may be created automatically from the
template because they do not require business reasoning:

- `troubleshoot`
- `revise`
- `manual-test-commands`

Only copy the template verbatim. Do not infer content.

### Business Artifact

These require reasoning or synthesis. Create at most one per invocation, then
stop:

- `brainstorm`
- `proposal`
- `specs`
- `design`
- `tasks`
- `plan`

Source handling:

- `brainstorm`: must consume the initial user input provided during
  `hello-spec-start` or in the current turn. Include an `Input Sources` trace.
- `proposal`: consume `brainstorm.md`; use the original input only to verify
  scope and hard constraints.
- `specs` / `design`: consume `proposal.md`, previous artifacts, and relevant
  code/docs. Re-read original input only for ambiguity or lost constraints.
- `tasks` / `plan`: consume canonical artifacts only (`proposal.md`,
  `specs/**/*.md`, `design.md`, `grill-spec.md`, and `tasks.md` for plan). If
  canonical artifacts conflict with original input, stop and route through
  `spec-plan-revise` rather than silently changing scope.

### Interactive Gate

`grill-spec` is a human-in-the-loop clarification gate.

Do not treat `grill-with-docs <change>` as a sufficient handoff. That skill is a
thin wrapper around `grilling` + `domain-modeling`; the OpenSpec
`grill-spec` instructions are the binding contract for paths, persistence, and
completion.

When `grill-spec` is ready, enter `grill-spec gate mode`:

1. Run `cd "<REPO_ROOT>" && openspec instructions grill-spec --change "<CHANGE_NAME>" --json`.
2. Treat the returned `instruction` body as binding. Follow its path overrides:
   - `CONTEXT.md` -> `.ai_doc/spec-workflow/CONTEXT.md`
   - `docs/adr/` -> `.ai_doc/spec-workflow/adr/`
   - `CONTEXT-MAP.md`, if needed -> `.ai_doc/spec-workflow/`
3. Use `grill-with-docs` behavior inline: `grilling` asks one question at a
   time with a recommended answer; `domain-modeling` writes resolved terms and
   justified ADRs to the overridden paths.
4. Read `design.md` Open Questions first, then `specs/**/*.md`, existing
   `.ai_doc/spec-workflow/CONTEXT.md`, and existing ADRs only as needed.
5. For every blocking Open Question, first try to resolve it by concrete
   evidence from code/specs/docs. Evidence-resolved items use
   `Status=resolved_by_evidence` and cite `Evidence=<path:line>`.
6. For items that require the user, write a concrete recommendation and mark
   `Status=pending_user_confirmation` with `Evidence=<exact question asked>` or
   the source of the recommendation. Ask exactly one pending question and wait.

Persistence rules:

- Persist before pausing for user input. If any item is pending, create or update
  `grill-spec.md` with `## Status` = `pending`; include all resolved and pending
  questions. Stop with `Stopped at: awaiting_grill_spec_confirmation`.
- While pending items remain, keep unresolved content visible in `design.md`
  Open Questions. Do not clear Open Questions prematurely.
- For resolved items, write conclusions back to `design.md` Decisions and update
  `.ai_doc/spec-workflow/CONTEXT.md` / ADRs when the gate instruction requires
  it.
- When every blocking question has `Status=user_confirmed` or
  `Status=resolved_by_evidence` and non-empty Evidence, clear `design.md` Open
  Questions, create/update `grill-spec.md` with `## Status` = `complete`, list
  touched CONTEXT terms / ADRs, then stop. Do not generate `tasks` / `plan` in
  the same invocation.

Completion rule:

`grill-spec.md` counts as complete only when each blocking question has
`Status=user_confirmed` or `Status=resolved_by_evidence`, plus non-empty
`Evidence=<path:line or exact user answer>` — never a checked box or file
existence (see `## NEVER`).

## Machine Contract

The purpose of this skill is to remove guesswork. Treat missing machine fields as
a stop condition, not as permission to infer paths from memory or naming habits.

**MANDATORY — read the entire file `references/openspec-cli-contract.md`
(~90 lines) before parsing any `openspec status --json` / `openspec instructions
--json` output; do NOT set range limits when reading it.** That file holds the
full field tables, the both-bodies-always-present rule, the `specs` glob edge
case, and the field → Stop Reason map. It is the ONLY reference this skill ships;
there is nothing else to load. The summary below covers only the happy path.

### Stop Reasons

Exact enum-like values for the final `Stopped at:` field. Keep the list small; add
a value only when a stop needs distinct downstream handling.

- `missing_status_contract`: status JSON lacks `schemaName` or `artifacts[]`.
- `missing_instructions_contract`: instructions JSON lacks `artifactId`,
  `changeDir`, or `outputPath`, or the class-appropriate body is empty
  (`template` for an Auto Placeholder, `instruction` for a Business Artifact).
  The current CLI always populates both bodies; the empty-body branch is
  drift-insurance for a future contract change.
- `path_contract_mismatch`: status and instructions `outputPath` disagree for the
  same artifact.
- `existing_human_content`: an Auto Placeholder output path exists and differs
  from `template`.
- `awaiting_progress_request`: the user asked for status only; no artifact was
  created.
- `missing_change_context`: no explicit or safely resolved current change was
  found.
- `ambiguous_change_context`: more than one candidate change was found; user
  selection is required.
- `awaiting_grill_spec_confirmation`: `grill-spec` has one or more pending user
  confirmations; no `tasks` / `plan` were created.
- `grill_spec_pending`: `grill-spec.md` exists but is not complete under the
  Interactive Gate completion rule.

### The two JSON calls (orientation only — the reference owns the full contract)

`openspec status ... --json` returns `schemaName` (must be `hello-spec-v2`) and an
ordered `artifacts[]`; the next artifact is the FIRST whose `status == "ready"`
(there is no `nextReadyArtifact`), and status carries no absolute paths.
`openspec instructions <artifact-id> ... --json` returns the absolute `changeDir`,
a relative `outputPath` (a glob for `specs`), and both `instruction` + `template`
(always present — pick the body by Artifact Class). The reference holds the field
tables, `specs` glob handling, and the field → Stop Reason map; never guess a
path, schema, or artifact order to recover from a missing field.

`grill-spec.md` counts as complete only under the Interactive Gate rule (item 5),
not from `artifacts[].status` alone.

## NEVER

Each of these anti-patterns causes a specific, hard-to-detect failure:

- NEVER resolve a change by fuzzy match, newest dir, or most-recent mention when
  several candidates exist — a wrong pick writes to the wrong proposal; stop with
  `ambiguous_change_context` instead.
- NEVER scan unrelated sibling repos or worktrees to "find" a likely change — it
  invents context the user never gave.
- NEVER pick an artifact's body by which field is present — `instruction` and
  `template` are always both present, so choose by Artifact Class or you write a
  bare placeholder where a reasoned artifact belongs.
- NEVER treat a checked box, file existence, or "looks done" wording as a complete
  `grill-spec` — the CLI flips an artifact to `done` on mere file existence, so
  only the evidence/status rule (Interactive Gate item 5) actually proves it.
- NEVER write to a literal `specs/**/*.md` — it is a glob; derive concrete
  `specs/<capability>/spec.md` paths from the `instruction` body.
- NEVER run `openspec-propose`, `openspec-ff-change`, or `openspec-apply-change`,
  generate more than one business artifact, edit business code, run tests/builds,
  or commit/push/archive — all leave this skill's single-step, pre-apply scope.

## Workflow

### Phase 0 - Identity Lock

Start with:

```text
已锁定任务：hello-spec-next；CHANGE_NAME=<change>（source=<explicit-path|explicit-name|cwd|context|sole-active-change>）；本轮只安全推进 hello-spec-v2 的下一个 artifact，不进入 apply，不改业务代码。
```

Forbidden objectives: do not run `openspec-propose` / `openspec-ff-change` /
`openspec-apply-change`, generate more than one business artifact, edit business
code, run tests/builds, or commit/push/archive (see `## NEVER` for why).

### Phase 1 - Locate Change

Determine `CHANGE_NAME`, `CHANGE_DIR`, and `REPO_ROOT`.

Resolve the change using the Change Resolution Contract before running any
status or instruction command. If the user omitted the proposal name, try cwd,
stable resume tokens in the current/immediately preceding context, then a single
active `hello-spec-v2` change under the locked repo; if resolution is missing or
ambiguous, stop with the corresponding Stop Reason and ask for a change name or
absolute proposal path.

First lock the repo root, then trust the JSON for the schema:

1. Find the nearest ancestor containing an `openspec/` directory; that is
   `REPO_ROOT`. The CLI auto-detects the active schema on its own — from
   `openspec/config.yaml` if the project has one, otherwise from the per-change
   `.openspec.yaml` marker. Do not read either file manually; trust the
   `schemaName` that `status --json` reports.
2. From `REPO_ROOT`, run the status call and read `schemaName` — that field is
   the authority. Only continue when it is `hello-spec-v2` (see Phase 2):

   ```bash
   cd "<REPO_ROOT>" && openspec status --change "<CHANGE_NAME>" --json
   ```

`openspec` must run from `REPO_ROOT` (the dir containing `openspec/`); it does
not search ancestors, so a child dir errors `Change ... not found`. If a command
fails, cd to the locked `REPO_ROOT` and retry; only ask the user if `REPO_ROOT`
itself could not be resolved. Do not guess across unrelated repos.

### Phase 2 - Verify Schema

Read status JSON and confirm `schemaName` is `hello-spec-v2`.

If not `hello-spec-v2`, stop and explain that this skill is only for
`hello-spec-v2`. Suggest `openspec-continue-change` for generic schemas.

### Phase 3 - Placeholder Fast Path

Intent gate (runs before any file write): the read-only Identity Lock promise
means a status-only turn must never write, even when ready placeholders exist —
auto-creating placeholders here would silently violate it. So if this turn is
status-only (per Intent semantics: not a progress request and not naming the
current ready artifact), report the status block and stop with `Stopped at:
awaiting_progress_request` now, before the loop below. Only enter the loop for a
progress request or a request that names the current ready artifact.

Then, while the next ready artifact is in `Auto Placeholder`:

1. Get instructions:

   ```bash
   cd "<REPO_ROOT>" && openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json
   ```

2. Read `template`, `changeDir`, and `outputPath` from JSON; the absolute file
   path is `changeDir` joined with `outputPath`.
3. Apply the overwrite guard:
   - If the file does not exist, write the template verbatim.
   - If it exists and its content is byte-for-byte equal to `template`, treat it
     as already satisfied and do not rewrite it.
   - If it exists and differs from `template`, stop with `Stopped at:
     existing_human_content`; report the path and do not overwrite it.
4. Re-run status.

Stop after a non-placeholder artifact becomes ready.

### Phase 4 - Business Artifact Or Gate

When a non-placeholder artifact is ready:

1. Get its instructions JSON.
2. If artifact is `grill-spec`, enter `grill-spec gate mode` from Interactive
   Gate. Do not just print `grill-with-docs <change>` and stop; the OpenSpec
   instructions must be carried into the current interaction.
3. If artifact is `tasks` or `plan`, first verify `grill-spec.md` exists and is
   complete under the evidence/status rule.
4. Create exactly one business artifact, then stop. (The Phase 3 intent gate has
   already confirmed this turn is a progress request or names the current ready
   artifact; a status-only turn never reaches here.)

For `plan.md`, enforce the atomic-step gate:

- review points are plain text, never checkboxes;
- each `StepID` checkbox is one atomic execution step;
- code steps include target file, function/method/type, exact change, and
  verification;
- verification steps include targeted command or manual/disabled reason;
- if not enough context exists, write `needs_plan_refinement` and missing
  questions instead of claiming the plan is executable.

### Phase 5 - Output Format

Always finish with:

````markdown
## Status
- Change:
- Schema:
- Progress:
- Auto-created placeholders:
- Created artifact:
- Stopped at:

## Why Stopped
<one short explanation>

## Next Command
```text
hello-spec-next <change>
```

## Suggested /clear Resume
```text
cd <repo root> && hello-spec-next <change>
```
````

## Success Criteria

A run is correct when these verifiable invariants hold (rules defined above, not
restated here):

- At most one Business Artifact is created per invocation; placeholders may be
  created in one pass.
- An existing human-authored placeholder is never overwritten (overwrite guard,
  Phase 3).
- `tasks` and `plan` are not created until `grill-spec.md` is complete per the
  Interactive Gate rule (item 5).
- When `grill-spec` is ready, the run enters gate mode, persists pending or
  complete `grill-spec.md` state, and stops before `tasks` / `plan`.
- A missing/mismatched JSON field produces the matching Stop Reason instead of a
  guessed path or order.
- No business code, test, build, commit, or apply action is performed.
