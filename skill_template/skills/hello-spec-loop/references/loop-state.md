# hello-spec-loop State Contract

This reference owns `loop.md`, stop reasons, and progress persistence.

## loop.md Purpose

`loop.md` is an orchestration ledger, not a business artifact. It exists so the
loop can survive `/clear`, user interruptions, and handoff to another agent.

Create it lazily at:

```text
<CHANGE_DIR>/loop.md
```

Only create it after a concrete `CHANGE_DIR` exists. If `hello-spec-start`
stops before creating/resolving the change directory, preserve the stop in chat
and do not create a floating `loop.md` elsewhere.

Do not put it in `.ai_doc/` and do not use it as a substitute for proposal,
design, tasks, plan, `human-decisions.md`, `revise.md`, or `troubleshoot.md`.

## Extra-Schema Contract

`loop.md` is intentionally extra-schema orchestration state under
`<CHANGE_DIR>`. It is not an OpenSpec artifact and must not be passed to
`openspec status`, `openspec apply`, or primitive skills as a generated
proposal/design/tasks/spec artifact.

Canonical artifacts still win: proposal/spec/design/tasks/plan/review reports
define SDD truth; `loop.md` only records routing, resume state, and copied
primitive outputs. If OpenSpec or wrapper tooling rejects unknown extra files
under `changeDir`, stop with:

```text
Stopped at: loop_ledger_tooling_rejected
```

Report the rejecting command/tool and preserve `loop.md` exactly as user state.
Do not delete, move, or rewrite it to satisfy the tool; ask for template/schema
support or a tool-owned ignore rule before continuing.

## Minimal Template

```markdown
# hello-spec-loop

## Identity
- Change: <CHANGE_NAME>
- Change dir: <absolute path>
- Repo root: <absolute path>
- Goal: human_code_review_ready
- Created at: <timestamp>
- Updated at: <timestamp>

## Current State
- Phase: <resolve|planning|apply|review_fix|gate|human_code_review_ready|blocked>
- Last stop reason: <none|enum>
- Loop route: <none|resolve|planning|apply|review_fix|planning_drift|code_drift|gate>
- Last primitive: <none|hello-spec-start|hello-spec-next|spec-plan-revise|hello-spec-apply|spec-code-review|spec-trouble-resolve>
- Last primitive stop reason: <none|verbatim Stopped at value>
- Pending gate: <none|source_gate|decision_gate|risk_gate|final_human_cr_gate>
- Resume intent: <auto_continue|awaiting_user_reply|manual_resume>

## Approvals And Decisions
- Source degraded: <no|NO_SOURCE_CONFIRMED=true>
- Decisions answered: <none|D001=A,...>
- Risk approvals: <none|RISK001=approved,...>

## Repo Set
- Primary repo: <unknown|absolute path>
- Changed repos: <none|absolute path list>
- Repo baselines: <unknown|repo => baseline ref/merge-base/HEAD-at-start>
- Worktrees: <unknown|repo => worktree path/branch>
- Diff stat by repo: <not_ready|repo => stat summary>
- Broad cross-repo scope: <no|yes: reason>

## Planning Progress
- Latest ready artifact: <none|artifact id>
- Last artifact written: <none|artifact path>
- Planning drift route: <none|revise.md/spec-plan-revise>

## Apply Progress
- Apply status: <not_started|running|blocked|complete>
- Subagent mode: <not_started|planned|serial_subagents|parallel_subagents|manual_fallback|blocked>
- Plan ledger: <unknown|done/total>
- Tasks ledger: <unknown|done/total>
- Code drift route: <none|troubleshoot.md/spec-trouble-resolve>

## Review-Fix Progress
- Review round: <0-3>
- Latest report: <none|absolute spec_code_review.md path>
- Latest CR Readiness: <unknown|verbatim template value>
- Latest accepted IDs: <none|R001,R002>
- Latest fixed IDs: <none|R001,R002>
- Latest human decision IDs: <none|D001,D002>
- Review dispatch: <none|independent_agent|inline_fallback|degraded_no_diff_or_context>
- Fix dispatch: <none|independent_agent|inline_fallback|manual_fallback>
- Machine State mode: <unknown|present|degraded_no_machine_state|unconsumable>

## Final Human Review Pack
- Changed repos: <not_ready|absolute path list>
- Diff stat by repo: <not_ready|repo => stat summary>
- Recommended human review scope: <not_ready|summary>
- Manual test commands: <not_ready|paths or IDs>
```

## Update Rules

- Update `loop.md` after every gate answer, artifact write, apply slice, review
  run, fix run, and stop.
