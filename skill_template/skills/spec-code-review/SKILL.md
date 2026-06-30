---
name: spec-code-review
description: 'Use for OpenSpec-style SDD pre-commit review/fix loops after a proposal has been applied. Supports two independent actions under one command: review mode writes/appends spec_code_review.md and never edits code; fix mode consumes the latest spec_code_review.md Fix Queue and fixes only Status=accepted items. Trigger keywords: "AI review 这次代码", "pre-commit review", "写完代码先做 spec-code-review", "$spec-code-review fix", "修 accepted", "修复 Fix Queue", Fix Queue, CR Readiness, spec_code_review.md.'
---

# spec-code-review

## 角色与边界

你是一个**独立 pre-commit reviewer**，目标是在提交前把 AI coding 容易漏掉的问题提前暴露出来：spec 是否真的正确、实现是否符合真实代码上下文、改动是否放在正确位置、命名是否表达业务语义、代码是否足够简洁。

本技能有两个独立 action，复用同一个入口，不新增额外技能名：

- `review` mode：只做 review，产出/追加 `spec_code_review.md`，不改代码。
- `fix` mode：读取最新 `spec_code_review.md` 的最新 Review Run，只修 `Fix Queue` 中 `Status=accepted` 的项，更新该报告的状态并运行轻量校验。
- 兼容说明：旧 schema 或旧报告里的 `report-only` 只指 `review` action；`fix` action 只有显式 `$spec-code-review fix` / `修 accepted` 才允许改业务代码，且不刷新旧 Gate/CR Readiness。
- 不 commit，不 push，不创建/处理 MR 评论。
- 不把 AI 怀疑点写入 `troubleshoot.md` 或 `backup.md`。
- 不要求用户复制长提示词。主交互应是 `$spec-code-review <change>` 与 `$spec-code-review fix` 的循环；长提示只作为跨会话/换模型 fallback。

优先使用独立 reviewer agent；如果平台支持不同模型，优先按用户指定模型（如 GPT-5.5 / Claude 4.8）执行 review。不同模型是降低确认偏差的手段，但质量主要来自本 SOP：必须看 spec、diff、上下文、引用点和邻近实现。只有当前 harness 明确允许开 subagent、且用户/系统没有禁止时，才使用独立 reviewer；否则必须走 `inline_fallback`，不能为了追求独立视角违反平台约束。

这不是通用代码审查的替代品，也不要降级成只看代码质量的 broad review。它的核心价值是把 SDD 约束和真实代码上下文放在同一个 gate 里：既审实现是否符合 spec，也审 spec 是否误判真实系统。

## Action Mode Decision

先解析本轮 action，再进入对应流程。不要把 review 和 fix 混成一次隐式自动循环。

| User input pattern | Action | Meaning |
|---|---|---|
| `$spec-code-review <change>` | `review` | 默认行为：审查该提案当前 diff，写/追加 `spec_code_review.md`。 |
| `$spec-code-review review <change>` / `$spec-code-review <change> review` | `review` | 显式 review mode。 |
| `$spec-code-review fix` / `修 accepted` / `修复 Fix Queue` | `fix` | 从 cwd 自动定位最新可消费的 `spec_code_review.md`，只修最新 Review Run 的 unresolved `accepted` 项。 |
| `$spec-code-review <change> fix` / `$spec-code-review fix <change>` | `fix` | 先定位提案，再消费其 `spec_code_review.md`。 |
| `$spec-code-review fix R001,R003` | `fix` | 只修指定 ID；这些 ID 仍必须在最新 Review Run 的 Fix Queue 中且 `Status=accepted`。 |

Mode identity lock：

- `review` mode forbidden objectives：不改业务代码、不更新 Fix Queue 为 fixed、不 commit/push/MR。
- `fix` mode forbidden objectives：不生成新的 review finding、不刷新旧 Gate/CR Readiness、不修 `human_decision`/`deferred`/`false_positive`、不静默扩大 scope、不 commit/push/MR。
- 修复后必须提示再跑一次 `review` mode 刷新 Gate；旧 Gate 不能被 fix mode 视为当前结论。

## Dispatch Mode Decision

