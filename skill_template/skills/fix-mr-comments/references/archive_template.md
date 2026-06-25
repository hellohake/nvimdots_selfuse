# 归档模板（mr-comment-resolution.md）

本文件由 `fix-mr-comments` 技能在 OpenSpec-style SDD 提案上下文中使用。SKILL.md 阶段 7 触发时**先 Read 一次本文件**，再按下述结构写入提案目录下的 `mr-comment-resolution.md`。

## 触发条件回顾

仅当本次会话工作在以下任一上下文时执行归档：

- `openspec/changes/<name>/`（active 提案）
- `openspec/changes/archive/<name>/`（已归档但本次又改了，照常写入）
- 用户在前序消息里点名的提案目录

> 多候选无法确定时**让用户挑**，不要自动写到所有目录里造成噪音。

## 固定路径

每个命中的提案根目录下：`<proposal_dir>/mr-comment-resolution.md`。文件名固定，不要带时间戳；时间戳放章节标题里，便于幂等追加与团队检索。

## 首次创建骨架

```markdown
# MR 评论处置记录

> 本文档由 `fix-mr-comments` 技能自动生成与维护，用于记录本提案相关 MR 上 review 评论的处置过程与结论。
> 每次执行该技能会以追加方式新增一节；请勿手动改动已有章节的结构（如需补充，新建 `## 备注` 子节即可）。

## 索引

<!-- AUTO-INDEX:START -->
<!-- AUTO-INDEX:END -->

---

<!-- ENTRIES:START -->
<!-- ENTRIES:END -->
```

## 单次执行追加章节

写到 `<!-- ENTRIES:START --> ... <!-- ENTRIES:END -->` 之间（END 前插入）。每仓一节，多仓不要混。

```markdown
## <YYYY-MM-DD HH:MM> · MR <repo>#<n>

- **触发人**：<git config user.name 兜底为 unknown>
- **分支**：`<branch>`
- **MR/PR**：[<repo>#<n>](<provider-supplied-url>)
- **Provider**：<provider_name>
- **本次处置评论数**：A=<x> / B=<x> / C=<x> / D=<x> / E=<x>；改码 <m> 条、回复 <r> 条、close <c> 条、保持 open <o> 条（其中人工评论已处理但按规则留人工自己 close 的 <h> 条，属预期）

### 评论处置矩阵

| Thread | File:Line | 评论摘要 | 作者类型 | 类型 | 改码 | 回复 | close |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ... | ... | ... | 人工/机器人 | A~E | 是/否 | 是/否 | 是/否 |

### 代码改动清单

- `path/to/file.go:120-145` — <一句话改动摘要>（对应 thread #<id>）

### 未闭环 / 待用户决策

- thread #<id>（<file:line>）：<原因>，建议下一步 <动作>

### 本地校验

- `mcp__gopls__go_diagnostics`（Go 工程）：error <e>，warning <w>；如有 error 列出涉及文件
- 非 Go 工程：<未跑 / 跑了什么轻量校验>

### 未自动执行

- 未自动 commit / 未自动 push / 未自动 approve（如本次实际有执行，请如实写明 commit sha / push 目标）
```

## 索引行

`<!-- AUTO-INDEX:START --> ... <!-- AUTO-INDEX:END -->` 之间**倒序**追加：

```markdown
- <YYYY-MM-DD HH:MM> · MR <repo>#<n> · A<x>/B<x>/C<x>/D<x>/E<x> · 改码 <m>，回复 <r>，close <c>，open <o>
```

## 幂等与冲突

- **同分钟重跑**：标题（同 MR、同分钟）已存在 → **续写该节**：处置矩阵按 `Thread` id 去重合并、改动清单去重追加，**不开新节**。
- **手工编辑共存**：仅在两组标记之间自动写；标记外的用户备注一律保留。
- **缺失标记**：用户清空了文件或丢了标记 → 重建首次创建骨架，再追加本次章节，不抛错。

## 写入完成

终端报告末尾追加一行（仅提案上下文）：

```
📎 已归档到 openspec/changes/<name>/mr-comment-resolution.md（追加 1 节）
```
