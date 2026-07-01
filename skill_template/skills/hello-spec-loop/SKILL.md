---
name: hello-spec-loop
description: Use when the user wants a hello-spec-v2 OpenSpec-style SDD change to run from an initial requirement prompt through planning, implementation, AI review/fix convergence, interruption/gate resume, and stop only at low-cost human code review; triggers include hello-spec-loop, 从需求一路实现, 自动推进到代码实现, loop 到 human review, 继续 loop, /clear 恢复, or fewer manual hello-spec-start/next/apply commands.
---

# hello-spec-loop

## Purpose

`hello-spec-loop` is the high-level orchestrator for `hello-spec-v2`.

It turns one initial requirement prompt into a mostly continuous SDD execution:
planning artifacts, conditional human decision packets, implementation through
`hello-spec-apply`, `spec-code-review review/fix/review` convergence, and then a
final stop at low-cost human code review.

It is not a replacement for the primitive skills. It drives them:

- `hello-spec-start`: new change identity, source gate, first artifact.
- `hello-spec-next`: artifact progression and `grill-spec` mechanics.
- `hello-spec-apply`: subagent implementation and ledger reconciliation.
- `spec-code-review`: independent review/fix loop after apply.
- `spec-plan-revise`: planning/target drift repair.
- `spec-trouble-resolve`: code-stage drift repair.

## Core Principle

Default to continuing the loop. Interrupt the user only when AI cannot safely
decide, when the action would be irreversible/high-risk, or when final code is
ready for human review.

When a gate is needed, do not ask the user to review files manually. Present a
short decision packet in chat, accept one consolidated reply, persist it, and
continue automatically.

Planning clarification is a different mechanism from loop decisions:

- Planning questions are owned by `hello-spec-next` / `grill-spec` and use the
  `QID` answer contract.
- Execution/review decisions are owned by this loop's gate protocol and use
  `Dxxx` entries in `human-decisions.md`.

## When Not To Use

- The repo is not `hello-spec-v2` and the user did not ask to upgrade or use v2.
- The user only wants a single primitive action such as `hello-spec-next`,
  `spec-code-review fix`, or `spec-trouble-resolve`.
- The user asks for read-only diagnosis only; use `spec-e2e-debug`.
- The user asks to commit/push; use `spec-commit-push` after review readiness.

## Identity Lock

Start every run with an identity line before any state-changing write:

```text
已锁定任务：hello-spec-loop；CHANGE_NAME=<name|unresolved>；目标=从需求推进到 AI review/fix 收敛后的 human_code_review_ready；默认自动继续，只有 Source/Decision/Risk/Final CR gate 才打断。
```

If the change cannot be resolved safely, stop with a concrete stop reason from
`references/loop-state.md`.

## Required References

Load references only when needed:

- Always read `references/loop-state.md` before resolving identity or writing
  `loop.md`; it owns stop propagation, loop-owned fields, phase enums,
  stale-state checks, primitive-confirmed transition rules, and the
  extra-schema status of `loop.md`.
- Read `references/gate-protocol.md` before asking the user for any gate input;
  it owns gate triggers, packet shape, reply parsing, and risk details.
- Read `references/review-fix-loop.md` before starting post-apply review/fix;
  it owns review/fix machine-state handling, round limits, and convergence.
- Before crossing a primitive boundary, read and invoke the current primitive
  skill named in **Primitive Contract Bridge** below.

Do NOT load neighbor skills just because they exist. Load only the primitive for
the boundary you are about to cross, plus the reference/template that primitive
itself says is authoritative. Field names mentioned in this skill are minimum
sanity checks; they never override the current primitive/template contract.

If a required reference is missing or unreadable, stop with:

```text
Stopped at: skill_package_incomplete
```

Eval `assertions` fields, when present under `evals/evals.json`, are for future
graders and benchmark tooling. Do NOT load evals at runtime. They are not
runtime behavior and must not override this skill, the references above, or
primitive contracts.

## Primitive Contract Bridge

`hello-spec-loop` is an orchestrator, not a cached copy of primitive behavior.
The current primitive skill body is authoritative whenever this file disagrees
with it.

