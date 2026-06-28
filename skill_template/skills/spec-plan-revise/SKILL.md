---
name: spec-plan-revise
description: "修正 OpenSpec-style SDD 规划文档偏差。Use when brainstorm/proposal/specs/design/tasks/plan 已生成但与预期不符，需要从最上游偏差层开始同步下游 artifacts；只改文档不碰代码。Triggers: 规划偏差、文档生成得不对、修正提案文档、改了 design 要同步 tasks/plan、brainstorm Open Questions 污染；代码偏差转 spec-trouble-resolve。"
---

# spec-plan-revise

## 角色与目标

你是严谨的资深架构师。处理**规划阶段（文档期）**的偏差：提案的 brainstorm/proposal/specs/design/tasks/plan 六类链路节点已经部分或全部生成，但内容与用户预期不符。你的目标是**一站式**把偏差改对，并**沿 openspec 依赖链把所有受影响的下游文档同步拉齐**。

术语口径：`brainstorm` 是**特殊上游 artifact**，用于定位最早偏差和清理历史 Open Questions；proposal/specs/design/tasks/plan 是**五类正式 artifact**，需要保持相互一致。处理完**归档到 backup.md**（场景标记 `[规划偏差]`）。

内置澄清：遇到“需求本身没想清/术语模糊”，就地澄清到可执行结论（grill-with-docs 的澄清机制 + 路径覆盖），**澄清阶段不跳转 `grill-with-docs` 技能**；plan 重生成可按阶段 3.4 调用 `superpowers:writing-plans`。澄清完直接改 + 同步，最小动线。

**唯一对外交接**：只改文档、绝不碰代码；若发现偏差牵连已有代码 → 停手，提示用户转 `spec-trouble-resolve`。

## Phase 0：Identity Lock 与输入适配

- 当前技能身份：`spec-plan-revise`，只处理**规划文档偏差**。
- 唯一主输入：提案名/提案绝对路径 + 偏差描述（优先 `<提案目录>/revise.md`）。
- 禁止目标：不处理代码偏差、不修 MR 评论、不做线上/泳道排障、不提交/推送代码。
- Slash-command 环境：`$1` 映射为提案名或绝对路径，`$ARGUMENTS` 映射为临时偏差描述。
- 普通对话环境：从用户话语中抽取“提案名/路径”作为 `$1`，其余偏差说明作为 `$ARGUMENTS`；若缺任一关键输入，先追问，不自行猜测。

## 用户输入

- `$1`：提案名或绝对路径（必填）。
- **偏差来源（主）**：提案目录下的 `revise.md`（若存在）——逐条记录“哪个文档/哪处不对、期望是什么”。优先读它，便于事后 review。
- `$ARGUMENTS`（辅）：临时小偏差可直接传文本。
- **优先级：`revise.md` > `$ARGUMENTS`**（鼓励留痕）。若 `revise.md` 不存在或为空，直接使用 `$ARGUMENTS`；两者皆空 → 提示用户按需创建 `revise.md` 或直接口述偏差，不替用户臆测。

推荐 `revise.md` 最小条目格式（半结构文本也可读，但清理只能按稳定条目执行）：

```markdown
## R001
- Location: <brainstorm/proposal/specs/design/tasks/plan + 章节/条目>
- Current problem: <现有写法哪里不符合预期>
- Expected change: <期望改成什么>
- Constraints: <不允许改什么/非目标/边界>
- Status: pending
```

多条目处理规则：
- 只处理 `Status: pending` 且本轮命中的条目；无法判断是否命中时先问用户。
- 条目没有稳定 ID 时，不做局部清理；完成后只在回执中说明哪些描述已处理。
- 处理完成后把命中条目的 `Status` 改为 `archived`，并在条目下补一行 `Archived in: backup.md <timestamp>`；不要删除未处理条目。
- 全部条目都已归档时，保留文件和条目历史，不重置为会丢信息的空骨架。

本轮范围选择：

| 输入组合 | 本轮处理范围 |
|---|---|
| `revise.md` 有 pending，`$ARGUMENTS` 为空 | 处理 `revise.md` 中所有可明确命中的 pending 条目。 |
| `revise.md` 有 pending，`$ARGUMENTS` 指定 R001/R002 等 ID | 只处理指定 ID；其他 pending 保留。 |
| `revise.md` 有 pending，`$ARGUMENTS` 明确限定一个临时偏差 | 先问用户本轮处理临时偏差还是 `revise.md` pending；不要自动混合。 |
| `revise.md` 无/空，`$ARGUMENTS` 有效 | 处理 `$ARGUMENTS`。 |
| 两者都有但范围互相冲突 | 停手澄清本轮范围。 |

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

