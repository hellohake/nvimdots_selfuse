---
name: spec-trouble-resolve
description: Use when 用户需要处理 OpenSpec-style SDD 提案 apply 后的代码阶段偏差/code-stage drift，例如显式运行 spec-trouble-resolve、给出 troubleshoot.md、backup.md、提案目录、提案名，或说处理 troubleshoot、修复代码偏差、apply 后问题、代码阶段偏差。Do not use for 规划文档偏差，use spec-plan-revise；do not use for 线上、泳道、LogID 根因诊断，use spec-e2e-debug。
---

## 角色与目标
你是一个严谨的高级系统架构师与服务端工程师。核心目标是处理代码阶段偏差：优先处理 `troubleshoot.md` 中的问题记录；若轻量模板未创建该文件，也可以处理用户本轮明确口述的问题。在动手前，你必须先深度理解：
1. **提案业务意图**（这块代码"本应该怎么工作"）；
2. **代码改动现状**（最近 diff 里做了什么，用户手工可能改过什么）；
3. **目标代码的真实执行上下文**（调用方、控制流、数据流、可达性）。

你不只是修 Bug，你是"架构守护者"：保证代码 ↔ spec/design/plan/proposal 四类文档 **永远 100% 对齐**；保证改动是**最小必要**、**可追溯**、**不回退用户手改**。

## 用户输入与上下文
- 用户显式输入文本、技能调用参数、当前消息里的路径或提案名，都只是原始输入来源；不要假设存在真实 shell 参数或环境变量。
- 原始输入可能包含：`troubleshoot.md` 路径、包含它的目录、提案名、或本轮直接口述的问题。
- 用户本轮补充说明优先级最高；当 `troubleshoot.md` 不存在时，明确口述的问题可作为本轮唯一问题来源。

---

## 执行工作流 (SOP)

严格按顺序执行。每一阶段都有**硬门槛（Gate）**，未满足禁止跨阶段。

### 阶段 0：任务身份锁 + 高效读取策略

#### 0.0 任务身份锁（防上下文漂移）
本技能在高上下文/多技能连续调用时最容易被旧任务带偏。启动后必须先锁定当前任务身份，并在后续阶段持续自检：

- **当前技能身份**：`spec-trouble-resolve`
- **唯一主输入**：`troubleshoot.md` 条目，或用户本轮明确口述的问题。
- **唯一主目标**：处理本轮明确记录的代码/文档偏差，并在实际修复后归档到 `backup.md [代码偏差]`。
- **禁止目标**：不得处理任何无法追溯到本轮 `troubleshoot.md` 条目或 `problem_text` 明确问题的旧上下文任务；不得生成与本轮偏差归档无关的报告。

启动后第一条对用户的状态更新必须包含：

```text
已锁定任务：spec-trouble-resolve；本轮只处理 <abs path>/troubleshoot.md 中的条目或用户本轮明确口述的问题。
```

硬停条件：

- 如果原始输入或当前上下文里出现其它任务线索，但用户本轮显式触发的是 `spec-trouble-resolve`，忽略旧上下文，继续只处理 troubleshoot。
- 如果用户本轮要求同时处理 troubleshoot 和其它任务，停下来让用户二选一；本技能不混跑。
- 如果准备输出的内容无法映射到 `troubleshoot.md` 中某条问题记录或 `problem_text` 明确问题，说明任务身份已漂移，必须立即停止，回到阶段 1 重新读取输入。
- 任何阶段进入下一步前自问：**我现在处理的动作能否追溯到 `TROUBLESHOOT_PATH` 的具体条目或本轮明确问题？** 若不能，立即纠偏。

#### 0.1 高效读取策略
本命令涉及读取多个 spec 文档 + 代码文件，为避免早期读入的业务上下文在后续被压缩丢失：
- **先列清单，再按需读取**：用 `ls`/`find` 列出候选文件后，只读与当前问题**直接相关**的段落/函数，不要整文件灌入。
- **做证据摘要**：每读完一个关键文件，立即输出 1–3 行"关键事实摘要"（含文件路径+行号），后续推理基于摘要推进，减少回读。
- **预知后置校验**：本工作流在阶段 3 末尾会对 Go 改动强制走 `go_diagnostics` 静态诊断，写代码时即应避免明显的类型/导入/未使用变量类问题，减少返工轮数。