Before each boundary, load/invoke the relevant primitive skill and follow its
current contract:

| Boundary | Required primitive | If it stops |
|---|---|---|
| Start a new change | `hello-spec-start` | If it stops before creating/resolving a concrete `changeDir`, do not create `loop.md`; preserve its exact `Stopped at:` reason in chat. If a `changeDir` exists, preserve the reason in `loop.md` without rewriting it. |
| Resolve/resume or generate next artifact | `hello-spec-next` | Copy its stop/artifact/QID outputs verbatim; record only loop phase, route, and ledger context separately. |
| Repair planning/target drift | `spec-plan-revise` | Use its current input and output contract; do not invent downstream artifacts when that primitive cannot confirm them. |
| Apply implementation | `hello-spec-apply` | Copy stop reasons, ledger results, apply status, and completion evidence verbatim; record loop context separately. |
| Review after apply | `spec-code-review review` | Load the current report template, copy readiness/Fix Queue/Machine State values verbatim, and keep loop interpretation to routing. |
| Fix review findings | `spec-code-review fix` | Let the primitive/template decide consumable repair items and refreshed status; the loop only records fix output and runs review again. |
| Repair code-stage drift | `spec-trouble-resolve` | Pass oral issues as `problem_text`; consume `troubleshoot.md` only when it already contains matching pending user content. |

Even when a primitive stop reason is unknown to this loop, copy the exact
primitive reason into `Last primitive stop reason` and stop with the same
user-facing `Stopped at:` value. Put loop context in `Loop phase:` /
`Loop route:` or `loop.md`; never replace the stop reason.

## Primitive Invocation Boundary

The user's end-to-end loop request authorizes repeated internal primitive
invocations. It does not authorize merging several primitive steps into one
unbounded action.

At every internal boundary:

1. Load the current primitive skill.
2. Execute exactly one primitive-safe unit.
3. Capture output, stop reason, artifact/report path, gate IDs, and repo/diff
   state as applicable.
4. Update `loop.md`.
5. Decide from the recorded state whether a gate is required or the loop may
   invoke the next primitive.

Primitive-safe units:

- `hello-spec-start`: one start/resume attempt through first concrete artifact
  or primitive stop.
- `hello-spec-next`: exactly one business artifact, or one `grill-spec` QID
  ask/consume step. If another artifact is ready, record state and gate status
  first, then invoke `hello-spec-next` again.
- `hello-spec-apply`: one apply slice under the current plan contract.
- `spec-code-review review`: one review run.
- `spec-code-review fix`: one template-authorized repair consumption pass.
- `spec-plan-revise` / `spec-trouble-resolve`: one primitive repair pass, then
  return to the state machine.

This boundary must not weaken `grill-spec`: unresolved planning questions still
stop inside `hello-spec-next` gate mode until the required `QID` answers are
recorded.

Run skeleton:

```text
lock identity -> invoke one primitive-safe unit -> copy primitive/template output
verbatim -> update loop.md -> gate/risk check -> choose next primitive from
references/loop-state.md. Preserve any primitive `Stopped at:` line exactly.
```

## Operating Modes

Natural language is the primary interface. Do not require flags.

| User intent | Mode |
|---|---|
| Initial requirement prompt | `start_or_resume` |
| Existing change name/path or "继续 loop" | `resume` |
| User answers a decision packet | `consume_gate_answer` |
| User interrupts with "目标不对/文档不对/不是这个意思" | `planning_drift` |
| User interrupts with "代码不对/实现有问题/测试不过" | `code_drift` |
| User explicitly asks commit/push | stop and point to `spec-commit-push` |

The default loop goal is always:

```text
human_code_review_ready
```

## Main Workflow

### Stage 0 - Resolve Or Start

1. If the input is a new requirement, use `hello-spec-start` semantics:
   infer or accept `CHANGE_NAME`, enforce Source Gate, verify schema, and create
   the change. Do not write `source.md` or `intake.md`.
   - If `hello-spec-start` stops at source/schema/name validation before a
     `changeDir` exists, stop the loop in chat only. Do not hand-create a
     change directory and do not write `loop.md`.
   - If the user later answers the Source Gate with degraded mode and the
     change is then created, initialize `loop.md` at that point and record
     `NO_SOURCE_CONFIRMED=true` both in `loop.md` and in `brainstorm.md`
     `Input Sources` when that artifact is created/updated.
