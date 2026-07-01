# spec-code-review.md Template

本文件是 `spec-code-review` 写入 `spec-code-review.md` 时必须遵守的输出契约。如果文件已经存在，追加新的 `## Review Run` section，并保留历史 run。只有用户明确要求口头预审且不写报告文件时，才可以跳过本模板。

本模板是报告字段和枚举语义的单一来源。不要在 `SKILL.md` 里重复定义 Severity、Status、CR Readiness、Fixability、Scope 或 Manual Test Commands 的字段契约；`SKILL.md` 只保留行为意图，字段级规则维护在这里。

````markdown
# Spec Code Review

## Review Run: <YYYY-MM-DD HH:mm:ss>

### Scope

- Proposal: `<proposal name or path>`
- Review report: `<absolute path to this file>`
- Repositories:
  - `<absolute repo path>` @ `<branch>`
- Diff baseline:
  - `<unstaged/staged/base ref, command used>`
- Reviewer model:
  - `<model or fallback>`
- Reviewer dispatch:
  - `mode=<independent_agent | inline_fallback | degraded_no_diff_or_context>`; `readonly=<yes | no + reason>`; `context=<curated_review_pack | degraded + reason>`
- Extra instructions:
  - `<user instructions or none>`

### Gate

- Result: `PASS | PASS_WITH_WARNINGS | BLOCKED`
- Blocker: `<count>`
- Major: `<count>`
- Minor: `<count>`
- Nit: `<count>`
- Human decision needed: `<count>`

### Executive Summary

<用简体中文写 3-6 条 bullet，finding 优先，不写泛泛安慰。代码标识符、文件路径、SQL/IDL/RPC/API 名称、状态枚举保留原文。>

### Human Review Focus

<用简体中文说明用户现在应该重点审什么。覆盖 Blocker/Major、human_decision 项、spec 反向风险，以及 coding agent 修复后是否建议再跑一轮 spec-code-review。>

### Human Decisions

本 section 只记录执行期/审查期 AI 不应静默代决的事项，不替代 `grill-spec`。规划期需求、术语、领域边界问题必须回到 `grill-spec` 或 `spec-plan-revise`。

- Decision queue path: `<absolute path to proposal/human-decisions.md or not_created>`
- Queue status: `not_needed | created | updated | pending_blocking | pending_non_blocking`
- Proposal type: `<hello-spec-v2 | lightweight_hello_spec | legacy_or_unknown>`
- Note:
  - `<中文说明是否有 human_decision 项；若有，列出 Dxxx 与阻塞范围。hello-spec-v2 下任何 Dxxx 都必须指向 human-decisions.md 持久条目；只有 lightweight/legacy 且未创建持久队列时才允许 not_created。>`

| Decision ID | Source Finding | Blocking | AI Recommendation | Options | Status |
|---|---|---|---|---|---|
| D001 | S001 | yes | <中文推荐方案> | A=<...>; B=<...> | pending_human |

### CR Readiness

- Ready for human CR: `YES | NO | PARTIAL`
- Reason:
  - `<中文说明为什么现在适合/不适合进入人工 CR>`
- Remaining blockers before low-cost CR:
  - `<无 / Rxxx / Sxxx / human_decision 项>`
- Recommended human review scope:
  - `<中文列出人工只需要重点核对的文件、finding、spec 反向风险、diff stat 或验证结果>`
- Suggested next action:
  - `<继续让 coding agent 修 accepted / 再跑一轮 spec-code-review / 进入人工 CR / 停止 AI loop 做人工深审>`
- Review consumption note:
  - `<中文说明 coding agent 只能处理最新 Fix Queue 的 accepted 项，且修复前必须验证 finding 证据仍成立；若证据不成立、scope 变大或指令不清，必须停止并更新状态，而不是盲修。>`

CR Readiness 判定规则：

