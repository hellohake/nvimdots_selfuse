---
name: spec-commit-push
description: openspec/speckit 提案 apply 完成、人工 review 过代码后，一键完成"多仓 rebase + 规范 commit + 确认后 push"的提交闭环。自动定位本次 sdd 开发改动的所有仓库与分支，逐仓 fetch+rebase 最新 master（冲突停手交人工解），读提案背景生成精简规范的 commit message（中文为主、Conventional Commits 格式），给用户确认（可口头改 message）后才 commit+push；需 force 时先展示本地/远端差异、经用户许可才用 --force-with-lease。一次提案开发可多次调用（增量提交）。Use when 用户说"提交代码 / push 这次改动 / 把这几个仓的代码提交了 / commit and push / 代码开发完了帮我提交"，或 hello-spec-v2 apply + 人工 review 后。
---

# spec-commit-push

## 🔴 安全红线（最高优先级，先读，违反 = 改坏协作分支 / 丢别人代码）

本技能执行 git 写操作（rebase / commit / push），且可能涉及 force，风险高。以下铁律无条件优先：

1. **保护分支绝不提交/push**：`master / main / develop / release/* / hotfix/* / prod / production / stable / HEAD(detached)`。三道闸（名称黑名单 + 远端 protected list + 上游 `@{u}`）任一命中 → **硬停**，让用户切特性分支后重来。push 前再独立校验一次。
2. **绝不自动 force**：rebase 后历史分叉需 force 时 → **停下来**，先给用户看「本地 vs 远端的具体差异」，**经用户明确许可**才用 `--force-with-lease`（远端有他人新提交会被拒，比裸 force 安全）。**永不**用裸 `git push --force`、**永不**用 `push <remote> HEAD:master` 这类覆盖主干形态。
3. **rebase 冲突不自动解**：冲突 → 停手，技能可分析冲突双方意图、给解决建议，但**解冲突操作由用户手动完成**；用户解完 `git rebase --continue` 后可再调本技能继续。
4. **push 是确认后才执行**：push 是 outward-facing 不可逆动作；commit message 必须先给用户确认（可改）才提交。
5. **异常/对不上先沟通**：本地远端分叉、推送被拒、MR 状态异常等 → 给具体信息，等用户决策，不擅自处理。

## 前置依赖

- **git**：分支、rebase、commit、push。
- **bytedcli**（可选）：查 MR / 受保护分支，优先 MCP（`mcp__bytedcli__*`），不可用回落 CLI。
- **gopls MCP**：Go 工程提交前可选轻量校验 `mcp__gopls__go_diagnostics`，**不**跑 `go build/test/vet`。
- 触发前提：apply 已完成、**代码已被用户 review**（本技能不审代码质量，只负责规范提交）。

## 执行工作流（SOP）

### 阶段 0 · 触发校验
确认用户显式触发（说了"提交/push 代码"等）。只是顺嘴提及 → 先一句话确认再开始。

### 阶段 1 · 仓库范围定位
找出本次 sdd 开发**实际改动过的所有仓库**（openspec 常一次改 2~N 个仓，漏一个就漏一组提交）。依次合并去重：
1. **会话回放**：扫本次会话所有 `Edit/Write` 文件路径，`git rev-parse --show-toplevel` 归并到仓库根。
2. **当前 cwd**：是 git 仓库则加入候选。
3. **提案推断**：有 `openspec/changes/<name>/` 或 `specs/<name>/` → 读 `tasks.md`/`design.md`/`plan.md` 提到的仓库路径加入。
4. **改动确认**：逐仓 `git status --porcelain` + `git diff --name-only` + 已提交未推送 `git log @{u}..HEAD --name-only`。三者皆空（无任何待提交/待推送）的仓库剔除。

把"仓库 + 分支 + 待提交/待推送概况"列表给用户确认后进入阶段 2。找不到任何改动仓库 → 询问用户，不硬猜。

### 阶段 2 · 逐仓预检 + rebase（每仓独立）
对每个仓库：
1. **保护分支三道闸**：名称 / 远端 protected / 上游，命中即硬停。
2. **fetch + 看落后**：`git fetch origin` → `git rev-list --left-right --count origin/master...HEAD` 看 ahead/behind。
3. **rebase 最新 master**（每次调用都做，因 master 高频迭代，攒着冲突更难解）：
   - behind=0（未落后）→ 跳过 rebase。
   - behind>0 → 先告诉用户"将基于 origin/master rebase，落后 N 个 commit" → 执行 `git rebase origin/master`。