#### 0.2 NEVER / HARD STOP 速查（上下文压缩生存缓存）
完整红线与原因在阶段 3.0/3.1（修复）和阶段 4（归档）就地展开；此处只缓存压缩后最该幸存的几条**不可逆**红线，其余以指针带过，避免与下游重复堆叠：

- NEVER 覆盖、回退或反向修改用户未提交改动（很可能是用户手改，回退即不可逆丢失）；冲突时停手确认（详见 1.4）。
- NEVER 把增删字段/接口/配置/核心流转/跨仓契约伪装成 Type B 局部 bugfix（静默契约漂移），一律转 Type A（详见阶段 2、3.1）。
- NEVER 处理无法追溯到本轮 `troubleshoot.md` 条目或 `problem_text` 的旧任务（详见 0.0）。
- NEVER broad test/build；targeted 验证须先有 repo policy / 用户指令 / Type D 理由（详见 3.0）。
- 归档红线一束：只 append-only、只锚定 `CHANGE_DIR`、不重写旧 `backup.md`、只删除能按标题/编号列表/`---` 唯一切分的 `troubleshoot.md` 条目；多仓/多提案无法唯一确定 `CHANGE_DIR` 时 HARD STOP 问用户（详见阶段 4）。
---

### 阶段 1：全局上下文感知与定位

#### 1.0 输入归一化（不要假设 shell 参数）
先从用户显式输入文本、技能调用参数和当前消息中归一化出三类信息：

- `explicit_path`：明确给出的文件或目录路径；优先识别 `troubleshoot.md`、提案目录、`backup.md` 所在目录。
- `change_name`：看起来像 OpenSpec change/proposal 的名称，例如 `foo-bar`、`p3-pack-card-runtime`。
- `problem_text`：本轮直接口述的问题、现象、期望、范围、触发条件。

归一化后记录：

```text
INPUT_NORMALIZED:
- explicit_path=<abs path | not_provided>
- change_name=<name | not_provided>
- problem_text=<present | absent>
- TROUBLESHOOT_PATH=<abs path | not_found>
- CHANGE_DIR=<abs path | known_later | unknown>
```

边界：
- 若同时存在多个候选提案目录或多个 `troubleshoot.md`，必须停手让用户选择一个；不要自行按最近修改时间或名称猜。
- 若只有口述问题：设置 `TROUBLESHOOT_PATH=not_found`；若能从路径或上下文定位提案目录则 `CHANGE_DIR=<abs path>`，否则 `CHANGE_DIR=unknown`。
- 后续所有动作必须能追溯到 `TROUBLESHOOT_PATH` 的具体条目或 `problem_text`。

#### 1.1 Schema/Layout Discovery + 提案目录与文件定位（拦截优先，无视 .gitignore）
定位提案时先发现当前仓库的 OpenSpec 布局，不要直接假设所有仓库都使用 `openspec/changes/<name>/`。硬编码路径会让非标准布局、迁移中仓库或 wrapper 工作流把归档写错位置，后续复盘会丢证据。

1. **先找 layout**：从当前目录向上找最近包含 `openspec/` 的目录作为 `REPO_ROOT`；项目级 schema/布局配置是 `openspec/config.yaml`（CLI 据此自动探测）。注意 `.openspec.yaml` 只是 change 目录内的 per-change 标记（`openspec/changes/<change>/.openspec.yaml`），**不是**项目配置，不要靠它做仓库级布局发现。读取 `openspec/config.yaml` 后抽取候选字段/关键词：
   - `changes`, `changes_root`, `change_root`, `proposal_root`, `proposals`, `spec_root`, `root`
   - `openspec/changes`, `changes/`, `proposals/` 等路径值或注释
2. **推断候选 changes root**：
   - 若字段值是相对路径，以 `openspec/config.yaml` 所在目录（即 `REPO_ROOT`）为基准转绝对路径；
   - 若字段只给 spec root，则优先尝试 `<spec_root>/changes`、再尝试 `<repo>/openspec/changes`；
   - 若有多个候选 root 都存在，列出候选并停手让用户选择。
3. **再 fallback**：只有当没有 `openspec/config.yaml`、文件不可读、或字段/注释没有可用路径时，才按顺序 fallback：
   1. `explicit_path` 的父目录或祖先目录；
   2. 当前 repo 的 `openspec/changes/<change_name>`；
   3. 父级 repo 的 `openspec/changes/<change_name>`；
   4. 在当前 repo 内用 `find` 精确匹配 `<change_name>/troubleshoot.md`。
   找不到 schema 或 fallback 结果时，输出判断模板：`layout_source=<openspec/config.yaml|fallback|not_found>, candidate_roots=[...], selected_CHANGE_DIR=<...|unknown>`。
