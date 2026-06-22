# Design: [Feature / Component Name]

## Context

<!-- Background and current state. 阐述业务背景、旧链路现状以及当前痛点。-->

## Goals / Non-Goals

**Goals:**

<!--What this design aims to achieve. 明确预期的业务效果或核心工程/性能指标。-->

**Non-Goals:**

<!-- What is explicitly out of scope. 明确本次迭代绝对不做的内容，防止范围蔓延。 -->

## Architecture Overview

<!-- High-level architecture, components, and interaction. 描述核心服务与上下游组件的协同关系。 -->

## Decisions

<!-- Key design decisions and rationale. 记录核心方案的选型对比与最终决定的原因。-->

## Detailed Design

<!-- Code-level implementation details. 具体的工程落地细节，强烈建议按“服务”或“数据处理阶段/模块”拆分小节。-->

### [Module / Step A]

- **Logic**: 
  <!-- Specific rules, algorithms, or data assembly logic. 具体的判定规则或执行步骤。-->

- **Concurrency & Safety**: 
  <!-- Golang-specifics: goroutine safety, oom prevention, panic prevention. Go 并发安全, 空指针, 性能劣化, 内存溢出预防。-->

- **Code Location**: 
  <!-- Target packages, files, or IDL dependencies. 核心代码落点与外部依赖路径。-->

### [Module / Step B]

- **Logic**: 

- **Concurrency & Safety**: 

- **Code Location**: 

## Data Flow & Interfaces (Optional)

<!-- Describe data structures, RPC/HTTP changes, or config updates. 仅在涉及对外接口、结构体扩展、字段协议变更时填写。-->

## Risks / Trade-offs & Observability

<!-- Known risks and trade-offs. 记录技术妥协点、已知风险，并给出对应的监控打点与兜底策略。-->

- **Risks & Fallbacks**: 
  <!-- Downstream timeout strategies, graceful degradation. 依赖故障或数据为空时的降级方案。-->

- **Metrics & Tags**:Metrics 
  <!-- Metrics names and tag dimensions. 新增的打点监控（如：cmp_summary.produce 及相关 Tags）。-->

- **Logging**: 
  <!-- Key info/warn logs for troubleshooting. 排查问题所需的关键日志打印点。-->

## Migration & Rollout Plan

<!-- Steps to deploy, AB test configs, and rollback strategy. AB 实验开关、灰度放量步骤以及快速回滚方案。-->

## Open Questions

<!-- Unresolved issues or prompts to be filled by other teams. 待业务方、算法或其他组确认的未决契约。-->
