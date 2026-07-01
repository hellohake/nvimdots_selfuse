# Go Diagnostics Protocol

Use this protocol when `spec-trouble-resolve` changes any Go file.

## When to Run

- Run after every Type A/B/D fix that creates or modifies `.go` files.
- Skip for pure documentation changes and Type C/E clarification-only outcomes.
- For non-Go code changes, use the repo's smallest existing static check or the test policy from `tasks.md`, `manual-test-commands.md`, repo docs, or the user's current instruction. Do not apply `go_diagnostics` to non-Go work.

## Required Check

Call the gopls MCP `go_diagnostics` tool with the minimal set of new or modified Go files from this turn.

Do not replace this with `go build`, `go test`, `go vet`, or a broad build command. Targeted tests may be extra verification only when the repo policy or user instruction allows them.

## Result Handling

- `error`: fix every error before completion. Re-run `go_diagnostics` after each fix.
- `warning` / `hint`: fix if directly caused by this turn. For unrelated historical diagnostics, record them in the archive self-check instead of widening the task.
- If a diagnostic exposes a contract mismatch, return to Type A classification instead of patching around it as a local bug.

## Retry Limit

If the same file does not converge after 3 diagnostics/fix rounds, stop and report:

- file path
- remaining errors
- fixes already attempted
- why further local guessing would risk widening or corrupting the proposal

## Tool Unavailable

If the gopls MCP tool is unavailable, do not claim diagnostics passed.

Report exactly:

```text
静态诊断未完成：gopls go_diagnostics 工具不可用。
```

Then include the impacted Go file list and any fallback check that was actually run.

## Completion Evidence

Before final response or archive, be able to state:

- which Go files were checked
- whether `error` diagnostics are clear
- any remaining warning/hint and why it was left untouched