根据当前 harness 能力选择 review 模式，并在报告 `Scope -> Reviewer dispatch` 里记录：

| Mode | 触发条件 | 允许行为 | 报告记录 |
|---|---|---|---|
| `independent_agent` | 当前 harness 明确允许开独立 reviewer，且用户/系统未禁止 | 给 reviewer 一个整理后的审查包；reviewer 只读；主流程写报告 | `mode=independent_agent; readonly=yes; context=curated_review_pack` |
| `inline_fallback` | 不能开 subagent、用户未授权、或当前工具无 agent 能力 | 当前 agent 按同一 SOP 审查；必须显式承认不是独立模型视角 | `mode=inline_fallback; readonly=yes; context=degraded + reason` |
| `degraded_no_diff_or_context` | 找不到可靠 diff、提案文档或关键上下文 | 不输出完整 gate；停手要求补输入，或只给口头预审 | `mode=degraded_no_diff_or_context; readonly=yes; context=degraded + missing inputs` |

## Review Dispatch Contract

如果使用 `independent_agent`，给 reviewer 的输入必须是整理后的审查包，而不是当前会话的完整历史。这样可以降低实现者叙事对 reviewer 的影响，也避免 reviewer 顺着 coding agent 的推理继续合理化。

审查包至少包含：

- 提案摘要：`proposal.md` / `design.md` / `tasks.md` / 相关 `spec.md` 的关键要求和边界。
- 改动范围：每个仓库的绝对路径、branch、`git status --porcelain`、diff baseline 和实际使用的 diff 命令。
- 真实 diff：`git diff --stat` / `git diff`，以及 staged diff（如存在）。
- 上下文证据：关键改动符号的定义、引用点、邻近模式、入口/出口。
- 约束：仓库 `AGENTS.md`、相关 gotchas、用户本轮额外 review 指令。

Reviewer agent 必须只读：不得修改 working tree、index、HEAD、branch、提案文档或报告文件。需要比较其他 revision 时，只能使用只读命令或临时 worktree；最终由主流程把审查结论整理进 `spec_code_review.md`。

## NEVER

- NEVER 把本技能降级成只看代码质量的通用 code review；必须同时审 spec、diff、上下文和 spec 反向风险。
- NEVER 在没有 `file:line`、spec 条款、引用点、命令输出或邻近模式证据时写确定 finding。
- NEVER 在 `review` mode 改代码、commit、push、创建 MR，或处理真实 MR 评论。
- NEVER 在 `fix` mode 修 `human_decision`、`deferred`、`false_positive`；如用户要求处理这些项，先让用户把对应项转为 `accepted` 或给出明确设计决策。
- NEVER 把轻量模板语义套到 `hello-spec-v2`：v2 缺失 `manual_test_commands.md` 是 schema drift / verification gap；v2 中只要存在 `human_decision` finding，就必须创建或更新 `<proposal_dir>/human-decisions.md`，并让报告里的 `Dxxx` 指向持久条目。只有轻量 `hello-spec` 或 legacy proposal 才允许 `not_enabled` / `not_created`。
- NEVER 静默扩大 Fix Queue 的 `Files`/`Scope`；触碰契约、数据、跨仓或设计判断时转 `human_decision`。
- NEVER 把旧 `Gate` 或旧 `CR Readiness` 当成修复后的当前状态；修复后需要新一轮 review 才能刷新 gate。
- NEVER 把没有跑、无法确认、或 changed-file 有新错误的验证缺口误标为 `PASS`；必须按模板降级为 `PARTIAL`/`NO` 并写明缺口。

## Finding Calibration Contract

严重级别按真实风险校准，不按 reviewer 的表达强度校准：

- 只有可能破坏核心需求、线上行为、数据/契约/权限/并发/缓存/实验链路、或把代码放进错误架构边界的问题，才标 `Blocker`。
- 明确会增加维护风险、漏掉关键边界、或需要默认修复的问题，标 `Major`。
- 局部质量、可读性、低风险重复代码，标 `Minor`。
- 纯风格、命名偏好、无行为影响的建议，标 `Nit`，默认不进入 `accepted`。

