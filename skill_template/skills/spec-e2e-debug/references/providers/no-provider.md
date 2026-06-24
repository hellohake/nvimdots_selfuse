# no-provider Diagnostic Provider

Use this provider when no safe diagnostic CLI is available.

## Metadata

- `provider_name`: `no-provider`
- `environment`: generic/offline
- `auth_check`: none
- `read_only_rule`: no external platform queries are executed

## Capabilities

No external capabilities are available. The skill should still:

- Read and normalize `debug.md`.
- Read relevant code and proposal context.
- Produce hypotheses.
- List the exact evidence still needed from the user.
- Write `debug-report.md`.

## Report Expectations

When using `no-provider`, `debug-report.md` must include:

- `Provider: no-provider`
- hypotheses that could not be verified
- user-supplied evidence needed next
- suggested read-only commands as placeholders when they can be inferred, clearly marked `not_run`

Do not invent platform evidence.
