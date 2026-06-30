---
name: hello-spec-next
description: Use when continuing a hello-spec-v2 OpenSpec-style SDD proposal after hello-spec-start, including "continue/next/推进/继续当前提案", creating the next artifact, safely resolving the current change from cwd/context, answering pending grill-spec questions, or resuming a grill-spec gate. Use instead of openspec-propose/openspec-ff-change for gated hello-spec-v2 progress.
---

# hello-spec-next

## Purpose

Move a `hello-spec-v2` proposal to the next safe point without losing human gates.

Use this after `hello-spec-start`. This skill is intentionally single-step for
business artifacts. At `grill-spec`, it does not merely print a handoff command:
it enters gate mode, runs the clarification workflow under the OpenSpec
instructions, and still stops before `tasks` / `plan`.

## Inputs

Input arrives as a single free-text message in natural language. Parse it for any
of these accepted kinds (more than one may appear in the same message):

- an explicit absolute proposal directory path, e.g.
  `/abs/repo/openspec/changes/<change>`;
- a change name, e.g. `p3-pack-card-runtime`;
- a progress phrase that authorizes advancing one step, e.g. "continue", "next",
  "推进", "继续当前提案", or "推进下一个";
- a `grill-spec` answer packet, in the stable `QID` form
  `Q001=A; Q002=B; Q003=自定义：...` or the numeric alias form `1=A; 2=B; ...`
  (numeric aliases are accepted only under the `Asked batch` / `Question map:`
  marker rule defined in the Interactive Gate reference). Tokens may be separated
  by newlines or `;`, and each `QID=value` is parsed independently.

If the change cannot be uniquely identified, stop and ask for the change name or
absolute proposal path (never guess by similarity or recency — see `## NEVER`).

## Change Resolution Contract

This is a state-changing workflow: resolving the wrong change can write files to
the wrong proposal. Treat change resolution as a contract, not a convenience.

Accepted resolution sources fall into two tiers. Sources 1-2 are explicit user
directives; sources 3-5 are implicit inferences:

1. Explicit absolute change dir:
   `/abs/repo/openspec/changes/<change>`.
2. Explicit change name argument:
   `hello-spec-next <change>`, where `<change>` matches an existing directory
   under the locked repo's `openspec/changes/`.
3. Current working directory is inside:
   `<repo>/openspec/changes/<change>/...`.
4. Current turn text or immediately preceding start/next output contains exactly
   one stable resume token:
   - `CHANGE_NAME=<change>`
   - `Change: <change>`
   - `hello-spec-next <change>`
   - `cd <repo root> && hello-spec-next <change>`
5. Locked repo has exactly one active change directory under
   `openspec/changes/` whose `openspec status --change "<change>" --json`
   verifies `schemaName == hello-spec-v2`.

Resolution rules:

- Lock `REPO_ROOT` before using any repo-local candidate. Prefer the nearest
  ancestor containing `openspec/`; if cwd is outside a repo or multiple repos are
  implied by the text, stop and ask for an absolute proposal path.
- Explicit sources short-circuit: if source 1 is present and source 2 is absent
  or names the same change, use source 1; if only source 2 is present, use it. An
  explicit directive is authoritative even if an implicit source would point
  elsewhere (the user named the change on purpose). If sources 1 and 2 are both
  present and name different changes, stop with `ambiguous_change_context`.
- Otherwise gather every implicit source (3, 4, 5) and require exactly one
  *distinct* change among them. If they all name the same change, use it. If they
  name different changes (e.g. cwd points to change X but a context token points
  to change Y), stop with `ambiguous_change_context` and list each candidate with
  its source (`cwd`, `context`, or `sole-active-change`) — never let one implicit
  source silently win, because a wrong pick writes to the wrong proposal.
- If no source yields a candidate, stop with `Stopped at: missing_change_context`.
  Never narrow a multi-candidate set by fuzzy match, newest dir, recency, or
  sibling-repo scan (see `## NEVER`).
- Before any file write, report the resolved identity in the first status update,
  using the fixed identity line defined in Phase 0 - Identity Lock.

Intent semantics:

- Status-only requests are status phrases such as "看一下状态", "where is this
  change", or "show status" — they only report status and do not write files.
  Classify a turn as status-only positively (it asks for status), not by
  exclusion; a progress phrase, a named artifact, and a grill-spec answer packet
  are each NOT status-only.