每个 finding 必须回答三件事：证据在哪里、为什么对这个提案重要、怎样最小化修复。没有 `file:line`、引用点、spec 条款或命令证据的判断，不能写成确定结论；只能写成 `human_decision` 或审查不确定性。

对"做得更完整"、"更专业"、"建议泛化/抽象/兼容更多场景"这类意见要先做 YAGNI 检查：查调用方、spec 需求和现有邻近模式。没有实际使用或明确需求支撑时，默认 `deferred` 或 `human_decision`，不要放进 `accepted`。

## Review Consumption Contract

`spec_code_review.md` 是 review 结果，不是盲目执行清单。`fix` mode 的完整消费规则以 `references/report_template.md` 的 **Coding Agent Handoff** 为唯一来源——该 section 会被原样写进每一份报告，coding agent 直接从报告读取，不依赖本文件，因此规则只在模板里维护一份。

要点（具体以模板为准）：只修最新一轮 `Status=accepted`；修前先验证 finding 证据仍成立，失效就转 `false_positive`/`blocked`；指令/scope 不清或超出 Fix Queue（触碰契约/数据/跨仓）就停手转 `blocked`/`human_decision`，不静默扩大；reviewer 建议与已定架构、repo 约束、YAGNI 或真实调用链冲突时技术性 push back；不把旧 Gate 当已自动刷新。

## 输入

- `$1...`：action、提案名、提案目录绝对路径、可选 finding ID 列表。按 `Action Mode Decision` 解析。
- `$ARGUMENTS`：额外 review/fix 指令，例如"重点看共享结构污染"、"只 review repo A"、"fix R001,R003"。
- 当前 git 工作树：apply 后的未提交 diff，或已 staged diff。

## 输出

- `review` mode 主输出：提案目录下的 `spec_code_review.md`。
- `fix` mode 主输出：业务代码修复 + 最新 Review Run 的 Fix Queue 状态更新；不刷新 Gate/CR Readiness。
- `review` mode 终端摘要：Gate、CR Readiness、Blocker/Major 数量、accepted IDs、human_decision IDs、报告绝对路径、下一步短命令。
- `fix` mode 终端摘要：已处理 finding IDs、fixed/blocked/false_positive 状态、验证结果、报告绝对路径、下一步复审命令。
- 写报告前**强制完整读取** [references/report_template.md](./references/report_template.md)，从头到尾读完，不要设置行数或范围限制；严格使用其结构。除非用户只要口头预审且不写文件，否则不要跳过模板。

## 报告语言

报告是给用户和 coding agent 共同消费的，**人读部分必须使用简体中文**：

- `Executive Summary`、`Human Review Focus`、`CR Readiness`、`Review Findings` 的 Finding/Evidence/Recommendation、`Spec 反向风险`、`Context Audit`、`Manual Test Commands`、`Fix Queue` 的 Instruction/Acceptance 都用中文写。
- 代码标识符、文件路径、SQL、IDL/RPC/API、错误原文、状态枚举（如 `BLOCKED`、`accepted`、`human_decision`）保留英文原文。
- 如果 reviewer agent 输出英文，写入 `spec_code_review.md` 前先翻译成中文；不要把英文散文直接写进最终报告。

## 输出 Contract 与 CR Readiness

`references/report_template.md` 是唯一字段 contract。严重级别、Finding/Queue status、Fixability、Scope、Manual Test Commands、CR Readiness 的枚举和值语义都以模板为准；主体只说明判断意图，避免两边重复维护后漂移。

报告必须单独给出 `CR Readiness`，帮助用户判断什么时候进入低成本人工 CR。核心判断意图：它不是替用户拍板，而是把人工 review 时机显式化——`Gate=PASS` 不等于自动批准，仍要看是否有未解决 accepted、human_decision 范围、验证缺口。`YES / PARTIAL / NO` 的具体判定条件以 `references/report_template.md` 的 `Readiness rules` 为准。

建议最多 3 轮：

- 第 1 轮：广域 review。
- 第 2 轮：复审修复并找二阶问题。
- 第 3 轮：收敛确认。若仍持续出现新的 Blocker/Major，停止 AI loop，进入人工深审。

## 执行工作流

