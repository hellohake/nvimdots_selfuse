---
name: hello-spec-start
description: Start a hello-spec-v2 OpenSpec-style SDD proposal safely from a natural-language prompt, with either an explicit change-name or an inferred kebab-case change-name when the user omits it. Use when the user wants to create a new hello-spec-v2 change, start a proposal, begin an OpenSpec-style SDD workflow, or says hello-spec-start / 启动提案 / 新建 hello-spec-v2 / 开始一个提案 / 不知道 change-name / 帮我起 change name. Use this only to START a new change (the first step); to advance an existing change, use hello-spec-next.
---

# hello-spec-start

## Purpose

Start a `hello-spec-v2` proposal without fast-forwarding past human gates. This is
the preferred entrypoint for new `hello-spec-v2` changes: it accepts either an
explicit change name or a plain-language request, derives a stable kebab-case
change name when needed, captures the remaining user text as the initial source
input, creates the OpenSpec change, fast-creates only lightweight placeholders,
and stops at the first business artifact. It replaces the pattern of manually
calling `openspec-new-change` and then accidentally using `openspec-ff-change` /
`openspec-propose`, which skip the gates.

## Input Shape

Accept natural language, not CLI-style flags (no `--prompt`):

```text
hello-spec-start <change-name> <initial user input...>
hello-spec-start <initial user input...>
```

Explicit change-name example:

```text
hello-spec-start p3-pack-card-runtime-redesign 基于飞书技术方案 https://...，重做 P3 C端打包运行时；base=feat/card_type_support；不要复用旧实现计划。
```

Inferred change-name examples:

```text
hello-spec-start 给搜索卡片补一个路由兜底能力
=> CHANGE_NAME=add-card-router-fallback

hello-spec-start 基于这个飞书文档重构 P3 C端打包运行时 https://...
=> CHANGE_NAME=p3-refactor-card-pack-runtime

hello-spec-start 修复 apply 后 tasks 和 plan 进度不一致
=> CHANGE_NAME=fix-tasks-plan-progress-sync
```

If only the change name is provided (no initial input), stop and ask for the
source:

```text
请提供这次提案的原始输入：可以是飞书文档链接、本地文档路径，或直接粘贴需求。
```

## Change Name Contract

This is a state-changing workflow: `CHANGE_NAME` becomes
`openspec/changes/<CHANGE_NAME>`. Treat name parsing as a contract, not a casual
guess.

Explicit name detection:

- The first non-space token after `hello-spec-start` is an explicit `CHANGE_NAME`
  only if it matches `^[a-z0-9][a-z0-9-]{2,62}[a-z0-9]$`, contains at least one
  hyphen, and is not a reserved workflow word.
- Reserved workflow words are never valid explicit names: `hello-spec-v2`,
  `hello-spec-start`, `proposal`, `change`, `start`, `spec`, `specs`, `design`,
  `tasks`, `plan`, `brainstorm`, `apply`, `archive`.
- If the first token is a URL, file path, branch name, config value, Chinese text,
  or a reserved workflow word, treat the whole remaining text as `INITIAL_INPUT`
  and infer `CHANGE_NAME`.

Inference algorithm when no explicit name is present:

1. Extract the main business object and action from `INITIAL_INPUT`.
2. Generate a short English kebab-case name: lowercase ASCII, 3-7 tokens, max 64
   chars, letters/digits/hyphens only.
3. Preserve an explicit phase prefix such as `p0`, `p1`, `p2`, `p3`, or `p4` only
   when the user includes that phase in the input.
4. Prefer domain words over workflow words. Drop URLs, local paths, branch names,
   dates, ticket IDs, and generic terms such as `proposal`, `change`, `spec`,
   `start`, `feature`, `fix`, and `refactor` unless the verb is needed for
   clarity.
5. If the name would be vague (`update-stuff`, `fix-bug`, `new-feature`) or the
   input does not expose a business object, stop and ask:

   ```text
   我无法从这段输入稳定生成 change-name。请补充一个 kebab-case 名称，或补充更具体的业务对象/动作。
   ```

6. Before any state-changing command, report the chosen name in the first status
   update:

   ```text
   已锁定任务：hello-spec-start；CHANGE_NAME=<name>（explicit|inferred）；本轮只启动 hello-spec-v2 提案并推进到第一个业务 artifact，不进入 apply，不改业务代码。
   ```

Do not append numeric suffixes automatically when the inferred name conflicts
with an existing change. Phase 3 handles conflicts by stopping and handing off to
`hello-spec-next` or asking the user for a new name.

## Source Input Policy

This is the single authoritative source-handling block; Phase 1 and the
business-artifact phase reference it instead of restating it. Core insight: the
initial input is an early-stage source whose authority decays. Capture it durably
(chat-only prompts are lost on `/clear` or to a new agent), then let canonical
artifacts (`proposal.md`, `specs/**`, `design.md`, `grill-spec.md`) become the
source of truth so raw prompts stop overriding decisions already settled there.