- Progress requests such as "continue", "next", "推进", or `hello-spec-next
  <change>` authorize advancing the current ready artifact by exactly one safe
  step.
- A generic progress request authorizes creating the current ready Business
  Artifact. When the ready artifact is `grill-spec`, it authorizes entering
  `grill-spec gate mode`, not generating `tasks` / `plan`.
- A message that answers pending `grill-spec` questions authorizes consuming
  those answers, writing resolved decisions back to `design.md`, and then asking
  the next unresolved batch or completing the gate.
- A request naming a specific artifact is treated as a progress request for the
  current ready artifact. If the named artifact IS the current ready one, create
  it. If it is ahead of the ready one, do not create it and do not skip ahead —
  advance the current ready artifact by one safe step and note that the named
  artifact is still gated behind it.

## Artifact Classes

### Auto Placeholder

These are inbox/placeholder files. They may be created automatically from the
template because they do not require business reasoning:

- `troubleshoot`
- `revise`
- `manual-test-commands`

Only copy the template verbatim. Do not infer content.

### Business Artifact

These require reasoning or synthesis. Create at most one per invocation, then
stop:

- `brainstorm`
- `proposal`
- `specs`
- `design`
- `tasks`
- `plan`

Source handling:

- `brainstorm`: must consume the initial user input provided during
  `hello-spec-start` or in the current turn. Include an `Input Sources` trace.
- `proposal`: consume `brainstorm.md`; use the original input only to verify
  scope and hard constraints.
- `specs` / `design`: consume `proposal.md`, previous artifacts, and relevant
  code/docs. Re-read original input only for ambiguity or lost constraints.
- `tasks` / `plan`: consume canonical artifacts only (`proposal.md`,
  `specs/**/*.md`, `design.md`, `grill-spec.md`, and `tasks.md` for plan). If
  canonical artifacts conflict with original input, stop and route through
  `spec-plan-revise` rather than silently changing scope.

### Interactive Gate

`grill-spec` is a human-in-the-loop clarification gate. Do not treat
`grill-with-docs <change>` as a sufficient handoff; that skill is a thin wrapper
around `grilling` + `domain-modeling`, while the OpenSpec `grill-spec`
instructions are the binding contract for paths and completion detection.

**MANDATORY when the ready artifact is `grill-spec` — read the entire file
`references/grill-spec-gate.md` (~130 lines) before asking any question or writing
any file; do NOT set range limits.** It owns the full gate procedure: gate mode,
the User Confirmation Loop (`QID`/numeric answer parsing, interactive-tool vs
numbered-batch fallback, the `Asked batch` / `Question map:` marker), and the
persistence rules. Load it only on a `grill-spec` turn; skip it otherwise. The
two safety anchors below stay in the body because the rest of the skill points at
them.

Persistence override: the served `grill-spec` instruction may say you can create
`grill-spec.md` with `## Status: pending` while items are
`pending_user_confirmation`. Do NOT do that. Because the CLI marks an artifact
`done` on file existence alone (see `## NEVER`), this skill overrides the served
body here: keep `grill-spec.md` absent until the gate is complete and persist all
pending state in `design.md` only. The served body still governs its path
overrides — only its persistence behavior is overridden.

Completion rule (grill-spec completion contract):

`grill-spec.md` counts as complete only when each blocking question has
`Status=user_confirmed` or `Status=resolved_by_evidence`, plus non-empty
`Evidence=<path:line or exact user answer>` — never a checked box or file
existence (see `## NEVER`). Until complete, `grill-spec.md` stays absent and all
pending state lives in `design.md` Open Questions; create it only at completion.
After completion the durable completeness signal is `grill-spec.md`
`## Status: complete`, and the granular evidence lives in `design.md` Decisions.
This is the canonical absent-until-complete statement; other mentions point here.

## Machine Contract

The purpose of this skill is to remove guesswork. Treat missing machine fields as
a stop condition, not as permission to infer paths from memory or naming habits.

**MANDATORY — read the entire file `references/openspec-cli-contract.md`
(~90 lines) before parsing any `openspec status --json` / `openspec instructions
--json` output; do NOT set range limits when reading it.** That file holds the
full field tables, the both-bodies-always-present rule, the `specs` glob edge
case, and the field → Stop Reason map. This skill ships two references, each
loaded only when its phase is reached: `references/openspec-cli-contract.md` for
JSON parsing (here) and `references/grill-spec-gate.md` for the gate (Interactive
Gate). The orientation in "The two JSON calls" below covers only the happy path;
the `### Stop Reasons` enum and the reference file cover the error contract.

