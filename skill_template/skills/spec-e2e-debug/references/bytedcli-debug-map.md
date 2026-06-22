# bytedcli 诊断平台映射表（只读命令清单）

> 本文件供 `spec-e2e-debug` 按需查阅。**调用方式**：通过 bytedcli MCP 工具（`mcp__bytedcli__run_command`），不是裸 `bytedcli` shell。
> **🔴 铁律**：本表只列**只读/查询**命令。任何 create/update/delete/deploy/scale/cancel/exec-写 等改状态命令**禁止执行**，需要时只列给用户人工跑。
> 用 `mcp__bytedcli__list_commands(domain=...)` 可查某域全部命令及参数。

## 决策树：从已知信息出发选路径

```
有 logid           → 路径①日志（首选，最直接）
现象在某服务       → 路径②服务定位 → 路径①日志
怀疑配置           → 路径③ tcc
怀疑实验/开关      → 路径④ libra/sip
怀疑指标/容量      → 路径⑤ apm/grafana/slardar
要看实例本地态     → 路径⑥ tce 实例/webshell
怀疑数据落库       → 路径⑦ DB
怀疑下游返回/要复现 → 路径⑧ RPC/复现
```

---

## ① 日志（首选）—— domain: log / slardar

按 logid 追链路日志，这是端到端诊断最直接的入口。

| 命令 | 用途 | 读写 |
|---|---|---|
| `log get-logid-log --logid <id> [--psm <psm>]` | 按 logid 拉日志（带 psm 用滚动 __logid 搜索） | 只读 ✅ |
| `log trace-tree --logid <id>` | 展示该 logid 的 BytedTrace 调用延迟树（看链路结构/慢点） | 只读 ✅ |
| `log search-psm-log --psm <psm> ...` | 按 PSM 搜日志（轮询模式） | 只读 ✅ |
| `log get-lane-instance-log --env <泳道> --psm <psm>` | 按泳道环境 + PSM 搜实例日志 | 只读 ✅ |
| `log search-prod-instance-log --psm <psm> --pods <...>` | 按 PSM + pod 列表搜实例日志 | 只读 ✅ |
| `slardar web data list / get / session-list` | Slardar 事件检索/详情/会话时间线 | 只读 ✅ |
| `slardar app file download` | 下载 App 日志文件到本地 | 只读 ✅ |

**🔑 防上下文爆炸手法**：日志量大时，**先窄后宽**只拉关键 psm + 时间窗 + 条数上限 → 把结果**写本地临时文件** `/tmp/e2e-debug-<logid>/<psm>.log` → 用 grep 在文件里找报错/关键字段/断点 → **只把命中行（含行号）读进上下文**，绝不内联整份日志。

## ② 服务定位 —— domain: bytetree / sd / tce / env

| 命令 | 用途 | 读写 |
|---|---|---|
| `bytetree`（search 节点/子节点/父链） | 服务树定位、归属、上下游 | 只读 ✅ |
| `sd`（service discovery lookup/report） | 站点路由、实例发现 | 只读 ✅ |
| `tce service get / search` | TCE 服务详情 + 仓库快照 | 只读 ✅ |
| `tce env-cascader --psm <psm>` | PSM → 分区/环境/泳道解析（read-only） | 只读 ✅ |
| `tce instance list / search` | 列/搜实例(pod)，按 IP/pod 名/host | 只读 ✅ |

## ③ 配置 —— domain: tcc

| 命令 | 用途 | 读写 |
|---|---|---|
| `tcc config get` | 查配置详情（核对线上/泳道实际值） | 只读 ✅ |
| `tcc config list` | 列命名空间下配置 | 只读 ✅ |
| `tcc config version list / get` | 配置版本历史/某版本数据（看是否近期改过） | 只读 ✅ |
| `tcc deployment list / get` | 查发布记录（定位是否某次发布引入） | 只读 ✅ |
| 🔴 `tcc config create/update`、`tcc deployment deploy/approve/operate` | **改配置/发布** | **禁止执行**，列给用户 |

## ④ 实验/开关 —— domain: libra / sip

