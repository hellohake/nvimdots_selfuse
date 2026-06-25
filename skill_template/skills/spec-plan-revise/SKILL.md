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
- **偏差来源（主）**：提案目录下的 `revise.md`（若存在）——逐条记录“哪个文档/哪处不对、期望是什么”。优先读它，便于事后 review。
- `$ARGUMENTS`（辅）：临时小偏差可直接传文本。
- **优先级：`revise.md` > `$ARGUMENTS`**（鼓励留痕）。若 `revise.md` 不存在或为空，直接使用 `$ARGUMENTS`；两者皆空 → 提示用户按需创建 `revise.md` 或直接口述偏差，不替用户臆测。

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
2. 读偏差来源：优先读已存在且有内容的 `revise.md`；没有该文件或内容为空时看 `$ARGUMENTS`；都空则让用户先写明/口述，并提示可按需创建 `<提案目录>/revise.md` 留痕。
3. **偏差清晰度预检（不清楚先问，不带着假设改文档）**：在读取大量 proposal/specs/design/tasks/plan 前，先判断 `revise.md` 条目或 `$ARGUMENTS` 是否足够进入文档修正。至少要能回答下面四项中的前三项：
   - **偏差位置**：哪个 artifact / 哪一节 / 哪个 requirement / 哪个任务项不对？
   - **当前问题**：现有文档写成了什么，为什么不符合预期？
   - **期望方向**：应该改成什么，或至少应该遵守哪条边界/非目标/业务意图？
   - **影响范围**：这次修正是否会影响下游 specs/design/tasks/plan，是否可能牵连已有代码？

   若不足三项，或只有“这里不对 / 文档有偏 / 和预期不符 / 帮我修一下”这类泛描述，必须立即停下来向用户追问，禁止进入阶段 1，禁止自行选择修正方向，禁止先改文档再等用户发现。

   追问规则：
   - 一次最多问 3 个最关键问题，优先补齐“偏差位置、当前问题、期望方向”。
   - 如果用户自己也没想清，按阶段 2 的方式就地澄清；但在澄清出明确结论前，不允许修改 proposal/specs/design/tasks/plan。
   - 如果偏差已经影响真实代码或需要同步改代码，提醒用户这是代码阶段偏差，应转 `spec-trouble-resolve`；本技能只改文档。

   追问模板：
   ```text
   我需要先补齐文档偏差信息再修正，否则容易把后续代码引向错误方向：
   1. 偏差位置：具体是 proposal/spec/design/tasks/plan 的哪一节或哪个条目？
   2. 当前问题：现在文档写法哪里不符合你的预期？
   3. 期望方向：你希望它改成什么边界、行为或方案？
   ```
4. **按需只读**相关文档（不整体内联大文件，做证据摘要）：proposal/specs/design/tasks/plan 中与偏差相关的段落。

### 阶段 1：定性偏差
判断两件事：
1. **偏差落在依赖链哪一层**（最上游的出错点）。
2. **偏差性质**：
   - **A 认知不清**（需求模糊/术语没定/方案没拍板）→ 进阶段 2 先就地澄清。
   - **B 已明确**（用户清楚哪错、要改成啥）→ 跳过澄清，直接阶段 3 改。

### 阶段 1.5：构建 Revision Packet（偏差注入包）
在进入澄清或修正文档前，必须把本轮偏差整理成一个短小、可传递给下游阶段的 `Revision Packet`。它是后续修正 proposal/specs/design/tasks/plan 的唯一偏差上下文，避免模型在同步下游时丢掉用户真正想改的点。

格式：

```markdown
## Revision Packet
- Source layer: <brainstorm | proposal | specs | design | tasks | plan>
- Deviation: <现有文档哪里错，引用文件/章节/requirement/task>
- Expected change: <用户期望改成什么；若未定，写 pending clarification>
- Constraints: <Non-Goals / 不允许改什么 / 业务边界>
- Affected downstream: <需要重核或修正的下游 artifact 列表>
- Evidence: <revise.md 条目 / $ARGUMENTS / 原文 path:line>
- Mode hint: <patch | regenerate-section | regenerate-artifact | pending>
```

规则：
- 偏差性质为 A 时，`Expected change` 和 `Mode hint` 可以先标 `pending clarification` / `pending`，阶段 2 澄清后必须回填。
- 偏差性质为 B 时，必须在阶段 3 前填完整，不允许带着空泛的 `Expected change` 去改文档。
- 下游每修完一层，都要把新的已落地事实写回 `Revision Packet` 的工作副本，再用更新后的 packet 修下一层。

### 阶段 2：就地澄清（仅 A 类，内置，不跳转）
用 grill-with-docs 的澄清方式：**一次问一个、每题给推荐答案、能查代码/文档就去查**。逼问到偏差点彻底清晰为止。

