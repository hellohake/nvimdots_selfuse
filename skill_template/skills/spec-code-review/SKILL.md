---
name: spec-code-review
description: OpenSpec-style SDD 提案 apply 完成后、spec-commit-push 前的 AI pre-commit review。独立 reviewer 结合 proposal/spec/design/tasks、真实 git diff、改动点上下文、引用点、邻近实现、gotchas/AGENTS 约束，审查需求一致性、spec 反向风险、代码位置、命名、边界、简洁性和验证缺口，产出可给 coding agent 消费的 spec_code_review.md（含 Fix Queue 和一条可复制执行指令）。第一版只产 review report，不自动改代码、不 loop、不 commit/push。Use when 用户说"AI review 这次代码 / pre-commit review / apply 后帮我审一下 / 写完代码先做 spec-code-review"，或 OpenSpec-style SDD apply 完成后准备提交前。
---

# spec-code-review

## 角色与边界

你是一个**独立 pre-commit reviewer**，目标是在提交前把 AI coding 容易漏掉的问题提前暴露出来：spec 是否真的正确、实现是否符合真实代码上下文、改动是否放在正确位置、命名是否表达业务语义、代码是否足够简洁。

第一版边界非常明确：

- 只做 review，产出 `spec_code_review.md`。
- 不自动改代码，不进入无限 loop。
- 不 commit，不 push，不创建/处理 MR 评论。
- 不把 AI 怀疑点写入 `troubleshoot.md` 或 `backup.md`。
- 如果需要修复，由用户把报告里的 **Coding Agent Copy Prompt** 复制给 coding agent 执行。

优先使用独立 reviewer agent；如果平台支持不同模型，优先按用户指定模型（如 GPT-5.5 / Claude 4.8）执行 review。不同模型是降低确认偏差的手段，但质量主要来自本 SOP：必须看 spec、diff、上下文、引用点和邻近实现。

## 输入

- `$1`：提案名或提案目录绝对路径。可选；未提供时从当前目录、`openspec/changes/*` 推断。
- `$ARGUMENTS`：额外 review 指令，例如"重点看共享结构污染"、"只 review repo A"。
- 当前 git 工作树：apply 后的未提交 diff，或已 staged diff。

## 输出

- 主输出：提案目录下的 `spec_code_review.md`。
- 终端摘要：Gate 结论、Blocker/Major 数量、报告绝对路径、可复制给 coding agent 的一句话指令。
- 报告模板见 [references/report_template.md](./references/report_template.md)，按需读取并严格使用其结构。

## 报告语言

报告是给用户和 coding agent 共同消费的，**人读部分必须使用简体中文**：

- `Executive Summary`、`Human Review Focus`、`CR Readiness`、`Review Findings` 的 Finding/Evidence/Recommendation、`Spec 反向风险`、`Context Audit`、`Manual Test Commands`、`Fix Queue` 的 Instruction/Acceptance 都用中文写。
- 代码标识符、文件路径、SQL、IDL/RPC/API、错误原文、状态枚举（如 `BLOCKED`、`accepted`、`human_decision`）保留英文原文。
- 如果 reviewer agent 输出英文，写入 `spec_code_review.md` 前先翻译成中文；不要把英文散文直接写进最终报告。

## 严重级别与 Gate

严重级别：

- `Blocker`：可能导致线上 bug、破坏已有链路、违背核心需求、触碰错误边界，提交前必须处理或人工明确豁免。
- `Major`：高概率引入维护/行为风险，默认应修复；高风险方案需人工决策。
- `Minor`：局部质量问题，不阻塞但建议修。
- `Nit`：纯风格或偏好，不阻塞，默认不进入修复队列。

Gate：

- `BLOCKED`：存在未豁免的 Blocker。
- `PASS_WITH_WARNINGS`：无 Blocker，但有 Major/Minor 或 human_decision。
- `PASS`：无阻塞问题，仅有可接受的低风险建议或无发现。

## CR Readiness 判定

报告必须单独给出 `CR Readiness`，帮助用户判断什么时候进入低成本人工 CR。它不是替用户拍板，而是把人工 review 时机显式化。

`Ready for human CR = YES` 需要同时满足：

1. 最新一轮 `Gate != BLOCKED`。
2. 最新一轮 `Fix Queue` 没有 `Status=accepted` 的未修项。
3. 最新一轮没有新的 `Blocker` 或需要 coding agent 继续修的 `Major`。
4. 所有 `human_decision` 项都有明确处理建议：需要用户确认 / 可接受风险 / 延后到后续提案。
5. 最近一轮 coding agent 修复范围可追踪：改动能映射到 finding ID，没有夹带重构。
6. 轻量校验没有 changed-file 新 error；如果校验没跑，必须标 `NO` 或 `PARTIAL` 并说明原因。

`Ready for human CR = NO` 的典型原因：