2. If the input names or implies an existing change, use `hello-spec-next`
   resolution semantics: explicit path, explicit name, cwd, resume token, or sole
   active `hello-spec-v2` change. Stop on ambiguity; do not guess by recency.
3. Create or update `<changeDir>/loop.md` using `references/loop-state.md` only
   after a concrete `changeDir` is known.

### Stage 1 - Plan Loop

Continue artifact progression through the current `hello-spec-next` contract.

Loop-owned behavior:

- Invoke only one `hello-spec-next` unit at a time and copy its artifact/QID
  result verbatim before deciding whether to continue.
- Do not create `grill-spec.md` while unresolved questions remain.
- Do not create `human-decisions.md` during planning. Planning uncertainty uses
  `design.md` / `grill-spec`; `human-decisions.md` is lazy execution/review
  state unless the current primitive explicitly requires it.
- Do not force a fixed "plan review" hard gate.

Only interrupt for:

- Source Gate.
- Decision Gate.
- Risk Gate.

If user feedback says the plan/target is wrong, classify it as planning drift and
run `spec-plan-revise`, then continue from the earliest affected artifact.

### Stage 2 - Apply Loop

After plan artifacts are ready and no blocking gate remains, continue into
`hello-spec-apply` without asking the user to type `hello-spec-apply`.

This is allowed because `hello-spec-loop` itself expresses the user's goal to
reach implemented code. Still obey `hello-spec-apply` exactly:

- before every apply slice, run the operational Risk Checklist in
  `references/gate-protocol.md`; if the slice matches a high-risk boundary and
  the plan or `human-decisions.md` does not already contain explicit approval,
  pause with `risk_gate`;
- load the current `hello-spec-apply` contract and copy its dispatch, ledger,
  stop, and completion evidence verbatim;
- never commit, push, archive, or create an MR;
- stop on blocking decisions exactly as reported by the primitive.

If implementation exposes target/design drift, route to `spec-plan-revise`. If
it exposes code-stage drift, route to `spec-trouble-resolve` with the issue text
as `problem_text` unless the user explicitly provided or requested use of a
matching `troubleshoot.md`.

### Stage 3 - AI Review/Fix Loop

After apply completes, run the review/fix convergence loop in
`references/review-fix-loop.md`:

```text
spec-code-review review -> spec-code-review fix -> spec-code-review review
```

Use independent review/fix roles when the harness allows it, but follow
`references/review-fix-loop.md` for exact role separation, fallback modes,
template consumption, and round-limit behavior.
Before each fix slice, apply the Risk Checklist owned by
`references/gate-protocol.md`; do not broaden a fix beyond the
template-authorized item without the gate route defined there.

### Stage 4 - Final Stop

Stop at:

```text
Stopped at: human_code_review_ready
```

only when the review/fix loop has converged per `references/review-fix-loop.md`.

The final response must give the human a low-cost review pack:

- final changed repositories and per-repo diff stat;
- latest `spec-code-review.md` path;
- `CR Readiness`;
- remaining `human_decision` IDs, if any;
- manual test commands or verification gaps;
- recommended human review scope.

Do not commit or push.

## Gate Policy

There are only four hard gates. Exact trigger criteria, packet text, reply
forms, persistence rules, and risk checklist live in
`references/gate-protocol.md`.

- `source_gate`
- `decision_gate`
- `risk_gate`
- `final_human_cr_gate`

Everything else is a soft checkpoint: record it in `loop.md` and continue.
Planning clarification remains owned by `hello-spec-next` / `grill-spec` `QID`,
not `Dxxx` / `human-decisions.md`.

## Interrupt Handling

User interruptions are first-class input. Do not tell the user to rerun another
command unless the loop cannot locate the change.