- Keep entries short. Link to artifact/report paths instead of pasting bodies.
- Keep repo-set state lightweight and evidence-based:
  - derive changed repos from the plan-owned `Subagent Dispatch Matrix`,
    apply/review worker outputs, and real `git status`/`git diff --stat`;
  - record a baseline per repo as the comparison basis actually used
    (`HEAD`, merge-base, branch point, or explicit user baseline);
  - record worktree path/branch per repo when known;
  - update `Diff stat by repo` before every review/fix round and final packet;
  - if more than one repo has production-code diff, set
    `Broad cross-repo scope=yes` unless the plan explicitly scoped the repo set.
- If `loop.md` conflicts with canonical artifacts, canonical artifacts win; fix
  `loop.md` from proposal/design/tasks/plan/report evidence and continue only
  when the canonical state is unambiguous. If canonical artifacts conflict with
  each other, stop at the primitive/report stop reason that exposed the conflict.
- Do not store raw long prompts here. `intake.md` remains retrospective-only.

## Loop Ledger Validation

Before trusting `loop.md`, validate it against canonical artifacts and the phase
enum. Allowed `Phase` values are `resolve`, `planning`, `apply`, `review_fix`,
`gate`, `human_code_review_ready`, and `blocked`; `Pending gate` values are
`none`, `source_gate`, `decision_gate`, `risk_gate`, and
`final_human_cr_gate`; `Resume intent` values are `auto_continue`,
`awaiting_user_reply`, and `manual_resume`.

Required minimum fields by phase:

| Phase | Required fields |
|---|---|
| `resolve` | `Change`, `Goal`, `Last primitive`, `Last primitive stop reason` |
| `planning` | `Change dir`, `Latest ready artifact`, `Last artifact written`, `Last primitive` |
| `apply` | `Apply status`, `Subagent mode`, `Plan ledger`, `Tasks ledger`, repo-set fields when code writes begin |
| `review_fix` | `Review round`, `Latest report`, `Latest CR Readiness`, `Latest accepted IDs`, `Machine State mode`, diff stat |
| `gate` | `Pending gate`, `Resume intent=awaiting_user_reply`, matching source/Dxxx/RISK evidence |
| `human_code_review_ready` | final changed repos, per-repo diff stat, latest report, readiness, manual verification state |
| `blocked` | `Last stop reason`, `Last primitive stop reason`, `Loop route` |

Stale-state detection:

- If `loop.md` says `apply` or `review_fix` but `plan.md` / `tasks.md` ledgers
  are missing, contradictory, or unreconciled, treat `loop.md` as stale.
- If review fields point to a missing, older, or unconsumable
  `spec_code_review.md`, treat review state as stale.
- If repo-set fields lack real git/worktree evidence before review/fix, refresh
  them before continuing.

Primitive-confirmed transition evidence:

- The cold-resume classifier below is advisory only. It selects the next
  primitive to invoke; it is never final authority to cross phases.
- `planning -> apply` is confirmed only by the current `hello-spec-next` /
  `hello-spec-apply` contracts. The loop may observe ready-looking plan/tasks,
  but it must invoke the primitive and copy its acceptance or stop verbatim.
- `apply -> review_fix` is confirmed only by current `hello-spec-apply`
  completion evidence plus recorded repo baseline and diff stat for the changed
  repo set. If either side is missing, stay in `apply` routing and refresh or
  invoke the primitive before review.
- `review_fix` progress is confirmed only by current `spec-code-review`
  template consumption. Copy readiness, accepted IDs, Machine State mode, and
  report stops verbatim; record loop context separately.

## Phase Transition Table

Use this table after every primitive call or user interruption. It is the loop's
state machine; primitive skills still own their internal field semantics.

