# [功能名称] 实施计划（Implementation Plan）

> **给执行 agent：** 用 `hello-spec-apply` 实施本计划。`hello-spec-v2` 的 apply 请求视为授权使用 subagent；除非用户显式给出 `SERIAL_APPLY=true`，禁止主 agent 悄悄串行实现生产代码。
> **红线：** 禁止执行 full `go build` / full-suite `go test ./...`（项目过大，会卡顿并耗尽内存）；targeted test 按 `tasks.md` / 本计划的测试能力分类执行，落地正确性至少用 gopls `go_diagnostics` / `gopls check` 校验。
> **红线：** 禁止生成/执行 `git add` / `git commit` 自动提交步骤——代码改动须人工 review 后由用户手动提交；每个任务末尾只标“review point（人工看 diff）”，不自动 commit。
> **上下文纪律：** 每个任务完成即落盘并更新 `plan.md` 执行勾选框与 `tasks.md` 粗粒度勾选框，subagent 写盘不回传，可断点续作。
> **进度账本：** 每个 checkbox 必须保留 `StepID=<change>-T<task>-S<step>` 与 `TaskRef=<tasks.md编号>`；暂停、总结或宣称完成前必须让 `plan.md` / `tasks.md` 进度一致。
> **原子步骤门禁：** 每个 checkbox 必须是原子执行步骤：一次聚焦代码改动、一次聚焦文档改动或一次明确验证。代码步骤必须包含目标文件、函数/方法/类型、具体改动和验证方式。review point 只能是普通文本，不能是 checkbox，不能占用 `StepID` / `TaskRef`。若步骤需要同时改多处无关文件、设计新接口或做新的产品/架构决策，必须拆分或写 `needs_plan_refinement`，不要把 plan 标为完成。
> **subagent 审计：** 编码前必须在 `Agent Execution Audit` 记录 `Subagent mode`、`Spawned agents`、`Manual fallback`、`Fallback reason`。subagent 不可用且未获 `SERIAL_APPLY=true` 时，停在 `subagent_mode_unavailable`。

**目标（Goal）：** <!-- 一句话 -->

**架构（Architecture）：** <!-- 2-3 句 -->

**技术栈（Tech Stack）：** <!-- 关键技术/依赖 -->

---

## 任务 1：<!-- 组件/模块名称 -->

- [ ] StepID=<change>-T1-S1 TaskRef=1.1 **步骤 1：** <!-- 原子执行步骤；写清目标文件、函数/方法/类型、具体改动、验证方式 -->
- [ ] StepID=<change>-T1-S2 TaskRef=1.1 **步骤 2：** <!-- 原子验证步骤；写 targeted command 或 manual/disabled 原因 -->
← review point：<!-- 人工看 diff 的检查点；普通文本，不写 checkbox，不写 StepID/TaskRef，不写 git commit -->

## Subagent Dispatch Matrix

生成 plan 后必须给 apply 阶段留下 dispatch 矩阵；apply 阶段只校验和消费这张矩阵，不能现场发明。若当前上下文无法填出非空矩阵，写 `needs_plan_refinement` 和缺失问题，不要宣称 plan 可执行。

| SliceID | TaskRefs | StepIDs | Worktree | Allowed Write Scope | Required Reads | Gotcha IDs | Test Policy | Reviewers | Stop Conditions |
|---|---|---|---|---|---|---|---|---|---|
| slice-1 | <!-- 1.1 --> | <!-- <change>-T1-S1 --> | <!-- /abs/path --> | <!-- files/dirs --> | <!-- plan/spec/design sections --> | <!-- none/Gxxx --> | <!-- unit_test_required/manual_test_only/unit_test_disabled --> | spec,quality | <!-- human_decision/dependency_missing/etc. --> |

## Plan Quality Gate

生成 plan 后必须自检：

- 所有 checkbox 都有 `StepID` 和 `TaskRef`。
- 所有 checkbox 都是原子执行步骤，不是粗粒度任务。
- 所有代码步骤都写清目标文件、函数/方法/类型、具体改动、验证方式。
- 所有验证步骤都有 targeted command，或明确 `manual_only` / `skipped_by_repo_rule` / `not_run_by_skill` 原因。
- review point 不是 checkbox，且没有 `StepID` / `TaskRef`。
- `Subagent Dispatch Matrix` 非空；每个生产代码 slice 都有明确 `Allowed Write Scope` 和 `Stop Conditions`。
- `Subagent Dispatch Matrix` 由 plan 阶段生成；apply 阶段只 validate/consume，缺失或过期必须停回 plan refine。
- 如果任一项做不到，写 `needs_plan_refinement` 和缺失上下文/问题清单，不要宣称 plan 可执行。

## Progress Reconcile Gate

暂停、交接、最终答复或宣称完成前必须执行：

- `plan.md` 中已完成的 checkbox 保留 `StepID` / `TaskRef`。
- 每个已完成 `TaskRef` 对应的 `tasks.md` checkbox 已同步勾选。
- 若 `tasks.md` 已勾选但 `plan.md` 对应步骤未勾选，继续修复账本，不能只写报告后结束。
- 未完成、部分完成、被阻塞的步骤保持未勾选，并在对应任务下写 `blocked:` 或 `partial:` 一行说明。
- 在下面的 Agent Execution Audit 里更新 `Progress ledger`。

## Agent Execution Audit

- Context discipline: PASS
- Key files read: none
- Large content inlined: no
- Output written to disk: yes
- Human decision queue: none
- Subagent mode: not_started
- Spawned agents: 0
- Manual fallback: no
- Fallback reason: none
- Progress ledger: plan=0/0, tasks=0/0, status=not_started
- Next command: `none`
- Suggested /clear resume: `none`