### Stop Reasons

Exact enum-like values for the final `Stopped at:` field. Keep the list small; add
a value only when a stop needs distinct downstream handling.

- `missing_status_contract`: status JSON lacks `schemaName` or `artifacts[]`.
- `missing_instructions_contract`: instructions JSON lacks `artifactId`,
  `changeDir`, or `outputPath`, or the class-appropriate body is empty
  (`template` for an Auto Placeholder, `instruction` for a Business Artifact).
  The current CLI always populates both bodies; the empty-body branch is
  drift-insurance for a future contract change.
- `path_contract_mismatch`: status and instructions `outputPath` disagree for the
  same artifact.
- `existing_human_content`: an Auto Placeholder output path exists and differs
  from `template`.
- `awaiting_progress_request`: the user asked for status only; no artifact was
  created.
- `missing_change_context`: no explicit or safely resolved current change was
  found.
- `ambiguous_change_context`: more than one candidate change was found; user
  selection is required.
- `awaiting_grill_spec_answer`: one `grill-spec` question was asked and the
  workflow is waiting for the user's answer; `grill-spec.md` must remain absent.
- `awaiting_grill_spec_batch_answer`: a numbered batch of `grill-spec` questions
  was asked and the workflow is waiting for numbered answers; `grill-spec.md`
  must remain absent.
- `invalid_pending_grill_spec_file`: `grill-spec.md` exists with pending or
  incomplete content; because the CLI treats it as done, it must be deleted or
  moved before replaying the gate.
- `proposal_complete_no_ready_artifact`: a progress request arrived but every
  entry in `artifacts[]` is `done` (none `ready`) — the proposal is fully
  advanced and the next step is apply, which is out of this skill's scope
  (see `## NEVER`). Report status only; do not create or guess anything.

### The two JSON calls (orientation only — the reference owns the full contract)

`status --json` gives `schemaName` (must be `hello-spec-v2`) and an ordered
`artifacts[]` with no absolute paths; the next artifact is the FIRST with
`status == "ready"` (there is no `nextReadyArtifact`). `instructions
<artifact-id> --json` gives the absolute `changeDir`, a relative `outputPath`
(a glob for `specs`), and both `instruction` + `template` (always present — pick
the body by Artifact Class). Field tables, the `specs` glob, and the
field → Stop Reason map live in `references/openspec-cli-contract.md` (loaded
above); never guess a path, schema, or artifact order to recover from a missing
field. `grill-spec.md` is complete only under the Interactive Gate's "Completion
rule", never from `artifacts[].status` alone.

## NEVER

Each of these anti-patterns causes a specific, hard-to-detect failure:

- NEVER resolve a change by fuzzy match, newest dir, or most-recent mention when
  several candidates exist — a wrong pick writes to the wrong proposal; stop with
  `ambiguous_change_context` instead.
- NEVER scan unrelated sibling repos or worktrees to "find" a likely change — it
  invents context the user never gave.
- NEVER pick an artifact's body by which field is present — `instruction` and
  `template` are always both present, so choose by Artifact Class or you write a
  bare placeholder where a reasoned artifact belongs.
- NEVER treat a checked box, file existence, or "looks done" wording as a complete
  `grill-spec` — the CLI flips an artifact to `done` on mere file existence, so
  only the evidence/status rule (see "Completion rule (grill-spec completion
  contract)" in Interactive Gate) actually proves it.
- NEVER batch-write all pending user decisions into `grill-spec.md` and stop with
  "please confirm" prose when an interactive question tool exists — the gate is an
  active AskUserQuestion/request_user_input loop, not a checklist for the user to
  open manually.
- NEVER create `grill-spec.md` while any blocking item is not yet
  `Status=user_confirmed` or `Status=resolved_by_evidence` — OpenSpec marks the
  artifact done from file existence alone, so this silently unblocks `tasks`.
- NEVER output `Next Command` as the primary next action while an interactive
  `grill-spec` question or numbered batch can still be asked in the current turn
  — ask the question/batch, then consume and persist the user's answer next turn.
- NEVER consume numeric answers like `1=A` unless `design.md` has a current
  `Asked batch` marker whose `Question map:` line binds `1` to a specific `QID`;
  prefer `Q001=A`.
