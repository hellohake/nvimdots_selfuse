# hello-spec-loop Review/Fix Loop

This reference owns the post-apply convergence loop. It assumes implementation
has completed through `hello-spec-apply` and ledgers are reconciled.

## Goal

Reduce human code-review cost before the user sees the final diff.

The loop shape is:

```text
spec-code-review review
  -> if current template says repair remains: spec-code-review fix
  -> spec-code-review review
  -> repeat until converged or max rounds
```

Review and fix should be driven by independent roles when available:

- Review role: read-only, creates/appends `spec-code-review.md`.
- Fix role: writes code only for latest Review Run `Fix Queue` rows where
  the current `spec-code-review` template says coding-agent repair is accepted.

The implementer must not self-certify final readiness.

## Preconditions

Before the first review:

- Current `hello-spec-apply` completion evidence is present, or that primitive
  explicitly stopped with code changes ready for review.
- Repo diff baseline/stat for the changed repo set is recorded.
- `plan.md` and `tasks.md` ledgers are reconciled according to the apply
  primitive's current contract.
- No blocking `pending_human` decision prevents review.
- There is a git diff to review. If diff baseline is unclear, let
  `spec-code-review` stop in degraded mode.

## Round Limit

Maximum: 3 review rounds.

Reasoning:

- Round 1: broad review.
- Round 2: review fixes and second-order issues.
- Round 3: convergence confirmation.

If the current report template still requires coding-agent repair after round 3,
stop:

```text
Stopped at: review_fix_loop_not_converged
```

Tell the user the AI loop no longer looks reliable enough to continue without
human deep review.

## Review Step

Run `spec-code-review review` or equivalent natural-language invocation for the
change.

Before parsing the report, load the current `spec-code-review` skill and its
`references/report_template.md`. The template is the only authoritative contract
for readiness, queue rows, manual-test state, and machine-readable state.

Copy template values verbatim into `loop.md`. Do not reproduce enum meanings in
this reference and do not parse old free-form prose or Markdown tables outside
the primitive/template contract. If the primitive authorizes degraded fallback,
record its stated mode and copied values; if it says the report is unconsumable,
preserve that stop reason verbatim.

If `spec-code-review` itself stops in `degraded_no_diff_or_context`, preserve
that primitive stop in `loop.md` instead of converting it into convergence
failure.

## Fix Step

Run `spec-code-review fix` when the current `spec-code-review` contract says
fix mode may consume the latest report. The loop must not parse the Fix Queue,
select accepted rows, compare machine state, or verify whether a finding still
applies before invoking fix mode. Evidence validation, accepted-row selection,
and degraded fallback decisions are owned by the current `spec-code-review`
contract.

Loop guardrails around the primitive:

- Before each fix, run only the Risk Checklist in `gate-protocol.md` against
  the intended primitive invocation scope and known write set.
- If the intended invocation scope is broader than the approved plan/review
  scope, stop or create a human decision; do not silently broaden code edits.
- Copy `spec-code-review fix` output, fixed IDs, degraded mode, and stop reasons
  verbatim; do not reinterpret them through loop-side report parsing.
- Fix mode does not refresh review readiness unless the current primitive
  explicitly says it does; normally run review again.

After fix mode, always run review mode again unless the user explicitly stops.
If fix mode reports degraded fallback, mismatched machine fields, or an
unconsumable latest report, copy that primitive result verbatim and route from
the copied stop/status.

## Convergence Conditions

Stop at `human_code_review_ready` when all are true:

- Current `spec-code-review` template says readiness is acceptable for human
  review.
- Current template state says no coding-agent repair items remain.
- Changed-file lightweight verification has no new error, or the gap is explicit
  and classified by the template/primitive as human/manual-only.
- `plan.md` and `tasks.md` remain reconciled after fixes.
- Any human decision has a clear Dxxx entry and recommended human scope.

## Human Decision Handling

When review produces `human_decision`:

1. Ensure `<proposal_dir>/human-decisions.md` has the Dxxx entry required by the
   current review template. If not, preserve the primitive/report defect route.
2. Present a decision packet using `gate-protocol.md`.
3. If the answer changes planning docs, route to `spec-plan-revise`, then return
   to apply/review as needed.
4. If the answer changes implementation only, route to `spec-trouble-resolve` or
   a scoped `spec-code-review fix`, then review again.

Do not let the fix role decide Dxxx.

## Machine State Delegation

The loop must not decide report consistency by itself. Load the current
`spec-code-review` template and let that primitive compare machine-readable and
human-readable sections, authorize fallback, or stop. Copy the resulting mode,
IDs, readiness, and stop reason verbatim into `loop.md`.

## Loop State Updates

After every review or fix, update `loop.md`:

- `Review round`
- `Latest report`
- `Latest CR Readiness`
- `Latest accepted IDs`
- `Latest fixed IDs`
- `Latest human decision IDs`
- `Review dispatch`
- `Fix dispatch`
- `Machine State mode` as reported by the current template/primitive

Keep only IDs and paths in `loop.md`; the full details live in
`spec-code-review.md`.

## Final Review Pack

When converged, produce a concise final packet:

```text
Stopped at: human_code_review_ready

CR Readiness: <verbatim template value>
Review rounds: <n>/3
Latest report: <abs path>/spec-code-review.md
Diff stat: <summary>
Accepted remaining: none
Human decisions: <none|Dxxx>
Manual verification: <none|commands/path>
Recommended human review scope:
1. <highest risk file or finding>
2. <highest risk file or finding>
```

Do not commit or push.
