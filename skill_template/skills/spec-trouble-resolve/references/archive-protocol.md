# Archive Protocol

Use this protocol before modifying `backup.md` or `troubleshoot.md` in `spec-trouble-resolve`.

Do not load this file when there is no `troubleshoot.md` and no `CHANGE_DIR`; in that case, do not create any archive file and report `未归档：缺少提案目录`.

## Archive Anchor

- `backup.md` is always under `CHANGE_DIR`.
- Never create a floating `backup.md` in the cwd, repo root, or temp directory.
- In multi-repo changes, code inspection and diagnostics happen per repo, but archive remains anchored to the single proposal `CHANGE_DIR`. If multiple proposal dirs are plausible, stop and ask the user to choose one.

## Append-Only Rule

Append this turn's archive block to the end of `backup.md`.

- If `backup.md` does not exist, create it first, then append.
- Do not rewrite, normalize, sort, clean, merge, or reformat existing `backup.md` content.
- Do not read the entire old `backup.md` during archive just to rebuild it. Earlier diagnostic reads of relevant history are allowed.
- Prefer the current platform's safe append capability. Under TRAE CLI manual edits, use `apply_patch` only to insert new lines at EOF.
- If using a patch, the hunk must append after the current final line only. It must not modify, delete, or reflow any existing line.
- If you cannot safely append without touching existing bytes, stop and report the blocker.

## Source Entry Handling

Move only entries handled in this turn from `troubleshoot.md` into `backup.md`.

Preserve:

- unhandled entries
- entries waiting for user clarification
- original separators and formatting around remaining entries

For entries waiting on Type C/E/user clarification, append:

```markdown
> 状态：待澄清 YYYY-MM-DD
```

## Entry Split Protocol

Before deleting anything from `troubleshoot.md`, mechanically identify entry boundaries:

1. Prefer `## 问题` / `### 问题` headings. Each heading through the next same-or-higher-level problem heading is one entry.
2. If no problem headings exist, split on top-level numbered list markers. Treat these as entry starts even when spacing is casual:
   - `1. xxx`
   - `1.xxx`
   - `1、xxx`
   - `1) xxx`
   A numbered entry runs until the next top-level numbered marker, problem heading, or `---` separator. Indented lines, quote blocks, sub-lists, and plain continuation lines belong to the previous numbered entry.
3. If neither headings nor numbered entries exist, split on an independent line of three or more hyphens: `---`.
4. Do not split on semicolons (`;` / `；`) or ordinary punctuation. They are sentence endings, not entry boundaries.
5. If none of the rules above uniquely identifies the handled entry, do not delete source content. Append a full copy of the relevant source text to `backup.md`, then add this status line in `troubleshoot.md`:

```markdown
> 状态：已处理但未自动删除 YYYY-MM-DD，原因：无法唯一切分条目
```

Before deletion, state the title or first-line summary that will be moved. If that summary maps to more than one entry, do not delete.

## Empty Troubleshoot

If all entries were handled and no content remains, keep `troubleshoot.md` and reset it to:

```markdown
# Troubleshoot

<!-- 在此追加新的问题条目，处理完成后会自动归档到 backup.md -->
```

## No Troubleshoot File

- If `CHANGE_DIR` is known: do not create `troubleshoot.md`; append the user's current `$ARGUMENTS` to `<CHANGE_DIR>/backup.md` under `### 用户原始输入`, and mention that future runs can use `troubleshoot.md` for better traceability.
- If `CHANGE_DIR` is unknown: do not archive and do not create `backup.md`.

## Archive Block Format

Append exactly this shape:

```markdown
## [代码偏差] 用户问题-{YYYY-MM-DD HH:mm}(**采用当前北京时间**)
### 用户原始输入
> (严格原样保留原始描述)

### 诊断结论
> 类型 A/B/C/D/E 中的哪一种，一句话讲明为什么

### 解决方案与说明
> - 改动代码：<file:line> 的 <函数> —— 做了什么（why > what）
> - 改动文档（仅类型 A）：逐项列出 spec.md / design.md / plan.md / proposal.md 的具体修改点
> - 类型 C/E：附澄清内容与用户确认过的结论

### 一致性自检
> - [ ] 代码 ↔ spec/design/plan/proposal 对齐
> - [ ] 未覆盖用户未提交改动
> - [ ] 未引入无关修改
> - [ ] (Go 改动)`go_diagnostics` 已通过,无遗留 error
> - [ ] 缺失 spec 族文档已记录，且未影响本次定性；若影响，已停手澄清
```