Input classes (used by Phase 1 and the business-artifact phase):

- `short_inline`: short direct request; no external source needed.
- `external_source`: contains a Lark/Feishu/doc URL or a local file path.
- `high_density_without_source`: more than 500 characters, or carries explicit
  hard constraints that would be expensive to lose, but has no readable URL/path.

`external_source` and `high_density_without_source` need a re-readable external
source. When one is required but missing or unreadable, stop and ask:

```text
1. 补充可读路径/链接
2. 降级继续（NO_SOURCE_CONFIRMED=true）
```

On degraded confirmation, record `NO_SOURCE_CONFIRMED=true` in the output and in
`brainstorm.md` Input Sources. Do not treat pasted content as "good enough" for
recovery on its own.

Never-create rules:

- Do NOT create `source.md`.
- Do NOT write `intake.md`; `intake.md` is generated by retrospective workflows
  such as `spec-opti-workflow`.

Consume-by-phase:

- `brainstorm` / `proposal`: consume the initial input. For `short_inline`,
  record the raw input summary in `brainstorm.md`.
- `specs` / `design`: consume `proposal.md` and `brainstorm.md` first; re-read the
  original source only to check scope, resolve ambiguity, or confirm a hard
  constraint was not lost.
- `tasks` / `plan`: do NOT use raw initial input as the normal source of truth.
  Use canonical artifacts (`proposal.md`, `specs/**/*.md`, `design.md`,
  `grill-spec.md`). If those conflict with initial input, stop and route through
  `spec-plan-revise`.

Language: all human-facing artifact content is Simplified Chinese (schema
`language_policy`); keep code identifiers, paths, and commands in their original
language.

When creating `brainstorm.md`, include a small visible source trace so later
phases can locate the source without another mandatory file:

```markdown
## Input Sources

- Primary input: <pasted in start turn | lark/doc url | local path>
- Source consumed: yes
- Source summary: <short summary>
- Hard constraints extracted: <short list>
```

## Workflow

Before creating anything, ask four questions. An unparseable name, a "no" to
questions 2-3, or a "yes" to question 4 is a stop-and-report condition — never a
reason to push ahead. This skill exists to hold these gates, not fast-forward
past them.

1. Is `CHANGE_NAME` explicit or safely inferable? (Phase 1)
2. Is the source re-readable, or recoverable only from this chat? (Phase 1)
3. Is this repo actually configured for `hello-spec-v2`? (Phase 2)
4. Does this change already exist? (Phase 3)

**MANDATORY — READ ENTIRE FILE**: before driving any `openspec` command (Phase 2
onward), read [`references/openspec-cli-contract.md`](references/openspec-cli-contract.md)
completely. It holds the exact, easy-to-misremember JSON field names and command
shapes — do not reconstruct them from memory. Read it once at the start; you do
not need to re-open it per command.

### Phase 0 - Identity Lock

Start with:

```text
已锁定任务：hello-spec-start；CHANGE_NAME=<name>（explicit|inferred）；本轮只启动 hello-spec-v2 提案并推进到第一个业务 artifact，不进入 apply，不改业务代码。
```

Forbidden objectives:

- Do not run `openspec-propose`, `openspec-ff-change`, or `openspec-apply-change`
  — these fast-forward past the human gates this workflow exists to preserve;
  gate-skipping is the exact failure this skill replaces (see Purpose above).
- Do not generate multiple business artifacts in one turn — each artifact is a
  human review point; batching them collapses those checkpoints.
- Do not create `source.md`.
- Do not edit business source code, and do not run tests/builds — this is a
  planning entrypoint; touching code or CI here means the proposal was skipped.
- Do not commit, push, or archive.

### Phase 1 - Parse and Source Input Gate

Parse the invocation using the Change Name Contract:

- If an explicit name is present, set `CHANGE_NAME` to that token and set
  `INITIAL_INPUT` to all remaining text.
- If no explicit name is present, set `INITIAL_INPUT` to all text after
  `hello-spec-start`, infer `CHANGE_NAME` from it, and mark the name source as
  `inferred`.
- If `CHANGE_NAME` is not safely inferable, stop and ask for a concrete
  change-name or more specific source input.
- If `INITIAL_INPUT` is empty after parsing, ask for the source and stop.

Run this gate BEFORE creating the OpenSpec change, so an unreadable source does
not leave a half-initialized change directory. Classify `INITIAL_INPUT` into one
of the three input classes from the Source Input Policy, then apply that policy:

- `short_inline`: continue.
- `external_source`: verify the URL/path is readable enough to consume before
  continuing.
- `external_source` (unreadable) or `high_density_without_source`: stop and ask
  the two-choice degraded-mode question from the Source Input Policy. On
  confirmation, continue and record `NO_SOURCE_CONFIRMED=true`.

