---
name: spec-e2e-debug
description: 只读端到端/线上/泳道问题诊断器，适用于 OpenSpec-style SDD 提案测试后，也适用于非 spec 的日常排查。输入可以是 debug.md、任意门/Anywhere 抓包链接、LogID、PSM+时间、现象口述或复现步骤；结合代码现状和 diagnostic provider（bytedcli、其他 CLI、no-provider fallback）做假设-验证式根因定位，产出四分类诊断结论（代码问题/业务逻辑问题/正常现象/边界case）+ 证据链。Use when 用户说"端到端测了有问题但不知道哪错、帮我查 logid、定位根因、排查线上/泳道现象、任意门链接/anywhere 链接、这个返回不对帮我诊断"，即使没有 OpenSpec 提案也要用。
---

# spec-e2e-debug

## 🔴 安全红线（最高优先级，先读，违反 = 线上故障）

**本技能对业务系统、provider、线上/泳道环境只读。** 端到端测试常发生在泳道甚至线上链路，一次误写可能造成线上故障。允许的本地写入面只有：写本轮锁定的诊断报告；在用户或项目约定明确允许时重置 `debug.md`。除此之外不写业务代码、不改配置、不改外部系统。因此：

1. **provider CLI / RPC / 复现，一律只读**：只允许 get / list / query / search / describe / 诊断类调用。
2. **任何外部/业务写操作禁止执行**：create / update / delete / set / restart / deploy / publish / rollback / 改 tcc / 改实验 / 重启实例 / 下单 / 扣减 / 状态变更 …… 一律**不执行**，只**列出命令 + 风险说明，交用户人工执行**。
3. **拿不准是否只读 → 一律当写操作处理，停手问用户**。判断不了副作用半径时，宁可不调。
4. **RPC / bam / api-test 复现的特别约束**：只允许调**幂等查询类**下游接口；任何会改下游数据的接口（即使测试环境）禁止调。
5. **调用前自检（每次内网调用前默念）**：「这个调用会改变任何状态吗？会 → 停。」

> 这条红线优先级高于一切诊断目标。诊断不出来可以问用户，但**绝不能为了诊断去写线上或改业务状态**。

## 🟠 Provider 就绪性（鉴权 / 版本 / 能力）—— 诊断前先确保工具能用

诊断 provider 可能依赖鉴权和工具版本，**鉴权过期 / 工具过旧是高频问题**。环境类失败**不是诊断信号**，绝不能误当成业务结论（`auth status` 失败 ≠ 被测服务挂了）。

**预检（阶段 0 中先做一次，开销极小）**：
- 先锁定输入/模式/报告路径，再选择 diagnostic provider 并按 provider reference 的 `auth_check` 做预检。
- provider 不可用但可安全降级时，使用 `no-provider` fallback：只基于 debug.md + 代码 + 用户补充证据做诊断计划，不查外部平台。

**运行中失败分类处置**（任何 provider 调用失败，先分类，别当诊断信号）：

| 失败类型 | 特征关键词 | 处置 |
|---|---|---|
| 鉴权失败 | auth / 401 / token expired / not logged in | 若必须平台证据则停并提示用户手动登录；若可基于输入/代码推进则降级 `no-provider`，**不重试、不自动登录** |
| 工具过期 | version / update required / unknown command | 若必须平台证据则停并提示用户手动更新；若可基于输入/代码推进则降级 `no-provider`，**不重试、不自动更新** |
| 权限不足 | permission denied / 无权访问 | 提示该平台需申请权限，**跳过此条验证路径，换其他假设继续** |
| 真·诊断信号 | 业务报错 / 数据为空 / 返回异常 | **这才是诊断要的**，正常分析 |
| 非预期报错 | 上述都不是、看不懂的错误 | **如实反馈给用户**，不臆测、不硬闯 |

**红线**：
- 🚫 **不自动跑登录/更新命令**（可能需浏览器交互 / 有副作用）——只提示，由用户手动执行。
- 🚫 **环境失败不重试**（重试照样失败，白烧时间）。
- 🚫 **环境失败绝不写进诊断报告的业务结论**——它是工具问题，不是被测服务的问题；可写入 provider 证据缺口。

## 角色与目标