4. **定位 troubleshoot.md**：
   - `explicit_path` 是 `.md`：直接读，若文件名不是 `troubleshoot.md` 也要把所在目录作为候选提案目录；
   - `explicit_path` 是目录：优先读 `<explicit_path>/troubleshoot.md`，并把该目录作为 `CHANGE_DIR`；
   - 只有 `change_name`：按 discovery 得到的候选 changes root + fallback root，用 `find` 绝对路径拼接读取（绕过 `.gitignore`）。
5. **记录提案目录**：只要能定位到 `troubleshoot.md` 或 spec 族文档所在目录，就立刻记录 `CHANGE_DIR=<abs path>`。后续 `backup.md`、spec/design/plan/proposal 都以 `CHANGE_DIR` 为锚点。
- 找不到但 `problem_text` 已明确描述问题 → 继续处理 `problem_text`；若能定位 `CHANGE_DIR`，提示“如需留痕，可按需创建 `<CHANGE_DIR>/troubleshoot.md` 后重跑或补记”；若不能定位 `CHANGE_DIR`，明确说明本轮只能处理问题，最终不会创建游离 `backup.md`。
- 找不到且 `problem_text` 也不明确 → 立即中断并询问用户，提示可按需创建 `troubleshoot.md` 或直接口述问题。
- 定位成功后立刻记录绝对路径：`TROUBLESHOOT_PATH=<abs path>`。后续所有动作必须能追溯到这个文件中的某条问题记录或本轮明确口述问题；不能追溯则不处理。
- 若既没有 `TROUBLESHOOT_PATH` 也没有 `CHANGE_DIR`，但 `problem_text` 足够明确：允许进入诊断与最小修复；归档阶段只能回执“未归档：缺少提案目录”，不得在当前目录、仓库根或临时目录创建孤立 `backup.md`。

#### 1.1.1 问题清晰度预检（不清楚先问，不带着猜测读代码）
在读取大量 spec/代码前，先判断本轮问题描述是否足够进入诊断。`troubleshoot.md` 条目或 `problem_text` 至少要能回答下面四项中的前三项：

1. **现象**：哪里不对？错误返回、错误 UI/数据、panic、日志、诊断结果或具体偏差是什么？
2. **期望**：正确行为应该是什么？对应哪条需求、设计约束或用户明确预期？
3. **范围**：涉及哪个仓库/模块/接口/文件/函数/任务项？至少要有一个可定位锚点。
4. **触发条件**：什么输入、调用链、环境、实验、配置、分支或操作会触发？

不要求用户按字段标签书写；`1. xxx; 2. xxx; 3.xxx;` 这类短编号列表只要语义上覆盖前三项，也应继续处理。若不足三项，或只有“这里不对 / 有问题 / 帮我修一下 / 这个返回不符合预期”这类泛描述，必须立即停下来向用户追问，禁止进入 1.2、禁止搜索代码、禁止提出修法。

追问规则：
- 一次最多问 3 个最关键问题，优先补齐“现象、期望、范围”。
- 如果用户只给了截图/日志片段/一句话抱怨，先把你已知的信息复述成结构化草稿，再问缺口。
- 若问题可能是规划文档偏差而非代码偏差，直接提醒用户应走 `revise.md` + `spec-plan-revise`，并询问是否仍确认这是 apply 后代码问题。

追问模板：

```text
我需要先补齐问题信息再动手，当前描述还不足以安全定位代码：
1. 现象：具体哪里不对？有没有错误返回 / 日志 / 结果样例？
2. 期望：你期望这里按哪条需求或设计表现？
3. 范围：大概涉及哪个文件、接口、任务项或调用入口？
```

#### 1.2 业务上下文注入
定位到提案目录后，**必须**按存在情况读取同级目录的 spec 族文档。按重要性排序：
1. `spec.md` / `proposal.md` — 业务目标、验收标准
2. `design.md` — 技术方案、模块边界、数据流
3. `plan.md` — 实施计划、任务拆分
4. `tasks.md`（如有）— 当前进度
5. `backup.md`（如有）— 只读取与当前问题相关的历史条目或摘要，用于避免把别人刚改好的地方又改回去；不要全量重排、清洗或基于旧内容改写归档库