- NEVER write to a literal `specs/**/*.md` — it is a glob; derive concrete
  `specs/<capability>/spec.md` paths from the `instruction` body.
- NEVER run `openspec-propose`, `openspec-ff-change`, or `openspec-apply-change`,
  generate more than one business artifact, edit business code, run tests/builds,
  or commit/push/archive — all leave this skill's single-step, pre-apply scope.

## Workflow

### Phase 0 - Identity Lock

Once Phase 1 has resolved the change, and before any file write, emit this fixed
identity line as the first status update:

```text
已锁定任务：hello-spec-next；CHANGE_NAME=<change>（source=<explicit-path|explicit-name|cwd|context|sole-active-change>）；本轮只安全推进 hello-spec-v2 的下一个 artifact，不进入 apply，不改业务代码。
```

If the change cannot be resolved (`missing_change_context` /
`ambiguous_change_context`), skip this line and ask for a change name or absolute
path instead.

Forbidden objectives: see `## NEVER` (no openspec-propose/ff-change/apply, no
multi-artifact, no business code/tests/commit/apply).

### Phase 1 - Locate Change

Determine `CHANGE_NAME`, `CHANGE_DIR`, and `REPO_ROOT`.

Resolve the change using the Change Resolution Contract before running any
status or instruction command. If the user gave an explicit path or change name,
that short-circuits. Otherwise gather every implicit source (cwd, stable resume
tokens in the current/immediately preceding context, and a single active
`hello-spec-v2` change under the locked repo) and require exactly one distinct
change among them; if they disagree, are missing, or are otherwise ambiguous,
stop with the corresponding Stop Reason and ask for a change name or absolute
proposal path.

First lock the repo root, then trust the JSON for the schema:

1. Find the nearest ancestor containing an `openspec/` directory; that is
   `REPO_ROOT`. The CLI auto-detects the active schema on its own — from
   `openspec/config.yaml` if the project has one, otherwise from the per-change
   `.openspec.yaml` marker. Do not read either file manually; trust the
   `schemaName` that `status --json` reports.
2. From `REPO_ROOT`, run the status call and read `schemaName` — that field is
   the authority. Only continue when it is `hello-spec-v2` (see Phase 2):

   ```bash
   cd "<REPO_ROOT>" && openspec status --change "<CHANGE_NAME>" --json
   ```

   (Capture stdout only; `openspec --json` writes a progress spinner to stderr,
   so do not merge `2>&1`.)

`openspec` must run from `REPO_ROOT` (the dir containing `openspec/`); it does
not search ancestors, so a child dir errors `Change ... not found`. If a command
fails, cd to the locked `REPO_ROOT` and retry; only ask the user if `REPO_ROOT`
itself could not be resolved. Do not guess across unrelated repos.

### Phase 2 - Verify Schema

Read status JSON and confirm `schemaName` is `hello-spec-v2`.

If not `hello-spec-v2`, stop and explain that this skill is only for
`hello-spec-v2`. Suggest the generic `openspec-continue-change` workflow (if it
is not installed, run `openspec update` to generate it) for generic schemas.

### Phase 3 - Placeholder Fast Path

Intent gate (runs before any file write): the read-only Identity Lock promise
means a status-only turn must never write, even when ready placeholders exist —
auto-creating placeholders here would silently violate it. So if this turn is
status-only (per Intent semantics: a status phrase such as "看一下状态", not a
progress request, not naming the current ready artifact, and not a grill-spec
answer packet), report the status block and stop with `Stopped at:
awaiting_progress_request` now, before the loop below. Enter the loop only for a
progress request or a request that names the current ready artifact. A grill-spec
answer packet (e.g. `Q001=A; Q002=B`) is not status-only and does not enter the
placeholder loop: skip to Phase 4 gate mode so the answer is consumed and
persisted to `design.md`.

Then, while the next ready artifact is in `Auto Placeholder`:

1. Get instructions:

   ```bash
   cd "<REPO_ROOT>" && openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json
   ```

2. Read `template`, `changeDir`, and `outputPath` from JSON; the absolute file
   path is `changeDir` joined with `outputPath`.