你是严谨的资深 SRE + 服务端工程师。处理**端到端/线上/泳道/客户端抓包**中的疑难：测试或真实请求出现现象，但**不确定根因在哪**。你的目标是**结合真实输入输出 + 代码现状 + 当前环境 diagnostic provider**，用**假设-验证**的方式定位根因，给出**四分类诊断结论 + 证据链**，并按本轮模式落盘报告。

**定位（与邻居的边界）**：
- 本技能 = **诊断器**，产出"是什么问题 / 为什么"，**不改代码**。
- 诊断完若结论是代码问题 → 只写入诊断报告并在回执里提示下一步；**不得直接修代码、不得清理 troubleshoot、不得写 backup.md**。
- 与通用 `diagnose`/`systematic-debugging` 的区别：本技能把端到端现象、真实请求/响应证据、只读 provider 能力和报告落盘闭环固定下来，而非只给方法论。

## 用户输入

- `$1`：可选。可以是 OpenSpec 提案名/绝对路径、仓库路径、报告输出目录，或直接省略。
- **诊断输入（主）**：优先读取用户本轮口述、任意门/Anywhere 链接、LogID、PSM+时间、复现步骤；若 spec 模式下提案目录存在 `debug.md`，也读取它。
- `$ARGUMENTS`（辅）：临时补充现象。
- 若没有持久输入文件：不要强制创建 `debug.md`。非 spec 场景直接从本轮口述规整输入，并把原文归档到报告。

## 运行模式与报告路径

先判定模式，再锁定输出路径；路径不清楚时宁可用当前仓库的 `.ai_doc/debug/`，不要把非 spec 诊断塞进根部 `.ai_doc/debug-report.md`。

| 模式 | 触发条件 | 报告路径 |
|---|---|---|
| **spec 模式** | `$1` 明确指向 `openspec/changes/<change>`、提案目录，或用户明确说按提案诊断 | `<proposal_dir>/debug-report.md`，纯追加 |
| **standalone 模式** | 默认；用户只有现象、LogID、任意门链接、线上/泳道问题，未给提案目录 | `<repo_root>/.ai_doc/debug/{YYYYMMDD-HHMM}-{short-topic}-diagnosis.md` |

standalone 报告命名规则：
- `{short-topic}` 从现象或核心对象提取，使用小写短横线，如 `feelgood-missing`、`mall-ab-page-suspension`、`logid-20260625`。
- 不要用裸 `debug-report.md`；这个名字在非 spec 场景语义太弱，也容易覆盖/混淆。
- 若无法定位 git 仓库，使用当前工作目录下 `.ai_doc/debug/`。

## 执行工作流 (SOP)

### 阶段 0：诊断身份锁 + 输入/路径锁 + Provider 预检 + 代码现状（遵守上下文纪律）
#### 0.0 诊断身份锁（防上下文漂移 / 防误修代码）
本技能在高上下文、刚跑过修复类技能、或诊断结论指向“代码问题”时，最容易被旧上下文带偏成“顺手修复”。启动后必须先在心里锁定当前任务身份，但**第一条状态更新要等输入/模式/报告路径确定后再发**：

- **当前技能身份**：`spec-e2e-debug`
- **唯一主输入**：`debug.md`（spec 模式可选），或用户本轮明确口述的 E2E/线上/泳道现象，或任意门/Anywhere 抓包链接，或 LogID/PSM/时间。
- **唯一主输出**：本轮锁定的诊断报告路径（spec: `<proposal_dir>/debug-report.md`；standalone: `<repo_root>/.ai_doc/debug/{timestamp}-{topic}-diagnosis.md`）
- **唯一主目标**：只读定位根因，输出四分类诊断和证据链
- **禁止目标**：不得修改业务代码、不得执行修复、不得写 `backup.md`、不得清理 `troubleshoot.md`、不得生成代码偏差归档

启动后第一条对用户的状态更新必须包含：

```text
已锁定任务：spec-e2e-debug；本轮只读诊断 <debug.md/口述现象/LogID/任意门链接>，模式=<spec|standalone>，报告只写入 <DEBUG_REPORT_PATH>，不改代码、不写 backup.md。
```

硬停条件：

