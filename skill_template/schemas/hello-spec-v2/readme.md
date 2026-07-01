# hello-spec-v2

`hello-spec-v2` 是面向复杂后端需求的 AI-native SDD 工作流模板：用磁盘提案目录承载 proposal/spec/design/tasks/plan，在其上叠加可审计的 AI 上下文纪律、DDD 澄清门、人工决策队列、经验飞轮、AI pre-commit review、手动测试命令台账和提交闭环。

完整设计说明见：

- `/data00/home/lihao.hellohake/.agents/.ai_doc/hello-spec-v2_workflow_design.md`
- `/data00/home/lihao.hellohake/.agents/.ai_doc/hello-spec-v2_workflow_summary.md`

## 快速链路

```text
brainstorm
  -> proposal / specs / design
  -> GATE-1: grill-with-docs via schema stage `grill-spec`
  -> tasks / plan
  -> hello-spec-apply
  -> spec-code-review
  -> human review
  -> spec-commit-push <proposal-name-or-absolute-proposal-dir>
  -> fix-mr-comments
  -> GATE-2: spec-opti-workflow + gotchas
```

说明：

- `grill-spec` 只是 schema stage id，不再有独立技能目录；实际澄清能力来自 `grill-with-docs`，并通过 schema 约束写入 `.ai_doc/spec-workflow/CONTEXT.md` 和 `.ai_doc/spec-workflow/adr/`。
- `hello-spec-apply` 是 `hello-spec-v2` 的推荐实现入口。它把 apply 请求视为 subagent 授权，按 plan slice 调度实现/审查，并禁止自动 commit。
- `spec-code-review` 是 apply 后、commit 前的 AI pre-commit review，只产 `spec-code-review.md`，不自动改代码。
- `manual-test-commands.md` 是提案级手动测试命令台账。任何阶段新增/修改测试文件，都要留下可复制 targeted test command。
- `human-decisions.md` 是执行期/审查期懒创建的人工决策队列，不替代 `grill-spec`。规划期需求/术语/边界不清走 `grill-spec`；apply/review/debug/MR 阶段暴露出的风险取舍，AI 先给推荐方案和选项，再写入本文件等人把关。
- `Agent Execution Audit` 是核心产物的审计段，用来证明本阶段遵守了 AI context discipline：读了哪些关键文件、是否内联大内容、下一步命令和 `/clear` 恢复命令是什么。
- `spec-commit-push` 推荐显式传提案名或绝对路径；空上下文不能唯一定位提案时必须停手询问。

## 推荐启动与推进方式

`hello-spec-v2` 继续复用 OpenSpec 的 change 目录、artifact status、`openspec instructions <artifact-id>` 和 apply 指令生成能力，但推荐用薄封装技能控制节奏，避免 fast-forward 绕过人工 gate。

## Schema 可用性预检

在目标业务仓库内使用 `hello-spec-v2` 前，先从仓库根目录确认 OpenSpec 能解析该 schema：

```text
cd <REPO_ROOT> && openspec templates --schema hello-spec-v2 --json
```

如果只看到 `spec-driven` 或报 `Schema 'hello-spec-v2' not found`，先把本模板同步/安装到目标仓库的 `openspec/schemas/hello-spec-v2/`，或安装到 OpenSpec 用户 schema 目录；不要用 `spec-driven` 代替执行。

推荐入口：

```text
hello-spec-start <change-name> <原始输入...>
hello-spec-start <原始输入...>  # 未显式提供 change-name 时，由技能根据原始输入推断 kebab-case 名称
hello-spec-next <change-name>
hello-spec-next  # cwd/context/唯一 active change 可唯一定位时可省略 change-name
hello-spec-apply <change-name>
```

使用约定：

- `hello-spec-start`：创建新 change，消费本轮原始输入（飞书链接、本地文档路径或直接粘贴的需求），只启动到第一个业务 artifact。可以显式传 `<change-name>`；也可以只传自然语言需求，由技能在状态变更前推断并回显 kebab-case `CHANGE_NAME`。它不写 `intake.md`，不创建 `source.md`，不进入 apply；高密度输入需要可重读的外部来源，无法读取时需用户确认降级。
- `hello-spec-next`：继续当前 change。可以显式传 `<change-name>` 或绝对提案目录；也可以省略名称，由技能从当前 cwd、上一轮 resume token 或当前 repo 唯一 active change 中解析。解析不到或多候选时必须停手询问。它只自动创建轻量 placeholder；业务 artifact 每次最多生成一个；到 `grill-spec` 时进入 gate mode，承接 `grill-with-docs` / `domain-modeling` 行为和 OpenSpec 指令约束；需要用户确认时优先用 `AskUserQuestion` / `request_user_input` 直接提问，Default mode 工具不可用时按 QID 批量提问（推荐回复 `Q001=A; Q002=B; Q003=自定义：...`，数字编号仅在 `design.md` 记录了 Asked batch 映射时可用）。用户回答先写回 `design.md` 和必要的 `.ai_doc/spec-workflow/` 文件；`grill-spec.md` 只能在所有阻塞问题完成后创建为 complete，pending 时创建该文件会让 OpenSpec 误判 gate 已完成。不得同轮生成 `tasks` / `plan`。
- `hello-spec-apply`：仅在用户本轮明确要求“开始实现 / apply / 按 plan 实现”后使用。它会进入代码实现阶段；对 `hello-spec-v2` 来说，这是推荐入口，负责 subagent 调度、no-commit、ledger reconcile、manual test command 和 human decision 阻塞。
- `openspec-apply-change`：保留为通用 OpenSpec apply 入口。若它解析到 `schemaName=hello-spec-v2`，应切换到 `hello-spec-apply`；只有用户显式给出 `SERIAL_APPLY=true` 或 subagent 工具不可用且未开始生产代码修改时，才允许按其通用串行 loop 降级。
- `openspec-verify-change` / `openspec-archive-change`：作为实现后的校验、归档动作使用，仍需结合 `spec-code-review`、人工 review 和 `spec-commit-push` 的约束。