3. Apply the overwrite guard:
   - If the file does not exist, write the template verbatim.
   - If it exists and its content is byte-for-byte equal to `template`, treat it
     as already satisfied and do not rewrite it.
   - If it exists and differs from `template`, stop with `Stopped at:
     existing_human_content`; report the path and do not overwrite it.
4. Re-run status.

Exit this loop and proceed to Phase 4 once a non-placeholder artifact becomes
ready, or once no artifact is ready at all. (This only ends the placeholder pass,
not the invocation.)

### Phase 4 - Business Artifact Or Gate

First handle the terminal state: if `artifacts[]` has no `ready` entry at all
(every entry is `done`), the proposal is fully advanced and the next step is
apply, which is out of scope (see `## NEVER`). Report the status block, stop with
`Stopped at: proposal_complete_no_ready_artifact`, and point the user at the apply
workflow. Do not create, guess, or invent a stop reason.

Otherwise, when a non-placeholder artifact is ready:

1. Get its instructions JSON.
2. If artifact is `grill-spec`, enter `grill-spec gate mode` from Interactive
   Gate. Do not just print `grill-with-docs <change>` and stop; the OpenSpec
   instructions must be carried into the current interaction.
3. If artifact is `tasks` or `plan`, first verify `grill-spec.md` exists with
   `## Status: complete` — the durable post-completion signal the gate writes only
   after the evidence/status rule was satisfied (granular evidence then lives in
   `design.md` Decisions, not Open Questions). If `grill-spec.md` exists but its
   `## Status` is anything other than `complete`, stop with
   `invalid_pending_grill_spec_file` and do not proceed.
4. Create exactly one business artifact, then stop. (The Phase 3 intent gate has
   already confirmed this turn is a progress request or names the current ready
   artifact; a status-only turn never reaches here.)

For `plan.md`, enforce the atomic-step gate:

- review points are plain text, never checkboxes;
- each `StepID` checkbox is one atomic execution step;
- code steps include target file, function/method/type, exact change, and
  verification;
- verification steps include targeted command or manual/disabled reason;
- if not enough context exists, write `needs_plan_refinement` and missing
  questions instead of claiming the plan is executable.

### Phase 5 - Output Format

Default finish format:

````markdown
## Status
- Change:
- Schema:
- Progress:
- Auto-created placeholders:
- Created artifact:
- Stopped at:

## Why Stopped
<one short explanation>

## Next Command
```text
hello-spec-next <change>
```

## Suggested /clear Resume
```text
cd <repo root> && hello-spec-next <change>
```
````

Carve-outs from the default format, by Stop Reason:

- `awaiting_grill_spec_answer` / `awaiting_grill_spec_batch_answer`: do not lead
  with `Next Command`. End with the single pending question (+recommended answer)
  or the numbered batch (+exact answer format). The next user message is the
  answer packet; consume and persist it before asking more.
- `proposal_complete_no_ready_artifact`: omit `Next Command` (no next artifact);
  point to the apply workflow, which is out of this skill's scope.
- `missing_change_context` / `ambiguous_change_context`: omit `Next Command`
  (there is no resolved `<change>` to fill in). For ambiguous, list each candidate
  with its source; for missing, ask for an absolute path or change name.

## Success Criteria

A run is correct when these verifiable invariants hold (each is a terse
checkable assertion; the full rules live in the sections above):

- At most one Business Artifact is created per invocation; placeholders may be
  created in one pass.
- An existing human-authored placeholder is never overwritten (overwrite guard,
  Phase 3).
- `tasks` and `plan` are not created until `grill-spec.md` is complete per the
  Interactive Gate's "Completion rule (grill-spec completion contract)".
- When `grill-spec` is ready, the run enters gate mode, keeps `grill-spec.md`
  absent while confirmations are pending (see the Completion rule), asks via the
  interactive tool one decision at a time, or a single numbered batch (1-5
  independent questions) when the tool is unavailable, and stops before
  `tasks` / `plan`.
- A user answer captured during `grill-spec` is immediately persisted to
  `design.md` before the next pending question is asked (`grill-spec.md` written
  only at completion — see the Completion rule).
- Numbered fallback answers are parsed by ID; malformed or missing answers are
  not guessed and are re-asked narrowly.
- Numeric fallback answers are accepted only when `design.md` has a current
  `Asked batch` map; `QID` answers are always preferred.
- A missing/mismatched JSON field produces the matching Stop Reason instead of a
  guessed path or order.
- No business code, test, build, commit, or apply action is performed.