| Interruption | Route |
|---|---|
| "目标不对 / 文档不对 / 不是这个意思" | write/consume `revise.md`, run `spec-plan-revise`, then continue loop. |
| "代码不对 / 实现有问题 / 测试不过" | run `spec-trouble-resolve` with the oral issue as `problem_text`, then return to review/fix loop. |
| Review feedback on template-authorized fix items | run `spec-code-review fix`, then review again. |
| New execution/review decision | create/update `human-decisions.md`, ask one Dxxx decision packet, persist answer, continue. |
| Commit/push request | stop and point to `spec-commit-push`; do not mix commit into loop. |

`troubleshoot.md` handling is intentionally narrow:

- If an existing `<changeDir>/troubleshoot.md` has pending user-authored content
  that matches this interruption, pass that path to `spec-trouble-resolve`.
- If the user orally reports a code issue and no matching pending
  `troubleshoot.md` entry exists, pass it as `problem_text`; do not create or
  append `troubleshoot.md`.
- Create or append `troubleshoot.md` only when the user explicitly asks to
  record the issue there (for example, "写到 troubleshoot.md 再处理").
- Never let apply workers, review workers, or loop orchestration auto-populate
  `troubleshoot.md`; the hello-spec-v2 schema treats it as user-curated.

If a worker is running and the interruption affects the worker's target or write
scope, reconcile before continuing:

1. Capture `git status --short` plus a focused diff, or the harness-equivalent
   changed-file snapshot, before discarding or overwriting anything.
2. Identify files touched by the interrupted apply/review/fix slice from worker
   output, diff paths, and `loop.md` progress.
3. Separate pre-existing/user edits from worker edits; preserve user edits and
   stop for confirmation if attribution is unclear.
4. Reconcile `plan.md`, `tasks.md`, and `loop.md` to the canonical post-slice
   state, marking partial slice work blocked or incomplete when needed.
5. If partial writes cannot be safely attributed or reverted, stop with the
   primitive/report reason if one exists, otherwise `apply_blocked` or
   `review_fix_loop_not_converged`, and ask for human confirmation.

If the interruption does not affect the active slice, finish the current slice
and apply the interruption at the next slice boundary.

## NEVER

- NEVER ask the user to review generated files as the primary gate interaction;
  summarize decisions in chat and continue after one reply.
- NEVER create `grill-spec.md` while pending decisions remain; OpenSpec treats
  file existence as gate completion, so a pending file false-completes planning.
- NEVER use `Dxxx` / `human-decisions.md` for planning clarification that belongs
  to `hello-spec-next` / `grill-spec` `QID`.
- NEVER create `human-decisions.md` before apply/review unless the primitive
  currently being invoked explicitly requires a concrete execution-stage entry.
- NEVER run `openspec-propose` or `openspec-ff-change` for this workflow.
- NEVER auto-fix `human_decision`, `deferred`, or `false_positive` review items.
- NEVER treat `spec-code-review fix` as refreshing `CR Readiness`; run review
  again after fix.
- NEVER continue a review/fix loop beyond the maximum round count in
  `references/review-fix-loop.md`.
- NEVER commit, push, archive, or create/handle MR comments from this skill.
- NEVER overwrite human-authored placeholder files; use the existing
  `hello-spec-next` overwrite guard semantics.
- NEVER infer paths or machine fields when the underlying skill's machine
  contract says to stop.
- NEVER create or append `troubleshoot.md` for an oral code issue unless the
  user explicitly asks to record it there; the schema treats it as a
  user-curated inbox, not an agent scratchpad.
- NEVER collapse primitive stop reasons into `apply_blocked` or
  `review_fix_loop_not_converged` when the primitive returned a more precise
  reason; recovery automation keys off the exact primitive stop value.

## Terminal Output Shape

Use concise Chinese summaries:

```text
状态：<phase>
进度：<artifact/apply/review round>
本轮动作：<what changed or what was reviewed>
Gate：<none | source_gate | decision_gate | risk_gate | final_human_cr_gate>
下一步：<auto-continue | waiting for QID answer via hello-spec-next | waiting for Dxxx answer | human_code_review_ready>
路径：<loop.md / spec-code-review.md / key artifacts>
```

When waiting for a gate answer, end with the exact accepted reply forms from
`references/gate-protocol.md`.
