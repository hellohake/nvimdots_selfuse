# Grill Spec Gate

<!--
本文件是 GATE-1 的完成标记，不承载完整设计正文。

执行要求：
- 通过 grill-with-docs 进入 grilling + domain-modeling。
- 真实澄清结论必须回写 design.md。
- 术语必须写入 .ai_doc/spec-workflow/CONTEXT.md。
- ADR 必须写入 .ai_doc/spec-workflow/adr/。
- 阻塞 Open Questions 未解决前，不要创建本文件。

完成判定：
- 每个问题必须写 `Status=<user_confirmed|resolved_by_evidence|pending_user_confirmation>`。
- 每个问题必须写 `Evidence=<path:line or exact user answer>`。
- 只有所有阻塞问题都是 `user_confirmed` 或 `resolved_by_evidence` 且 Evidence 非空时，Status 才能写 `complete`。
- 任何阻塞问题为 `pending_user_confirmation` 或缺 Evidence 时，Status 保持 `pending`，不得继续生成 tasks/plan。

建议格式：
### Q001 · <问题标题>

- Status: <user_confirmed | resolved_by_evidence | pending_user_confirmation>
- Evidence: <path:line or exact user answer>
- Recommendation: <AI 推荐答案，pending 时必须写>
- Resolution: <最终结论；pending 时写“等待用户确认”>
- Written back: <design.md/spec path/CONTEXT term/ADR or none>
-->

## Status

pending

## Resolved Questions

<!-- QUESTIONS:START -->

暂无。

<!-- QUESTIONS:END -->

## Touched Domain Model

- CONTEXT terms: none
- ADRs: none

## Next

After all blocking questions are resolved, update design.md, clear Open Questions, then continue to tasks.
