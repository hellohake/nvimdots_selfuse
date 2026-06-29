# openspec CLI JSON Contract (hello-spec-v2)

Authoritative field contract for the two `openspec` calls this skill parses.
Verified against `openspec` v1.2.0. The skill body keeps only an orientation
summary; this file is the source of truth for field names, the next-ready rule,
and the missing/mismatch → Stop Reason mapping.

## Status JSON

Run `openspec status --change "<CHANGE_NAME>" --json` after `REPO_ROOT` and
schema discovery are locked. It emits:

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
  absolute file path.
- `instruction` (singular): the body to follow for a Business Artifact.
- `template`: the verbatim content for an Auto Placeholder.
- `dependencies[]` (each with `id`, `done`, `path`, `description`) and
  `unlocks[]`: useful for explaining what a stop is waiting on.

If instructions `outputPath` disagrees with this artifact's `outputPath` in
status JSON, stop with `Stopped at: path_contract_mismatch`. If `changeDir`,
`outputPath`, or the body field (`instruction` for Business Artifacts,
`template` for Auto Placeholders) is missing, stop with `Stopped at:
missing_instructions_contract`.

The CLI also returns `changeName`, `schemaName`, and `description` on this call;
they are informational and not load-bearing for path/body resolution.

## Field → Stop Reason quick map

| Condition observed in JSON | `Stopped at:` value |
|---|---|
| status missing `schemaName` or `artifacts[]` | `missing_status_contract` |
| instructions missing `changeDir`, `outputPath`, or body field | `missing_instructions_contract` |
| status `outputPath` ≠ instructions `outputPath` for same artifact | `path_contract_mismatch` |

Never infer a path, schema, or artifact order to "recover" from a missing field;
emit the matching stop instead.
