# OpenSpec CLI Contract (hello-spec-v2)

Exact field names and command shapes for the `openspec` calls this workflow
drives. Verified against `openspec` v1.2.0. The JSON shape is specific and easy
to misremember — trust THIS file, not recollection.

## Project schema config

The project schema lives in `openspec/config.yaml` (top-level `schema:` key),
auto-detected by the CLI:

```yaml
schema: hello-spec-v2
```

A repo-root `.openspec.yaml` is NOT the project config. `.openspec.yaml` only
appears as a per-change marker at `openspec/changes/<change>/.openspec.yaml`.

`openspec status --json` WITHOUT `--change` does not report the project schema;
it lists active changes or errors asking for `--change`. To learn the schema
before any change exists, read `openspec/config.yaml` directly.

## `openspec status --change <name> --json`

Top-level keys: `changeName`, `schemaName`, `isComplete`, `applyRequires`,
`artifacts`.

Each `artifacts[]` entry has exactly `id`, `outputPath`, `status` (blocked
entries also carry `missingDeps`). `status` is one of `done` / `ready` /
`blocked`.

- The next artifact to act on = the FIRST entry with `status == "ready"`. There
  is NO `nextReadyArtifact` field; scan the list yourself.
- Status output has NO `resolvedOutputPath` and NO `changeDir`.

## `openspec instructions <artifact-id> --change <name> --json`

Keys: `changeName`, `artifactId`, `schemaName`, `changeDir`, `outputPath`,
`description`, `instruction`, `template`, `dependencies`, `unlocks`.

- `changeDir` is absolute; `outputPath` is relative; `instruction` is singular.
- Build the write target as `<changeDir>/<outputPath>`. Because status JSON has
  no `resolvedOutputPath`, this is the only correct way to the absolute path.

## Placeholder vs business detection

Decide from `instruction` semantics, never a memorized ID list (so it survives
schema changes):

- **Placeholder**: `instruction` directs you to create the file verbatim from
  `template` with no reasoning — wording like "create as an empty placeholder
  using the template verbatim" / "Copy the template content as-is".
- **Business**: `instruction` instructs synthesis or invokes another skill.

In the current schema the placeholders are `troubleshoot`, `revise`, and
`manual-test-commands`. Treat the instruction text as authoritative if the
schema's placeholder set changes.

## Create command

```bash
openspec new change "<CHANGE_NAME>"
```