### 阶段 -1：Action Identity Lock

1. 按 `Action Mode Decision` 解析 action。没有显式 `fix` 时默认 `review`。
2. 输出第一条状态时说明：
   - `Locked action: spec-code-review review; primary input=<change/path/inferred>; forbidden=<no code edits/no commit/no push>`
   - 或 `Locked action: spec-code-review fix; primary input=<report/change/inferred>; forbidden=<new findings/no Gate refresh/non-accepted fixes/no commit/no push>`
3. 如果用户一句话里同时要求 review 和 fix，先执行显式 action；没有显式 action 时执行 `review`，并在终端摘要给出下一步 `$spec-code-review fix`。

### 阶段 0：定位提案与仓库范围

1. 定位提案目录，优先级：
   - `$1` 是绝对路径且存在。
   - `$1` 是提案名：查 `openspec/changes/$1`。
   - 当前目录向上查找 proposal/spec/design/tasks/plan 组合。
   - 如果出现多个合理候选，不要自选；列出候选路径、各自命中的证据，询问用户确认。
2. 定位改动仓库：
   - 当前 cwd 是 git 仓库则加入。
   - 提案 `plan.md` / `tasks.md` / `design.md` 中提到的仓库路径加入。
   - 对候选仓库跑 `git status --porcelain`、`git diff --name-only`、`git diff --cached --name-only`；无 diff 的剔除。
3. 识别提案类型：`hello-spec-v2` / 轻量 `hello-spec` / `legacy_or_unknown`。优先看 proposal schema metadata、`.openspec.yaml`、提案目录既有 artifact 和 schema marker；无法确认时按 `legacy_or_unknown` 记录，不套用 v2 专属硬约束。
4. 找不到提案或 diff 时停止并询问用户，不硬猜。diff baseline 不确定时，只能写 degraded preflight，不给完整 Gate。

### 阶段 1：加载 review 上下文

按上下文纪律只读必要内容：

1. 读取提案文档摘要：`proposal.md`、`design.md`、`tasks.md`、相关 `spec.md`/`plan.md`。
2. 读取项目约束：
   - 仓库根 `AGENTS.md` / `CLAUDE.md` / `GEMINI.md`（存在则读）。
   - 提案或仓库 `.ai_doc/spec-workflow/gotchas.md`（存在则读相关 tag）。
   - `~/.agents/gotchas/general.md`（存在且相关时读 Top 命中）。
3. 读取每个 touched repo 的测试能力上下文，并在报告 `Context Audit` 或 `Verification Guidance` 记录：
   - `git remote get-url origin` 得到 `repo_remote`。
   - Go repo 读取 `go.mod` 的 `module` 行得到 `go_module`；非 Go repo 写 `go_module=none`。
   - 读取项目 `.ai_doc/spec-workflow/test_policy.yaml`（存在时）和用户 `~/.agents/test_policy.yaml`（存在时）。
   - 按 `unit_test_required | manual_test_only | unit_test_disabled | unknown` 分类，并写明依据来自 repo remote、Go module、项目/用户 override、repo 文档或用户确认。
4. 读取 diff：
   - 未 staged：`git diff --stat` + `git diff`。
   - staged：也读 `git diff --cached --stat` + `git diff --cached`。
   - diff 很大时先按文件分组，逐文件读取关键 hunk 和上下文，避免整块塞满上下文。
5. 读取提案级 `manual_test_commands.md`。存在则读；不存在时按提案类型分支：`hello-spec-v2` 记录 expected path、schema drift / verification gap 和补救建议；轻量 `hello-spec` / legacy 才可标记 ledger 未启用。不要因为轻量模板缺文件而阻塞 review，也不要强制轻量模板创建。
6. 读取提案级 `human-decisions.md`（存在则读）。不存在且本轮没有 `human_decision` 不是错误；但 `hello-spec-v2` 一旦产生 `Dxxx`，必须先懒创建或更新 `<proposal_dir>/human-decisions.md`，不能只把决策留在报告散文里。

### 阶段 2：上下文审计

对每个改动文件/关键符号执行最小但真实的上下文审计：

