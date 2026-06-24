# spec_code_review.md Template

Use this structure for every review run. If the file already exists, append a new `## Review Run` section and preserve older runs.

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

<3-6 bullets in Simplified Chinese. Findings first. Avoid generic reassurance. Keep code identifiers, file paths, SQL/IDL/RPC/API names, and status enums in their original English form.>

### Human Review Focus

<Use Simplified Chinese. Tell the user exactly what they should review now. Include Blocker/Major, human_decision items, spec reverse risks, and whether a second spec-code-review run is recommended after coding-agent fixes.>

### Human Decisions

Use this section only for execution/review-stage decisions that AI should not make silently. It is not a replacement for `grill-spec`; planning-stage requirement/terminology/domain-boundary questions must go back to `grill-spec` or `spec-plan-revise`.

- Decision queue path: `<absolute path to proposal/human-decisions.md or not_created>`
- Queue status: `not_needed | created | updated | pending_blocking | pending_non_blocking`
- Note:
  - `<中文说明是否有 human_decision 项；若有，列出 Dxxx 与阻塞范围>`

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

Readiness rules:

- `YES`: latest `Gate != BLOCKED`; latest Fix Queue has no unresolved `Status=accepted`; no new Blocker/Major needs coding-agent fixes; `human_decision` items are explicitly scoped; lightweight verification has no changed-file new error.
- `PARTIAL`: no known Blocker remains, but there are human_decision/spec-contract risks, pending human-decisions, or verification gaps that the user must check before commit.
- `NO`: any Blocker remains, any accepted item is unresolved, new Blocker/Major keeps appearing across review runs, repair diff exceeds Fix Queue scope, or changed-file verification is missing/failed.

### Review Findings

| ID | Severity | Category | File:Line | Finding | Evidence | Recommendation | Status |
|---|---|---|---|---|---|---|---|
| R001 | Blocker | 上下文正确性 | `/abs/path/a.go:42` | <中文描述问题> | <中文说明代码/spec/引用点证据，保留代码标识符原文> | <中文说明具体建议> | accepted |

Categories:

- 需求一致性
- 上下文正确性
- 边界与位置
- 业务语义
- 简洁性
- 验证缺口

Status values:

- `accepted`: clear enough for coding agent to fix.
- `human_decision`: needs human design or risk decision.
- `deferred`: not blocking this commit.
- `false_positive`: reviewer concern rejected by evidence.

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

### Manual Test Commands

Use this section to give the user copyable targeted test commands. Do not claim these were executed unless they actually were. If the proposal-level `manual_test_commands.md` ledger exists, check and reference it; if it is absent, treat the ledger as optional/not enabled for this template and keep the commands in this report.

- Ledger path: `<absolute path to proposal/manual_test_commands.md | not_enabled>`
- Ledger status: `covered | missing_command | not_enabled | not_applicable`
- Ledger note: `<中文说明台账是否已有对应命令；如果未启用，说明本报告已提供可复制命令，可按需创建 ledger>`

| ID | Covers | Test files | Command | Status | Notes |
|---|---|---|---|---|---|
| C001 | R001/R003 | `/abs/path/server_middleware/scene_inject_mw_test.go` | See command block below | `not_run_by_skill` | `<中文说明该命令覆盖什么，为什么需要用户手动跑>` |

```bash
cd <ABSOLUTE_REPO_PATH>
go test ./server_middleware -run 'TestSceneFromRequest' -count=1
```

Rules:

- If changed tests exist, include at least one command per touched package/module.
- For Go, derive package-relative path from the repo root and extract `TestXxx` names from changed `*_test.go`; prefer `go test ./pkg -run 'TestA|TestB' -count=1`.
- If the repo forbids automatic `go test`, mark `Status=not_run_by_skill` or `skipped_by_repo_rule`; the command is still useful for the user to run manually.
- If `manual_test_commands.md` already contains the command, cite its command ID here. If the file exists but misses the command, mark `Ledger status=missing_command` and include the command in this report. If the file does not exist, mark `Ledger status=not_enabled`; do not require the template to create it.
- If no tests changed, write: `本轮未发现新增/修改测试文件，未生成手动单测命令。`

### Fix Queue

This section is the coding-agent handoff queue for THIS review run. The coding agent should only fix rows with `Status=accepted` in the latest review run unless the user explicitly says otherwise.

| ID | Severity | Status | Fixability | Scope | Files | Instruction | Acceptance |
|---|---|---|---|---|---|---|---|
| R001 | Blocker | accepted | clear | local | `/abs/path/a.go` | <中文写具体修复指令> | <中文写验收标准> |

Fixability values:

- `clear`
- `needs_design`
- `risky`
- `unclear`

Scope values:

- `local`
- `cross-file`
- `contract`
- `data`
- `unknown`

### Coding Agent Handoff

The coding agent must follow these constraints:

1. Only process finding IDs listed in the latest `Review Run`'s `Fix Queue` with `Status=accepted`.
2. Do not modify `human_decision`, `deferred`, or `false_positive` items.
3. Every code change must map to a finding ID.
4. Do not do opportunistic refactors or unrelated cleanup.
5. If an accepted item requires broader scope than listed, stop and report instead of expanding silently.
6. After fixing, update this report's Fix Queue status:
   - `accepted -> fixed`
   - `accepted -> blocked` with reason if it cannot be fixed safely.
7. Run the lightweight verification listed below.
8. Do not treat an older review run's `Gate` as current after fixes. After fixes, recommend a second `spec-code-review` run unless the user explicitly skips it.

### Verification Guidance

- Required:
  - `<gopls diagnostics / syntax check / targeted command>`
- Manual test commands:
  - `见 Manual Test Commands；这些命令供用户手动复制执行，除非本报告明确写已执行，否则不要当成已跑结果。`
- Forbidden or skipped:
  - `<go build/go test skipped reason if applicable>`

### Coding Agent Copy Prompt

```text
请读取 <ABSOLUTE_PATH_TO_SPEC_CODE_REVIEW_MD>，只修复最新一轮 Review Run 的 Fix Queue 里 Status=accepted 的项；不要处理 human_decision/deferred/false_positive；每个改动必须映射到 finding ID，修完后更新该报告的 Fix Queue Status 并运行报告里写明的轻量校验。
```
````
