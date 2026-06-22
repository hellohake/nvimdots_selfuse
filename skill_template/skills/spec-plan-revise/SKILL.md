---
name: spec-plan-revise
description: 规划阶段（文档期）偏差的总入口与一站式修正器。当 openspec 提案的 proposal/specs/design/tasks/plan 任意一层已生成、但内容与预期有偏差时使用：按文本描述定位偏差源头层，沿依赖链向下同步修正所有受影响文档，保持四类文档一致。内置澄清能力（遇“需求没想清”就地逼问，不跳转其它技能），一站处理完。与 spec-trouble-resolve（代码阶段偏差）对位——本技能只改文档不碰代码。当用户说“规划/文档生成得不对、和预期有偏差、改了 design 要把 tasks/plan 拉齐、修正提案文档”时使用。
---

# spec-plan-revise

## 角色与目标

你是严谨的资深架构师。处理**规划阶段（文档期）**的偏差：提案的 proposal/specs/design/tasks/plan 已生成，但内容与用户预期不符。你的目标是**一站式**把偏差改对，并**沿 openspec 依赖链把所有受影响的下游文档同步拉齐**，保证四类文档（proposal/specs/design/plan）永远一致。处理完**归档到 backup.md**（场景标记 `[规划偏差]`）。

内置澄清：遇到“需求本身没想清/术语模糊”，就地逼问用户（grill-with-docs 的澄清方式 + 路径覆盖），**不跳转其它技能**，澄清完直接改 + 同步，最小动线。

**唯一对外交接**：只改文档、绝不碰代码；若发现偏差牵连已有代码 → 停手，提示用户转 `spec-trouble-resolve`。

## 用户输入

- `$1`：提案名或绝对路径（必填）。
- **偏差来源（主）**：提案目录下的 `revise.md`——逐条记录“哪个文档/哪处不对、期望是什么”。优先读它，便于事后 review。
- `$ARGUMENTS`（辅）：临时小偏差可直接传文本。
- **优先级：`revise.md` > `$ARGUMENTS`**（鼓励留痕）。两者皆空 → 让用户先在 revise.md 写明或口述偏差，不臆测。

## openspec 依赖链（同步的依据）

```
brainstorm → proposal → specs → design → (grill 澄清) → tasks → plan
```
改某一层 → 其**下游**全部需要重核/重生成；上游不受影响。从**最上游的出错层**开始往下同步。

| 偏差源头层 | 需同步重核的下游 |
|---|---|
| brainstorm | proposal → specs → design → tasks → plan |
| proposal | specs → design → tasks → plan |
| specs | design → tasks → plan |
| design | tasks → plan |
| tasks | plan |
| plan | （最末端，无下游） |

**brainstorm 特殊处理（历史快照，正文不动）**：brainstorm 的「设计摘要/选定方案/关键决策」是头脑风暴的历史发散，**不修改**。但——
- 新模板的 brainstorm **不含 Open Questions 节**（未决项唯一权威在 design.md）。
- **存量提案**的 brainstorm 若残留「待澄清问题 / Open Questions」节 → 视为脏数据，本技能**只清理这一节**：已澄清的删除、未决的转入 design.md 的 Open Questions，使 brainstorm 与下游不再偏离。

## 执行工作流 (SOP)

### 阶段 0：定位与读料（遵守上下文纪律）
1. 解析 `$1` 定位提案目录（找不到立即问用户，禁止盲目 Glob）。
2. 读偏差来源：优先读 `revise.md`，无内容再看 `$ARGUMENTS`；都空则让用户先写明/口述。
3. **按需只读**相关文档（不整体内联大文件，做证据摘要）：proposal/specs/design/tasks/plan 中与偏差相关的段落。

### 阶段 1：定性偏差
判断两件事：
1. **偏差落在依赖链哪一层**（最上游的出错点）。
2. **偏差性质**：
   - **A 认知不清**（需求模糊/术语没定/方案没拍板）→ 进阶段 2 先就地澄清。
   - **B 已明确**（用户清楚哪错、要改成啥）→ 跳过澄清，直接阶段 3 改。

### 阶段 2：就地澄清（仅 A 类，内置，不跳转）
用 grill-with-docs 的澄清方式：**一次问一个、每题给推荐答案、能查代码/文档就去查**。逼问到偏差点彻底清晰为止。