| Phase | Entry condition | Invoke/load | Success signal | Stop signal/routing | `loop.md` update | Next phase |
|---|---|---|---|---|---|---|
| `resolve` | User gave a new requirement and no `changeDir` is locked. | Load `hello-spec-start`; create or resolve `CHANGE_NAME`; enforce source/schema gates. | Start primitive returns a concrete `changeDir` and first artifact state. | `source_gate_required`, `schema_mismatch`, `schema_unavailable`, or primitive stop. | Identity, `Phase=planning`, last primitive, first artifact path; or blocked stop reason. | `planning` or `gate`/`blocked` |
| `resolve` | User gave existing change name/path, cwd context, resume token, or sole active change. | Load `hello-spec-next` resolution semantics. | Primitive resolves exactly one `changeDir`. | Copy primitive stop verbatim; list candidates only when the primitive exposes them. | Identity if resolved; otherwise stop reason and `Resume intent=awaiting_user_reply`. | Advisory phase from canonical state, then primitive-confirmed transition |
| `planning` | `changeDir` exists and at least one planning artifact is ready or pending. | Load `hello-spec-next` only. For `grill-spec`, load its gate reference through `hello-spec-next`. | Copy one artifact/QID/completion result from the primitive. | Planning QID stops stay in `hello-spec-next`; planning drift routes to `spec-plan-revise`; other primitive stops are preserved. | Latest ready artifact, last artifact written, pending gate only if source/risk; do not write `human-decisions.md`. | `planning` until current primitive confirms apply boundary |
| `planning` | Classifier sees apply-ready-looking artifacts. | Load current `hello-spec-apply`; do not re-parse plan fields from this skill. | Apply primitive accepts the plan contract and starts/continues slices. | Primitive stop is preserved; plan repair uses `spec-plan-revise` only when the current primitive/report says so. | `Apply status=running|blocked`, subagent mode, plan/tasks ledgers if known, repo-set fields when code writes begin, primitive stop reason. | `apply`, `planning`, or `gate`/`blocked` |
| `apply` | Apply has started and production-code slices remain. | Continue `hello-spec-apply`; load only its current contract/references; run Risk Checklist before code writes. | Copy slice result and ledger evidence from the primitive. | Blocking decisions/risk/code drift/plan drift route through their current primitive/gate contracts; copy any primitive stop. | Completed slice summary, ledger counts, repo diff stat, human Dxxx IDs if any. | `apply`, `planning`, `review_fix`, or `gate`, only after primitive-confirmed evidence |
| `apply` | `hello-spec-apply` reports completion. | Verify repo baseline/diff stat; load `references/review-fix-loop.md`, then current `spec-code-review` and its report template. | A review run writes a template-consumable latest report. | Missing/unusable report state follows current `spec-code-review`; copy its stop/fallback result verbatim. | `Apply status=complete`, `Review round=1`, latest report path and copied template fields. | `review_fix` |
| `review_fix` | Current report template says coding-agent fix work remains and round count allows it. | Load `spec-code-review fix`; run Risk Checklist; let the primitive/template consume the report. | Copy fix result; then run review again. | Copy report/template mismatch, missing-machine-state fallback, risk, or scope stop verbatim. | Latest fixed IDs, fix dispatch, machine-state mode, per-repo diff stat, then next review round after review. | `review_fix` |
| `review_fix` | Latest review report is template-consumable. | Load current `spec-code-review` report template; copy its readiness and queue fields verbatim. | Template says no coding-agent repair remains; loop convergence checks pass. | Accepted/nonaccepted/human decision meanings come from the template; max-round exhaustion remains loop-owned. | Readiness, accepted IDs, human Dxxx IDs, dispatch mode, report path. | `human_code_review_ready`, `gate`, or `blocked` |
| `human_code_review_ready` | Review/fix convergence conditions are met. | No primitive; format final human review packet. | Final packet includes diff stat, report path, readiness, verification gaps, and review scope. | Commit/push/MR requests are out of scope and route to `spec-commit-push`. | `Phase=human_code_review_ready`, final pack fields, `Pending gate=final_human_cr_gate`. | stop |

## Stop Reasons

Use exact enum-like values after `Stopped at:`.

Primitive stop propagation is mechanical:

- If a primitive skill returns `Stopped at: <reason>`, the user-facing line MUST
  be exactly `Stopped at: <reason>`, even when `<reason>` is unknown to this
  table.
- Record the same verbatim value in `Last primitive stop reason`.
- Use `Loop route` / `Phase` to explain where the loop was when it stopped; do
  not replace the primitive reason with a loop synonym.
- Only use a loop-owned stop reason when no primitive returned a stop reason.

Primitive stop normalization fallback, only when no formal `Stopped at:` line is
present:

| Observed primitive output | Normalize to | Notes |
|---|---|---|
| `hello-spec-start` asks for a missing or unreadable high-density source before `changeDir` exists. | `source_gate_required` | Ask the source gate packet; do not create `loop.md`. |
| `hello-spec-start` / `hello-spec-next` cannot resolve a change name or context. | `missing_change_context` | Use only for explicit missing-context output. |
| `hello-spec-start` / `hello-spec-next` reports multiple candidate changes or ambiguous context. | `ambiguous_change_context` | List candidates when available; do not pick by recency. |
| Schema file/config cannot be found, loaded, or discovered. | `schema_unavailable` | Use for missing/unreadable schema, not wrong schema. |
| Discovered schema is not `hello-spec-v2` or conflicts with locked identity. | `schema_mismatch` | Preserve stronger primitive wording in context. |
| `hello-spec-next` / `grill-spec` asks for one pending `QID` answer. | `awaiting_grill_spec_answer` | Planning clarification stays in `design.md`; no Dxxx. |
| `hello-spec-next` / `grill-spec` asks for a batch of pending `QID` answers. | `awaiting_grill_spec_batch_answer` | Use when the neighbor contract already emits the batch form. |
| Current `hello-spec-apply` contract says plan-owned fields must be repaired before apply can continue. | Copy its stop reason verbatim | Route to `spec-plan-revise` / `hello-spec-next`; do not continue apply. |

