# Human Decisions

> 本文件是本提案在 apply / review / debug / MR 阶段的懒创建人工决策队列。AI 先给推荐方案和取舍，人只负责批准、拒绝或延后；不要把执行期关键决策只留在聊天里。

## 使用规则

- 只有执行期/审查期的 AI 无法安全自行决定，或继续执行会改变需求/契约/风险边界时，才新增条目。
- 规划期需求不清、术语不清、领域边界不清，优先走 `grill-spec` / `spec-plan-revise`，不要用本文件替代澄清门。
- 每条决策必须有稳定 ID：`D001`、`D002`。
- AI 必须先给推荐方案，不能只把开放问题丢给用户。
- `pending_human` 且 blocking 的条目会阻塞 apply complete / commit-push。
- 决策 resolved 后，必须回写到 canonical artifact：`design.md`、`specs/**/*.md`、`tasks.md` 或 `plan.md`。

## Decisions

<!-- DECISIONS:START -->

暂无。

<!-- DECISIONS:END -->

## 记录模板

```markdown
### D001 · <一句话决策标题>

- Status: `pending_human`
- Blocking: `yes`
- Raised by: `<stage / report / finding ID>`
- Blocks:
  - `<artifact/task/file>`
- Context:
  - `<为什么现在必须决策，引用 path:line 或 finding ID>`
- AI recommendation:
  - `<推荐选项及理由>`
- Options:
  - `A` 推荐：<做法>；Trade-off: <代价/风险>
  - `B`：<做法>；Trade-off: <代价/风险>
- Human decision:
  - `<approved A / approved B / rejected / deferred until ...>`
- Follow-up writes:
  - `<需要回写的 design/spec/tasks/plan 路径>`

## Agent Execution Audit
- Context discipline: PASS
- Key files read: <path:line summary bullets, or none>
- Large content inlined: no
- Output written to disk: yes
- Human decision queue: D001
- Next command: `<copyable command or none>`
- Suggested /clear resume: `<copyable command or none>`
```
