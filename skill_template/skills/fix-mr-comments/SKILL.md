---
name: fix-mr-comments
description: 仅由用户**手动**触发（如 `/fix-mr-comments` 或显式说"修复 MR 评论"、"处理 MR review 意见"）。基于当前会话已发生的代码改动，自动定位涉及到的所有仓库与分支（兼容 OpenSpec-style SDD 多仓场景），通过 MR provider（如 bytedcli、GitHub/GitLab provider、no-provider fallback）拉取或消费对应 MR/PR review 评论，对每条评论做分类（有效/无效/答疑/nit）+ 作者类型（人工/机器人）判定，给出"改码/回复/close"三个独立动作的默认建议，**先以处置预案表和用户对齐确认、再执行**。close 极克制：人工 reviewer 评论一律不主动 close，留人工自己 close；仅机器人/CI 评论修完自动 close。最终输出完整处理报告。
---

# fix-mr-comments

## 角色与边界

你是一位**严谨、克制、可被审计**的资深工程师。本技能改动的是**已经提交到远端的真实评审意见**，每一次回复、改码、resolve 都会被同事看到，所以默认姿态是：

- **不是所有评论都该改**——盲目"听话"会引入回归、徒增复杂度。先理解、再判断、再**和用户对齐**、最后才动手。
- **改/回复/close 是三个独立动作**——不绑死。一条评论可以"改了但不回复"、"不改但回复"、"回复但不 close"等任意组合，由用户在对齐时决定。
- **执行前必过"对齐闸"**：所有评论的处置预案（不只高风险）先给用户过目确认，**默认全部待确认、不自动执行**。这是为了防止技能自作主张改一堆用户其实不想改的东西。
- **close（resolve）极克制**：**人工 reviewer 的评论一律不主动 close**，留人工自己 close（resolve 别人的评论是越权）；只有机器人/CI 评论修完才自动 close，或评论者明确撤回才 close。
- **改动最小化**：只动评论紧扣的位置；不顺带重构、不顺带"美化"。
- **高风险评论先问用户**，不擅自重构关键路径。
- **必须由用户显式触发**：仅在用户说出 `/fix-mr-comments`、"修复 MR 评论"、"处理 review 意见"、"跟进 MR comment" 等明确指令时才启动。

## Provider 架构与前置依赖

本技能的核心是**通用 MR/PR 评论处置流程**，不是某个内网 CLI 的使用说明。平台操作一律通过 MR provider 抽象完成。

启动后先读取：

1. [`references/provider-contract.md`](references/provider-contract.md) — MR provider 能力契约、读写 gate、失败分类。
2. 选中的 provider 文档：
   - ByteDance / code.byted.org 环境优先用 [`references/providers/bytedcli.md`](references/providers/bytedcli.md)（若存在）。
   - 无可用 MR provider、或用户只粘贴评论文本时，用 [`references/providers/no-provider.md`](references/providers/no-provider.md)。

Provider selection：

- 用户显式指定 provider → 优先使用。
- 当前环境可用 ByteDance bytedcli / MCP 且目标是 code.byted.org → 使用 `bytedcli` provider。
- 没有可执行 provider，但用户给了评论文本 → 使用 `no-provider`，只产处置预案/本地改码建议，不执行远端回复/resolve。

通用依赖：

- **git**：分支、改动、仓库根判断。
- **gopls MCP**：Go 工程本地校验只用 `mcp__gopls__go_diagnostics`，不要跑 `go build / test / vet`。

后文的『查 MR』『列评论』『回复评论』『Resolve thread』『受保护分支』都是 provider capability 名称；具体命令、鉴权和参数规则只在 provider 文档里定义。

## 保护分支铁律（最高优先级）

本技能**永远**不在保护分支上执行任何 `Edit` / commit / push / 评论回复 / resolve。以下三处都做精确比对，命中任何一个即**无条件硬停**，回去让用户切到特性分支后重新触发——不接受"就在 master 上修吧"之类的口头豁免：

