---
name: hello-spec-next
description: Continue a hello-spec-v2 OpenSpec-style SDD proposal by exactly one safe step, with either an explicit change name/path or a safely resolved current change from cwd/context/unique active change. Use when the user wants to continue, advance, 推进, 继续当前提案, create the next artifact, or says hello-spec-next after hello-spec-start, even if they omit the proposal name. Auto-creates only lightweight placeholders, stops at grill-spec gates, never uses openspec-propose or openspec-ff-change, and never enters apply or edits business code.
---

# hello-spec-next

## Purpose

Move a `hello-spec-v2` proposal to the next safe point without losing human gates.

Use this after `hello-spec-start`. This skill is intentionally single-step for
business artifacts and hard-stops at `grill-spec`.

## Inputs

- `$1`: optional change name or absolute proposal directory.
- `$ARGUMENTS`: optional instruction such as "continue p3-pack-card-runtime",
  "继续当前提案", or "推进下一个".

If the change cannot be uniquely identified, stop and ask for the change name or
absolute proposal path. Do not choose by fuzzy similarity, old chat recency, or
"most likely" when more than one candidate exists.

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
  source (`cwd`, `context`, or `active-change`).
- Do not scan unrelated sibling repos or worktrees to "find" a likely change.
- Do not pick the newest directory, the most recently mentioned name, or the
  closest fuzzy match when multiple candidates exist.
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
  Artifact, except when the ready artifact is `grill-spec`, which is always a
  gate stop.
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

Do not auto-create `grill-spec.md`. When it is ready:

1. Stop.
2. Tell the user this is GATE-1.
3. Invoke or instruct invocation of `grill-with-docs`, which runs `grilling` +
   `domain-modeling`.
4. Apply the domain-modeling path override:
   - `CONTEXT.md` -> `.ai_doc/spec-workflow/CONTEXT.md`
   - `docs/adr/` -> `.ai_doc/spec-workflow/adr/`
5. `grill-spec.md` can be `complete` only when each blocking question has
   `Status=user_confirmed` or `Status=resolved_by_evidence`, plus non-empty
   `Evidence=<path:line or exact user answer>`. This is the single authoritative
   completion rule for `grill-spec`; other sections refer back here.
6. If any blocking item is `pending_user_confirmation` or lacks evidence, keep
   `grill-spec.md` pending and do not generate tasks/plan. A checked box, the
   mere existence of the file, or casual "looks done" wording never satisfies
   this rule — only explicit status plus evidence does.

## Machine Contract

The purpose of this skill is to remove guesswork. Treat missing machine fields as
a stop condition, not as permission to infer paths from memory or naming habits.

**MANDATORY — read the entire file `references/openspec-cli-contract.md`
(~63 lines) before parsing any `openspec status --json` / `openspec instructions
--json` output; do NOT set range limits when reading it.** That file holds the
full field tables, the absent-field edge cases, and the field → Stop Reason map.
The summary below covers only the happy path.

### Stop Reasons

Exact enum-like values for the final `Stopped at:` field. Keep the list small; add
a value only when a stop needs distinct downstream handling.

- `missing_status_contract`: status JSON lacks `schemaName` or `artifacts[]`.
- `missing_instructions_contract`: instructions JSON lacks `changeDir`,
  `outputPath`, or the body field for the current artifact.
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

### The two JSON calls

1. `openspec status --change "<CHANGE_NAME>" --json` → `schemaName` (must be
   `hello-spec-v2`) and an ordered `artifacts[]` of `{id, outputPath, status}`.
   There is no `nextReadyArtifact`: the next artifact is the FIRST entry whose
   `status == "ready"`; if none is `ready`, report status only. Status JSON
   carries no `changeDir` and no absolute paths.
2. `openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json` for that
   ready artifact → `changeDir` (ABSOLUTE; source `CHANGE_DIR` here), `outputPath`
   (relative; join with `changeDir` for the file path), `instruction` (Business
   Artifact body) or `template` (Auto Placeholder verbatim body), plus
   `dependencies[]` / `unlocks[]` for explaining a stop.

Treat a missing field, or a status-vs-instructions `outputPath` mismatch, as the
matching Stop Reason above (full mapping in the reference); never guess a path,
schema, or artifact order to recover. `grill-spec.md` counts as complete only
under the Interactive Gate rule (item 5), not from `artifacts[].status` alone.

## Workflow

### Phase 0 - Identity Lock

Start with:

```text
已锁定任务：hello-spec-next；CHANGE_NAME=<change>（source=<explicit-path|explicit-name|cwd|context|sole-active-change>）；本轮只安全推进 hello-spec-v2 的下一个 artifact，不进入 apply，不改业务代码。
```

Forbidden objectives:

- Do not run `openspec-propose`.
- Do not run `openspec-ff-change`.
- Do not run `openspec-apply-change`.
- Do not generate more than one business artifact.
- Do not edit business source code.
- Do not run tests/builds.
- Do not commit, push, or archive.

### Phase 1 - Locate Change

Determine `CHANGE_NAME`, `CHANGE_DIR`, and `REPO_ROOT`.

Resolve the change using the Change Resolution Contract before running any
status or instruction command. If the user omitted the proposal name, try cwd,
stable resume tokens in the current/immediately preceding context, and finally a
single active `hello-spec-v2` change under the locked repo. If resolution is
missing or ambiguous, stop with the corresponding Stop Reason and ask for a
change name or absolute proposal path.

First lock the repo root, then trust the JSON for the schema:

1. Find the nearest ancestor containing an `openspec/` directory; that is
   `REPO_ROOT`. The project schema config, if any, is `openspec/config.yaml`
   (the CLI auto-detects the schema from it). `.openspec.yaml` is only a
   per-change marker inside a change dir, not the project config — do not rely
   on it for discovery.
2. Run `openspec status --change "<CHANGE_NAME>" --json` and read `schemaName`
   from it. The CLI already resolves the active schema, so this is the
   authority; no manual config read is required.
3. Only continue when `schemaName == hello-spec-v2` (see Phase 2).

Run:

```bash
openspec status --change "<CHANGE_NAME>" --json
```

If status fails because cwd is wrong, ask for the repo root or proposal path. Do
not guess across unrelated repos.

### Phase 2 - Verify Schema

Read status JSON and confirm `schemaName` is `hello-spec-v2`.

If not `hello-spec-v2`, stop and explain that this skill is only for
`hello-spec-v2`. Suggest `openspec-continue-change` for generic schemas.

### Phase 3 - Placeholder Fast Path

Repeat while the next ready artifact is in `Auto Placeholder`:

1. Get instructions:

   ```bash
   openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json
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
2. If artifact is `grill-spec`, stop and present the gate instructions.
3. If artifact is `tasks` or `plan`, first verify `grill-spec.md` exists and is
   complete under the evidence/status rule.
4. Create exactly one business artifact only when this turn is a progress
   request or explicitly names that current ready artifact. After writing it,
   stop.
5. If this turn is status-only, do not create the artifact. Stop with
   `Stopped at: awaiting_progress_request`.

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
- A missing/mismatched JSON field produces the matching Stop Reason instead of a
  guessed path or order.
- No business code, test, build, commit, or apply action is performed.