## 缺失/部分生成 artifact 决策表

| 情况 | 处理 |
|---|---|
| 下游 artifact 不存在 | 按 schema instruction/template 生成缺失下游，记录为 `sync-created`。 |
| 上游 artifact 不存在 | 停手确认；不要为了修下游倒推生成上游历史文档。 |
| `brainstorm.md` 不存在 | 可继续处理五类正式 artifact；不要补造 brainstorm。 |
| `.openspec.yaml` 缺失 | 提示用户提供 schema；若用户确认继续，只按现有文档风格做最小修正，不生成缺失 artifact。 |
| 目标 artifact 半生成/占位 | 若有 schema，按阶段说明补齐本次偏差所需部分；若无 schema，先问用户是否允许按现有风格补齐。 |

## Fast Path / Full Path 决策表

| 入口 | 路径 |
|---|---|
| `plan` 单点命令/检查点修正，且无下游、无 schema 缺失、无 `revise.md` 多条目 | Fast Path：读偏差 → 构建最小 `Revision Packet` → patch plan → inline 自检 → append backup → 回执。 |
| `tasks` 单点任务描述/依赖修正，且只影响 plan | Short Full Path：构建 `Revision Packet` → patch tasks → 重核/patch plan → 自检归档。 |
| proposal/specs/design/brainstorm 任一上游变化 | Full Path：从源头层修起，按依赖链重核所有下游。 |
| 需求模糊、术语没定、期望方向不清 | Clarify Path：先阶段 2 澄清，回填 `Revision Packet` 后再选 Fast/Full。 |

## 执行工作流 (SOP)

### 阶段 0：定位与读料（遵守上下文纪律）
1. 解析 `$1` 定位提案目录（找不到立即问用户，禁止盲目 Glob）。
2. 读偏差来源：优先读已存在且有内容的 `revise.md`；没有该文件或内容为空时看 `$ARGUMENTS`；都空则让用户先写明/口述，并提示可按需创建 `<提案目录>/revise.md` 留痕。
3. **偏差清晰度预检（不清楚先问，不带着假设改文档）**：在读取大量 brainstorm/proposal/specs/design/tasks/plan 前，先判断 `revise.md` 条目或 `$ARGUMENTS` 是否足够进入文档修正。至少要能回答下面四项中的前三项：
   - **偏差位置**：哪个 artifact / 哪一节 / 哪个 requirement / 哪个任务项不对？
   - **当前问题**：现有文档写成了什么，为什么不符合预期？
   - **期望方向**：应该改成什么，或至少应该遵守哪条边界/非目标/业务意图？
   - **影响范围**：这次修正是否会影响下游 specs/design/tasks/plan，是否可能牵连已有代码？

   若不足三项，或只有“这里不对 / 文档有偏 / 和预期不符 / 帮我修一下”这类泛描述，必须立即停下来向用户追问，禁止进入阶段 1，禁止自行选择修正方向，禁止先改文档再等用户发现。

   追问规则：
   - 一次最多问 3 个最关键问题，优先补齐“偏差位置、当前问题、期望方向”。
   - 如果用户自己也没想清，按阶段 2 的方式就地澄清；但在澄清出明确结论前，不允许修改 brainstorm/proposal/specs/design/tasks/plan。
   - 如果偏差已经影响真实代码或需要同步改代码，提醒用户这是代码阶段偏差，应转 `spec-trouble-resolve`；本技能只改文档。

   追问模板：
   ```text
   我需要先补齐文档偏差信息再修正，否则容易把后续代码引向错误方向：
   1. 偏差位置：具体是 brainstorm/proposal/spec/design/tasks/plan 的哪一节或哪个条目？
   2. 当前问题：现在文档写法哪里不符合你的预期？
   3. 期望方向：你希望它改成什么边界、行为或方案？
   ```
4. **按需只读**相关文档（不整体内联大文件，做证据摘要）：brainstorm/proposal/specs/design/tasks/plan 中与偏差相关的段落。

### 阶段 1：定性偏差
判断两件事：
1. **偏差落在依赖链哪一层**（最上游的出错点）。
2. **偏差性质**：
   - **A 认知不清**（需求模糊/术语没定/方案没拍板）→ 进阶段 2 先就地澄清。
   - **B 已明确**（用户清楚哪错、要改成啥）→ 跳过澄清，直接阶段 3 改。

偏差源头判定表：