1. 读被改函数/结构体/常量的完整定义及相邻实现。
2. 查引用点：
   - Go 项目优先用 `gopls` 符号引用工具；不可用时用 `rg`。
   - 非 Go 项目用 `rg` 查调用方、同名字段、同目录模式。
3. 查邻近模式：
   - 同 package / 同目录 / 同类型 handler、strategy、dao、client、parser 的既有实现。
4. 查入口与出口：
   - 这个改动从哪里被调用，结果流向哪里，是否影响共享结构、公共 API、IDL、RPC/HTTP schema、DB、缓存、实验、埋点或热路径。

报告中必须写明 `Context Audit`：看了哪些引用点和邻近模式。没查到也要写"未找到"和查询方式，避免伪审查。

### 阶段 3：按 6 类 review

每个 finding 必须有证据，优先给 `file:line`。没有证据的直觉不要写成结论，只能写到"需人工确认"。

1. **需求一致性**：实现是否覆盖 proposal/design/tasks/spec；是否漏需求、误实现、越界实现。
2. **上下文正确性**：调用链、引用点、已有行为、边界条件、错误处理、强弱依赖、事务/并发/缓存是否被破坏。
3. **边界与位置**：代码是否放在正确层；是否污染 shared/中台/公共结构；是否违反 repo 架构。
4. **业务语义**：命名是否体现业务含义；是否双重否定、概念混淆、泛化过度。
5. **简洁性**：是否有多余抽象、重复代码、过度兼容、参数膨胀、死代码；参考 `simplify` 的 reuse/quality/efficiency 思路，但本技能只报告不修。
6. **验证缺口**：是否缺少轻量校验；Go 大仓优先 gopls diagnostics，不要求技能自动跑重型 `go build` / `go test`；测试建议必须遵守阶段 1 的测试能力分类；如果本次 diff 新增/修改了测试文件，必须给出用户可手动复制执行的 targeted test command。

### 阶段 4：反向审查 spec

单独输出 `Spec 反向风险`：结合真实代码上下文判断 spec/design 是否漏掉边界、误判现状、或要求本身会破坏既有行为。

这类问题默认 `Status=human_decision`，因为它往往不是简单改代码，而是要用户决定修 spec、改方案，还是接受风险。

### 阶段 5：生成 Fix Queue

把 findings 转成 coding agent 可消费的修复队列，而不是散文建议。

默认取舍意图：核心风险且修复边界清晰的项才交给 coding agent；需要设计判断、跨文件/契约/数据风险、或只是低风险建议的项，不要默认塞进可执行队列。

所有执行期/审查期的 `human_decision` 项必须在报告里映射为稳定 `Dxxx` 条目（AI recommendation + options + blocking scope），不要只把决策留在散文里。

按提案类型处理持久队列：

- `hello-spec-v2`：任何 `human_decision` finding 都必须创建或更新 `<proposal_dir>/human-decisions.md`；报告里的 `Dxxx` 必须指向该文件中的持久条目，`Decision queue path` 写绝对路径，不能写 `not_created`。
- 轻量 `hello-spec` / legacy：`human-decisions.md` 仍是可选持久队列；默认不创建，只有出现需要跨轮跟踪的 blocking human decision，或用户明确要求持久队列时，才懒创建/更新。无持久队列时才允许 `Decision queue path: not_created`。

边界：`human-decisions.md` 不替代 `grill-spec`。如果问题属于规划期需求没想清、术语不清、领域边界不清，应标记为 spec/design 需要回到 `grill-spec` 或 `spec-plan-revise`，而不是把长期澄清问题塞进执行期决策队列。

Fix Queue 的字段和枚举以 `references/report_template.md` 为唯一 contract。这里的核心意图是：只把证据充分、修复边界清楚、适合 coding agent 独立处理的项设为 `accepted`；任何需要设计判断、契约/数据/跨仓风险、或 scope 不清的项都转 `human_decision` 或 `blocked`，不要伪装成可执行任务。

### 阶段 5.5：生成 Manual Test Commands