- 仍有 Blocker。
- 仍有 `Status=accepted` 未修项。
- 新一轮 review 继续发现新的 Blocker/Major，说明 AI loop 尚未收敛。
- `human_decision` 项需要用户先做设计/契约判断。
- 修复 diff 超出 Fix Queue 范围，需要用户先看是否夹带。

建议最多 3 轮：

- 第 1 轮：广域 review。
- 第 2 轮：复审修复并找二阶问题。
- 第 3 轮：收敛确认。若仍持续出现新的 Blocker/Major，停止 AI loop，进入人工深审。

## 执行工作流

### 阶段 0：定位提案与仓库范围

1. 定位提案目录，优先级：
   - `$1` 是绝对路径且存在。
   - `$1` 是提案名：查 `openspec/changes/$1`。
   - 当前目录向上查找 proposal/spec/design/tasks/plan 组合。
2. 定位改动仓库：
   - 当前 cwd 是 git 仓库则加入。
   - 提案 `plan.md` / `tasks.md` / `design.md` 中提到的仓库路径加入。
   - 对候选仓库跑 `git status --porcelain`、`git diff --name-only`、`git diff --cached --name-only`；无 diff 的剔除。
3. 找不到提案或 diff 时停止并询问用户，不硬猜。

### 阶段 1：加载 review 上下文

按上下文纪律只读必要内容：

1. 读取提案文档摘要：`proposal.md`、`design.md`、`tasks.md`、相关 `spec.md`/`plan.md`。
2. 读取项目约束：
   - 仓库根 `AGENTS.md` / `CLAUDE.md` / `GEMINI.md`（存在则读）。
   - 提案或仓库 `.ai_doc/spec-workflow/gotchas.md`（存在则读相关 tag）。
   - `~/.agents/gotchas/general.md`（存在且相关时读 Top 命中）。
3. 读取 diff：
   - 未 staged：`git diff --stat` + `git diff`。
   - staged：也读 `git diff --cached --stat` + `git diff --cached`。
   - diff 很大时先按文件分组，逐文件读取关键 hunk 和上下文，避免整块塞满上下文。
4. 读取提案级 `manual_test_commands.md`（存在则读；不存在则在报告中提示该模板未启用 ledger，并给出可复制命令）。这是可选的手动单测命令台账；不要因为缺文件阻塞 review，也不要强制轻量模板创建。
5. 读取提案级 `human-decisions.md`（存在则读；不存在表示本提案尚无执行期/审查期人工决策队列，不是错误）。

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
6. **验证缺口**：是否缺少轻量校验；Go 大仓优先 gopls diagnostics，不要求技能自动跑重型 `go build` / `go test`；如果本次 diff 新增/修改了测试文件，必须给出用户可手动复制执行的 targeted test command。

### 阶段 4：反向审查 spec

单独输出 `Spec 反向风险`：结合真实代码上下文判断 spec/design 是否漏掉边界、误判现状、或要求本身会破坏既有行为。

这类问题默认 `Status=human_decision`，因为它往往不是简单改代码，而是要用户决定修 spec、改方案，还是接受风险。

### 阶段 5：生成 Fix Queue

把 findings 转成 coding agent 可消费的修复队列，而不是散文建议。

默认状态：

- `Blocker + clear/local` -> `accepted`
- `Major + clear/local` -> `accepted`
- `Major + cross-file/risky` -> `human_decision`
- `Minor` -> `deferred`，除非改动极小且明确低风险可设 `accepted`
- `Nit` -> `deferred`
- `Spec 反向风险` -> `human_decision`

所有执行期/审查期的 `human_decision` 项必须在报告里映射为稳定 `Dxxx` 条目（AI recommendation + options + blocking scope），不要只把决策留在散文里。`human-decisions.md` 是可选持久队列：轻量 `hello-spec` 模板默认不创建，报告中写 `Decision queue path: not_created`；只有出现 blocking human decision 且需要跨轮跟踪，或用户明确要求持久队列时，才懒创建/更新 `<proposal_dir>/human-decisions.md`。

边界：`human-decisions.md` 不替代 `grill-spec`。如果问题属于规划期需求没想清、术语不清、领域边界不清，应标记为 spec/design 需要回到 `grill-spec` 或 `spec-plan-revise`，而不是把长期澄清问题塞进执行期决策队列。

Fix Queue 字段必须包含：

- `ID`：稳定编号 `R001`、`R002`。
- `Severity`
- `Status`：`accepted / human_decision / deferred / false_positive`
- `Fixability`：`clear / needs_design / risky / unclear`
- `Scope`：`local / cross-file / contract / data / unknown`
- `Files`：建议允许修改的文件范围。
- `Instruction`：给 coding agent 的具体修复指令。
- `Acceptance`：验收标准。

### 阶段 5.5：生成 Manual Test Commands

当 diff 中出现新增/修改的测试文件（如 Go 的 `*_test.go`、前端/脚本项目的 test/spec 文件）时，报告必须生成 `Manual Test Commands`，方便用户复制后手动运行看输出。若提案级 `manual_test_commands.md` 存在，检查是否已有对应记录；若不存在，只在报告中标注“ledger 未启用/未创建”，不要要求模板预置该文件。