| 现象 | 源头层 |
|---|---|
| 历史 brainstorm 残留 Open Questions / 待澄清问题污染下游 | brainstorm |
| 业务目标、范围、非目标、成功标准错 | proposal |
| SHALL/验收口径/场景行为/兼容性要求错 | specs |
| 架构取舍、数据流、接口边界、状态模型错 | design |
| 任务拆分、依赖关系、测试策略、执行颗粒度错 | tasks |
| 执行顺序、命令、检查点、回滚/验证步骤错 | plan |

### 阶段 1.5：构建 Revision Packet（偏差注入包）
在进入澄清或修正文档前，必须把本轮偏差整理成一个短小、可传递给下游阶段的 `Revision Packet`。它是后续修正 brainstorm/proposal/specs/design/tasks/plan 的唯一偏差上下文，避免模型在同步下游时丢掉用户真正想改的点。

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
用 grill-with-docs 的澄清方式：**一次问一个、每题给推荐答案、能查代码/文档就去查**。澄清到偏差点可执行、可同步、可归档为止。

最小问法模板：
- 问题：`为了修正 <artifact/条目>，需要确认：<单个关键选择>？`
- 推荐：`建议选 <A>，因为 <影响/取舍>。`
- 影响：说明该选择会同步影响哪些下游 artifact。
- 落盘：术语写 `CONTEXT.md`，架构取舍写 ADR，普通偏差只回填 `Revision Packet`。
- 停止：当 `Expected change` / `Constraints` / `Affected downstream` 都明确后停止澄清。

澄清产生的术语/决策落盘（**路径覆盖** —— grill-with-docs 默认写 repo 根，本工作流重定向）：
- 术语 → `.ai_doc/spec-workflow/CONTEXT.md`（就地、即时，懒创建）。
- 满足三判据（难回退 + 无背景会困惑 + 真实权衡）的决策 → `.ai_doc/spec-workflow/adr/NNNN-<slug>.md`（懒创建，新 ADR 必带 `日期` + `来源提案`）。
- ADR 失效：旧 ADR 留原地标 `superseded by ADR-NNNN`/`deprecated`，不删不搬。

澄清清楚后，先回填 `Revision Packet` 的 `Expected change` / `Constraints` / `Mode hint`，再进入阶段 3。

### 阶段 3：Schema-guided repair（按原阶段规则修，不重跑整个 workflow）
从**源头层**开始，按依赖链逐层向下修正。但这不是“重新跑整个 OpenSpec workflow”，而是 `schema-guided repair`：每个受影响 artifact 都先读取它自己的 OpenSpec/schema 阶段说明，再把 `Revision Packet` 作为额外约束注入，做最小必要修正。

#### 3.0 执行器选择（Inline vs 委派候选）
默认 inline 修正。满足以下任一条件时，只是进入**委派候选**，不等于可以直接启动 subagent：

- 受影响 artifact >= 3；
- 源头层为 proposal/specs/design 且影响 tasks/plan；
- 任一 artifact 需要 `regenerate-section` 或 `regenerate-artifact`；
- plan 需要重生成；
- 当前主上下文已读取大量 spec/代码，继续执行会导致上下文污染。

只有宿主规则允许且用户已经显式授权 subagent/delegation/parallel agent work 时，才能启用**串行 subagent mode**。否则必须 inline 串行修正；当 inline 会明显降低质量、超出上下文承载，或无法可靠 review 时，停下说明质量风险并请求用户授权委派。

Subagent mode 不是并行执行，必须按依赖链串行：proposal → specs → design → tasks → plan。主 agent 保留职责：维护 `Revision Packet`、选择修正模式、发起 worker、review worker 结果、最终一致性反查、归档和清理。Subagent 只负责单个 artifact 或一个明确 artifact group 的受控修正。

委派前 MANDATORY - READ `references/repair-templates.md` 的 Worker Contract；inline 模式不要加载该模板。Worker contract 至少包含：`Revision Packet`、授权写入集、目标 artifact instruction/template、上游摘要、禁止目标，以及 worker result 的文件清单、修正模式、packet 字段覆盖、下游影响和风险。

#### 3.0.1 Subagent 快照 diff review gate（不依赖 git diff）
OpenSpec 提案文档可能未被 git 跟踪，或被 `.gitignore` 忽略，所以主 agent **不得依赖 `git diff` review worker 结果**。MANDATORY - READ `references/snapshot-diff-gate.md` before launching the first subagent. Do NOT load it in inline mode.

Review gate 的最低通过条件：
- 只改授权 artifact / 文件，未碰代码、`backup.md`、`revise.md`；
- diff 对齐 `Revision Packet` 的 `Deviation` / `Expected change`，且未违反 `Constraints` / Non-Goals；
- 保持目标 artifact 的 schema/template 格式；
- worker 明确给出下游影响摘要。