4. **冲突处理**：rebase 冲突 → **立即停手**。列出：冲突文件、每个文件的冲突块（ours/theirs 双方内容）、各自意图分析、解决建议。**等用户手动解 + `git rebase --continue`**，技能不碰冲突文件。
5. **分叉检测（已 push 过的分支 rebase 后必然分叉）**：rebase 改写了已推送历史 → 本地与 `@{u}` 分叉。此时**不立即 push**，标记为"需 force"，留到阶段 5 经用户许可处理。

### 阶段 3 · 生成 commit message（读提案，精简规范）
读提案 `proposal.md`/`design.md` 提炼背景，但**硬性精简**——commit 不是技术方案，是给 reviewer/coding agent 快速看懂的摘要。

**判断首次 vs 后续提交**（影响详略）：
- **首次**（分支无 commit 或从未 push）：写完整背景，作为 MR 开篇。
- **后续**（分支已有提交/已 push）：写**增量** message，聚焦本轮新增改动，背景一句话带过（"接前序，本轮补充 xxx"），不重复全量背景。

**格式**（Conventional Commits，中文为主，专业术语如 API/RPC/rebase 保留英文）：
```
<type>(<scope>): <一句话主题>

背景：<1-2 句，为什么做（首次写全，后续可略）>
改动：<本仓本轮改了啥，3-5 条要点>
影响面：<影响哪些模块/接口/行为，方便 review>
```
- `type`：feat / fix / refactor / chore / docs / perf / test / style 等，从改动内容推断。
- `scope`：仓库名或核心模块名。
- 多仓：背景共享提案上下文，**改动/影响面各仓各写**（每仓是独立 commit）。

### 阶段 4 · 确认闸（改 message 方便）
对每个仓库，打出：
- **commit message 全文**（阶段 3 生成的）。
- **diff 摘要**：`git diff --stat`（待提交）+ 改动文件列表。
- （若标记"需 force"）**本地 vs 远端差异**：双方 commit 列表 + ahead/behind。

用户可**口头调整 message**（"主题换成 xxx"、"背景精简点"），技能改完再给看，直到用户说 OK。**得到确认前禁止 commit/push。**

### 阶段 5 · commit + push（确认后）
1. `git add` 本次相关改动（不夹带无关脏改动；有无关改动先提示用户）→ `git commit` 用确认的 message。
2. （Go 工程可选）`mcp__gopls__go_diagnostics` 扫本次 .go 文件，error 先报用户。
3. **push 前再做一次保护分支闸**：`git rev-parse --abbrev-ref HEAD` + `@{push}` 解析的远端目标分支都不在黑名单（防 `push.default` 把改动推到 master）。
4. **push**：
   - 普通情况（无分叉）→ `git push`。
   - **需 force（分叉）**：已在阶段 4 给用户看过差异 → **再次显式征求许可**（"确认 force push 到 <branch>？"）→ 许可后 `git push --force-with-lease`。**未获许可不 push**。
5. push 后：若有 open MR 给出链接 `https://code.byted.org/<repo>/merge_requests/<n>`；无则提示可创建 MR（不自动建）。

### 阶段 6 · 汇总
每仓输出：分支 / 是否 rebase（落后几个）/ commit sha / push 结果 / MR 链接 / 待办（冲突待解、待 force 决策等）。简短，用户 1 分钟看完。

## 失败与回退
- **rebase 冲突**：停手给建议，用户手动解；技能不 `--continue`、不 `--abort`（除非用户要）。
- **push 被拒（非分叉）**：给远端拒绝原因，不擅自 force。
- **本地远端对不上**：给双方具体差异（commit/文件/ahead-behind），等用户决策。
- **bytedcli/git 异常**：原样报错给用户，不臆测重试。

## 与邻居技能的边界
- 本技能 = **提交闭环**（rebase+commit+push）。提交后产生/更新 MR。
- `fix-mr-comments` = 提交后处理 MR 上的 review 评论（接力下一环）。
- `spec-trouble-resolve` = 修代码（在提交前；本技能不审代码、不修代码）。
- 一次提案可多次调用本技能（增量提交），每次都 rebase 最新 master。

## 关键红线 (Hard Rules)
1. 🔴 保护分支绝不提交/push（三道闸，push 前复查）。
2. 🔴 force 必须用户许可 + 先看差异，只用 `--force-with-lease`，绝不裸 force / 覆盖主干。
3. 🔴 rebase 冲突不自动解，停手交人工。
4. 🔴 push 前 message 必经用户确认；push 是确认动作。
5. 异常/分叉/对不上先给具体信息、等用户决策，不擅自处理。
6. 只提交本次相关改动，不夹带无关脏改动。