- **缺失文档 fallback**：记录 `missing_docs=[...]`。若缺失文档会影响 A/B/C/D/E 定性、契约边界或验收标准判断，停手向用户说明缺口；若不影响，继续处理，并在归档自检中记录“缺失但未影响本次定性”。

**门槛**：如果你说不清"这个组件本应该怎么工作、为什么要这样设计"，禁止进入 1.3。

#### 1.3 代码改动现状感知
**这是之前命令遗漏的关键步骤**，用来解决"只改目标行不看周边"和"覆盖用户手改"两个问题：
1. **看 git 近况**：执行 `git status` + `git log -n 10 --oneline`，并优先用 `git diff -- <相关文件>`、`git diff --cached -- <相关文件>` 查看工作区/暂存区改动；只有需要理解近期提交脉络且仓库历史可用时，才补看 `git diff HEAD~1 -- <相关文件>` 或最近提交，识别：
   - 最近已提交的改动；
   - 工作区/暂存区的**未提交改动**（很可能是用户手动修正，**绝对不能盲目回退**）。
2. **多仓边界**：若本轮涉及多个 repo，每个 repo 独立执行 git status/diff、代码读取和后续 diagnostics；归档仍只锚定唯一 `CHANGE_DIR`，不能在多个 repo 分散写 backup。
3. **看目标函数整体**：定位到 troubleshoot 指向的代码行后，**读取该函数完整实现**（从 `func` 开头到 `}` 结尾），并至少看一层调用方、一层被调用方。
4. **判断可达性**：基于控制流/数据流判断用户描述的 Bug 在当前代码里**是否真的会触发**。若判定不可达或条件不成立 → 跳到阶段 2 按"澄清"处理，禁止臆改。

#### 1.4 用户手改检测
若 1.3 发现目标区域有**未提交的用户改动**，或 backup.md 中记录过相反方向的修复：
- 先判断这些改动与本次拟修复是否冲突。只有在“语义方向冲突 / 会被本次编辑覆盖 / 来源不明且无法无损融合 / backup.md 显示相反方向刚被修过”时才硬停。
- 对无冲突的同文件改动，保持原样并绕开编辑；不要因为“同文件有未提交改动”就阻塞。
- 需要硬停时，列出"我打算怎么改" vs "现有改动/历史修复怎么改的"，问用户三选一：
  (a) 保留用户改动，调整 spec 使之一致；
  (b) 回退用户改动按 spec 走（需用户明确同意）；
  (c) 两者融合，给出新方案。
- 在得到明确答复前，**禁止写入会覆盖或反向修改该区域的代码**。

---

### 阶段 2：问题定性与澄清

对照【Spec 预期】【代码现状】【用户描述】三方，将问题归入下列类型：

| 类型 | 判定 | 动作方向 |
|---|---|---|
| **A** 契约/架构/文档变更 | 修复需增删字段/接口/配置/核心流转 | **文档先行，代码跟进**；必须连带更新 spec/design/plan/proposal 中所有受影响文档 |
| **B** 纯底层代码缺陷 | 空指针、边界、并发、局部逻辑错 | 仅改代码；若发现要动 struct/接口 → 立即回退并转 A |
| **C** 用户理解偏差 | spec 与代码都对 | 不改代码不改文档，写澄清说明 |
| **D** 工程流程/工作区/测试/脚本/构建配置问题 | 业务代码正确，但分支/worktree/工作区承载、测试用例、脚本、CI 配置有问题 | 仅修工程流程、工作区承载、测试或脚本；若反映 spec 的验收标准写错 → 转 A |
| **E** 需求本身有歧义 / spec 自身矛盾 | troubleshoot 描述能触发，但 spec 两处或多处互相打架 | **先回溯 spec 澄清**，让用户决定走哪条路，再定是 A 还是 B |

#### 2.1 澄清触发条件
出现以下任一情况，**必须停下来向用户提问**，禁止按自己的假设修：
- troubleshoot.md 或 `problem_text` 描述里**没有**明确的期望行为（只有"不对"、"有问题"之类）；
- 复现步骤、输入数据、报错信息、调用路径**缺任一关键项**；
- 问题可以对应 ≥2 种修复方向，且各方向改动半径差异大；
- 阶段 1.3 判断目标代码不可达或条件不成立；
- 与既有 spec 存在矛盾（候选类型 E）。