- `YES`: 最新 `Gate != BLOCKED`；最新 Fix Queue 没有未解决的 `Status=accepted`；没有新的 Blocker/Major 需要 coding agent 修复；`human_decision` 项已有明确 scope；轻量验证没有 changed-file new error。
- `PARTIAL`: 没有已知 Blocker，但仍有 human_decision/spec-contract 风险、待处理 human-decisions，或用户提交前必须人工确认的验证缺口。
- `NO`: 仍有任何 Blocker；仍有未解决 accepted 项；多轮 review 持续出现新的 Blocker/Major；修复 diff 超出 Fix Queue scope；或 changed-file 验证缺失/失败。
- Verification gap rule: 轻量验证未运行、无法解释、或报告 changed-file new error 时，禁止标 `YES`。明确的人工验证缺口用 `PARTIAL`；阻断低成本 CR 的 changed-file 检查缺失/失败用 `NO`。

### Next Actions

优先给短命令。正常循环是 review -> fix -> review；如果同一 agent harness 可以运行 `fix` mode，不要让用户复制长提示词。

- Fix accepted queue:
  - `$spec-code-review fix`
  - `$spec-code-review <change-name> fix`
- Re-run review after fixes:
  - `$spec-code-review <change-name>`
- Human decisions:
  - `<Dxxx>=<option>` 或更新 `<human-decisions.md path>`
- Cross-session fallback:
  - `只有切换 agent/model，或新会话无法直接调用 $spec-code-review fix 时，才使用文末 fallback prompt。`

### Machine State

本代码块供 `fix` mode 使用。保持合法 JSON；fix mode 修改队列后必须同步更新。Markdown 表格仍是人读来源，但该代码块可避免后续 agent 解析散文或误读旧 run。

一致性规则：`fix` mode 消费前必须对比最新 `Review Run` 的 Markdown `Fix Queue` 表格与本 `Machine State`。`accepted`、`fixed`、`blocked`、`false_positive`、`human_decisions` 集合任一不一致时，停止并在 `Fix Mode Notes` 标记 `blocked` 或要求人工确认；不能只信 JSON 或只信表格继续改代码。

```json
{
  "schema": "spec-code-review/v1",
  "review_run_id": "<YYYY-MM-DD HH:mm:ss>",
  "change_name": "<proposal name>",
  "proposal_dir": "<absolute proposal dir>",
  "report_path": "<absolute path to spec-code-review.md>",
  "cr_readiness": "YES | NO | PARTIAL",
  "gate": "PASS | PASS_WITH_WARNINGS | BLOCKED",
  "accepted": ["R001"],
  "fixed": [],
  "blocked": [],
  "false_positive": [],
  "human_decisions": ["D001"],
  "deferred": [],
  "manual-test-commands": ["C001"]
}
```

### Review Findings

| ID | Severity | Category | File:Line | Finding | Evidence | Recommendation | Status |
|---|---|---|---|---|---|---|---|
| R001 | Blocker | 上下文正确性 | `/abs/path/a.go:42` | <中文描述问题> | <中文说明代码/spec/引用点证据，保留代码标识符原文> | <中文说明具体建议> | accepted |

严重级别校准：

- `Blocker`: 可能破坏核心需求、线上行为、数据/契约/权限/并发/缓存/实验链路，或明显违反架构边界。
- `Major`: 高概率维护/行为风险，默认应修，但未达到阻塞提交级别。
- `Minor`: 局部质量或可维护性建议，不阻塞。
- `Nit`: 纯风格或偏好，不进入 `accepted`，除非用户明确要求。

Category 取值：

- 需求一致性
- 上下文正确性
- 边界与位置
- 业务语义
- 简洁性
- 验证缺口

Status 取值：

- `accepted`: 问题证据和修复边界足够清楚，可以交给 coding agent 修。
- `human_decision`: 需要人工做设计或风险决策。
- `deferred`: 不阻塞本次提交。
- `false_positive`: reviewer 疑点已被证据否定。
- `fixed`: coding agent 已修复 accepted 项，并把改动映射到该 finding。
- `blocked`: coding agent 无法安全修复 accepted 项，因为证据变化、指令不清或所需 scope 超出 Fix Queue。

### Spec 反向风险

| ID | Spec Gap | Code Evidence | Risk | Recommendation | Status |
|---|---|---|---|---|---|
| S001 | <中文说明 spec/design 漏掉什么> | `/abs/path/a.go:42`, refs: `/abs/path/b.go:88` | <中文说明风险> | <中文说明修 spec/design 或代码策略> | human_decision |

### Context Audit