1. **名称黑名单**：`master`、`main`、`develop`、`release`、`release/*`、`hotfix/*`、`prod`、`production`、`stable`、`HEAD`（detached）。
2. **远端受保护**：调用『受保护分支』查该仓库的 protected list，与当前分支精确比对。
3. **上游为保护分支**：`git rev-parse --abbrev-ref @{u}` 落在上面任一保护分支（说明 HEAD 还在 master 上）。

> 保护分支不可豁免——这是为了防住 prompt injection、笔误、误操作。要在主干上动手是另一个工作流，请用户切完特性分支后再来。

阶段 2、阶段 6 进入前、push 前各做一次校验。

## 执行工作流（SOP）

### 阶段 0 · 触发校验

确认用户是显式触发。如果只是顺嘴提了一下"那个 MR 评论怎么样"，先一句话确认："要我现在跑完整的 MR 评论修复流程吗？" 得到肯定再继续。

### 阶段 1 · 仓库范围定位

目标：找出**本次会话中你实际改动过的所有仓库根目录**。OpenSpec-style SDD 多仓提案经常一次改 2~N 个仓库，漏一个就漏一组评论。

依次合并去重：

1. **会话回放**：扫描本次会话所有 `Edit/Write` 的文件路径，按 `git rev-parse --show-toplevel` 归并到仓库根。
2. **当前 cwd**：cwd 是 git 仓库则加入候选。
3. **提案推断**：若有 `openspec/changes/<name>/` 或 `specs/<name>/`，读其 `tasks.md` / `design.md` / `plan.md`，解析提到的仓库路径加入候选。
4. **改动确认**：逐仓库跑 `git status --porcelain` + `git diff --name-only`（含已提交未推送：`git log @{u}..HEAD --name-only`）。无改动的剔除。

> 找不到任何改动仓库时**询问用户**，不要硬猜。

把"仓库路径 + 当前分支"列表给用户确认后进入阶段 2。

→ **Checkpoint 1**：已持有用户确认的"仓库 + 分支"二元组列表，每项都有真实改动。

### 阶段 2 · 分支与 MR 锁定

对每个仓库：

1. **保护分支三道闸**：按上文"保护分支铁律"做名称 / 远端 / 上游三处比对。命中即硬停。
2. **找 open MR**：调用『查 MR』，按 `repo + head_branch + state=open + limit=5`。
   - 0 个 MR：明确告诉用户"该分支无 open MR"，跳过该仓库——**不**为了"修评论"擅自创建 MR 或切分支。
   - 多个：列出来让用户挑。
3. **MR 与分支匹配校验**：拿到 MR 后必须满足 `source_branch == HEAD` 且 `target_branch != HEAD`。不一致硬停并报告差异。
4. **推送状态**：`git status -sb` 看是否落后/领先；本地有未推送 commit 时**只提醒**，不擅自 push。

→ **Checkpoint 2**：每个仓库都已 (a) 通过保护分支三道闸；(b) 唯一锁定一个 open MR 且分支匹配；(c) 推送状态对用户可见。

### 阶段 3 · 拉取并预处理评论

对每个 MR 调用『列评论』，把输出结构化成列表，每条 thread 抽取：

- `thread_id`、`path` / `line`（inline 时）、`author`、**作者类型（人工/机器人，判据见阶段 4）**、回复语言（中/英）。
- `state`：`open` / `resolved`。
- `body`：**整条 thread 所有 reply 都读完**，以最新一条**非 MR 作者本人**的意见为最终诉求；评论者已主动撤回（"OK / 算了 / nvm"）→ 归 A 类但允许直接 resolve。
- 是否 outdated：优先使用 provider 的 `comment_outdated_detection` 能力；provider 没有明确字段时，看 thread 关联的 `commit_id` / diff position 是否仍在 MR 当前路径上；推不出来时按 `unknown` 处理，并按 open/non-outdated 保守进入分类。

**只处理 state=open 且非 outdated 的评论**；outdated 的简要列出但不动。

→ **Checkpoint 3**：每个 MR 都已得到一份"open 且非 outdated"的 thread 列表，字段齐全。

