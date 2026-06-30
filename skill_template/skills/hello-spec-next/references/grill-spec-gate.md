# grill-spec gate mechanics (hello-spec-v2)

Full procedure for `hello-spec-next`'s Interactive Gate. The skill body keeps the
orientation, the persistence override, and the Completion rule; this file owns the
step-by-step gate mode, the User Confirmation Loop, and the persistence rules.
This is loaded MANDATORY only when the ready artifact is `grill-spec`.

The Stop Reason values used below (`awaiting_grill_spec_answer`,
`awaiting_grill_spec_batch_answer`, `invalid_pending_grill_spec_file`) are defined
in the skill body's `### Stop Reasons`; this file uses them, the body defines them.

## grill-spec gate mode

When `grill-spec` is ready, enter gate mode:

1. Run `cd "<REPO_ROOT>" && openspec instructions grill-spec --change "<CHANGE_NAME>" --json`.
   (Capture stdout only; the progress spinner goes to stderr — do not merge `2>&1`.)
2. Treat the returned `instruction` body as binding for paths and completion
   detection. Follow its path overrides:
   - `CONTEXT.md` -> `.ai_doc/spec-workflow/CONTEXT.md`
   - `docs/adr/` -> `.ai_doc/spec-workflow/adr/`
   - `CONTEXT-MAP.md`, if needed -> `.ai_doc/spec-workflow/`

   Persistence override (also stated in the body): the served instruction may say
   you can create `grill-spec.md` with `## Status: pending` while items are
   `pending_user_confirmation`. Do NOT do that. Because the CLI marks an artifact
   `done` on file existence alone, this skill keeps `grill-spec.md` absent until
   the gate is complete and persists all pending state in `design.md` only. The
   served body still governs the path overrides above — only its persistence
   behavior is overridden.
3. Use `grill-with-docs` behavior inline: `grilling` asks one question at a
   time with a recommended answer; `domain-modeling` writes resolved terms and
   justified ADRs to the overridden paths.
4. Read `design.md` Open Questions first, then `specs/**/*.md`, existing
   `.ai_doc/spec-workflow/CONTEXT.md`, and existing ADRs only as needed.
5. For every blocking Open Question, first try to resolve it by concrete
   evidence from code/specs/docs. Evidence-resolved items use
   `Status=resolved_by_evidence` and cite `Evidence=<path:line>`.
6. For items that require the user, write a concrete recommendation and enter the
   User Confirmation Loop below (keep `grill-spec.md` absent until complete — see
   the body's Completion rule).

## User Confirmation Loop

1. Identify pending user-decision items from `design.md` Open Questions. If the
   current user message is an answer packet (`Q001=A`, `Q002=B`,
   `Q003=自定义：...`, `1=A`, `2=B`, `3=自定义：...`, etc.), consume it before
   asking anything new:
   - prefer stable `QID=<answer>` keys such as `Q001=A`;
   - accept numeric aliases (`1=A`) only when `design.md` contains a current
     `Asked batch: <batch-id>` section whose `Question map:` line unambiguously
     maps each display index to a QID;
   - accept `A`/`确认推荐` as the recommendation, `B` as the listed alternative,
     and `自定义:<text>`（半角或全角冒号均可，即 `自定义:` 或 `自定义：`）as the
     user-provided resolution;
   - if an answer is missing, malformed, or references an unknown number, do not
     guess; ask only for the ambiguous item(s).
2. Persist every parsed answer before asking the next batch:
   - keep `grill-spec.md` absent until complete (see the body's Completion rule);
   - set the matching item `Status=user_confirmed`;
   - set `Evidence=<exact user answer>`;
   - update `Resolution=<final answer>`;
   - write the decision back to `design.md` Decisions;
   - remove the resolved item from the active `Asked batch` map;
   - update `.ai_doc/spec-workflow/CONTEXT.md` / ADRs if the instruction requires it.
3. For newly needed user decisions, build questions with:
   - decision title;
   - recommended answer;
   - short rationale;
   - evidence path:line or exact source;
   - options: `A=确认推荐`, `B=<main alternative when meaningful>`,
     `自定义：<your replacement decision>`.
4. If an interactive user-question tool is available in the current mode, use it.
   Preferred tool names by environment: `AskUserQuestion`, `request_user_input`,
   or the platform's direct equivalent. The tool call is the question; do not
   replace it with a plain assistant paragraph. Ask exactly one question through
   the tool, then persist its answer and continue the loop when the runtime
   allows.
5. If the session says Default mode, or the attempted tool returns unavailable,
   treat the interactive tool as unavailable. Use numbered batch fallback:
   - if there are 1-5 pending questions and they are independent, ask them all in
     one numbered batch;
   - if there are more than 5, ask the first 3-5 only;
   - if some questions depend on earlier answers, ask only the dependency root(s).
6. Before showing a numbered batch, persist a lightweight `Asked batch` marker in
   `design.md` Open Questions, not in `grill-spec.md`. The marker must include:
   - `Asked batch: GATE1-BNNN`
   - `Question map: 1=Q001, 2=Q002, ...`
   - `Interaction mode: numbered_batch_fallback`
   This marker is the only source of truth for consuming numeric answers after
   `/clear` or context loss.
7. In numbered batch fallback, stop with `Stopped at: awaiting_grill_spec_batch_answer`,
   `interaction_mode=numbered_batch_fallback`, and end with the batch plus this
   answer format:

   ```text
   请按 QID 回复，数字也可用但 QID 更稳：
   Q001=A
   Q002=B
   Q003=自定义：<你的决策>
   ```

## Persistence rules

- Persist progress in `design.md` Open Questions and decisions while the gate is
  pending. Do not use `grill-spec.md` as a pending checklist.
- If a previous run already created `grill-spec.md` with `## Status` other than
  `complete`, treat it as an invalid pending output marker: stop with
  `Stopped at: invalid_pending_grill_spec_file` and tell the user to delete or
  move that exact file outside the change output path before replaying the gate.
- If an interactive question tool is available, ask with the tool, wait for the
  answer, persist the answer, then continue the gate loop or stop only at the end
  of the invocation. If asking the question yields control back to the user, stop
  with `Stopped at: awaiting_grill_spec_answer` and keep `grill-spec.md` absent.
- If only numbered batch fallback is available, the batch prompt itself is the
  pending state. Persist only the lightweight `Asked batch` marker in
  `design.md`; do not create `grill-spec.md`. Consume the user's next answer
  packet and persist it before asking another batch.
- While pending items remain, keep unresolved content visible in `design.md`
  Open Questions. Do not clear Open Questions prematurely.
- For resolved items, write conclusions back to `design.md` Decisions and update
  `.ai_doc/spec-workflow/CONTEXT.md` / ADRs when the gate instruction requires
  it.
- At completion (criteria per the body's Completion rule), clear `design.md` Open
  Questions, create `grill-spec.md` with `## Status` = `complete`, list touched
  CONTEXT terms / ADRs, then stop — do not generate `tasks` / `plan` in the same
  invocation. After completion the durable completeness signal is `grill-spec.md`
  `## Status: complete` (only written here, after evidence); the granular
  per-question evidence now lives in `design.md` Decisions, not Open Questions.