- Changed symbols checked:
  - `<symbol>`: definition `<abs path:line>`, references checked via `<gopls/rg command summary>`.
- Adjacent patterns checked:
  - `<abs path:line>`: <why relevant>.
- Shared/public contracts touched:
  - `<none or list>`
- Project constraints checked:
  - `<AGENTS.md/gotchas/design docs read>`
- Test policy discovered:
  - `<repo abs path>`: `classification=<unit_test_required | manual_test_only | unit_test_disabled | unknown>`; `repo_remote=<git remote get-url origin or none>`; `go_module=<module or none>`; `project_policy=<.ai_doc/spec-workflow/test_policy.yaml path or absent>`; `user_policy=<~/.agents/test_policy.yaml or absent>`; `basis=<中文说明匹配依据>`
- YAGNI checks for broadening suggestions:
  - `<none / searched callers via rg ... and found ... / no usage found so deferred / human_decision>`

### Manual Test Commands

本 section 用来给用户可复制的定向测试命令。除非实际执行过，不要声称这些命令已经运行。存在提案级 `manual-test-commands.md` 时必须检查并引用；缺失时按提案类型分支：`hello-spec-v2` 标为 verification gap / schema drift，并给出 expected path 与补救建议；只有 lightweight/legacy 才可把 ledger 标为 optional/not enabled，并把命令留在本报告内。

- Ledger path: `<absolute path to proposal/manual-test-commands.md | not_enabled | missing_expected:<absolute path>>`
- Ledger status: `covered | missing_command | not_enabled | not_applicable | verification_gap | schema_drift`
- Ledger note: `<中文说明台账是否已有对应命令；hello-spec-v2 缺失时写 expected path、verification gap/schema drift 和补救建议；lightweight/legacy 未启用时说明本报告已提供可复制命令，可按需创建 ledger>`

| ID | Covers | Test files | Command | Status | Notes |
|---|---|---|---|---|---|
| C001 | R001/R003 | `/abs/path/server_middleware/scene_inject_mw_test.go` | See command block below | `not_run_by_skill` | `<中文说明该命令覆盖什么，为什么需要用户手动跑>` |

```bash
cd <ABSOLUTE_REPO_PATH>
go test ./server_middleware -run 'TestSceneFromRequest' -count=1
```

规则：

- 如果存在 changed tests，每个 touched package/module 至少给一条命令。
- Go 项目从 repo root 推导 package-relative path，并从 changed `*_test.go` 提取 `TestXxx` 名称；优先 `go test ./pkg -run 'TestA|TestB' -count=1`。
- 如果 repo 禁止自动运行 `go test`，标 `Status=not_run_by_skill` 或 `skipped_by_repo_rule`；命令仍然提供给用户手动运行。
- 如果 `manual-test-commands.md` 已包含命令，在这里引用其 command ID；如果文件存在但缺命令，标 `Ledger status=missing_command` 并在报告里补命令。
- 如果文件不存在：`hello-spec-v2` 标 `Ledger path=missing_expected:<absolute path to manual-test-commands.md>`，`Ledger status=verification_gap` 或 `schema_drift`，并建议创建/补齐该 ledger；lightweight/legacy 才标 `Ledger status=not_enabled`，不要强制轻量模板创建。
- 如果没有测试文件改动，写：`本轮未发现新增/修改测试文件，未生成手动单测命令。`

### Fix Queue

本 section 是本轮 review run 的 coding-agent handoff queue。除非用户明确另说，coding agent 只能修最新 review run 中 `Status=accepted` 的行。

| ID | Severity | Status | Fixability | Scope | Files | Instruction | Acceptance |
|---|---|---|---|---|---|---|---|
| R001 | Blocker | accepted | clear | local | `/abs/path/a.go` | <中文写具体修复指令> | <中文写验收标准> |

Fixability 取值：

- `clear`
- `needs_design`
- `risky`
- `unclear`

Scope 取值：

- `local`
- `cross-file`
- `contract`
- `data`
- `unknown`

### Coding Agent Handoff

这是 `$spec-code-review fix` 和跨会话 coding agent 的执行契约。用户不需要在提示词里重复这些规则。

Coding agent 必须遵守：

