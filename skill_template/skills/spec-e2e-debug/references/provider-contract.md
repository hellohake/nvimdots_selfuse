# Diagnostic Provider Contract

`spec-e2e-debug` is a diagnosis workflow. A provider is the read-only backend used to verify hypotheses in a specific environment.

## Provider Selection

Choose exactly one provider per run:

1. User-specified provider in the prompt, if present.
2. Environment default when available. In ByteDance internal repos, this is usually `bytedcli`.
3. `no-provider` fallback when no diagnostic CLI is available.

The selected provider must be written into `debug-report.md`.

## Provider Metadata

Every provider reference should define:

- `provider_name`
- `environment`
- `auth_check`
- `read_only_rule`
- `capabilities`

## Capability Contract

The table below is a common taxonomy, not a closed whitelist. Providers may expose additional read-only domains/tools. If a diagnostic need does not fit the table, use provider discovery to look for a safe read-only command and record the discovered capability in `debug-report.md`.

| Capability | Purpose | Typical inputs | Required evidence in report |
|---|---|---|---|
| `logs` | Query logs by request id, service, and time window | logid, service/psm, time window | temp log path + matched lines |
| `service` | Locate service, instances, lane, routing, upstream/downstream | service/psm, env/lane | instance/status/routing evidence |
| `config` | Read config values and deployment records | key, namespace, env | value + source/version |
| `experiment` | Diagnose experiment or switch hit | experiment/key/user/context | hit/miss evidence |
| `metrics` | Read metrics, alarms, dashboards | metric, tags, time window | datapoints/link/summary |
| `db` | Read database or warehouse data | table, key, SELECT query | rows/count/query path |
| `rpc` | Reproduce read-only downstream calls | method, request | request/response summary |
| `discovered:<name>` | Provider-specific read-only capability discovered at runtime | depends on provider | discovery result + read-only justification + evidence |

## Provider Discovery

Use discovery when:

- debug.md mentions a platform/tool not listed in the common capability table;
- the obvious capability does not fit the evidence needed;
- the user explicitly asks to inspect a provider-native platform, such as a config/feature/metadata system.

Discovery rules:

1. Prefer provider-native command discovery (`list commands`, `help`, schema lookup, capability listing).
2. Search by user terms and likely aliases.
3. Before running a discovered command, classify it as read-only or write-capable.
4. Only run commands whose purpose and verb are read-only (`get`, `list`, `query`, `search`, `describe`, `show`, `read`, `inspect`, `diagnose`).
5. Never run commands with write verbs (`create`, `update`, `delete`, `set`, `apply`, `deploy`, `restart`, `scale`, `approve`, `operate`, `cancel`, or shell exec with write commands).
6. If read-only status is unclear, do not run it. Put the command and risk into the report for the user.
7. Record discovery in the report:
   - search terms used
   - command/domain found or not found
   - read-only classification
   - command actually executed, if any

Missing discovery results are useful evidence too: report that the provider did not expose an obvious read-only command for that platform.

## Read-Only Classification

Treat read-only as a positive proof requirement. A command is runnable only when both hold:

- The command description/verb indicates read-only behavior.
- Inputs are constrained to query/lookup parameters, not desired state.

If either condition is missing, do not run the command.

## Core Rules

- Provider commands must be read-only. Any write/update/delete/deploy/restart/cancel/scale command is forbidden and should only be listed for the user with risk notes.
- Large outputs must be written to temp files and searched locally; only evidence snippets should enter the report.
- Missing capabilities are acceptable. Skip unsupported verification paths and state the gap in `debug-report.md`.
- Auth/tool/version failures are provider environment failures, not business conclusions.
