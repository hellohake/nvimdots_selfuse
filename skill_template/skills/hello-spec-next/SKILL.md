---
name: hello-spec-next
description: Continue a hello-spec-v2 OpenSpec-style SDD proposal by exactly one safe step. Use when the user wants to continue, advance, or create the next artifact for a hello-spec-v2 change after hello-spec-start. Auto-creates only lightweight placeholders, stops at grill-spec gates, never uses openspec-propose or openspec-ff-change, and never enters apply or edits business code.
---

# hello-spec-next

## Purpose

Move a `hello-spec-v2` proposal to the next safe point without losing human gates.

Use this after `hello-spec-start`. This skill is intentionally single-step for
business artifacts and hard-stops at `grill-spec`.

## Inputs

- `$1`: change name or absolute proposal directory.
- `$ARGUMENTS`: optional instruction such as "continue p3-pack-card-runtime".

If the change cannot be uniquely identified, ask for the change name or absolute
proposal path.

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
   `Evidence=<path:line or exact user answer>`.
6. If any blocking item is `pending_user_confirmation` or lacks evidence, keep
   `grill-spec.md` pending and do not generate tasks/plan.

## Machine Contract

The purpose of this skill is to remove guesswork. Treat missing machine fields as
a stop condition, not as permission to infer paths from memory or naming habits.

### Stop Reasons

Use these exact enum-like values in the final `Stopped at:` field. Keep this list
small; add a new value only when the stop condition needs distinct downstream
handling.

- `missing_status_contract`: `openspec status --json` lacks required fields.
- `missing_instructions_contract`: `openspec instructions --json` lacks required
  fields for the current artifact.
- `path_contract_mismatch`: status JSON and instructions JSON disagree on
  `resolvedOutputPath`.
- `existing_human_content`: an Auto Placeholder output path already exists and
  differs from the template.
- `awaiting_progress_request`: the user asked for status only, so no artifact was
  created.

### Status JSON

Run `openspec status --change "<CHANGE_NAME>" --json` after `REPO_ROOT` and
schema discovery are locked. Required fields:

- `schemaName`: must equal `hello-spec-v2`.
- `changeDir`: absolute or repo-root-relative path to the proposal directory.
- `nextReadyArtifact.id`: artifact id to handle next.
- `artifacts[]`: list containing at least `id`, `status`, and
  `resolvedOutputPath` for each artifact.

Use `nextReadyArtifact.id` as the only source of truth for the next step. Use
`artifacts[].resolvedOutputPath` to find existing artifact files. If any required
field is missing, stop with `Stopped at: missing_status_contract` and include the
missing field names.

### Instructions JSON

Run `openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json` for
the current `nextReadyArtifact.id`. Required fields:

- `artifactId`: must match `nextReadyArtifact.id`.
- `resolvedOutputPath`: output path for this artifact.
- `template`: required only for Auto Placeholder artifacts.
- `instructions` or equivalent artifact guidance: required for Business
  Artifacts.

If `resolvedOutputPath` disagrees with the matching `artifacts[]` entry from
status JSON, stop with `Stopped at: path_contract_mismatch`. If required fields
are missing, stop with `Stopped at: missing_instructions_contract`.

### Completion Checks

- Treat an artifact as ready only when it is named by `nextReadyArtifact.id`.
- Treat `grill-spec.md` as complete only under the status/evidence rule in the
  Interactive Gate section. Do not accept a checked box, file existence, or
  casual "looks done" wording as sufficient.
- Do not guess schema paths, output paths, or artifact ordering when JSON is
  incomplete.

## Workflow

### Phase 0 - Identity Lock

Start with:

```text
已锁定任务：hello-spec-next；本轮只安全推进 hello-spec-v2 的下一个 artifact，不进入 apply，不改业务代码。
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

Accepted inputs:

- Absolute change dir: `/abs/repo/openspec/changes/<change>`
- Change name: find under nearest `openspec/changes/<change>`

First lock the repo root:

1. Locate the nearest ancestor containing `.openspec.yaml`.
2. Read `.openspec.yaml` to discover the active schema configuration.
3. Only continue when schema discovery and `openspec status --json` both confirm
   `schemaName=hello-spec-v2`.

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

2. Read `template` and `resolvedOutputPath` from JSON.
3. Apply the overwrite guard:
   - If `resolvedOutputPath` does not exist, write the template verbatim.
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

- Placeholder artifacts may be created in one pass.
- Existing human-authored placeholder files are never overwritten.
- At most one business-bearing artifact is created.
- `grill-spec` is never skipped.
- `tasks` and `plan` remain blocked until `grill-spec.md` is complete with
  status/evidence.
- Status and instructions JSON fields are validated before writing; missing
  fields stop the workflow instead of triggering path or order guesses.
- The skill never applies code changes.