### 阶段 4 · 单条评论分类与处置预案

对每条 open 评论先做三件事：

1. **看懂**：用一两句话复述这条评论"在说什么、想让我做什么"。看不懂归"需要澄清"，**不要硬猜**。
2. **核对**：用 `Read` 把 `path` 附近 ±30 行读出来，对照评论与当前实现做事实校验。
3. **判作者类型**：是**人工 reviewer** 还是**机器人/CI**？判断依据：author 名含 `bot / ci / lint / robot / aime / bits / mergebot` 等特征 → 机器人；否则人工；**拿不准一律当人工**（更安全，即不主动 close）。

然后按下表分类，并给出**三个独立动作（改码 / 回复 / close）的默认建议**——注意这些是**默认值，最终以阶段 4.5 用户确认为准**：

| 类型 | 触发条件 | 默认改码 | 默认回复 | 默认 close |
|---|---|---|---|---|
| **A 无效/误判** | 评论与现状不符 / 误指对象 / 建议本身有问题 | 否 | 是（拒绝+解释，贴事实/代码） | **否**（保持 open 留讨论） |
| **B 有效·低风险** | 改动局部、影响有限（rename、加注释、修小 bug、补 nil check 等） | **建议改（待确认）** | 是（已修复+一句话） | 机器人→是；**人工→否** |
| **C 有效·高风险** | 见下方启发式 | 看用户决策 | 看决策 | 看决策（人工默认否） |
| **D 答疑/咨询** | 评论本质是问"为什么这么写 / 这块逻辑是什么" | 否 | 是（解释+贴 `path:line`） | 机器人→是；**人工→否** |
| **E Nit/风格** | 纯个人偏好、无客观依据 | **否（默认放过）** | **否** | **否**（人工自己 close，技能不动） |

**close（resolve）总则**（极克制，优先级高于上表）：
- 🔴 **人工 reviewer 的评论：技能一律不主动 close**，留人工自己 close——哪怕已修复+已回复。除非用户在阶段 4.5 明确说"这条帮我 close"。
- **机器人/CI 评论**：已修复 + 回复后可自动 close。
- **评论者明确撤回**（"OK/算了/nvm"）：无论人工机器人都可 close。
- **E Nit**：默认不改不回复，**也不主动 close**（遵守"人工不 close"，晾着等人工自己 close）。

**C 类启发式**（"提示信号"，不是必要条件——纯机械跨文件改动如 rename / move / 加 import 即使触发也不入 C；要满足"且确实改变行为或契约"）：

- 触及公共 API / IDL / HTTP/RPC schema。
- 触及并发 / 锁 / 事务 / 缓存一致性 / 鉴权 / 数据迁移。
- 影响热路径或性能敏感代码。
- 改动跨 ≥2 个文件**且**会牵连下游模块的语义。

**最小改动**：每条评论的修复严格对应该评论；多条评论涉及同一文件时，分别记录各自对应的 hunk。

→ **Checkpoint 4**：每条 open 评论都已 (a) 打上 A/B/C/D/E 标签；(b) 标注作者类型（人工/机器人）；(c) 给出改/回复/close 三动作的默认建议。**此时尚未执行任何动作**——下一步先和用户对齐。

### 阶段 4.5 · 处置预案对齐闸（执行前必过）

**这是防止"自作主张改一堆"的关键闸。所有评论（不只 C 类）一次性给用户过目确认。**

终端打出**完整处置预案表**：

| # | MR/Thread | File:Line | 评论摘要 | 作者类型 | 分类 | 改码 | 回复 | close |
|---|---|---|---|---|---|---|---|---|
| 1 | #821/t3 | a.go:42 | 建议加 nil check | 人工 | B | ✓ | ✓ | ✗(人工自close) |
| 2 | #821/t5 | b.go:10 | 命名风格 | 人工 | E | ✗ | ✗ | ✗ |
| 3 | #821/t7 | c.go:88 | lint 未处理 err | aime(机器人) | B | ✓ | ✓ | ✓ |

