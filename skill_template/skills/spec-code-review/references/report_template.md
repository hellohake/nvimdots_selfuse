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

<3-6 bullets. Findings first. Avoid generic reassurance.>

### Review Findings

| ID | Severity | Category | File:Line | Finding | Evidence | Recommendation | Status |
|---|---|---|---|---|---|---|---|
| R001 | Blocker | 上下文正确性 | `/abs/path/a.go:42` | <problem> | <code/spec/reference evidence> | <specific recommendation> | accepted |

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
| S001 | <what the spec/design missed> | `/abs/path/a.go:42`, refs: `/abs/path/b.go:88` | <risk> | <fix spec/design or code strategy> | human_decision |

### Context Audit

- Changed symbols checked:
  - `<symbol>`: definition `<abs path:line>`, references checked via `<gopls/rg command summary>`.
- Adjacent patterns checked:
  - `<abs path:line>`: <why relevant>.
- Shared/public contracts touched:
  - `<none or list>`
- Project constraints checked:
  - `<AGENTS.md/gotchas/design docs read>`

### Fix Queue

This section is the coding-agent handoff queue. The coding agent should only fix rows with `Status=accepted` unless the user explicitly says otherwise.

| ID | Severity | Status | Fixability | Scope | Files | Instruction | Acceptance |
|---|---|---|---|---|---|---|---|
| R001 | Blocker | accepted | clear | local | `/abs/path/a.go` | <specific coding instruction> | <how to verify closure> |

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

1. Only process finding IDs listed in `Fix Queue` with `Status=accepted`.
2. Do not modify `human_decision`, `deferred`, or `false_positive` items.
3. Every code change must map to a finding ID.
4. Do not do opportunistic refactors or unrelated cleanup.
5. If an accepted item requires broader scope than listed, stop and report instead of expanding silently.
6. After fixing, update this report's Fix Queue status:
   - `accepted -> fixed`
   - `accepted -> blocked` with reason if it cannot be fixed safely.
7. Run the lightweight verification listed below.

### Verification Guidance

- Required:
  - `<gopls diagnostics / syntax check / targeted command>`
- Forbidden or skipped:
  - `<go build/go test skipped reason if applicable>`

### Coding Agent Copy Prompt

```text
请读取 <ABSOLUTE_PATH_TO_SPEC_CODE_REVIEW_MD>，只修复其中 Fix Queue 里 Status=accepted 的项；不要处理 human_decision/deferred/false_positive；每个改动必须映射到 finding ID，修完后更新该报告的 Fix Queue Status 并运行报告里写明的轻量校验。
```
````
