# Human Decisions

<!--
本文件是提案在 apply / review / debug / MR 阶段的懒创建人工决策收件箱。

提案创建期不生成本文件；只有执行期/审查期出现 AI 不能安全自行决定、
继续执行会改变需求/契约/风险边界的事项时，才创建并在 DECISIONS 区追加条目。

边界：
- 规划期需求不清、术语不清、领域边界不清，走 `grill-spec` / `spec-plan-revise`。
- 本文件只记录执行期/审查期的风险取舍；不要替代澄清门。
- AI 必须先给推荐方案和理由，不能只把开放问题丢给用户。
- `pending_human` 且 blocking 的条目会阻塞 apply complete / commit-push。
- resolved 后必须回写 canonical artifact：design.md / specs/**/*.md / tasks.md / plan.md。

建议格式：
### D001 · <一句话决策标题>

- Status: <pending_human | approved | rejected | deferred>
- Blocking: <yes | no>
- Raised by: <stage / report / finding ID>
- Blocks: <artifact/task/file>
- Context: <为什么现在必须决策，引用 path:line 或 finding ID>
- AI recommendation: <推荐选项及理由>
- Options:
  - A 推荐：<做法>；Trade-off: <代价/风险>
  - B：<做法>；Trade-off: <代价/风险>
- Human decision: <approved A / approved B / rejected / deferred until ...>
- Follow-up writes: <需要回写的 design/spec/tasks/plan 路径>
-->

## Decisions

<!-- DECISIONS:START -->

暂无。

<!-- DECISIONS:END -->