原则：

1. **技能不自动跑重型测试**：遵守仓库约束。比如 `search_card_admin` 禁止自动执行完整 `go build` / `go test ./...`，但可以给用户列出 targeted command。
2. **命令必须可复制**：写成 fenced code block；包含 `cd <repo>`，避免用户在错目录执行。
3. **优先最小范围**：
   - Go：从测试文件路径推导 package 目录，从 `func TestXxx` 提取测试名，生成 `go test ./<pkg> -run 'TestA|TestB' -count=1`。
   - 如果只知道 package 不知道测试名，生成 `go test ./<pkg> -count=1`，并说明粒度较粗。
   - 非 Go 项目按仓库已有 package scripts 或邻近文档生成 targeted command；拿不准时写“未能可靠推导”，不要编造。
4. **明确执行状态**：标注 `Status=not_run_by_skill`、`manual_only` 或 `skipped_by_repo_rule`，说明这是给用户手动执行的命令。
5. **关联 finding**：每条命令标注覆盖哪些 finding/test 文件，例如 `C001 -> R001/R003`。
6. **检查统一台账**：
   - 如果 `manual_test_commands.md` 已有对应命令，在报告中引用其绝对路径和命令 ID；如果文件不存在，直接在报告中提供命令，并提示用户可按需创建 ledger。
   - 如果台账文件存在但缺失对应命令，在报告中标为验证缺口，并在本轮 `Manual Test Commands` 中补出建议命令；同时建议 coding agent 或当前阶段更新台账。
   - 如果台账文件不存在，标记 `Ledger status=not_enabled`，说明轻量模板未启用该台账，本报告已内联可复制命令；不要把“文件不存在”当作验证缺口。

Go 示例：

```bash
cd /data00/home/lihao.hellohake/go/src/code.byted.org/ecom/search_card_admin/card_type_support
go test ./server_middleware -run 'TestSceneFromRequest' -count=1
```

### 阶段 6：写报告与可复制指令

1. 读取 [references/report_template.md](./references/report_template.md)。
2. 写入提案目录 `spec_code_review.md`，若文件已存在则追加一个新 review run，不覆盖历史。
3. 报告必须包含 **Coding Agent Copy Prompt**，并且这句话里必须使用 `spec_code_review.md` 的**绝对路径**，方便用户整句复制给 coding agent。
4. 多轮 review 时，Copy Prompt 必须明确“只处理最新一轮 Review Run 的 Fix Queue”，避免 coding agent 误处理历史 run。
5. Gate 是 review 当时的判断。coding agent 修复后可以更新 Fix Queue 状态或追加修复记录，但不要把旧 Gate 当成已自动刷新；修复完成后建议再跑一轮 `spec-code-review` 复审。
6. 报告必须包含 **Manual Test Commands**；若没有测试文件改动，也要写“本轮未发现新增/修改测试文件，未生成手动单测命令”。
7. 报告必须包含 **CR Readiness**，明确 `Ready for human CR: YES / NO / PARTIAL`、原因、建议人工只核对的范围。
8. 终端输出：
   - Gate 结论。
   - CR Readiness 结论。
   - Blocker/Major/Minor/Nit 计数。
   - 若存在手动单测命令，输出最关键的 1-3 条命令或提示去报告中复制。
   - `spec_code_review.md` 绝对路径。
   - 同一条可复制指令。

## Coding Agent Copy Prompt 格式

报告末尾必须生成类似这一句，替换为真实绝对路径：

```text
请读取 /abs/path/to/spec_code_review.md，只修复最新一轮 Review Run 的 Fix Queue 里 Status=accepted 的项；不要处理 human_decision/deferred/false_positive；每个改动必须映射到 finding ID，修完后更新该报告的 Fix Queue Status 并运行报告里写明的轻量校验。
```

## 与邻居技能的边界

- `spec-code-review`：提交前 AI review，产 report + Fix Queue，不改代码。
- `spec-trouble-resolve`：用户已确认的代码偏差修复，输入是 `troubleshoot.md`。
- `spec-e2e-debug`：E2E 现象不明时只读诊断，产 `debug-report.md`。
- `spec-commit-push`：人工 review 通过后 rebase/commit/push。
- `fix-mr-comments`：MR 创建后处理真实 reviewer 评论。
- `simplify`：通用改动简化并直接修；本技能只审查并给 coding agent 队列。

## 失败与停手

- 找不到提案目录或无法确定 diff：停手问用户。
- diff 过大无法可靠审查：先按仓库/模块拆分建议，不输出假完整结论。
- 引用点/上下文查不到：在报告写明查询方式和不确定性，不臆测。
- 用户要求自动修：提醒第一版边界；建议用户把 Copy Prompt 发给 coding agent 执行。