Do not infer stop reasons from vague errors. If the output does not match one
row above and has no formal stop line, stop with the safest primitive-owned
blocking state available from its current contract, or `skill_package_incomplete`
when the required contract cannot be loaded.

Loop-owned stop reasons:

| Stop reason | Meaning |
|---|---|
| `source_gate_required` | Source gate fallback before a concrete changeDir or primitive formal stop exists. |
| `risk_gate` | The next apply/fix slice matches the loop Risk Checklist and lacks explicit approval. |
| `awaiting_decision_packet` | Waiting for a loop Dxxx decision packet answer. |
| `awaiting_risk_packet` | Waiting for a loop risk packet answer. |
| `planning_drift_repair_required` | User feedback requires `spec-plan-revise` routing and no primitive emitted a stronger stop. |
| `code_drift_repair_required` | User feedback requires `spec-trouble-resolve` routing and no primitive emitted a stronger stop. |
| `review_fix_loop_not_converged` | Loop-owned max review/fix rounds were exhausted. |
| `human_code_review_ready` | Final desired stop: low-cost human code review pack ready. |
| `skill_package_incomplete` | Required reference/template/neighbor skill is missing or unreadable. |
| `loop_ledger_tooling_rejected` | OpenSpec/wrapper tooling rejected `loop.md` as an unknown extra-schema file. |

Primitive-owned stop reasons:

- Do not maintain a copied enum list here.
- Load the current primitive/template, copy its `Stopped at:` value verbatim, and
  write loop context separately in `Phase`, `Loop route`, and `Last primitive`.

## Resume Resolution

When resuming:

1. Prefer explicit absolute change path or change name from the user.
2. Else use cwd inside a change dir.
3. Else use a single stable token in current context: `CHANGE_NAME=<name>` or
   `hello-spec-loop <name>`.
4. Else, if the locked repo has exactly one active `hello-spec-v2` change, use it.
5. If candidates conflict or more than one remains, stop with
   `ambiguous_change_context`.

Never use fuzzy match, mtime, newest directory, or sibling repo scans to choose.

## Cold-Resume Classifier

When resuming after `/clear`, reconstruct phase from canonical artifacts before
trusting `loop.md`. Use the first matching row with concrete evidence to choose
the next primitive only. The classifier is advisory and cannot by itself cross
`planning -> apply`, `apply -> review_fix`, or `review_fix -> human_code_review_ready`.

| Observed canonical state | Phase | Next primitive/action |
|---|---|---|
| No `loop.md`, but a concrete `changeDir` exists and planning artifacts are incomplete. | `planning` | `hello-spec-next` |
| `plan.md` and `tasks.md` look apply-ready, no unresolved `QID`, and no review report for current diff exists. | `apply` candidate | Invoke `hello-spec-apply`; only its current contract can confirm the transition. |
| `loop.md` says `review_fix`, but canonical `tasks.md` has unchecked apply tasks or `plan.md` lacks reconciliation evidence. | `apply` or `planning` candidate | Treat `loop.md` as stale; invoke `hello-spec-apply` or repair through `spec-plan-revise` only when the primitive/report confirms that route. |
| Plan artifacts explicitly record a revise-required state. | `planning` candidate | Invoke `spec-plan-revise`, then `hello-spec-next` as needed. |
| Apply appears complete, but repo baseline or diff stat is missing before review. | `apply` candidate | Refresh repo-set evidence; enter review only after apply completion evidence and diff baseline are recorded. |
| Latest `spec_code_review.md` is older than the current git diff or points at a different baseline. | `review_fix` | Run a fresh `spec-code-review review`; do not fix stale accepted rows. |
| Latest report has template-consumable coding-agent fix work and round count is below limit. | `review_fix` | `spec-code-review fix`, then `spec-code-review review`. |
| Latest report template says no coding-agent repair remains and readiness is final-acceptable. | `human_code_review_ready` candidate | Confirm through `references/review-fix-loop.md`, then emit final human CR packet. |

Mixed states favor canonical artifacts over `loop.md`. Repair `loop.md` from the
chosen row only after recording why the older state was stale.