澄清产生的术语/决策落盘（**路径覆盖** —— grill-with-docs 默认写 repo 根，本工作流重定向）：
- 术语 → `.ai_doc/spec-workflow/CONTEXT.md`（就地、即时，懒创建）。
- 满足三判据（难回退 + 无背景会困惑 + 真实权衡）的决策 → `.ai_doc/spec-workflow/adr/NNNN-<slug>.md`（懒创建，新 ADR 必带 `日期` + `来源提案`）。
- ADR 失效：旧 ADR 留原地标 `superseded by ADR-NNNN`/`deprecated`，不删不搬。

澄清清楚后，先回填 `Revision Packet` 的 `Expected change` / `Constraints` / `Mode hint`，再进入阶段 3。

### 阶段 3：Schema-guided repair（按原阶段规则修，不重跑整个 workflow）
从**源头层**开始，按依赖链逐层向下修正。但这不是“重新跑整个 OpenSpec workflow”，而是 `schema-guided repair`：每个受影响 artifact 都先读取它自己的 OpenSpec/schema 阶段说明，再把 `Revision Packet` 作为额外约束注入，做最小必要修正。

#### 3.0 执行器选择（Inline vs 串行 Subagent）
默认 inline 修正。只有满足以下任一条件，才启用**串行 subagent mode**：

- 受影响 artifact >= 3；
- 源头层为 proposal/specs/design 且影响 tasks/plan；
- 任一 artifact 需要 `regenerate-section` 或 `regenerate-artifact`；
- plan 需要重生成；
- 当前主上下文已读取大量 spec/代码，继续执行会导致上下文污染。

Subagent mode 不是并行执行，必须按依赖链串行：proposal → specs → design → tasks → plan。主 agent 保留职责：维护 `Revision Packet`、选择修正模式、发起 worker、review worker 结果、最终一致性反查、归档和清理。Subagent 只负责单个 artifact 或一个明确 artifact group 的受控修正。

每个 subagent 的输入必须包含：
- 当前 `Revision Packet`；
- 授权写入集（只能改这些文件/目录）；
- 目标 artifact 的 OpenSpec/schema instruction + template；
- 上游已更新摘要；
- 禁止目标：不碰代码、不改 backup.md、不清理 revise.md、不提交、不扩大范围。

每个 subagent 的回执必须包含：

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

#### 3.0.1 Subagent 快照 diff review gate（不依赖 git diff）
OpenSpec 提案文档可能未被 git 跟踪，或被 `.gitignore` 忽略，所以主 agent **不得依赖 `git diff` review worker 结果**。每个 subagent 前后必须走快照 diff：

1. **确定授权写入集**：例如单文件 `design.md`，或目录型 artifact `specs/**/*.md`。未授权文件一律不得修改。
2. **worker 前做快照**：复制授权写入集到 `/tmp/spec-plan-revise-snapshots/<change>/<artifact>/<timestamp>/before/`。不存在的授权文件记录为 `MISSING` 标记。
3. **worker 后做 diff**：
   - 单文件：`diff -u before/file.md current/file.md`
   - 目录：`diff -ru before/specs current/specs`
   - 新增文件：检查是否只新增授权文件，并把新文件内容纳入 review。
   - 删除文件：默认视为 review fail，除非 `Revision Packet` 明确要求删除该 artifact/文件。
4. **主 agent review gate**：只读 worker 回执 + snapshot diff + 必要上下文段落，不重做 worker 全量分析。

快照生命周期：
- Review gate 通过后，立即删除该 worker 的 `before/` 快照目录，只保留必要的 diff 摘要在主 agent 记忆/回执中。
- Review gate 不通过且需要 worker 返工时，保留快照目录到返工完成；返工通过后删除。
- 若需要停下来问用户，保留快照目录，并在给用户的回执里明确写出 `SNAPSHOT_DIR=<abs path>`，方便继续诊断；下次恢复处理完后再删除。
- 技能最终结束前，best-effort 删除本轮已通过 review 的快照目录。禁止删除仍处于待用户决策、待返工或未完成 review 的快照目录。
- 不要把快照复制到仓库内；快照只放 `/tmp/spec-plan-revise-snapshots/...`，避免污染提案目录。

Review gate 通过条件：
- 只改授权 artifact / 文件；
- 未碰代码、`backup.md`、`revise.md`；
- diff 对齐 `Revision Packet` 的 `Deviation` / `Expected change`；
- 未违反 `Constraints` / Non-Goals；
- 保持目标 artifact 的 schema/template 格式；
- worker 明确给出下游影响摘要。

