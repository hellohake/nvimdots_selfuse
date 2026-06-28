# `spec-workflow-retro.md` Template

Read this file only when writing or incrementally merging `<proposal-dir>/spec-workflow-retro.md`.

```markdown
# Spec 工作流复盘原料 - {提案名}

> 本文件由 spec-opti-workflow 生成并维护，是飞轮的“复盘产料端”。
> 支持多次增量执行，历史沉淀永不覆盖。坑点入库请走 `gotchas` 技能；技能落地需人工审核。

## 📜 执行记录 (Run Log)
| # | 时间 | 新增语料 | 本次变更 |
|---|------|----------|----------|
| 1 | 2026-06-12 | 初次生成（spec.md / backup.md） | 新增 X 条 |

## 🎯 核心认知偏差 (Cognitive Gap)
- **[2026-06-12]** 一针见血的 Gap。

---

## 一、代码风格偏好（坑点候选来源）
**[风格项：例如 错误处理优先卫语句]** <!-- added: 2026-06-12 -->
- 🚩 触发场景 when：…
- ✅ Do：…
- ❌ Don't：…
- 📌 依据：backup.md 第 N 次反复修正
> 标注【建议入 gotchas】的项，复盘后用 `gotchas` 技能蒸馏。

## 二、AGENTS.md Patch Plan（不直接改文件，人审 diff 后再应用）
> 只处理满足 AGENTS hard gate 的 always-on 规则。场景化经验由 `gotchas` 技能治理，不在这里重复入库。
> AGENTS hard gate：`always_on + high_loss + not_obvious + short_rule` 全为 yes 才能 `Decision=propose_patch`。
> 标准目标区域：
> ```markdown
> ## AI Agent Operating Rules
> <!-- AI-RULES:START -->
> <!-- AI-RULES:END -->
> ```
>
> 首次适配规则：
> - 若 `AGENTS.md` 不存在：`Action=create_file`，生成最小 AGENTS.md + 上述标准区域。
> - 若没有 `## AI Agent Operating Rules`：`Action=append_section`，建议插入在项目说明/核心工作流之后、详细规范之前；patch 必须给出真实上下文。
> - 若有 section 但没有 marker：`Action=add_markers_and_patch`，保留原 section 内容，在 section 内补 `AI-RULES` marker，再追加/合并规则。
> - 若 marker 已存在：`Action=patch_inside_markers`，只允许在 marker 内 append/rewrite/merge，禁止改动 marker 外内容。
> - 若 `AGENTS.md` 很长、结构混乱、或无法确定安全插入点：`Decision=needs_human`，只给 1-2 个候选位置和理由，禁止臆测插入。
>
> 状态：`[ ] proposed` / `[ ] needs_human` / `[x] applied YYYY-MM-DD` / `[x] rejected YYYY-MM-DD` / `[x] skip_gotchas` / `[x] skip_redundant`。

### AIP-001 · <短标题> <!-- added: 2026-06-12 -->
- Status: `[ ] proposed`
- Decision: `propose_patch | skip_gotchas | skip_redundant | needs_human`
- Target: `AGENTS.md`
- Action: `create_file | append_section | add_markers_and_patch | patch_inside_markers | rewrite | merge | none`
- Section: `AI Agent Operating Rules`
- Rule ID: `AR-001`
- Gate:
  - always_on: `yes/no` — <一句话理由>
  - high_loss: `yes/no` — <一句话理由>
  - not_obvious: `yes/no` — <一句话理由>
  - short_rule: `yes/no` — <一句话理由>
- Duplicate check:
  - Existing similar rule: `<none | AGENTS.md:line | 内容摘要>`
- Patch:
  ```diff
  <基于真实 AGENTS.md 上下文生成的最小 diff；首次无 section 时包含 section + marker>
  ```
- Human review:
  - `approve / reject / rewrite`

### AIP-002 · <不进 AGENTS 的候选示例> <!-- added: 2026-06-12 -->
- Status: `[x] skip_gotchas`
- Decision: `skip_gotchas`
- Reason: <未满足 always_on 或 short_rule，属于场景化技术坑>
- Next: 由 `gotchas` 技能按标签治理；本技能不写 gotchas。

> 若本次没有满足 hard gate 的 AGENTS patch，写：“本次无 AGENTS.md Patch Plan，原因：…”。仍可列出 `skip_gotchas/skip_redundant`，说明为什么不进 AGENTS。

## 三、可复用资产候选（仅描述，不产文件）
| 候选名 | 类型 | 触发场景 | 是否值得做成 skill/command | 状态 |
|---|---|---|---|---|
| xxx | skill候选 | 新增 XX 素材的固定步骤 | 待用户审核 | added:2026-06-12 |
> 本技能不生成技能文件。用户认可后自行 copy 到 ~/.agents/skills/<name>/SKILL.md。
> 若本次无候选，写：“本次无可复用资产候选，原因：…”

## 四、架构与设计思路反思
**[遗漏点：例如 边界映射]** <!-- added: 2026-06-12 -->
- 现象：…
- 根因：…
- 下次如何前置规避（可加进 brainstorm/spec/grill-spec 检查项）：…

## 五、下次 Spec 开发 Checklist（精简版）
- [ ] <!-- added: 2026-06-12 --> …

## 六、输入侧复盘（提示词质量）  <!-- 仅当传入 $2 提示词文档路径才生成 -->
> 原始输入快照：./intake.md（源：<$2 路径>）

### 6.1 问题归因分布
| backup 问题 | 归因 | 依据 |
|---|---|---|
| <问题1> | ①提示词 | intake#clarify 留了“mg 取名待定”悬空点 |
| <问题2> | ②隐性知识 | 项目惯例：素材 ID 不应硬编码 |
| <问题3> | ③实现失误 | 已说清、知识够，纯疏忽 |

本次：①50% ②33% ③17% → 主要矛盾在【提示词】

### 6.2 提示词改进建议（针对 ① 类）
**[pmt-ambiguity]** <!-- added: 2026-06-12 -->
- 🚩 现象：intake 里“mg 取名现在也不确认”
- ✅ 改进：要么先定名，要么明确“请调研后给候选让我确认”，不留悬空
- 📈 prompting.md 晋升候选：[是/否]
```

第六节仅在 `$2` 传入时生成；未传 `$2` 且用户确认跳过时，整节省略，并在回执里说明已按用户确认跳过输入侧复盘。
