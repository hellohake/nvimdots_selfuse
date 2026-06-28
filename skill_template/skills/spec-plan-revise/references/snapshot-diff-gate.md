# Snapshot Diff Review Gate

Use this reference only when `spec-plan-revise` enables serial subagent mode. The point is to verify proposal document edits even when the files are untracked or gitignored; `git diff` alone is not enough.

## Workflow

1. Determine the authorized write set.
   - Single-file example: `<change>/design.md`
   - Directory example: `<change>/specs/**`
   - Files outside the authorized set must not change.
2. Before starting the worker, snapshot the authorized write set to:
   `/tmp/spec-plan-revise-snapshots/<change>/<artifact>/<timestamp>/before/`
3. If an authorized file does not exist yet, record a `MISSING` marker in the snapshot directory.
4. After the worker finishes, review the real filesystem against the snapshot:
   - Single file: `diff -u before/file.md current/file.md`
   - Directory: `diff -ru before/specs current/specs`
   - New files: confirm every new file is inside the authorized write set and review its full content.
   - Deleted files: fail review unless the `Revision Packet` explicitly authorized deletion.
5. Review only the worker result, snapshot diff, and necessary context snippets. Do not redo the worker's full analysis.
6. After review passes, update the main `Revision Packet` working copy before launching the next downstream worker.

## Pass Conditions

- Only authorized artifact files changed.
- No code, `backup.md`, or `revise.md` changed.
- The diff implements the `Revision Packet` deviation and expected change.
- The diff respects all constraints and Non-Goals.
- The target artifact still follows its schema/template shape.
- The worker result states downstream impact clearly.

## Failure Handling

- Small issue: the main agent may apply a local patch and record why.
- Medium issue: ask the same worker to revise once, passing snapshot diff and review comments.
- Direction conflict or constraint violation: stop and ask the user.
- Two failed worker attempts: stop and report current diff, failure reason, and suggested choices.

## Snapshot Lifecycle

- Review pass: delete the worker's snapshot directory immediately after capturing the useful diff summary.
- Review fail with retry: keep the snapshot until the retry passes, then delete it.
- Need user decision: keep the snapshot and report `SNAPSHOT_DIR=<abs path>` in the response.
- End of skill run: best-effort delete snapshots whose reviews passed.
- Never copy snapshots into the repository.
