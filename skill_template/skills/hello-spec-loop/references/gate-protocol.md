# hello-spec-loop Gate Protocol

This reference owns human interaction. A gate is not a request for the user to
open files. A gate is a compact decision packet in chat. After the user replies,
persist the decision and continue the loop automatically.

## Gate Classes

| Gate | Required when | Not required when |
|---|---|---|
| `source_gate` | Input is high-density, missing a readable source, or the source is unreadable. | Short inline prompt with no hard-to-recover constraints. |
| `decision_gate` | Apply/review/debug stage exposes a concrete `Dxxx` choice that changes behavior, contract, data, or cross-repo boundary and AI cannot safely choose. | Planning clarification is still in `hello-spec-next` / `grill-spec` and uses `QID`; the decision is already in proposal/spec/design/grill evidence or can be resolved from code/docs. |
| `risk_gate` | The next step semantically mutates IDL, DB/data contracts, public API, data migration/backfill, online write behavior, permission/security, unknown write scope, or unapproved broad cross-repo blast radius. | The next step is local, reversible, already covered by plan/spec, or only read-only references existing contracts/constants. |
| `final_human_cr_gate` | Review/fix loop converged and human should review final diff. | Earlier planning checkpoints; these are soft checkpoints unless risk appears. |

There is no fixed plan-review gate. Plan readiness is validated by the loop and
neighbor skills. Escalate to `risk_gate` only when the plan contains a high-risk
decision or missing authorization.

## Risk Checklist

Run this checklist before every apply slice and every review-fix slice. Compare
the intended write set, current diff paths, worker scope, and plan/task evidence.

Require `risk_gate` when any item matches and there is no explicit approval in
`plan.md`, `human-decisions.md`, or a prior recorded risk approval:

- Allowed Write Scope: slice would write outside its declared files, repo, or
  module boundary, or the write set is unknown.
- Intended Write Set: diff paths are unexpectedly broad or include files not
  named by the approved slice/review row.
- IDL/contract schema mutation: edits to `.thrift`, `.proto`, generated IDL,
  OpenAPI schema, migration, compatibility contract files, or generated outputs
  that change those contracts.
- Public API/contract mutation: changes to exported interfaces,
  route/endpoint contracts, SDK surface, request/response structs, event
  schemas, or config contracts used by other teams/repos.
- DB/data mutation: DDL, migrations, ORM model shape changes, table/field
  contract changes, cache key format changes, data backfills, or read-write
  semantic changes.
- Permission/security/auth mutation: authn/authz, ACL, token, encryption,
  privacy, compliance, or permission-check behavior changes.
- Online write/provider ops: scripts or provider calls that could mutate online
  services, configs, queues, storage, jobs, tickets, or releases.
- Broad cross-repo scope: more than one production repo changes, repo baselines
  are missing, or the slice crosses FE/Admin/BE/IDL boundaries without an
  approved scoped repo set.

Do NOT gate merely because the slice reads or mentions table names, SQL, cache
keys, existing structs, IDL paths, or config constants. Read-only references are
not risk by themselves when the approved write scope does not mutate those
contracts or their runtime semantics.

If the match is already explicitly approved, record the evidence in `loop.md`
and continue. If approval is ambiguous, use `risk_gate`; do not downgrade it to
a soft checkpoint.

## Planning Clarification Boundary

Do not use this file's `Dxxx` packet for planning clarification.

- If the ready artifact is `grill-spec`, invoke `hello-spec-next` gate mode.
- Use `QID` answers such as `Q001=A`; numeric aliases require the current
  `design.md` Asked batch map.
- Persist pending planning answers and `Asked batch` state to `design.md` and
  `.ai_doc/spec-workflow`; keep `grill-spec.md` absent until complete.
- Create `grill-spec.md` only as the complete marker required by
  `hello-spec-next`.
- Do not create `human-decisions.md` before apply/review unless the current
  primitive explicitly requires a concrete execution-stage decision entry.

## Packet Rules

Every gate packet must fit in chat and include:

- Gate name and reason.
- Default recommendation.
- Impact scope.
- Options with short stable IDs.
- Exact reply forms.
- Paths for optional evidence only.

Do not say "please review these files" as the primary ask.

## Source Gate Packet

