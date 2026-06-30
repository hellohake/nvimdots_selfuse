# Grill Spec Gate

<!--
本文件是 GATE-1 的完成标记，不承载完整设计正文。

关键机制：OpenSpec 仅凭“文件是否存在”判定 artifact 为 done（不解析 ## Status）。
因此本文件一旦创建即视为 GATE-1 完成、解锁 tasks/plan。

执行要求：
- 通过 grill-with-docs 进入 grilling + domain-modeling。
- 阻塞 Open Questions 全部解决前，绝对不要创建本文件；澄清过程中的所有状态
  （含 pending_user_confirmation）只写在 design.md 的 Open Questions / Decisions。
- 真实澄清结论必须回写 design.md。
- 术语必须写入 .ai_doc/spec-workflow/CONTEXT.md。
- ADR 必须写入 .ai_doc/spec-workflow/adr/。

完成判定（创建本文件的前置条件）：
- 每个阻塞问题都已是 `user_confirmed` 或 `resolved_by_evidence`，且 Evidence 非空。
- 仍有 `pending_user_confirmation` 或缺 Evidence 时，保持本文件不存在，继续在
  design.md 中澄清，不得生成 tasks/plan。
- 本文件只在“已全部解决”时创建，因此其 Status 恒为 `complete`。

建议格式（仅记录已解决项；pending 项不在此文件出现）：
### Q001 · <问题标题>

- Status: <user_confirmed | resolved_by_evidence>
- Evidence: <path:line or exact user answer>
- Resolution: <最终结论>
- Written back: <design.md/spec path/CONTEXT term/ADR or none>
-->

## Status

complete

## Resolved Questions

<!-- QUESTIONS:START -->

暂无。

<!-- QUESTIONS:END -->

## Touched Domain Model

- CONTEXT terms: none
- ADRs: none

## Next

design.md 已回写、Open Questions 已清空，可继续 tasks。