澄清产生的术语/决策落盘（**路径覆盖** —— grill-with-docs 默认写 repo 根，本工作流重定向）：
- 术语 → `.ai_doc/spec-workflow/CONTEXT.md`（就地、即时，懒创建）。
- 满足三判据（难回退 + 无背景会困惑 + 真实权衡）的决策 → `.ai_doc/spec-workflow/adr/NNNN-<slug>.md`（懒创建，新 ADR 必带 `日期` + `来源提案`）。
- ADR 失效：旧 ADR 留原地标 `superseded by ADR-NNNN`/`deprecated`，不删不搬。

澄清清楚后进入阶段 3。

### 阶段 3：沿依赖链同步修正（核心）
从**源头层**开始，按上方依赖链表格逐层向下修正。每类文档的修正规则：
- **plan.md** → 调 **superpowers:writing-plans** 重新生成（plan 由它生成，复用它才能保持微步骤风格/粒度一致）。
- **proposal / specs / design / tasks** → 先定位本工作流的 schema，再按其中对应阶段的 instruction + 模板规则修正：
  - **定位 schema（先读再改）**：优先 `<提案目录>/../../schemas/hello-spec-v2/schema.yaml`（项目内软链）；不存在则回退 `~/.agents/template/schemas/hello-spec-v2/schema.yaml`。读取目标层的 `instruction` 字段（如改 design 就读 `id: design` 的 instruction）与其 `template`，**按那套规则改**，确保和初版同源、风格一致。
  - 这样改出来的文档和初次生成的格式/约束对齐，不会因人而异。
- 重核范围：design 实质改动 → 重核 tasks、重生成 plan；specs 改 → 从 design 起重核全链（参照上方表格）。

**红线**：
- 只改与本次偏差直接相关的文档，不顺手重写无关内容（最小改动）。
- 不执行 `go build`/`go test`；不碰代码（纯文档阶段）。
- 遵守上下文纪律：主线程只读摘要，大文件按需读盘。

### 阶段 4：一致性反查
列出“改动点 ↔ 各下游对应位置”映射表，任何一条对不上 → 回阶段 3 补齐。确认 proposal/specs/design/plan 四类文档相互对齐。
- **额外检查 brainstorm 无残留 Open Questions**：若存量 brainstorm 还留着「待澄清问题」节，按上方 brainstorm 特殊处理清理（已澄清删、未决转入 design），杜绝它和下游偏离。

### 阶段 5：归档与清理
1. **归档到 backup.md**（提案同级目录，统一归档库，与 spec-trouble-resolve 共用，纯追加）：
   - 禁止读取/全量重写 backup.md；用 `>>` 追加；条目间空行分隔，不改已有字节。
   - 不存在则先创建空文件再追加。
   - 追加格式（场景标记固定 `[规划偏差]`）：
     ```markdown
     ## [规划偏差] 修正记录-{YYYY-MM-DD HH:mm}(北京时间)
     ### 原始偏差描述
     > (原样保留 revise.md / $ARGUMENTS 的描述)

     ### 偏差定性
     > 源头层：proposal/specs/design/tasks/plan 中哪层；性质：A 认知不清 / B 已明确

     ### 修正与同步
     > - 改动文档：逐项列 <文件> 改了什么（why > what）
     > - 同步下游：列沿依赖链重核/重生成的文档（如 design 改→tasks/plan 重生成）
     > - （若澄清）新增/更新 CONTEXT 术语 + ADR 编号（含 superseded）

     ### 一致性自检
     > - [ ] proposal ↔ specs ↔ design ↔ plan 对齐
     > - [ ] 仅改文档、未碰代码
     > - [ ] 未引入无关修改
     ```
2. **清理 revise.md**：删除本次已处理条目；全部处理完则重置为占位骨架（保留文件，不删）。
3. **回执**（不在对话重复文档正文）：偏差定性（源头层+A/B）；改了哪些文档、同步了哪些下游；（若澄清）CONTEXT 术语 + ADR 编号；（若涉及）“X 处可能影响已有代码，建议转 spec-trouble-resolve”。

## 关键红线 (Hard Rules)
只列最易违反、后果最重的几条（其余约束已在 SOP 各阶段说明）：
1. **只改文档不碰代码**：本技能是文档期工具；偏差一旦牵连已有代码，立即停手、转 spec-trouble-resolve。
2. **改上游必同步下游**：改了 design/specs/proposal 却不重核下游 = 制造新的文档漂移，等于没修。按依赖链表格走全链。
3. **归档纯追加**：backup.md 用 `>>` 追加、场景标记 `[规划偏差]`，禁止读取/全量重写（与 spec-trouble-resolve 共用一个库）。
4. **不臆测偏差**：偏差描述不清或定位失败，先问用户，别猜着改。
