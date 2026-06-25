# Debug Inputs

<!--
本文件是 `spec-e2e-debug` 的端到端诊断输入收件箱。

提案创建期不生成；只有 apply 后端到端测试出现“现象不明、根因未知”时才创建。
`spec-e2e-debug` 结合代码现状 + 当前 diagnostic provider 做只读根因定位，输出同级
`debug-report.md`；不改业务代码，不写 backup.md，不执行写操作。

最小输入：
- 现象：实际 vs 期望。
- 定位锚点：logid，或 psm + 发生时间。
- 可选：环境/泳道、配置、实验、下游、DB 表、复现步骤、初步判断。

建议格式：
### D001 · <一句话现象标题>

- Actual: <实际现象>
- Expected: <期望行为>
- LogID: <logid or none>
- PSM: <service name or none>
- Environment: <ppe / boe / lane / online / unknown>
- Occurred at: <time point or narrow time range>
- Suspects: <config / experiment / downstream / db / none>
- Repro: <entry, request params, account, steps, or none>
- Notes: <your initial guess or none>

诊断完成后：
- 完整输入会归档到 debug-report.md。
- 本文件会被重置为空收件箱。
-->

## Inputs

<!-- DEBUG:START -->

暂无。端到端测试出现未知根因问题时，在此追加 D001 条目。

<!-- DEBUG:END -->
