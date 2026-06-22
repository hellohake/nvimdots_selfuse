# Gotchas（项目级坑点库）

<!-- SCHEMA_VERSION: 2 -->
<!-- TAGS: lang-go, lang-ts, infra-api-contract, infra-db, flow-openspec, flow-cr-review, flow-design-intent -->
<!-- 注入规则：按需求领域标签，每桶 hits 降序取 Top 5，只引 ID+摘要，不贴整库 -->
<!-- 废弃条目见同目录 gotchas.archive.md -->

<!--
本文件是【项目级坑点库】，是经验复用飞轮的“成品仓（项目层）”。
落地位置：.ai_doc/spec-workflow/gotchas.md（只放 Active；废弃条目搬到 gotchas.archive.md）
写入方式：禁止手工随意追加。统一由 `gotchas` 治理技能在每次复盘后【手动跑一次】蒸馏写入，走三道闸：

【准入闸】一条坑必须同时满足才进库：
  ① 会重复犯（不是一次性失误）
  ② 有明确触发场景 when
  ③ 有明确规避动作 do/don't
  ——“需求没写清”导致的问题不进这里，那是 spec 质量问题，应由 grill-spec 澄清门拦截。

【分层闸】先进本文件（项目级）；同一坑的 src 覆盖 ≥2 个不同项目 → 晋升到全局 ~/.agents/gotchas/general.md。

【淘汰闸 · 分标签桶】不设全局总数硬上限；按领域标签分桶，单桶软上限 30 条：
  - 重复坑只 upsert，按 src 去重不重复刷 hits；
  - 被 CI/lint/工具固化 或 长期 0 命中 → 剪切到同目录 gotchas.archive.md（不再注入，删除由用户手动决定）；
  - 超桶优先合并语义相近条，不硬砍。

标签必须取自顶部 TAGS 词表，禁止自由造词；新标签需用户确认后加入词表。

条目格式（lint 化，单行可 grep，注入时引 ID 不贴正文）：
- [G-NNN] <领域标签> | when:<触发场景> | do:<该做> | don't:<别做> | hits:<次数> | src:backup.md#<提案/时间戳> | <最近命中日期>
-->

## Active

<!-- 示例（同标签条目相邻成桶）：
- [G-001] lang-go | when:多 goroutine 写同一 map | do:用 sync.Map 或加锁 | don't:裸 map 并发写 | hits:2 | src:backup.md#proposal-auth | 2026-06-12
-->

