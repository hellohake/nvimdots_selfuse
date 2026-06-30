---
name: hello-spec-apply
description: Use when applying or continuing implementation for a hello-spec-v2 OpenSpec-style SDD proposal, including "开始实现", "apply", "按 plan 实现", "继续实现", "执行计划", "实现这个提案", or when openspec-apply-change resolves schemaName=hello-spec-v2. This is the required apply entrypoint for hello-spec-v2; do not use generic openspec-apply-change directly for hello-spec-v2 implementation.
---

# hello-spec-apply

Implement a `hello-spec-v2` proposal without collapsing the workflow into one long
main-thread coding session.

This skill exists because `hello-spec-v2` apply has stronger rules than generic
OpenSpec apply: subagent authorization, context discipline, plan/tasks ledger
reconciliation, no auto-commit, test-policy handling, and human-decision blocking.

## Hard Boundary

Invoking `hello-spec-apply <change>` or an equivalent user request is explicit
authorization to use delegated subagents for this apply phase. If the platform
does not allow spawning subagents, stop before code edits with
`Stopped at: subagent_mode_unavailable` unless the user explicitly says
`SERIAL_APPLY=true`.

Never silently fall back to main-agent serial implementation. That failure mode
burns context and makes the `Agent Execution Audit` untrustworthy.

Subagent tools being unavailable only permits read-only preflight or ledger-only
cleanup. It never authorizes serial production-code implementation by itself.

## Inputs

Accept either:

- absolute proposal directory: `/abs/repo/openspec/changes/<change>`;
- change name: `hello-spec-apply <change>`;
- hot-context request when exactly one active `hello-spec-v2` change can be
  resolved safely.

Resolve identity using the same contract as `hello-spec-next`: explicit path,
explicit name, cwd inside a change dir, stable resume token, or exactly one active
`hello-spec-v2` change. Stop on `missing_change_context` or
`ambiguous_change_context`.

## Required Preflight

1. Lock `REPO_ROOT` to the directory that contains `openspec/`.
2. Run from `REPO_ROOT`; OpenSpec does not reliably walk up from child dirs.
3. Confirm schema:
   ```bash
   openspec status --change "<change>" --json
   ```
   `schemaName` must be `hello-spec-v2`.
4. Get current apply contract:
   ```bash
   openspec instructions apply --change "<change>" --json
   ```
   Treat the returned apply instruction as the binding source of truth for this
   run. Required machine fields are `changeName`, `changeDir`, `schemaName`,
   `contextFiles`, `progress`, and `tasks`. If any are missing, stop with
   `Stopped at: machine_contract_missing` and do not guess paths.
5. Run Template Contract Preflight before production-code edits:
   - Gotchas red-lines: identify touched domain tags, load project/global
     gotchas when present, filter to IDs and short do/don't summaries only, and
     record `已查 gotchas：...` in the apply audit or first ledger update. Do
     not paste whole gotcha files into the main context.
   - Test capability: ensure `tasks.md` and `plan.md` contain a test capability
     classification for every touched repo (`repo_remote`, `go_module`,
     classification, basis). If it is missing for a production-code slice, stop
     with `Stopped at: needs_plan_refinement`; do not infer it only in chat.
   - Human decisions: read `human-decisions.md` if it exists. Blocking
     `pending_human` entries stop the slice before code edits.
   - Dispatch matrix: `plan.md` must contain a non-empty
     `Subagent Dispatch Matrix`. Every production-code slice needs `SliceID`,
     `TaskRefs`, `StepIDs`, `Worktree`, `Allowed Write Scope`, `Test Policy`,
     `Reviewers`, and `Stop Conditions`. If the matrix is absent, placeholder
     only, or does not cover the next production-code step, stop with
     `Stopped at: needs_plan_refinement`.
6. Read only summaries/frontmatter first:
   - `plan.md`: StepID/TaskRef, task headings, Agent Execution Audit.
   - `tasks.md`: coarse checkboxes and test capability classification.
   - `design.md`, `grill-spec.md`, `specs/**/*.md`: only sections needed to
     derive red-lines and acceptance checks.
7. Before any code edit, update `plan.md` Agent Execution Audit with:
   ```text
   Subagent mode: planned
   Spawned agents: 0
   Manual fallback: no
   Fallback reason: none
   ```

## Dispatch Plan

Consume the `Subagent Dispatch Matrix` from `plan.md` first. Do not invent a
replacement matrix in the apply phase. If the matrix is missing or incomplete,
stop with `needs_plan_refinement` and point the user back to the plan stage.

Do not create one subagent for every checkbox. Group tightly-related micro-steps
into serial slices that have disjoint or mostly-disjoint write scopes, following
the matrix.

Good default slices for plan authors and refinement suggestions:

| Slice | Typical TaskRefs | Write Scope |
|---|---|---|
| preflight | 1.x | ledgers only, no production code |
| core domain/cache | 2.x | domain + infrastructure cache/repository |
| SDK/application | 3.x-5.x | start/application/domain service |
| integration adapter | 6.x-7.x | downstream repo adapter/wiring |
| final verification | all touched | ledgers, diagnostics, manual commands |