```text
[Gate: source_gate]
原因：输入包含高密度约束，但没有可重读来源；继续会降低 /clear 后的可恢复性。

默认建议：A，补一个可读链接或本地路径后继续。
恢复信息：
- CHANGE_NAME: <inferred-or-provided name>
- Repo root: <absolute repo root>
- Source classification: <high_density_without_source|source_unreadable|source_missing>
- Change dir exists: <no|yes: absolute changeDir>

选项：
A. 补充可读路径/链接（推荐）
B. 降级继续，记录 NO_SOURCE_CONFIRMED=true

回复方式：
- `A: <path-or-url>`
- `B: NO_SOURCE_CONFIRMED=true`
- `/clear 后带来源恢复：hello-spec-loop CHANGE_NAME=<name> SOURCE=<path-or-url> REPO=<absolute repo root>`
- `/clear 后降级恢复：hello-spec-loop CHANGE_NAME=<name> NO_SOURCE_CONFIRMED=true REPO=<absolute repo root>`
- 若 Change dir exists=yes：`hello-spec-loop <absolute changeDir>`
- `暂停`
```

When `changeDir` does not exist, this packet is the only durable resume contract.
Do not create a floating `loop.md`; include the fields above verbatim enough that
another agent can resume after `/clear` without guessing the name, repo, source
state, or degraded answer. If `CHANGE_NAME` cannot be inferred, stop with the
primitive's name/context stop instead of presenting a source gate.

On `B`, write `NO_SOURCE_CONFIRMED=true` to `brainstorm.md` Input Sources when
that artifact is created/updated, and record the approval in `loop.md` only
after a concrete `changeDir` exists.

## Decision Gate Packet

```text
[Gate: decision_gate]
原因：<why AI cannot safely decide>
默认建议：A，<short reason>
影响范围：<artifacts/files/modules>
证据：<optional path:line list>

D001 <decision title>
A. <recommended option and tradeoff>
B. <alternative and tradeoff>
C. 自定义：<free text>

回复方式：
- `A` 或 `继续`：按默认建议继续 loop
- `D001=B`
- `D001=自定义：...`
- `改：<统一反馈>`：规划偏差写入/消费 revise.md；执行/审查 Dxxx
  写入 human-decisions.md
- `暂停`
```

If several independent decisions exist, ask up to 5 in one packet. Prefer the
fewest questions that unblock the loop. Accept one consolidated answer such as:

```text
D001=A; D002=自定义：只在 C 端生效; D003=B
```

Persistence:

- Execution/review risk after code exists: create/update `human-decisions.md`.
- If the user's reply reveals planning/design ambiguity, do not store it as
  `Dxxx`; route it to `spec-plan-revise` or `hello-spec-next` `QID` handling.
- Update `loop.md` `Decisions answered`.
- Continue automatically.

## Risk Gate Packet

```text
[Gate: risk_gate]
原因：下一步涉及 <IDL/DB/public API/data/online write/security/cross-repo>。
默认建议：<approve|revise|defer>，<short reason>
影响范围：<blast radius>
证据：<optional paths>

RISK001 <risk title>
A. 批准继续（推荐/不推荐：<reason>）
B. 改方案：<short alternative>
C. 暂缓，先停在当前状态

回复方式：
- `RISK001=A`
- `RISK001=B: <补充方案>`
- `RISK001=C`
- `暂停`
```

If approved, record it in `loop.md` and the relevant artifact audit. If revised,
route to `spec-plan-revise` or `spec-trouble-resolve` based on whether code has
already been written and what must change.

## Final Human CR Packet

Final CR is a stop, not an auto-continue gate.

```text
[Gate: final_human_cr_gate]
Stopped at: human_code_review_ready

CR Readiness: <verbatim template value>
最新报告：<abs path>/spec_code_review.md
人工重点看：
1. <file/finding/risk>
2. <file/finding/risk>
验证命令：<manual_test_commands path or key commands>
剩余决策：<none|Dxxx list>

不自动 commit/push。通过后请运行 spec-commit-push。
```

## Reply Parsing

Recognize:

- `继续`, `A`, `默认`, `approve`: choose default option for all pending decisions.
- `D001=B`, `RISK001=A`: choose exact option.
- `Q001=A` or `1=A`: not a loop decision. Route to `hello-spec-next`
  `grill-spec` answer handling; numeric answers are valid only with a current
  `design.md` Asked batch map.
- `自定义：...` or `D001=自定义：...`: write the custom decision.
- `改：...`: classify as planning or code drift, then route to the matching
  repair skill.
- `暂停`: update `loop.md` and stop.

If the answer is ambiguous, ask one clarification packet. Do not continue by
guessing.

## UX Rules

- Keep interruption count low. Combine independent decisions into one packet.
- Do not gate on every artifact. Artifact generation is automatic unless a real
  decision/risk appears.
- Do not require long exact confirmation sentences.
- Do not ask users to copy prompts between skills; the loop invokes neighbor
  skills directly.
