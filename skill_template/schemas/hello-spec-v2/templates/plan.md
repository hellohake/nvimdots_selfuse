# [功能名称] 实施计划（Implementation Plan）

> **给执行 agent：** 用 superpowers:subagent-driven-development 按任务逐个实施本计划，每个任务用全新 subagent。
> **红线：** 禁止执行 `go build` / `go test`（项目过大，会卡顿并耗尽内存）；落地正确性用 gopls `go_diagnostics` 校验。
> **红线：** 禁止生成/执行 `git add` / `git commit` 自动提交步骤——代码改动须人工 review 后由用户手动提交；每个任务末尾只标“review point（人工看 diff）”，不自动 commit。
> **上下文纪律：** 每个任务完成即落盘并更新勾选框，subagent 写盘不回传，可断点续作。

**目标（Goal）：** <!-- 一句话 -->

**架构（Architecture）：** <!-- 2-3 句 -->

**技术栈（Tech Stack）：** <!-- 关键技术/依赖 -->

---

## 任务 1：<!-- 组件/模块名称 -->

- [ ] **步骤 1：** <!-- 2-5 分钟可完成的微步骤，含文件路径 -->
- [ ] **步骤 2：** <!-- 微步骤 -->
<!-- 任务末尾可标 “← review point：人工看 diff”，但不要写 git commit -->

## Agent Execution Audit

- Context discipline: PASS
- Key files read: none
- Large content inlined: no
- Output written to disk: yes
- Human decision queue: none
- Next command: `none`
- Suggested /clear resume: `none`
