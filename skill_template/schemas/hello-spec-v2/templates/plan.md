# [功能名称] 实施计划（Implementation Plan）

> **给执行 agent：** 用 superpowers:subagent-driven-development 按任务逐个实施本计划，每个任务用全新 subagent。
> **红线：** 禁止执行 `go build` / `go test`（项目过大，会卡顿并耗尽内存）；落地正确性用 gopls `go_diagnostics` 校验。
> **红线：** 禁止生成/执行 `git add` / `git commit` 自动提交步骤——代码改动须人工 review 后由用户手动提交；每个任务末尾只标“review point（人工看 diff）”，不自动 commit。
> **上下文纪律：** 每个任务完成即落盘并更新 `plan.md` 执行勾选框与 `tasks.md` 粗粒度勾选框，subagent 写盘不回传，可断点续作。
> **进度账本：** 每个 checkbox 必须保留 `StepID=<change>-T<task>-S<step>` 与 `TaskRef=<tasks.md编号>`；暂停、总结或宣称完成前必须让 `plan.md` / `tasks.md` 进度一致。

**目标（Goal）：** <!-- 一句话 -->

**架构（Architecture）：** <!-- 2-3 句 -->

**技术栈（Tech Stack）：** <!-- 关键技术/依赖 -->

---

## 任务 1：<!-- 组件/模块名称 -->

- [ ] StepID=<change>-T1-S1 TaskRef=1.1 **步骤 1：** <!-- 2-5 分钟可完成的微步骤，含文件路径 -->
- [ ] StepID=<change>-T1-S2 TaskRef=1.1 **步骤 2：** <!-- 微步骤 -->
<!-- 任务末尾可标 “← review point：人工看 diff”，但不要写 git commit -->

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
- Progress ledger: plan=0/0, tasks=0/0, status=not_started
- Next command: `none`
- Suggested /clear resume: `none`