推荐顺序：

```text
hello-spec-start <change-name> <原始输入...>  # 创建 change + placeholder + 可生成 brainstorm
hello-spec-start <原始输入...>  # 等价启动方式；缺省 change-name 时自动推断并回显
  -> hello-spec-next <change-name>  # proposal
  -> hello-spec-next  # 等价推进方式；上下文可唯一定位时可省略 change-name
  -> hello-spec-next <change-name>  # specs/design
  -> hello-spec-next <change-name>  # GATE-1: grill-spec gate mode（AskUserQuestion 逐项确认并落盘）
  -> hello-spec-next <change-name>  # tasks
  -> hello-spec-next <change-name>  # plan
  -> human review
  -> hello-spec-apply <change-name>
```

原始输入边界：

- 原始输入主要服务于 brainstorm/proposal/design 形成之前。
- `hello-spec-start` 不写 `intake.md`；飞书/本地文档/长 prompt/硬约束需要可重读的外部来源，用户明确降级时记录 `NO_SOURCE_CONFIRMED=true`。
- `brainstorm.md` 必须记录 `Input Sources` 和短摘要。
- `proposal/specs/design` 以已生成 artifact 为主输入，必要时回查原始输入确认硬约束。
- `tasks/plan` 默认不读原始输入；如果发现 canonical artifacts 与原始输入冲突，停止并走 `spec-plan-revise`，不要在 plan 阶段直接改口径。

仍可使用的 OpenSpec 原生命令：

```text
openspec-new-change <change-name>
openspec-continue-change <change-name>
```

它们适合低风险或通用 schema；对于 `hello-spec-v2`，优先使用 `hello-spec-start` / `hello-spec-next`。

不推荐入口：

```text
openspec-propose ...
openspec-ff-change ...
```

不要把这两个技能作为 `hello-spec-v2` 的默认入口。它们的原生语义是一次性生成所有 `applyRequires` 前置产物，直到提案变成 apply-ready。对本 schema 来说，这通常会直接生成到 `plan.md`，再叠加通用 coding agent 的“能做就继续做”策略，容易误入 `openspec-apply-change` 并开始改代码。

如果用户输入里出现“先实现”“直接做”“把代码写了”等词，但当前调用的是 `openspec-new-change` / `openspec-continue-change`，仍以当前技能身份为准：本轮只创建或推进文档 artifact，不进入 apply，不改业务代码。`hello-spec-v2` 的实现阶段必须等待用户明确发起 `hello-spec-apply <change-name>` 或等价指令；通用 `openspec-apply-change` 解析到 `schemaName=hello-spec-v2` 时也应切到 `hello-spec-apply`。

## 测试策略

测试不是全局禁用，而是按仓库能力分类：

- `unit_test_required`：能跑 targeted unit test 的仓库，行为改动必须优先写/跑 targeted regression test。
  - 已知例子：`/data00/home/lihao.hellohake/go/src/code.byted.org/ecom/search_card_admin/main`
- `unit_test_disabled`：单测已知跑不起来或成本过高的仓库，不强制单测，使用 gopls diagnostics / AI review / manual verification。
- `manual_test_only`：不让 agent 自动跑，但必须写出用户可复制执行的命令。
- 未列出的仓库：默认按 `unit_test_required` 处理。也就是行为改动需要 targeted regression test；只有项目级 `.ai_doc/spec-workflow/test_policy.yaml`、用户级 `~/.agents/test_policy.yaml`、仓库文档或你明确确认“跑不了单测”时，才降级到 `unit_test_disabled/manual_test_only`。

默认仍禁止 full-suite 命令，例如 `go test ./...` 和 full `go build`，除非仓库明确允许。

项目级例外配置放在仓库内：

```text
.ai_doc/spec-workflow/test_policy.yaml
```

模板只定义规则，不内置具体业务仓库。当前已在这些仓库里配置 `unit_test_disabled`：

- `/data00/home/lihao.hellohake/go/src/code.byted.org/ecom/search_loader/main/.ai_doc/spec-workflow/test_policy.yaml`
- `/data00/home/lihao.hellohake/go/src/code.byted.org/ecom/search_stream/main/.ai_doc/spec-workflow/test_policy.yaml`

## 常用命令

```text
openspec-new-change <change-name>
openspec-continue-change <change-name>
hello-spec-apply <change-name>
openspec-apply-change <change-name>  # 通用 OpenSpec apply；hello-spec-v2 优先切到 hello-spec-apply
spec-code-review <proposal-name-or-absolute-proposal-dir>
spec-commit-push <proposal-name-or-absolute-proposal-dir>
spec-opti-workflow <proposal-name-or-absolute-proposal-dir> <original-prompt-doc>
gotchas <proposal-name-or-absolute-proposal-dir>
```

## 本地模板同步

本模板目录会通过 `.zshrc sync_cfg()` 同步到：

```text
/data00/home/lihao.hellohake/.config/nvim/skill_template/schemas/hello-spec-v2/
```

历史备注：

```text
ln -s /data00/home/lihao.hellohake/.agents/template/schemas/ schemas
禁止：rm -rf schemas
```