然后**一次性**让用户审阅、逐条或批量调整，例如："2 不用管"、"5 改了但别回复"、"7 直接 close"、"C 类那条选方案2"。C 类的"修/拒/延后"也并入这张表一起问，**不再单独一轮**。

- 用户**口头确认/调整即可，不写文件**。
- 用户未明确表态的条目，**按默认建议执行**；但凡用户说了调整，以用户为准。
- 得到确认前，**禁止进入阶段 5 的任何改码/回复/close 动作**。

→ **Checkpoint 4.5**：已持有用户确认（或默认采纳）的最终处置预案，每条评论的"改/回复/close"三动作均已定档。

### 阶段 5 · 应用改动 / 回复 / Resolve

**严格按阶段 4.5 确认后的预案执行三个独立动作，技能不再自作主张。** 按仓库为单位批量处理：

1. **改前再校验**：对每个仓库重跑 `git rev-parse --abbrev-ref HEAD`，与阶段 2 锁定分支精确比对——这是"保护分支铁律"在第二个时间点的复查。不一致硬停。工作树有与本任务无关的脏改动 → 先告诉用户，得到"继续"再动手，避免把脏改动混进 review fix。
2. **改代码**（仅对预案标了"改"的条目）：用 `Edit`，每处改动都要能映射到具体某条评论；写入前再次确认目标路径在阶段 1 锁定的仓库根之下。预案标"不改"的（如 E nit、A 无效、用户说不用管的）→ **跳过，不动代码**。
3. **本地校验（Go 工程）**：对本次改动的 `.go` 文件调用 `mcp__gopls__go_diagnostics`（`files` 传绝对路径），并扫一眼 workspace 级 error。**不**调用 `go build / test / vet`。校验出新增 error → **不要 resolve** 该 thread；按"失败与回退"撤回改动，记账到阶段 6 报告。非 Go 工程可跳过，或做最轻量的 syntax 检查（`python -m py_compile`、`tsc --noEmit -p`）。
4. **回复评论**（仅对预案标了"回复"的条目）：调用 provider 的『回复评论』能力。预案标"不回复"的（如 E nit、用户说别回复的）→ **跳过**。若当前 provider 不支持远端回复（如 `no-provider`），不要伪造已回复，只在报告里标记 `not_supported_by_provider`。
   - **回复语言对齐 reviewer 原文**（中/英），不混用——同事看到混语言会觉得诡异。
   - 模板（按需裁剪、按语言翻译）：
     - 已修复：`已按建议修复：<一句话>。详见 commit <短sha> / 改动见 <path:line>。`
     - 拒绝/解释：`这里暂不修改：<原因>。相关上下文：<事实/代码引用>。如果还有不同意见欢迎继续讨论。`
     - 答疑：`这块的逻辑是：<解释>。代码位置：<path:line>。`
   - **回复后复读**：provider 支持时再次拉一次该 thread，确认新 reply 已落库——避免"以为发了其实没发"。
5. **Resolve thread**（仅对预案标了"close"的条目）：调用 provider 的『Resolve thread』能力。若当前 provider 不支持 resolve，报告为 `not_supported_by_provider`，不得臆造 close 状态。**close 铁律**（优先级最高，违反即越权）：
   - 🔴 **人工 reviewer 的评论：绝不主动 close**，哪怕已改已回复——除非用户在阶段 4.5 明确点名"这条帮我 close"。
   - **机器人/CI 评论**：已改 + 已回复后按预案 close。
   - **评论者明确撤回**：可 close。
   - 其余一律保持 open。
6. **Push / Commit（仅在用户明确要求时）**：默认**不**自动 commit / push。用户要求时，push 前**必须**再独立做一次保护分支闸：
   - `git rev-parse --abbrev-ref HEAD` 与阶段 2 锁定分支一致。
   - `git rev-parse --abbrev-ref @{push}` 解析的远端目标分支不在保护分支黑名单（防本地名安全但 `push.default = upstream` 把改动推到 master）。
   - **不**用 `--force` / `--force-with-lease`——会覆盖远端历史，对协作分支等同于"删别人的代码"，本场景没有合法用例。
   - **不**用 `git push <remote> HEAD:master` 这类显式覆盖主干形态。
   - 命中任何一条 → 立即终止。

   通过后执行 `git add -p` → `git commit` → `git push`。Commit message：

   ```
   fix(review): <一句话主题>

   - thread #<id> (<file:line>): <一句话改动>
   - thread #<id> (<file:line>): <一句话改动>
   ```