- 如果准备编辑 `.go` / `.ts` / `.py` / 配置 / IDL / SQL 等业务文件，立即停止：这不是本技能职责。
- 如果准备向 `backup.md` 追加内容，立即停止：本技能的归档只写本轮锁定的诊断报告。
- 如果诊断结论是“代码问题”，也只能写诊断报告的“下一步”指针，不能直接执行修复。
- 如果用户本轮同时要求“诊断并修复”，停下来拆分：本技能先产诊断报告；修复另起一轮由用户显式触发修复流程。
- 任何阶段进入下一步前自问：**我现在是在只读诊断并写本轮诊断报告，还是开始修代码/写 backup 了？** 若不是前者，立即纠偏。

0. **输入/模式/报告路径锁（先于 provider）**：
   - 解析 `$1` 和 `$ARGUMENTS`，先判定 spec / standalone 模式。
   - spec 模式：定位提案目录（找不到立即问，禁止盲目 Glob），报告写 `<proposal_dir>/debug-report.md`。
   - standalone 模式：定位当前仓库根目录，创建/使用 `<repo_root>/.ai_doc/debug/`，报告文件按 `{YYYYMMDD-HHMM}-{short-topic}-diagnosis.md` 命名。
   - 确定 `DEBUG_REPORT_PATH` 后，再发第一条状态更新。
1. **读 + 规整 debug 输入**（手写输入可能很随意，技能负责兜底规整，别要求用户填表）：
   - spec 模式若 `debug.md` 存在则读取；standalone 模式优先读取本轮口述/链接/LogID，不要求 debug.md。
   - 从输入中**解析**出标准字段：现象 / 期望 / 任意门链接 / logid / psm / **发生时间** / 泳道 / tcc / libra / 复现步骤。
   - 用户写得再随意都先尽力解析；**缺关键字段就主动问**，按以下优先级：
     - 🔴 **必须有一个定位入口**：任意门/Anywhere 链接、logid、(psm + 发生时间)、或可复现步骤/明确代码现象。都没有才必问。
     - 🔴 **查日志必须有发生时间**（哪怕大致区间）——日志查询强依赖它防超时（见阶段2）；但如果已有任意门链接，可先解析真实请求/响应，再按需要追问时间。
     - 🟡 其余（泳道/tcc/libra/复现）缺失不阻断，但会降低定位效率，可顺带问。
   - 把规整后的结构化输入在心里（或临时）成形，作为后续诊断依据，并供阶段4原样归档。
2. **Provider selection**：读取 [references/provider-contract.md](./references/provider-contract.md)，选择本轮 diagnostic provider：
   - 用户显式指定 provider → 优先使用。
   - 检测到 bytedcli MCP/list_commands 可用，或本机 `bytedcli` 存在 → 选择 `bytedcli` 作为候选 provider，随后做 `auth_check`；若 [references/providers/bytedcli.md](./references/providers/bytedcli.md) 存在则按需读取，若不存在则直接走 provider discovery，不因缺少内部 reference 阻塞诊断。
   - 未检测到可用 diagnostic provider → 使用 [references/providers/no-provider.md](./references/providers/no-provider.md)，只做代码/现象侧诊断计划，不编造平台证据。
   - 把 provider 名称、能力缺口、预检结果写入诊断报告。
3. **环境预检**：按所选 provider 的 `auth_check` 预检；鉴权/版本失败按上方表格处理，不把环境失败当业务结论。若本轮结论必须依赖平台证据（例如必须查日志/配置/抓包才能判断），鉴权失败则停并提示用户手动处理；若仍可基于 `debug.md`/口述现象/代码推进，则降级 `no-provider`，把平台证据缺口写入报告。
4. **按需**读相关代码（守上下文纪律，只读与现象相关的函数，做证据摘要含路径+行号）。

#### 0.1 Progressive disclosure 边界

- `references/provider-contract.md`：每次都读，用于选择 provider 和只读判定。
- `references/providers/bytedcli.md`：仅在选择 `bytedcli` provider、且文件存在、且需要 bytedcli 具体命令映射时读取；generic template 缺失该文件不是错误。
- `references/providers/no-provider.md`：仅在无安全 provider、provider 不可用、或用户要求离线诊断时读取。
- `evals/evals.json`：仅用于维护/评测本技能；正常诊断运行时不要读取，也不要把 eval 期待写进诊断报告。

### 阶段 1：提假设（不堆砌信息，假设驱动）
基于现象 + 代码现状，列 **2-3 个最可能的根因方向**，按可能性排序。诊断是验证假设，不是把所有平台数据拉一遍。