Do not write a new source file. Do not write `intake.md`.

### Phase 2 - Schema Discovery

Confirm this repo is configured for `hello-spec-v2` before creating the change
(per the CLI contract, the project schema lives in `openspec/config.yaml`, NOT in
`.openspec.yaml`):

1. Locate the repo root from cwd: prefer the nearest directory containing
   `openspec/`; otherwise the current git root.
2. Read the top-level `schema:` key and confirm `schema: hello-spec-v2`:

   ```bash
   cat <repo root>/openspec/config.yaml
   ```

3. If it is not `hello-spec-v2` (or no config is found), stop and report: cwd;
   repo-root candidate; `openspec/config.yaml` path (or none); discovered schema;
   and the repo path the user should provide.

Phase 3 re-confirms post-creation via status `schemaName`. Do not create a
non-`hello-spec-v2` change and discover the mismatch afterward.

### Phase 3 - Create Change

The four-question gate above must pass first; question 4 — does this change
already exist — is resolved here. Before running `openspec new change`, check
whether `openspec/changes/<CHANGE_NAME>` already exists. Existing change handling:

- If it exists and `openspec status --change "<CHANGE_NAME>" --json` succeeds
  with `schemaName=hello-spec-v2`, do not recreate or overwrite it. Stop, report
  that the change already exists, and suggest `hello-spec-next <CHANGE_NAME>`.
- If it exists and status shows partial artifacts, treat it as an existing
  change, not a start target. Stop and hand off to `hello-spec-next`.
- If it exists but schema is not `hello-spec-v2`, stop and report the discovered
  schema.
- If the directory exists but OpenSpec status is unreadable, stop and report the
  path plus the status error. Ask the user whether to inspect/repair manually.

Only create a new change when no existing change directory/status is present.
Then run:

```bash
openspec new change "<CHANGE_NAME>"
openspec status --change "<CHANGE_NAME>" --json
```

If `openspec new change` itself errors, stop and report its stderr — do not retry
blindly or hand-create the directory. Otherwise confirm `schemaName` is
`hello-spec-v2`; if it is not, stop — this skill is only for `hello-spec-v2`.

### Phase 4 - Placeholder Fast Path

Use this explicit algorithm (field names per the CLI contract). Do not invent
placeholder behavior.

Loop:

1. Run `openspec status --change "<CHANGE_NAME>" --json`.
2. Find the first artifact in `artifacts[]` with `status == "ready"` (scan the
   list yourself; there is no next-ready field).
3. Run `openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json`.
4. Decide placeholder vs business from the instruction semantics, not a memorized
   ID list (see the contract's detection rule): a placeholder directs verbatim
   copy from `template`; a business artifact instructs synthesis or invokes
   another skill.
5. If it is not a placeholder (a business artifact or a gate), stop the loop.
6. For a placeholder, write `template` verbatim to `<changeDir>/<outputPath>`
   (both read from the instructions JSON).
7. Re-run status and continue the loop.

Never infer placeholder content. Never create business artifacts in this phase.
Stop when the next ready artifact is business-bearing or a gate.

### Phase 5 - First Business Artifact

If the next ready artifact is `brainstorm`, a start invocation with non-empty
`INITIAL_INPUT` is permission to draft exactly this one artifact (unless the user
said "only create the change"). After creating brainstorm, stop.

Phase-specific delta for `brainstorm.md`:

- Consume the initial input per the Source Input Policy's consume-by-phase rules.
  For `external_source`, read the URL/path with the relevant available
  tools/skills before drafting. If degraded mode was confirmed, consume the
  current-turn pasted input and mark `NO_SOURCE_CONFIRMED=true`.
- Include the `## Input Sources` trace from the Source Input Policy.
- Extract goals, non-goals, hard constraints, known references, and open questions.
  Write the content in Simplified Chinese per the Source Input Policy's language rule.
- Do not create `proposal.md` in the same turn unless the user explicitly asks
  after reviewing brainstorm.

If the next artifact is not `brainstorm`, stop and show the next instruction.

### Phase 6 - Output Format

Close with a short status report: change name and confirmed schema; which
placeholders were auto-created; the artifact you stopped at plus one line on why;
then the resume commands. The `cd <repo root>` is the non-obvious part — a
`/clear` drops the working directory, so the next agent needs it.

```text
## Next Command
hello-spec-next <change>

## Suggested /clear Resume
cd <repo root> && hello-spec-next <change>
```

## Success Criteria

Done correctly means: a `hello-spec-v2` change exists; only lightweight
placeholders were auto-created (no `source.md`, no `intake.md`); and the flow
stopped at the first business artifact — either having drafted exactly one ready
`brainstorm` (initial input consumed into it), or having stopped to ask for
missing input. Never proceed into proposal/specs/design/tasks/plan here.
