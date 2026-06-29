# openspec CLI JSON Contract (hello-spec-v2)

Authoritative field contract for the two `openspec` calls this skill parses.
Verified against `openspec` v1.2.0. The skill body keeps only an orientation
summary; this file is the source of truth for field names, the next-ready rule,
and the missing/mismatch → Stop Reason mapping.

## Status JSON

Run `openspec status --change "<CHANGE_NAME>" --json` after `REPO_ROOT` and
schema discovery are locked. Both `openspec` calls must run from `REPO_ROOT`
(the dir directly containing `openspec/`); the CLI does not walk up ancestors,
so prefix each with `cd "<REPO_ROOT>" &&`. It emits:

- `changeName`: the change being reported.
- `schemaName`: must equal `hello-spec-v2`.
- `isComplete`, `applyRequires[]`: informational; do not gate on them here.
- `artifacts[]`: ordered list; each entry has `id`, `outputPath` (relative to
  the change dir), and `status` (`done` | `ready` | `blocked`). A `blocked`
  entry also carries `missingDeps[]`.

There is no `nextReadyArtifact` field. Derive the next artifact yourself: it is
the FIRST entry in `artifacts[]` whose `status == "ready"`. If none is `ready`,
report status only. Reading readiness from `artifacts[].status` is the
sanctioned method, not the inference this skill forbids — `status` is the CLI's
own verdict, so trusting it is the opposite of guessing from memory or naming.

Status JSON intentionally has no `changeDir` and no absolute paths; the absolute
change dir comes from the instructions call below. If `schemaName` or
`artifacts[]` is absent, stop with `Stopped at: missing_status_contract` and
name the missing field.

## Instructions JSON

Run `openspec instructions <artifact-id> --change "<CHANGE_NAME>" --json` for
the artifact you derived as ready. It emits:

- `artifactId`: must match the ready artifact.
- `changeDir`: ABSOLUTE path to the change dir. Source `CHANGE_DIR` from here.
- `outputPath`: this artifact's path relative to `changeDir`. Join them for the
  absolute file path — except `specs`, whose `outputPath` is a glob (see below).
- `instruction` (singular): the prose describing how to produce the artifact.
- `template`: the artifact's starter / placeholder content.
- `dependencies[]` (each with `id`, `done`, `path`, `description`) and
  `unlocks[]`: useful for explaining what a stop is waiting on.

`instruction` and `template` are BOTH always present and non-empty for EVERY
artifact — placeholders and business artifacts alike (e.g. brainstorm ships a
~1.8k-char instruction plus a ~600-char template; even troubleshoot ships both).
So never decide what an artifact is by which field exists. Choose the body by
the artifact's class from the skill's Artifact Classes list:

- Auto Placeholder (`troubleshoot`, `revise`, `manual-test-commands`): write the
  `template` verbatim; its `instruction` only restates "copy the template".
- Business Artifact (`brainstorm`, `proposal`, `specs`, `design`, `tasks`,
  `plan`): follow the `instruction`; `template` is the skeleton it fills in.

### specs outputPath is a glob, not a writable file

The `specs` artifact's `outputPath` is `specs/**/*.md` (it generates one file per
capability), not a single path. Never write to a literal `.../specs/**/*.md`.
For `specs`, derive concrete `specs/<capability>/spec.md` paths from the
capabilities named in the `instruction` body and create one file each.
`path_contract_mismatch` still works for `specs`: status and instructions report
the identical glob string, so they match.

### Stop conditions

If instructions `outputPath` disagrees with this artifact's `outputPath` in
status JSON, stop with `Stopped at: path_contract_mismatch`. Stop with `Stopped
at: missing_instructions_contract` if `artifactId`, `changeDir`, or `outputPath`
is missing, or if the body field for this artifact's class is EMPTY (`template`
empty for an Auto Placeholder, `instruction` empty for a Business Artifact). A
present-but-unused body field is normal and is never a stop reason. v1.2.0 always
populates both bodies, so the empty-body branch is drift-insurance for a future
contract change, not a path the current CLI exercises.

The CLI also returns `changeName`, `schemaName`, and `description` on this call;
they are informational and not load-bearing for path/body resolution.

## Field → Stop Reason quick map

| Condition observed in JSON | `Stopped at:` value |
|---|---|
| status missing `schemaName` or `artifacts[]` | `missing_status_contract` |
| instructions missing `artifactId`, `changeDir`, or `outputPath` | `missing_instructions_contract` |
| class-appropriate body empty (`template` for placeholder / `instruction` for business) | `missing_instructions_contract` |
| status `outputPath` ≠ instructions `outputPath` for same artifact | `path_contract_mismatch` |

Never infer a path, schema, or artifact order to "recover" from a missing field;
emit the matching stop instead.
