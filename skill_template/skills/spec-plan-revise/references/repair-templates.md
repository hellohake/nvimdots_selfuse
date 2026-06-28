# Repair Templates

Load this reference only in these cases:
- Before launching a delegated worker.
- Before appending a `[规划偏差]` entry to `backup.md`.

Do not load this file for simple inline patch-only repairs unless you are about to archive.

## Worker Contract

Every delegated worker input must include:

- Current `Revision Packet`.
- Authorized write set: exact files/directories the worker may edit.
- Target artifact OpenSpec/schema instruction and template.
- Upstream updated summary.
- Forbidden objectives: do not touch code, `backup.md`, or `revise.md`; do not commit; do not expand scope.

Every delegated worker result must use this shape:

```markdown
## Worker Result
- Artifact: <artifact-id>
- Files changed:
  - <abs path>
- Mode used: <patch | regenerate-section | regenerate-artifact>
- Revision Packet fields addressed:
  - Deviation: <resolved | partial | not addressed>
  - Expected change: <implemented | partial | not implemented>
  - Constraints: <respected | violated + why>
- Downstream impact:
  - <artifact>: <none | needs update because ...>
- Risk / open question:
  - <none | ...>
```

## Archive Template

Append this template to `backup.md` without modifying existing bytes:

```markdown
## [规划偏差] 修正记录-{YYYY-MM-DD HH:mm}(北京时间)
### 原始偏差描述
> (原样保留 revise.md / $ARGUMENTS 的描述)

### 偏差定性
> 源头层：brainstorm/proposal/specs/design/tasks/plan 中哪层；性质：A 认知不清 / B 已明确

### 修正与同步
> - 改动文档：逐项列 <文件> 改了什么（why > what）
> - 同步下游：列沿依赖链重核/重生成的文档（如 design 改 -> tasks/plan 重生成）
> - （若澄清）新增/更新 CONTEXT 术语 + ADR 编号（含 superseded）

### 一致性自检
> - [ ] brainstorm（如涉及）-> proposal -> specs -> design -> tasks -> plan 对齐
> - [ ] 仅改文档、未碰代码
> - [ ] 未引入无关修改
```

## Archive Safety Check

- If `backup.md` already ends with the same timestamp and same handled `revise.md` IDs, do not append a duplicate.
- If append fails, stop and report the failure. Do not rewrite the whole file as recovery.
- If the host requires patch-based edits, append at end-of-file with a minimal patch and no changes to existing lines.
- Safe append priority: host append tool > `apply_patch` at end-of-file > shell append only when the host allows it.

## Revise Cleanup Rules

- Only update stable entries matched in this run.
- Structured entry: change `Status: pending` to `Status: archived`, then add `Archived in: backup.md <timestamp>`.
- Free text or entries without stable IDs: do not delete or rewrite; mention in the final receipt that the text was handled but left intact.
- Unmatched `pending` entries must remain unchanged.
- If `$ARGUMENTS` handled a temporary deviation and no `revise.md` existed, do not create one unless the user asks.

## Final Receipt Template

Use this shape for the final user-facing response. Do not paste full document bodies.

```markdown
完成 spec-plan-revise。

- 偏差定性：源头层 `<brainstorm|proposal|specs|design|tasks|plan>`；性质 `<A 认知不清|B 已明确>`；路径 `<Fast Path|Short Full Path|Full Path|Clarify Path>`。
- 修改文档：`<path>` - <改了什么，why > what>。
- 同步下游：`<none|artifact -> 对应位置>`。
- 自检结果：未碰代码；未改未授权文档；`Revision Packet` 已覆盖 Deviation / Expected change / Constraints；`backup.md` 已 append-only 归档。
- 留痕：`revise.md` <未创建|未清理自由文本|R001 archived>；`backup.md` <timestamp>。
- 后续：<none|如果发现已影响代码，转 spec-trouble-resolve>。
```
