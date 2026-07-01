# Manual Test Commands

<!--
本文件是提案级手动测试命令收件箱。

提案创建期保持为空；只有当 apply / review / fix 阶段新增或修改测试文件时，
才在 COMMANDS 区追加可复制的 targeted test command。

追加规则：
- 命令必须包含 `cd <绝对仓库路径>`。
- 命令必须 targeted；不要写 `go test ./...` / full build / full test，除非仓库明确允许。
- 如果 agent 没跑命令，写明 `Status=not_run_by_skill` / `manual_only` / `skipped_by_repo_rule`。
- 如果命令无法可靠推导，写原因，不要编造。

建议格式：
### C001 · <测试意图>

- Stage: <apply | spec-trouble-resolve | spec-code-review-fix | fix-mr-comments | other>
- Related: <task/finding id or none>
- Repo: <absolute repo path>
- Test files: <absolute paths or none>
- Covers: <业务/代码行为>
- Status: <not_run_by_skill | manual_only | skipped_by_repo_rule | run_passed | run_failed>
- Reason: <为什么需要用户手动执行，或执行结果摘要>

```bash
cd <absolute repo path>
<copyable targeted test command>
```
-->

## Commands

<!-- COMMANDS:START -->

暂无。新增/修改测试文件时在此追加记录。

<!-- COMMANDS:END -->