| 命令 | 用途 | 读写 |
|---|---|---|
| `libra experiment get` | 实验详情 | 只读 ✅ |
| `libra experiment traffic` | 流量分配（看是否命中） | 只读 ✅ |
| `libra experiment search --key <参数key>` | 按参数 key 搜实验（定位某开关被哪个实验控制） | 只读 ✅ |
| `libra experiment report / realtime` | 实验报告/实时指标 | 只读 ✅ |
| `libra test-user list` / `test-whitelist list` | 测试用户/白名单（看你的测试账号是否在内） | 只读 ✅ |
| `sip`（query LIBRA/Demotion/TCE events） | 命中/降级/变更事件诊断 | 只读 ✅ |
| 🔴 `libra experiment create/release/pause/close`、`test-user add/delete` | **改实验/改名单** | **禁止执行**，列给用户 |

## ⑤ 指标/打点 —— domain: apm / grafana / slardar

| 命令 | 用途 | 读写 |
|---|---|---|
| `apm`（监控查询） | 服务指标、错误率、延迟 | 只读 ✅ |
| `grafana dashboard get` | 看板数据 | 只读 ✅ |
| `slardar web flex query series/indicator-card` | 自定义指标时序/卡片 | 只读 ✅ |
| `slardar web alarm-history` | 告警历史（是否有相关告警） | 只读 ✅ |

## ⑥ 实例本地态 —— domain: tce（webshell）

| 命令 | 用途 | 读写 |
|---|---|---|
| `tce instance list / search` | 定位 pod | 只读 ✅ |
| `tce webshell open` / `exec --cmd <只读命令>` | 进实例看本地日志/进程/文件 | **仅限只读命令**（cat/grep/tail/ps/ls 等）；🔴 任何写命令（rm/mv/kill/重启/改文件）禁止 |
| 🔴 `tce instance delete`、`tce cluster update/scale`、`tce deployment cancel/execute-step` | **删实例/改集群/动发布** | **禁止执行**，列给用户 |

> webshell exec 风险最高：它能在实例上跑任意命令。**只允许只读查看类命令**；拿不准的命令一律不跑。

## ⑦ DB 真实数据 —— domain: rds / bytehouse / hive / tqs

| 命令 | 用途 | 读写 |
|---|---|---|
| `tqs`（SQL analyze/submit/result） | 跑 **SELECT** 查真实落库数据 | **仅 SELECT** ✅ |
| `bytehouse`（SQL query） | ClickHouse 查询 | **仅 SELECT** ✅ |
| `hive`（DataLeap catalog 查询） | 数仓数据 | 只读 ✅ |
| `rds`（database 查询类） | RDS 查询 | **仅 SELECT** ✅ |
| 🔴 任何 INSERT/UPDATE/DELETE/DDL | **改库** | **禁止执行**，列给用户 |

> 写 SQL 时人工/技能都要确认是 SELECT。带 update/delete/insert/drop/alter 的语句一律不执行。

## ⑧ 下游 RPC 返回 / 复现 —— domain: bam / api-test

| 命令 | 用途 | 读写 |
|---|---|---|
| `bam method list / get` | 查下游接口定义、方法 schema | 只读 ✅ |
| `bam idl schema` | 服务完整 IDL 参考 schema | 只读 ✅ |
| `api-test`（调接口复现） | 调下游接口看真实返回 / 复现现象 | **仅幂等查询类接口** ✅ |
| 🔴 调用任何会写下游数据的接口（下单/扣减/状态变更/写库），即使测试环境 | — | **禁止执行**，列给用户 |

> RPC 复现最危险：agent 判断不了接口副作用半径。**只调明确幂等的查询接口**；拿不准 → 当写处理，停手问用户。

---

## 通用执行规范

1. 每个命令执行前自检：「会改变任何状态吗？会 → 停」。
2. 命令产出大（日志/大结果集）→ 落临时文件再检索，不内联。
3. 所有执行过的只读命令记入 debug-report 的「附：只读命令」。
4. 所有"需要写才能确认/修复"的 → 记入 debug-report 的「附：需人工执行的写操作」，附风险说明。
