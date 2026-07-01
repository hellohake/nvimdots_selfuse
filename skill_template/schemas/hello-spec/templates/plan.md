# [Feature Name] Implementation Plan

> **For agentic workers:** The main agent is the coordinator. Implementation
> must be delegated through superpowers:subagent-driven-development using the
> `Subagent Execution Contract` below. If subagents are unavailable, stop before
> production-code edits unless the user explicitly provides `SERIAL_APPLY=true`.

**Goal:** <!-- One sentence -->

**Architecture:** <!-- 2-3 sentences -->

**Tech Stack:** <!-- Key technologies -->

**Verification Policy:** <!-- Do not use full `go test ./...` or broad `go build`; list allowed targeted checks or gopls diagnostics. -->

---

## Subagent Execution Contract

| SliceID | TaskRefs | Allowed Write Scope | Read First | Acceptance | Verification | Stop Conditions |
|---|---|---|---|---|---|---|
| S1 | 1.1 | `path/to/file.go` | `design.md#section`, `tasks.md#1` | <!-- concrete done condition --> | <!-- command or gopls diagnostics --> | <!-- ambiguity, scope expansion, missing dependency --> |

## Task 1: <!-- Component Name -->

- [ ] **Step 1:** <!-- micro-step -->
- [ ] **Step 2:** <!-- micro-step -->