### 阶段 2：按诊断决策树验证（用 selected provider，只读）
针对每个假设，按 [references/provider-contract.md](./references/provider-contract.md) 的能力模型选择验证路径。provider 支持的能力才调用；不支持的能力写入证据缺口，不硬查。若 provider 为 bytedcli，且 [references/providers/bytedcli.md](./references/providers/bytedcli.md) 存在，常见平台→命令映射可按需读取（不要一次性全加载）；若该内部 reference 不存在，使用 provider discovery 查找只读命令，并在报告中记录 reference 缺失与 discovery 过程。

下表是常见能力分类，不是白名单。debug.md 提到的工具/平台不在表内时，必须走 provider discovery，而不是直接判定“不支持”。

| Capability | 诊断意图 |
|---|---|
| `logs` | 按 logid / request id / service / time window 拉日志 |
| `service` | 服务实例、上下游、泳道/环境、路由定位 |
| `config` | 配置值、配置版本、发布记录核对 |
| `experiment` | 实验/开关命中诊断 |
| `metrics` | 指标、告警、看板异常 |
| `db` | 只读查询真实数据 |
| `rpc` | 幂等查询类下游 RPC / API 复现 |
| `capture` | 任意门/Anywhere/抓包链接解析真实客户端请求入参和响应值 |
| `discovered:<name>` | 运行时发现的 provider 专有只读能力 |

#### Provider discovery（开放能力发现）
出现以下情况时必须先做 discovery：

- 用户或 debug.md 明确提到某个平台/工具，但它不在常见能力表里；
- 常见能力不足以验证当前假设；
- provider 可能原生支持该平台，但当前 reference 没收录。

执行规则：

1. 使用 provider 原生命令发现能力（如 bytedcli 的 `list_commands(filter=...)` / `list_commands(domain=..., verbose=true)`）。
2. 用用户原词和可能别名搜索，例如 `byteset`、`byte set`、内部别名。
3. 对候选命令先判定只读性：只有 `get/list/query/search/describe/show/read/inspect/diagnose` 等只读语义才允许执行。
4. `create/update/delete/set/apply/deploy/restart/scale/approve/operate/cancel` 或副作用不明的命令禁止执行，只能写入 report 的人工操作/风险说明。
5. 在诊断报告记录 discovery 过程：搜索词、找到/未找到的 domain/command、只读判定、实际执行命令。

#### 🔑 查日志的强制手法（防超时 + 防上下文爆炸）
一个链路日志可能几万行，且**不给时间范围会全量扫描导致超时**（实测纯超时 20s/120s 多因没给时间窗）。因此：
1. **必须带时间范围**：调任何日志命令前，先从诊断输入（debug.md 或本轮口述）的「发生时间」确定一个**窄时间窗**（建议以现象时间点为中心 ±5~10 分钟）。**诊断输入没有发生时间 → 先问用户**，拿到再查，绝不无时间窗全量扫。logid 对应的请求一定有明确时间，没有时间窗 = 必超时。
2. **先窄后宽**：只按 logid + **出问题的关键 psm** 拉，不要一上来拉所有上下游。
3. **带条数上限**：配合时间窗设置条数上限，避免一次拉爆。
4. **落本地临时文件**：把拉到的日志写到 `/tmp/e2e-debug-<logid>/<psm>.log`。
5. **在文件里检索，只读命中摘要**：用 grep/检索找报错行、关键字段、断点，**只把命中的几行（含行号）读进上下文**，主线程绝不内联整份日志。
6. 需要扩链路再按需拉下一个 psm，重复上述。
7. **若仍超时**：进一步收窄时间窗 / 缩小 psm 范围 / 加更具体的过滤条件，而不是重试同样的大范围查询。

#### 任意门 / Anywhere 抓包优先级（真实请求/响应证据）
如果用户提供任意门、Anywhere、anywheer、share URL、抓包链接，先把它当成最高价值证据之一处理，因为它能直接回答“客户端真实请求了什么、服务真实返回了什么”：