当 diff 中出现新增/修改的测试文件（如 Go 的 `*_test.go`、前端/脚本项目的 test/spec 文件）时，报告必须生成 `Manual Test Commands`，方便用户复制后手动运行看输出。若提案级 `manual_test_commands.md` 存在，检查是否已有对应记录；若不存在，按提案类型分支：`hello-spec-v2` 标为 schema drift / verification gap 并给 expected path 与补救建议；轻量 `hello-spec` / legacy 才标注 ledger 未启用，不要求模板预置该文件。

核心原则：不自动跑重型测试；命令必须可复制并包含 `cd <repo>`；优先最小范围；命令生成、是否执行、跳过原因必须依据阶段 1 的测试能力分类；明确 `not_run_by_skill` / `manual_only` / `skipped_by_repo_rule`；每条命令关联 finding 或测试文件。字段、状态和 Go 命令推导规则以 `references/report_template.md` 为准，避免在主体和模板之间维护两套表格契约。

### 阶段 6：写报告与可复制指令

1. **强制完整读取** [references/report_template.md](./references/report_template.md)，从头到尾读完，不要设置行数或范围限制；这是输出格式 contract，不是可选参考。
2. 写入提案目录 `spec_code_review.md`，若文件已存在则追加一个新 review run，不覆盖历史。
3. 报告必须包含 **Next Actions**：优先给短命令 `$spec-code-review fix` / `$spec-code-review <change>`，不要把长 copy prompt 作为主路径。
4. 报告必须包含模板的 **Coding Agent Handoff** section（消费规则单一来源）；coding agent 修复后更新 Fix Queue 状态即可，旧 Gate 不会自动刷新，建议修完再跑一轮 `spec-code-review` 复审。
5. 报告必须包含 **Machine State** JSON，方便 `fix` mode 稳定定位最新 Review Run、accepted IDs 和 human_decision IDs；Markdown 表格仍是人读主结构。
6. 报告必须包含 **Agent Execution Audit**，按 `hello-spec-v2` schema 的 `ai_context_discipline.audit_contract` 填充模板字段；轻量/legacy 也保留该 section，无法确认的字段写 `none` / `no:<reason>`，不要省略。
7. 报告必须包含 **Manual Test Commands**；若没有测试文件改动，也要写“本轮未发现新增/修改测试文件，未生成手动单测命令”。
8. 报告必须包含 **CR Readiness**，明确 `Ready for human CR: YES / NO / PARTIAL`、原因、建议人工只核对的范围。
9. 终端输出：
   - Gate 结论。
   - CR Readiness 结论。
   - Blocker/Major/Minor/Nit 计数。
   - latest Review Run 的 `accepted` IDs 和 `human_decision` IDs；计数和展开列表必须一致。
   - 若存在手动单测命令，输出最关键的 1-3 条命令或提示去报告中复制。
   - `spec_code_review.md` 绝对路径。
   - 下一步短命令，例如 `$spec-code-review fix`；跨会话/换模型时才给 fallback prompt。

## Fix Mode 工作流

`fix` mode 是受限修复器，不是 reviewer。它消费 review 结果，但不产生新的 finding，也不刷新 Gate。

### Fix 阶段 0：定位报告

1. 如果用户给了提案名或绝对提案目录，定位 `<proposal_dir>/spec_code_review.md`。
2. 如果用户只说 `$spec-code-review fix` / `修 accepted`：
   - 当前目录本身有 `spec_code_review.md`，直接使用。
   - 否则从当前 repo 根的 `openspec/changes/*/spec_code_review.md` 中找候选。
   - 优先选择最新 Review Run 中存在 unresolved `Status=accepted` 的报告。
   - 如果有多个候选，列出候选、mtime、accepted IDs、CR Readiness，停手让用户确认；不要猜。
3. 找不到报告、报告没有 Review Run、或最新 Review Run 没有 `Fix Queue` 时停手，提示先跑 `$spec-code-review <change>`。

### Fix 阶段 1：读取消费 contract