Parallelize only read-only exploration or final independent review. For code
changes, prefer serial subagents unless write scopes are clearly disjoint.

## NEVER

- NEVER use generic `openspec-apply-change` to directly implement a
  `hello-spec-v2` proposal; switch to `hello-spec-apply`.
- NEVER treat unavailable subagent tools as permission to serially edit
  production code. Production-code serial fallback requires explicit
  `SERIAL_APPLY=true`.
- NEVER check a `tasks.md` item while its mapped `plan.md` `StepID`s are
  unchecked or missing.
- NEVER write or auto-populate `troubleshoot.md` during apply.
- NEVER run full-suite `go test ./...` or full `go build` unless repo policy
  explicitly says it is safe; targeted tests follow test policy.
- NEVER run `git add`, `git commit`, `git push`, archive, or create an MR.
- NEVER declare apply complete while blocking `pending_human` decisions,
  unresolved dispatch gaps, or unreconciled ledgers remain.

## Subagent Prompt Contract

Each implementation subagent prompt must include:

- `Skill identity`: hello-spec-apply worker for `<change>`.
- `SliceID`, `TaskRefs`, and exact `StepID`s.
- absolute worktree path and allowed write scope.
- relevant spec/design/gotcha/test-policy excerpts by ID, not whole files.
- no-commit rule: do not run `git add`, `git commit`, push, archive, or open MR.
- ledger rule: update `plan.md` checkboxes for completed StepIDs and update
  `tasks.md` only when all matching plan steps for a TaskRef are complete.
- output rule: write code/tests/ledgers to disk; final response is only status,
  changed paths, commands run, and blockers.
- stop conditions: unresolved human decision, missing dependency version,
  ambiguous architecture decision, test-policy conflict, or required file outside
  write scope.

Use this implementation prompt skeleton:

```text
You are a hello-spec-apply implementation worker for CHANGE=<change>.

SliceID: <slice-id>
TaskRefs: <task refs>
StepIDs: <step ids>
Worktree: <absolute path>
Allowed write scope:
- <paths>

Read from disk:
- <plan/design/spec paths and exact sections>

Red-lines:
- <gotcha/test-policy/design constraints by ID>

Rules:
- Implement only this slice.
- Do not run git add/commit/push/archive.
- Do not edit files outside Allowed write scope.
- Update plan.md checkboxes only for completed StepIDs.
- Update tasks.md only when all StepIDs for that TaskRef are complete.
- If blocked, leave checkboxes unchecked and add a short blocked line.
- Return Status=DONE|DONE_WITH_CONCERNS|BLOCKED|NEEDS_CONTEXT, changed paths,
  commands run, and unresolved blockers.
```

Reviewer subagents must review uncommitted worktree diffs, not commit SHAs:

```text
You are a hello-spec-apply reviewer for CHANGE=<change>.
Review SliceID=<slice-id> using plan.md StepIDs, tasks.md TaskRefs,
spec/design/grill-spec constraints, and current git diff/status.
Do not modify files.
Return PASS or FAIL with file:line evidence and required fixes.
```

## Execution Loop

For each slice:

1. Spawn one implementation subagent with `fork_context=false` and a bounded prompt
   using the contract above.
2. Wait only when the next coordinator action depends on that worker's result.
3. Inspect the worker's changed paths and status.
4. Spawn a spec-conformance reviewer for that slice.
5. If spec review fails, send the findings back to the implementation worker or
   apply a tightly-scoped fix locally only if the fix is trivial and inside the
   same write scope.
6. Spawn a code-quality reviewer for non-trivial code slices after spec review
   passes.
7. Reconcile `plan.md` and `tasks.md`; update audit:
   ```text
   Subagent mode: serial_subagents
   Spawned agents: <n>
   Manual fallback: no
   Progress ledger: plan=<done>/<total>, tasks=<done>/<total>, status=<PASS|PARTIAL|BLOCKED>
   ```

## Fallback Policy

Manual serial implementation is allowed only when one of these is true:

- user explicitly says `SERIAL_APPLY=true`;
- the slice is a tiny ledger-only edit with no production code;
- an urgent one-line fix is needed after reviewer feedback and is cheaper than
  redispatching.
- subagent tools are unavailable and the action is read-only or ledger-only.

For production-code edits, `SERIAL_APPLY=true` is the only serial fallback
authorization.

When using fallback, write this before editing:

```text
Subagent mode: manual_fallback
Manual fallback: yes
Fallback reason: <reason>
User authorization: <SERIAL_APPLY=true|tool_unavailable|ledger_only|one_line_review_fix>
```

If fallback is not authorized, stop with `Stopped at: subagent_mode_unavailable`.

## Completion Gate

Before final response:

- `plan.md` and `tasks.md` are reconciled.
- `human-decisions.md` has every unresolved execution-stage decision; blocking
  `pending_human` entries keep apply status `PARTIAL` or `BLOCKED`.
- `manual_test_commands.md` records commands for all new/modified test files, or
  a clear repo-policy reason.
- gopls diagnostics or local `gopls check` results are recorded.
- final summary says whether subagents were used, how many, and why any fallback
  happened.

Do not claim `apply complete` while any blocking human decision or unmatched
plan/tasks ledger entry remains.