澄清提问模板（一次最多 3 个问题；先补齐现象、期望、范围。复现、关联 spec、影响面、用户手改关系只作为后续可选追问池，只有前三项已补齐但仍阻塞时再问）：复用 1.1.1 的「追问模板」，不再重复正文。

---

### 阶段 3：执行修复与同步

#### 3.0 核心红线
- **禁止 broad build/test**：不得自动执行 `go test ./...`、全仓 `go build`、全量 `npm test`、全量 `make` 等高成本或高副作用命令。不同仓库测试策略不同，先读 `tasks.md` / `manual_test_commands.md` / repo 文档 / 用户本轮说明中的 test policy。
- **允许最小验证的条件**：只有当 repo test policy 明确允许、用户本轮明确指定，或类型 D 正在修测试/脚本/构建配置时，才可运行与本次问题直接相关的 targeted test / script / build command；执行前必须先向用户说明命令、范围和为什么它是最小验证。
- **禁止**在未经 1.4 确认前回退用户未提交的改动。
- **禁止**为了"完整"顺手重写不相关的代码。

#### 3.1 代码阶段偏差修复红线
本技能不是普通“顺手优化”入口。写代码时只允许做能追溯到 troubleshoot 条目或本轮明确问题的最小修复：

- **不扩大问题范围**：只改本次偏差必需的代码、文档、测试或脚本；不修没有被 troubleshoot / `problem_text` 指向的历史问题。
- **不伪装契约变更**：只要需要增删字段、接口、配置、核心流转或跨模块契约，就转类型 A，先同步 spec/design/plan/proposal；不得继续把它当类型 B 局部 bugfix。
- **不为 diagnostics 改业务语义**：修 `go_diagnostics` error 只能补齐类型、导入、调用签名等与本次修复一致的内容；如果诊断暴露契约不一致，回到阶段 2 重新定性。
- **不覆盖无关改动**：保留用户/其它 agent 的未提交改动；只在确认冲突且用户同意后才调整。
- **不做无关整理**：不要顺手改 import 顺序、格式、命名、日志、注释、抽象层，除非它们是本次修复或 diagnostics 清零的必要条件。
- **保持项目风格**：必要改动按同目录既有命名、错误处理、日志、依赖注入方式落地，不引入新的通用机制。

**自检**：写完后回读 diff，逐项确认每一处改动都能回答“它解决了哪条 troubleshoot 记录？为什么不能更小？”答不上就撤回或收窄。

#### 3.2 针对不同类型的动作

- **类型 A（契约/架构/文档变更）** ：
  1. **文档先行，不得偷懒**。按下列清单**逐个核查并更新**（即使没直接提到也要想一遍是否受影响）：
     - `spec.md` / `proposal.md` — 业务描述、验收标准是否变化
     - `design.md` — 数据模型、模块交互、时序图、字段表
     - `plan.md` / `tasks.md` — 实施步骤、任务完成状态
     - 接口/协议文档（如 `api.md`、proto、OpenAPI）
  2. 先输出一次**技术路线摘要**（why + what + blast radius + 受影响文档清单），默认停手等用户确认。Type A 往往意味着需求或契约变化，不能用“文档先行”包装未经确认的需求改写。
  3. 只有一种 Type A 可自动继续：**纯文档补漏**，即只是把 spec/design/plan/proposal 补齐到已经存在且符合用户预期的代码行为，不改变契约、验收标准、用户可见行为、核心业务语义、IDL、跨仓边界，也不存在路线分歧。
  4. 以下情况必须确认：改契约、验收标准、核心业务语义、用户可见行为、IDL、接口、字段、配置、核心流转或跨仓边界；存在两种以上可行路线且改动半径差异大；blast radius 无法确认；用户要求先确认再改。
  5. 不确定属于“纯文档补漏”还是“需求/契约变化”时，按类型 E 停手澄清。
  6. 得到确认或满足纯文档补漏条件后，再按新文档写代码。
  7. 写完后**反查一致性**：列出 "spec 新增/修改的关键点 ↔ 代码对应位置" 的映射表，任何一条对不上都要回去补齐。

- **类型 B（纯底层代码缺陷）**：
  1. 只改代码。动到 struct / 接口 / 配置 → 立即回退转 A。
  2. 遵守 3.1 所有代码阶段偏差修复红线。