Review gate 不通过时：
- 小问题：主 agent 可做局部 patch，并记录原因；
- 中等问题：要求同一 worker 返工一次，传入 snapshot diff 和 review comments；
- 方向性问题或约束冲突：停止并向用户提问；
- 连续两次返工仍不收敛：停止，输出当前 diff、失败原因和建议选择。

通过后，主 agent 更新 `Revision Packet` 工作副本，再启动下一个下游 worker。

#### 3.1 定位当前提案 schema（先读再改）
先读 `<提案目录>/.openspec.yaml` 的 `schema` 字段；再按顺序尝试：
1. `<repo>/openspec/schemas/<schema>/schema.yaml`
2. `<repo>/openspec/schemas/<schema>.yaml`
3. `~/.agents/template/schemas/<schema>/schema.yaml`
4. `~/.agents/template/schemas/<schema>.yaml`

找不到时不要回退到固定模板；提示用户提供 schema 路径，或按现有文档风格最小修正。

#### 3.2 获取目标 artifact 的原始阶段说明
对每个受影响 artifact（proposal/specs/design/tasks/plan），优先使用 OpenSpec CLI 读取真实 instruction：

```bash
openspec instructions <artifact-id> --change "<change-name>" --json
```

如果 CLI 不可用或当前环境无法定位 change，则读取 schema.yaml 中对应 artifact 的 `instruction` 和 `template`。不要凭本技能自己的自由理解改写。

#### 3.3 注入 Revision Packet 并选择修正模式
把 `Revision Packet` 作为本次修正的额外输入约束，结合目标 artifact 的原始 instruction/template，选择下列模式之一：

| 模式 | 适用场景 | 处理方式 |
|---|---|---|
| `patch` | 单个字段、段落、边界、命名、任务描述有偏差 | 只改相关段落，保留其余内容 |
| `regenerate-section` | 某一节整体不对，但 artifact 其余部分仍有效 | 重写该节，并检查上下文衔接 |
| `regenerate-artifact` | 下游 artifact 已整体失效，继续 patch 会制造更多漂移 | 按该阶段 instruction/template 重新生成整个 artifact；仅在 tasks/plan 或严重失效文档中使用 |

默认策略：
- proposal/specs/design：默认 `patch`；整节语义失效才 `regenerate-section`；除非用户明确要求或文档整体不可用，否则不全量重写。
- tasks：上游 design/specs 实质变化时，可重建相关任务组；不要无关重排全部任务。
- plan：tasks 或 design 实质变化时，优先重新生成相关 plan 段；若任务链整体变化，才全量重生成。

#### 3.4 分层同步规则
- **proposal / specs / design / tasks**：按目标 artifact 的 schema instruction + template + `Revision Packet` 修正。
- **plan.md**：需要重生成时调用 **superpowers:writing-plans**，但输入必须包含更新后的 `Revision Packet`、最新 `tasks.md`、最新 `design.md`，并明确“只反映本次偏差及其下游影响，不添加无关任务”。
- 每修完一层，更新 `Revision Packet` 的工作副本，记录该层已经落地的事实，再带着更新后的 packet 修下一层。

**红线**：
- 只改与本次偏差直接相关的文档，不顺手重写无关内容（最小改动）。
- 不执行 `go build`/`go test`；不碰代码（纯文档阶段）。
- 遵守上下文纪律：主线程只读摘要，大文件按需读盘。
- 不允许“完整重跑整个 OpenSpec workflow”来代替修正；全量重生成只能作为单个 artifact 的模式选择，并且要说明原因。
- subagent 结果必须经主 agent 的 snapshot diff review gate 验收后才能进入下一层。

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
2. **清理 revise.md（仅当文件存在时）**：删除本次已处理条目；全部处理完则重置为占位骨架（保留文件，不删）。若本次只使用 `$ARGUMENTS` 且无 `revise.md`，不要强制创建；在回执里提示“如需留痕，可按需创建 revise.md”。
3. **回执**（不在对话重复文档正文）：偏差定性（源头层+A/B）；改了哪些文档、同步了哪些下游；（若澄清）CONTEXT 术语 + ADR 编号；（若涉及）“X 处可能影响已有代码，建议转 spec-trouble-resolve”。

## 关键红线 (Hard Rules)
只列最易违反、后果最重的几条（其余约束已在 SOP 各阶段说明）：
1. **只改文档不碰代码**：本技能是文档期工具；偏差一旦牵连已有代码，立即停手、转 spec-trouble-resolve。
2. **改上游必同步下游**：改了 design/specs/proposal 却不重核下游 = 制造新的文档漂移，等于没修。按依赖链表格走全链。
3. **归档纯追加**：backup.md 用 `>>` 追加、场景标记 `[规划偏差]`，禁止读取/全量重写（与 spec-trouble-resolve 共用一个库）。
4. **不臆测偏差**：偏差描述不清或定位失败，先问用户，别猜着改。
