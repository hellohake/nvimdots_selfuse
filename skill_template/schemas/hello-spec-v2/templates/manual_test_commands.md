# Manual Test Commands

> 本文件记录本提案中由 AI 生成/修改测试文件后，留给用户手动复制执行的 targeted test command。
> Agent 默认不自动执行重型测试；即使因仓库规则跳过执行，也必须把可复制命令写在这里。

## 使用规则

- 每当任意阶段新增/修改测试文件，都追加或更新一条命令记录。
- 命令必须包含 `cd <绝对仓库路径>`，避免在错误目录执行。
- 命令优先最小范围，不写 `go test ./...`、全量 `npm test` 这类大范围命令，除非仓库明确要求。
- 如果不能可靠推导命令，必须写明原因，不能编造。
- `Status` 表示 agent 是否执行过该命令：
  - `not_run_by_skill`：仓库规则或成本原因，未由 agent 执行，留给用户手动跑。
  - `manual_only`：设计上只允许用户手动执行。
  - `run_passed`：agent 已执行且通过。
  - `run_failed`：agent 已执行但失败，需附失败摘要。
  - `skipped_by_repo_rule`：仓库规则禁止 agent 执行。

## Commands

<!-- COMMANDS:START -->

暂无。新增/修改测试文件时在此追加记录。

<!-- COMMANDS:END -->

## 记录模板

```markdown
### C001 · <测试意图>

- Stage: `<apply | spec-trouble-resolve | spec-code-review-fix | fix-mr-comments | other>`
- Related findings/tasks: `<R001/R003/T012/none>`
- Repo: `<absolute repo path>`
- Test files:
  - `<absolute test file path>`
- Covers:
  - `<这条命令覆盖的业务/代码行为>`
- Status: `not_run_by_skill`
- Reason: `<为什么需要用户手动执行，或为什么 agent 未执行>`

```bash
cd <absolute repo path>
<copyable targeted test command>
```
```