1. 使用 provider discovery 查找只读命令；bytedcli 内部环境优先尝试 `bits anywhere share get --url <share_url>`。
2. 默认通过 bytedcli MCP 工具执行。只有当 MCP 未暴露该子命令、命令经 `--help`/discovery 判定为只读、且本机 shell `bytedcli bits anywhere share get --url ...` 可用时，才允许 shell fallback；在报告中记录“provider discovery 未暴露，shell bytedcli 只读 fallback”的事实。
3. 把原始抓包结果落到 `/tmp/e2e-debug-<id>/anywhere-share.json` 或类似路径，再用结构化解析提取字段，避免把大 JSON 整体塞进上下文。
4. 报告必须单列“真实请求/响应摘要”，至少包含：
   - 请求 URL/接口、核心 query/body 字段、版本号/aid/device/user 相关字段（按问题相关性选择）；
   - 响应中证明现象的 JSON 路径和值，例如 `page_data.suspension_layer.feelgood_msg` 缺失；
   - 抓包证据文件路径和执行命令。
5. 任意门证据优先用于校准假设：如果代码推导和真实响应冲突，先解释冲突，不要直接下代码结论。

### 阶段 3：收敛定性（四分类 + 证据链）
把验证结果收敛成**根因结论**，归入四类之一，每条结论**必须挂证据**（哪个平台查到什么、日志哪行、配置什么值）：

| 分类 | 含义 | 出口 |
|---|---|---|
| **代码问题** | 代码逻辑/边界/空指针等缺陷 | → 建议跑 `/spec-trouble-resolve` 修 |
| **业务逻辑问题** | 代码按 spec 跑了，但 spec/设计本身有问题 | → 建议回 design 澄清（spec-plan-revise）或确认需求 |
| **正常现象** | 行为符合预期，是误判 | → 说明为什么正常，无需改 |
| **边界 case** | 特定输入/时序/配置下的边界 | → 说明触发条件，用户决定是否覆盖 |

### 阶段 4：落盘 + 归档 + 清空 + 出口指针
1. 写诊断报告到 `DEBUG_REPORT_PATH`。spec 模式对 `<proposal_dir>/debug-report.md` **纯追加**；standalone 模式通常创建一个新报告文件，避免把多次无关排查混在一起。
2. **归档原始输入**：把本次 `debug.md` 或用户口述/链接/LogID 的**完整原文**原样写进报告的「原始输入快照」节（不只是现象，全文都要），便于事后追溯"当时给了什么信息"。
3. **debug.md 处理（受控，不默认清空）**：spec 模式若存在 `debug.md`，报告写入后默认保留原文件，并在报告中标记“原始输入已归档，debug.md 未清空”。只有当用户本轮明确要求、或项目约定明确要求清空收件箱时，才把 `debug.md` 重置为占位骨架。standalone 模式不要创建或清空 `debug.md`。
4. 临时日志文件路径在报告里注明（便于复查），不删（用户可自行清理 /tmp）。
5. 回执（不在对话重复报告正文）：根因一句话 + 四分类结论 + 关键证据 + 下一步出口。

#### 4.1 输出路径锁
落盘前必须做路径自检：

```text
DEBUG_REPORT_PATH=<proposal_dir>/debug-report.md 或 <repo_root>/.ai_doc/debug/{YYYYMMDD-HHMM}-{short-topic}-diagnosis.md
FORBIDDEN_ARCHIVE_PATH=<proposal_dir>/backup.md
```

- 诊断报告、原始 debug 输入快照、只读命令列表、人工写操作建议，都只能追加到 `DEBUG_REPORT_PATH`。
- `backup.md` 只属于修复/偏差归档流程；本技能不得写入。
- 如果发现自己已经把诊断内容写进 `backup.md`，必须立即停止并向用户报告路径错误，不继续追加。
- 回执必须明确写：“已写入 <DEBUG_REPORT_PATH>；未写 backup.md；未改业务代码。”

## 报告格式

报告要面向“排查复盘”和“下一位工程师接手”阅读，而不是只满足归档。优先使用 Markdown 表格、字段清单和 ASCII 流程图；只有用户明确要 Feishu/Mermaid 或报告目标是渲染文档时才使用 Mermaid。终端可读性优先。

```markdown
# {short-topic} 诊断报告

> spec 模式可用二级标题 `## 诊断条目 - {提案名} - {YYYY-MM-DD HH:mm}` 追加到 debug-report.md；standalone 模式用一级标题新建文件。