Review gate 不通过时，按问题级别局部 patch、要求返工或停下问用户；连续两次返工仍不收敛时，输出当前 diff、失败原因和建议选择。

通过后，主 agent 更新 `Revision Packet` 工作副本，再启动下一个下游 worker。

#### 3.1 定位当前提案 schema（先读再改）
先读 `<提案目录>/.openspec.yaml` 的 `schema` 字段；再按顺序尝试：
1. `<repo>/openspec/schemas/<schema>/schema.yaml`
2. `<repo>/openspec/schemas/<schema>.yaml`
3. `~/.agents/template/schemas/<schema>/schema.yaml`
4. `~/.agents/template/schemas/<schema>.yaml`

找不到时不要回退到固定模板；提示用户提供 schema 路径，或在用户确认后按现有文档风格最小修正。schema 缺失时不得生成不存在的下游 artifact。

#### 3.2 获取目标 artifact 的原始阶段说明
对每个受影响 artifact（brainstorm/proposal/specs/design/tasks/plan），优先使用 OpenSpec CLI 读取真实 instruction：

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

**局部执行约束**：
- 只改与本次偏差直接相关的文档，不顺手重写无关内容（最小改动）。
- 遵守上下文纪律：主线程只读摘要，大文件按需读盘。
- 全量重生成只能作为单个 artifact 的模式选择，并且要说明原因。
- subagent 结果必须经主 agent 的 snapshot diff review gate 验收后才能进入下一层。

Inline 自检（不依赖 git diff）：
- 修改前记录 touched files 计划 + 每个文件的关键段落摘要。
- 修改后局部读取/`rg` 验证关键字段已落地，且 `Revision Packet` 三项核心字段（Deviation / Expected change / Constraints）均被覆盖。
- 显式检查未碰代码、未改未授权文档、未改未命中的 `revise.md` 条目。
- 若存在下游 artifact，阶段 4 的“改动点 ↔ 下游位置”映射表不能为空。

### 阶段 4：一致性反查
列出“改动点 ↔ 各下游对应位置”映射表，任何一条对不上 → 回阶段 3 补齐。确认 brainstorm 特殊上游节点与 proposal/specs/design/tasks/plan 五类正式 artifact 相互对齐。
- **额外检查 brainstorm 无残留 Open Questions**：若存量 brainstorm 还留着「待澄清问题」节，按上方 brainstorm 特殊处理清理（已澄清删、未决转入 design），杜绝它和下游偏离。

### 阶段 5：归档与清理
1. **归档到 backup.md**：append-only，不得改已有字节或全量重写。MANDATORY - READ `references/repair-templates.md` 的 Archive Template and Archive Safety Check before archiving.
2. **清理 revise.md（仅当文件存在时）**：只归档本轮命中的稳定条目；不删除未处理内容。具体规则见 `references/repair-templates.md` 的 Revise Cleanup Rules。
3. **回执**（不在对话重复文档正文）：MANDATORY - READ `references/repair-templates.md` 的 Final Receipt Template before responding. 回执只列偏差定性、改了哪些文档、同步了哪些下游、自检结果；（若澄清）CONTEXT 术语 + ADR 编号；（若涉及）“X 处可能影响已有代码，建议转 spec-trouble-resolve”。

## 最危险反模式 (NEVER)

- NEVER 用完整重跑 workflow 替代定点修正，因为这会丢失人工 gate、历史决策和最小改动边界。
- NEVER 依赖 `git diff` 验收 subagent 文档改动，因为 proposal 文档可能未跟踪或被忽略。
- NEVER 删除没有稳定 ID 或未命中的 `revise.md` 内容，因为这会抹掉用户尚未处理的偏差。
- NEVER 倒推生成缺失的上游历史 artifact，因为这会伪造规划过程。
- NEVER 把 `brainstorm` 历史摘要/选定方案改写成当前事实；只清理 Open Questions 污染。

## 关键红线 (Hard Rules)
只列最易违反、后果最重的几条（其余约束已在 SOP 各阶段说明）：
1. **只改文档不碰代码**：本技能是文档期工具；偏差一旦牵连已有代码，立即停手、转 spec-trouble-resolve。
2. **改上游必同步下游**：改了 design/specs/proposal 却不重核下游 = 制造新的文档漂移，等于没修。按依赖链表格走全链。
3. **归档纯追加**：backup.md 只能 append-only，场景标记 `[规划偏差]`，禁止改已有字节或全量重写（与 spec-trouble-resolve 共用一个库）。
4. **不臆测偏差**：偏差描述不清或定位失败，先问用户，别猜着改。