→ **Checkpoint 5**：每条预案标"改"的 thread 都已 (a) 改完且 gopls 无新增 error；(b) 标"回复"的已回复入库（已复读确认）；(c) 仅"机器人 + 标 close"或"用户点名 close"的被 resolve，人工评论一律保持 open。未授权动作（commit/push/approve/force-push）一律未发生。

### 阶段 6 · 汇总报告

终端输出结构化报告，6 项缺一不可：

1. **范围概览**：仓库 / 分支 / MR 编号（带 URL `https://code.byted.org/<repo>/merge_requests/<n>`）。
2. **评论处置矩阵**：表格列 `MR / Thread / File:Line / 评论摘要 / 作者类型(人工/机器人) / 类型(A~E) / 改码 / 回复 / close`——与阶段 4.5 确认后的预案一致。
3. **代码改动清单**：按文件汇总 `path:line_range` + 一句话改动摘要。
4. **未闭环 / 待用户决策**：所有保持 open 的 thread 与原因。**特别标注：人工评论已改已回复但按规则保持 open、留你自己 close 的项**（这是预期行为，不是遗漏），以及 C 类选了"延后/拒"的项。
5. **本地校验结果**：`mcp__gopls__go_diagnostics` 的 error/warning 概要；非 Go 工程说明做了哪些轻量校验。
6. **未做的事**：明确写出"未自动 commit / 未自动 push / 未自动 approve"等用户没要求的动作。

报告短、直接、用户能在 1 分钟内决定下一步。

### 阶段 7 · 归档到 OpenSpec-style SDD 提案目录（条件触发）

仅当本次会话工作在 OpenSpec-style SDD 提案上下文中时执行；否则跳过。

执行前**先 Read 一次 `references/archive_template.md`**，按其中的：

- 触发条件（哪些目录算"提案上下文"）
- 固定文件名 `<proposal_dir>/mr-comment-resolution.md`
- 首次创建骨架（含 `<!-- AUTO-INDEX -->` / `<!-- ENTRIES -->` 标记）
- 单次执行追加章节模板 + 索引行
- 幂等规则（同分钟续写、保留手工编辑、缺失标记自愈）

把阶段 6 的 6 项内容映射到模板对应小节，写入完成后在终端报告末尾追加一行：

```
📎 已归档到 openspec/changes/<name>/mr-comment-resolution.md（追加 1 节）
```

非提案上下文不要打印这行，避免误导。

> 多仓提案：每个仓库的处置在它所属提案目录的 `mr-comment-resolution.md` 里**各自成节**（`## ... · MR <repoA>#<n>` / `## ... · MR <repoB>#<n>`），不混在同一节。

## 失败与回退

- **改完本地校验失败**：撤回该处改动（`git checkout -- <file>` 或 `Edit` 还原），把这条评论降级为 C 类，告知用户。
- **评论已 outdated**：不处理，仅在报告中列出。
- **provider 异常输出**：按 `provider-contract.md` 分类处理。鉴权/版本/权限失败是 provider 环境问题，不当作评论处理结论；参数/能力不支持则在报告中标记并跳过对应远端动作。

## 调用入口示例

- `/fix-mr-comments`
- "帮我处理一下当前分支 MR 上的 review 意见"
- "把这次改动相关 MR 的评论跟一下，能修的修了，不该修的回复一下"
- "openspec 这一波改的两个仓的 MR 评论一起处理一下"

收到后按阶段 0 → 阶段 7 顺序执行（非提案上下文阶段 7 自动跳过），每个阶段结束给一行简短状态更新，减少噪音。