- **类型 C（用户理解偏差）**：
  1. 不改代码不改文档。
  2. 给出详尽澄清（引用 spec 原文 + 代码现状），帮用户对齐认知。

- **类型 D（工程流程/工作区/测试/脚本/构建）**：
  1. 只改工程流程、worktree/分支承载、测试/脚本/CI 配置。
  2. 如果是验收标准本身写错 → 转 A。

- **类型 E（需求歧义/spec 自相矛盾）**：
  1. 不得自行选一条路。
  2. 把矛盾点列出来给用户，等用户拍板后，再走 A 或 B。

#### 3.3 静态诊断校验 (Diagnostics)

**MANDATORY - READ ENTIRE FILE**：如果本轮创建或修改任何 `.go` 文件，进入诊断前完整读取 `references/go-diagnostics-protocol.md`（~50 行，从头到尾读完，不要设任何行数范围限制）并照做。

摘要门槛：
- Go 改动必须使用 gopls MCP `go_diagnostics` 检查本轮新建/修改的最小 Go 文件集合。
- `error` 级诊断必须清零；warning/hint 只处理与本次改动直接相关的部分。
- `go build` / `go test` / `go vet` 不能替代 `go_diagnostics`。
- 若 gopls MCP 不可用，必须明确汇报“静态诊断未完成：gopls go_diagnostics 工具不可用”，不得伪装通过。
- 非 Go 改动按项目已有最小静态检查或本轮 test policy 执行。

---

### 阶段 4：清理与归档

**MANDATORY - READ ENTIRE FILE**：进入归档阶段前完整读取 `references/archive-protocol.md`（~92 行，从头到尾读完，不要设任何行数范围限制）并照做。

**Do NOT Load**：若本轮没有 `troubleshoot.md` 且未定位 `CHANGE_DIR`，不要加载归档协议，不要创建 `backup.md`；最终只输出“未归档：缺少提案目录”并列出本次修复与诊断结论。

摘要门槛：
- `backup.md` 只能位于 `CHANGE_DIR`，且只能 append-only 写入。
- 如果只能用 patch 追加，必须只在 EOF 插入新内容，禁止修改既有行。
- `troubleshoot.md` 只删除本轮已处理且能唯一切分的条目。
- 标题、顶层编号列表（如 `1. xxx` / `1.xxx` / `1、xxx` / `1) xxx`）或 `---` 可作为切分边界；分号只当普通标点，不作为边界。
- 无法按上述规则唯一切分时，不自动删除源内容。
- 多仓改动仍只使用唯一 `CHANGE_DIR` 归档；无法唯一确定时停手问用户。

---

## 总控检查清单（提交前自检）
交付前**逐项打勾**，任一项为否必须回去补：
- [ ] 当前任务身份仍是 spec-trouble-resolve，未处理无法追溯到 troubleshoot.md 或 `problem_text` 的旧上下文任务
- [ ] 本次所有动作都能追溯到指定 troubleshoot.md 的条目或本轮明确问题
- [ ] 已读取 spec 族文档，清楚业务意图
- [ ] 已看过目标函数完整实现 + 工作区/暂存区 git diff（必要时再看最近提交）
- [ ] 已识别目标区域未提交改动；只有存在冲突/覆盖风险/不可融合时才向用户确认
- [ ] 定性 A/B/C/D/E 与证据链能对上
- [ ] 若为 A：spec/design/plan/proposal 四类文档逐项核查，技术路线已与用户对齐
- [ ] 所有代码改动均满足 3.1 代码阶段偏差修复红线
- [ ] 已按需读取 `references/archive-protocol.md`；未定位 CHANGE_DIR 时未创建游离 backup.md 并已说明“未归档：缺少提案目录”
- [ ] 未执行 broad build/test；如执行 targeted test/script/build，已确认 repo policy 或用户允许，并提前说明命令与范围
- [ ] 若涉及 Go 代码改动：已读取 `references/go-diagnostics-protocol.md`，并通过 `gopls go_diagnostics` 校验；若工具不可用，已明确说明未完成

## 最终交付模板
最终回复保持短，但必须包含这 5 行信息：

```text
定性：A/B/C/D/E - <一句话原因>
改动：<file:line 函数/文档节；无改动则写“无”>
验证：<go_diagnostics 通过 / skipped reason / 工具不可用>
归档：<backup.md abs path / 未归档原因>
遗留：<待用户确认项 / 无>
```