1. **强制完整读取** [references/report_template.md](./references/report_template.md)，从头到尾读完，不要设置行数或范围限制。
2. 读取完整 `spec_code_review.md`，只消费最新 `## Review Run`。
3. 优先读取最新 run 的 `Machine State`；如果不存在，回退解析 `Fix Queue`、`Human Decisions`、`CR Readiness`。
4. 对比最新 run 的 Markdown `Fix Queue` 表格和 `Machine State`；若 `accepted` / `fixed` / `blocked` / `false_positive` / `human_decisions` 集合不一致，停止并按模板标记 `blocked` 或要求人工确认，不能只信 JSON。
5. 只选 `Status=accepted` 的 Fix Queue 行；如果用户指定 ID，指定 ID 必须在该集合内。
6. 如果没有 unresolved accepted：
   - 若有 pending `human_decision`，提示用户先处理 `Dxxx`。
   - 否则提示可再跑 `$spec-code-review <change>` 复审或进入人工 CR。

### Fix 阶段 2：逐项修复

对每个 accepted finding：

1. 读取 `Files`、`Instruction`、`Acceptance`、对应 `Review Findings` 证据和相关代码上下文。
2. 修前验证 finding 证据仍成立：
   - 证据不成立：只更新该项为 `false_positive`，写明代码/spec 证据。
   - 指令、文件范围或验收标准不清：更新为 `blocked`，写明需要澄清什么。
   - 修复需要超出 `Scope`/`Files`，触碰契约、数据、跨仓或设计判断：更新为 `blocked` 或新增/引用 `human_decision`，不要静默扩大。
3. 只做与 finding ID 对应的最小修复；不要顺手重构、格式化无关文件或处理其他状态的项。
4. 每个代码改动都要能映射到 finding ID；必要时在报告 `Fix Mode Notes` 写映射，不要求在业务代码里加噪声注释。

### Fix 阶段 3：更新报告与验证

1. 在最新 Review Run 的 `Fix Queue` 中更新状态：
   - `accepted -> fixed`
   - `accepted -> blocked`
   - `accepted -> false_positive`
2. 在 `Fix Mode Notes` 记录每个 ID 的处理结果、关键文件、验证命令和结果。
3. 更新 `Machine State` 中的 `accepted` / `fixed` / `blocked` / `false_positive` ID 列表。
4. 按 `Verification Guidance` 和相关 `Manual Test Commands` 跑轻量校验；如果 repo 规则禁止自动跑重型测试，明确标 `skipped_by_repo_rule` 或 `manual_only`，不要伪装成 PASS。
5. 终端输出必须给出：
   - `Fixed: Rxxx`
   - `Blocked: Rxxx` / `False positive: Rxxx`（如有）
   - 验证结果
   - 报告路径
   - 下一步：`$spec-code-review <change>` 复审刷新 Gate

## 与邻居技能的边界

- `spec-code-review review`：提交前 AI review，产 report + Fix Queue，不改代码。
- `spec-code-review fix`：消费最新 report 的 accepted Fix Queue 并改代码；不产生新 finding，不刷新 Gate。
- `spec-trouble-resolve`：用户已确认的代码偏差修复，输入是 `troubleshoot.md`。
- `spec-e2e-debug`：E2E 现象不明时只读诊断，产 `debug-report.md`。
- `spec-commit-push`：人工 review 通过后 rebase/commit/push。
- `fix-mr-comments`：MR 创建后处理真实 reviewer 评论。
- `simplify`：通用改动简化并直接修；本技能只审查并给 coding agent 队列。

## 失败与停手

- 提案目录多候选：列出候选、命中依据和推荐项，询问用户确认；不要自行选择并输出正式 Gate。
- 找不到提案目录或无法确定 diff：停手问用户；如果用户只要预审，只能写 degraded preflight，不给 `PASS`/`BLOCKED`。
- diff baseline 不确定：写明缺失的 baseline 证据和已读到的 status/diff 片段，输出 `degraded_no_diff_or_context`，不给完整 Gate。
- diff 过大无法可靠审查：按仓库/模块拆分 review run；本轮只覆盖已声明范围，不输出假完整结论。
- 引用点/上下文查不到：在报告写明查询方式和不确定性，不臆测。
- fix mode 多候选报告：列出候选、accepted IDs、更新时间和推荐项，询问用户确认；不要自行选择。
- fix mode 没有 accepted：不改代码，提示处理 human_decision、复审或进入人工 CR。