1. 只处理最新 `Review Run` 的 `Fix Queue` 中 `Status=accepted` 的 finding ID。
2. 不处理 `human_decision`、`deferred` 或 `false_positive` 项。
3. 修复前必须对比 Markdown `Fix Queue` 与 `Machine State`；若 `accepted` / `fixed` / `blocked` / `false_positive` / `human_decisions` 集合不一致，停止并标记 `blocked` 或要求人工确认，不能只信 JSON。
4. 每个代码改动都必须映射到一个 finding ID。
5. 不做顺手机会主义重构或无关 cleanup。
6. 修每个 accepted 项前，先验证 finding 证据在当前代码里仍成立；若不成立，带证据把该行更新为 `false_positive` 或 `blocked`。
7. 如果指令、文件 scope 或验收标准不清，停止并把该行标为 `blocked`，写明需要澄清什么。
8. 如果 accepted 项需要超出已列 scope，触碰 contract/data/cross-repo 边界，或与 repo 约束冲突，停止并报告，不要静默扩大。
9. 如果 reviewer 建议更泛化或更“proper”的实现，先查真实用法和 spec 需求；缺少证据支撑时标 `deferred` 或 `human_decision`，不要实现额外能力。
10. 修复后更新本报告的 Fix Queue status：
   - `accepted -> fixed`
   - 无法安全修复时，`accepted -> blocked` 并写原因。
   - finding 无效时，`accepted -> false_positive` 并写代码/spec 证据。
11. 更新 `Machine State`，确保 `accepted`、`fixed`、`blocked`、`false_positive` 与最新 Fix Queue 一致。
12. 新增或更新 `Fix Mode Notes`，记录 ID 到改动的映射和验证证据。
13. 运行下方列出的轻量验证。
14. 不要把旧 review run 的 `Gate` 当作修复后的当前结论。修复后建议再跑一轮 `spec-code-review`，除非用户明确跳过。

### Fix Mode Notes

`$spec-code-review fix` 消费最新 Fix Queue 后追加或更新本 section。Review mode 可以保留为 `not_run`。

- Fix mode status: `not_run | partial | completed | blocked`
- Fix command:
  - `<command used, e.g. $spec-code-review fix>`
- State consistency check:
  - `<PASS | blocked: Markdown Fix Queue and Machine State disagree on accepted/fixed/blocked/false_positive/human_decisions; human confirmation required>`
- Processed IDs:
  - `<Rxxx -> fixed/blocked/false_positive; short Chinese evidence>`
- Code change mapping:
  - `<Rxxx>: <files changed and why>`
- Verification:
  - `<command/result or skipped_by_repo_rule/manual_only>`

### Verification Guidance

- Required:
  - `<gopls diagnostics / syntax check / targeted command>`
- Test policy basis:
  - `<repo abs path>`: `classification=<unit_test_required | manual_test_only | unit_test_disabled | unknown>`; `basis=<repo_remote/go_module/project_policy/user_policy/repo-doc/user-confirmation>`
- Manual test commands:
  - `见 Manual Test Commands；这些命令供用户手动复制执行，除非本报告明确写已执行，否则不要当成已跑结果。`
- Forbidden or skipped:
  - `<go build/go test skipped reason if applicable>`

### Agent Execution Audit

- Context discipline: `PASS | PARTIAL | FAIL`
- Key files read:
  - `<path:line summary bullets, or none>`
- Large content inlined: `no | yes:<reason>`
- Output written to disk: `yes | no:<reason>`
- Human decision queue: `<none | D001,D002 in human-decisions.md>`
- Next command: `<copyable command or none>`
- Suggested /clear resume: `<copyable command or none>`

### Cross-Session Fallback Prompt

优先使用 `$spec-code-review fix`。只有把报告交给无法直接调用该命令的其他 agent/session 时，才使用这个 fallback。

```text
请读取 <ABSOLUTE_PATH_TO_SPEC_CODE_REVIEW_MD>，只修复最新一轮 Review Run 的 Fix Queue 里 Status=accepted 的项；不要处理 human_decision/deferred/false_positive；每个改动必须映射到 finding ID，修完后更新该报告的 Fix Queue Status 并运行报告里写明的轻量校验。
```
````
