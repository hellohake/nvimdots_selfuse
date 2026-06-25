---
name: hello-spec-advance
description: Advance a hello-spec-v2 OpenSpec-style SDD proposal safely. Use when the user wants to continue or quickly advance a hello-spec-v2 change without using openspec-propose or openspec-ff-change. It auto-creates only lightweight placeholder artifacts, stops at business/design/gate artifacts, and never enters apply or edits business code.
---

# hello-spec-advance

## Purpose

Advance a `hello-spec-v2` proposal without losing the human review gates.

This skill is a safety wrapper around OpenSpec's artifact status/instructions:

- Fast-path trivial placeholder artifacts.
- Stop at documents that require business reasoning.
- Stop hard at `grill-spec`.
- Never run `openspec-propose`, `openspec-ff-change`, `openspec-apply-change`, or write business code.

Use this instead of fast-forward commands for `hello-spec-v2`.

## Inputs

- `$1`: change name or absolute proposal directory.
- `$ARGUMENTS`: optional instruction such as "advance p3-pack-card-runtime".

If the change cannot be uniquely identified, ask the user for the change name or absolute proposal path.

## Artifact Classes

### Auto Placeholder

These are inbox/placeholder files. They may be created automatically from template, because they do not require business reasoning:

- `troubleshoot`
- `revise`
- `manual-test-commands`

Only copy the template verbatim. Do not infer content.

### Stop And Ask / Draft One Artifact

These require business reasoning or substantial document synthesis. Stop and show the next instruction instead of silently continuing:

- `brainstorm`
- `proposal`
- `specs`
- `design`
- `tasks`
- `plan`

You may create exactly one of these only when the user explicitly asks you in this turn to draft that artifact. After creating it, stop.

### Interactive Gate

`grill-spec` is a human-in-the-loop clarification gate.

Do not auto-create `grill-spec.md`. When it is ready:

1. Stop.
2. Tell the user this is GATE-1.
3. Invoke or instruct invocation of `grill-with-docs`, which runs `grilling` + `domain-modeling`.
4. Apply the domain-modeling path override:
   - `CONTEXT.md` -> `.ai_doc/spec-workflow/CONTEXT.md`
   - `docs/adr/` -> `.ai_doc/spec-workflow/adr/`
5. Only after blocking questions are resolved should `grill-spec.md` be created as the completion marker.

## Workflow

### Phase 0 - Identity Lock

Start with:

```text
已锁定任务：hello-spec-advance；本轮只安全推进 hello-spec-v2 artifact，不进入 apply，不改业务代码。
```

Forbidden objectives:

- Do not run `openspec-propose`.
- Do not run `openspec-ff-change`.
- Do not run `openspec-apply-change`.
- Do not generate multiple non-placeholder artifacts in one turn.
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

If status fails because the cwd is wrong, ask for the repo root or proposal path. Do not guess across unrelated repos.

### Phase 2 - Verify Schema

Read status JSON and confirm `schemaName` is `hello-spec-v2`.

If not `hello-spec-v2`, stop and explain that this skill is only for `hello-spec-v2`. Suggest `openspec-continue-change` for generic schemas.

### Phase 3 - Advance Loop

Repeat while the next ready artifact is in `Auto Placeholder`:

1. Get instructions:

   ```bash
   openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json
   ```

2. Read `template` and `resolvedOutputPath` from JSON.
3. Write the template verbatim to `resolvedOutputPath`.
4. Re-run status.

Stop after a non-placeholder artifact becomes ready.

### Phase 4 - Stop At Important Step

When a non-placeholder artifact is ready:

1. Get its instructions JSON.
2. Print a short summary:
   - change
   - schema
   - ready artifact
   - output path
   - why this step requires human/agent attention
3. Provide a copyable next command or prompt.

For `grill-spec`, say:

```text
当前到达 GATE-1: grill-spec。
禁止生成 tasks/plan。
下一步需要运行 grill-with-docs（grilling + domain-modeling），澄清 design.md 的 Open Questions。
```

For `tasks` or `plan`, remind the user that these depend on the gate result and must not be generated before `grill-spec.md` exists.

### Phase 5 - Output Format

Always finish with:

````markdown
## Status
- Change:
- Schema:
- Progress:
- Auto-created placeholders:
- Stopped at:

## Why Stopped
<one short explanation>

## Next Command
```text
<copyable command or prompt>
```

## Suggested /clear Resume
```text
cd <repo root> && hello-spec-advance <change>
```
````

## Implementation Notes

Use shell commands for OpenSpec status/instructions and file reads. Use `apply_patch` for manual file edits when creating or changing skill/schema files. When creating a proposal artifact from template, use the normal file editing tools available in the environment, but only for the intended artifact.

If `resolvedOutputPath` is a glob pattern, do not auto-create it unless the schema instruction clearly defines the concrete path. This is why `specs` should stop for human/agent drafting.

## Success Criteria

- Placeholder artifacts may be created in one pass.
- Business-bearing artifacts are not silently generated.
- `grill-spec` is never skipped.
- `tasks` remains blocked until `grill-spec.md` exists.
- The skill never applies code changes.