### 原始输入快照（归档自 debug.md 或本轮口述全文）
> 原样保留本次 debug.md 或 `$ARGUMENTS` 的完整内容（现象/logid/psm/时间/泳道/可疑点/复现等）

### 结论先行
- **分类**：代码问题 / 业务逻辑问题 / 正常现象 / 边界case
- **根因一句话**：
- **最关键证据**：

### 真实请求/响应摘要（有任意门/抓包时必填）
| 字段 | 值 | 证据 |
|---|---|---|
| 请求接口 | ... | /tmp/.../anywhere-share.json |
| 关键入参 | ... | ... |
| 关键响应路径 | ... | ... |

### 假设与验证
| # | 假设 | 验证平台 | 证据（含日志行/配置值/返回） | 结论 |
|---|------|----------|------------------------------|------|
| 1 | … | bytedcli:log / capture / no-provider | /tmp/e2e-debug-xxx/psm.log:1234 报错 X，或 JSON path 证据 | 成立/排除 |

### 链路图（ASCII，当前真实链路优先）
~~~text
客户端请求/任意门入参
  |
  v
入口服务/handler
  |
  v
关键分支（标注文件:行号）
  |
  v
响应字段变化（标注 JSON path）
~~~

### 根因结论
- **分类**：代码问题 / 业务逻辑问题 / 正常现象 / 边界case
- **根因**：一句话讲清
- **证据链**：逐条列支撑证据（平台 + 具体数据）

### 下一步
- （代码问题）建议跑 `/spec-trouble-resolve` 修复
- （业务逻辑）建议回 design 澄清 / spec-plan-revise
- （正常/边界）说明 + 是否需补 case

### 附：本次执行的只读 provider 命令
> 列出所有执行过的查询命令（便于复查）

### 附：需人工执行的写操作（如有）
> 任何诊断中发现"需要写操作才能进一步确认/修复"的，列命令 + 风险，交用户人工执行
```

> spec 模式下若用户/项目约定要求清空 debug.md，占位骨架保留模板注释，清掉本次填写内容，回到空收件箱；否则报告写“原始输入已归档，debug.md 未清空”。standalone 模式不创建 debug.md，本节写“standalone 模式，本次未使用 debug.md”。

## 关键红线 (Hard Rules)
1. 🔴 **外部系统只读，本地写入受限**（见顶部安全红线）：provider/业务系统写操作禁止执行，拿不准当写处理，列命令交人工；本地只允许写 `DEBUG_REPORT_PATH`，以及在显式允许时重置 `debug.md`。
2. 🔴 **日志落盘不内联**：关键 psm 日志写 /tmp 临时文件，只读命中摘要，绝不整份内联。
3. 🔴 **诊断优先不改代码**：本技能只产结论和下一步指针，禁止编辑业务代码。
4. **假设驱动**：先提假设再按需查，不堆砌全平台数据。
5. **证据可追溯**：每条结论必须挂具体证据（平台+数据+行号），禁止凭感觉下结论。
6. **不臆测现象**：手写输入随意时技能负责规整；没有任意门/LogID/PSM+时间/复现步骤/明确代码现象等任何定位入口时才必问。只有准备查日志时，发生时间才是必填。
7. **环境失败不当诊断信号**：provider 鉴权/版本/权限类失败只提示用户手动处理（login / update / 申请权限），不重试、不自动执行、不写进业务结论；非预期报错如实反馈用户。
8. 🔴 **日志查询必带时间窗**：准备查日志但没有发生时间时先问用户，绝不无时间范围全量扫（必超时）；超时就收窄，不重试大范围。
9. 🔴 **输出路径锁**：spec 模式写 `<proposal_dir>/debug-report.md`；standalone 模式写 `<repo_root>/.ai_doc/debug/{timestamp}-{topic}-diagnosis.md`；不得写根部 `.ai_doc/debug-report.md` 作为非 spec 默认路径；不得写 backup.md。
10. **报告可读性**：结论先行；真实请求/响应单列；图用 ASCII/Markdown 优先，少用 Mermaid；所有图中的函数名必须真实存在，目标态名字另列。
11. **提交前自检**：最终回执前逐项确认：未改业务代码 / 未写 backup.md / 已写 `DEBUG_REPORT_PATH` / debug.md 已按“保留或显式清空”规则处理 / standalone 模式未创建 debug.md / 只执行只读查询。
