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
3. Write the template verbatim to `resolvedOutputPath`.
4. Re-run status.

Stop after a non-placeholder artifact becomes ready.

### Phase 4 - Business Artifact Or Gate

When a non-placeholder artifact is ready:

1. Get its instructions JSON.
2. If artifact is `grill-spec`, stop and present the gate instructions.
3. If artifact is `tasks` or `plan`, first verify `grill-spec.md` exists and is
   complete under the evidence/status rule.
4. Create exactly one business artifact only when the user asked this turn to
   draft/continue that artifact. After writing it, stop.

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
- At most one business-bearing artifact is created.
- `grill-spec` is never skipped.
- `tasks` and `plan` remain blocked until `grill-spec.md` is complete with
  status/evidence.
- The skill never applies code changes.
