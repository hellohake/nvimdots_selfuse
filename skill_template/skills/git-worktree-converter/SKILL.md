---
name: git-worktree-converter
description: Use when the user wants to convert or plan converting an ordinary single-checkout Git repository into the user's bare-root plus peer-worktree layout, migrate/normalize a repo to worktree mode, make a repo look like the search_loader worktree format, detect main/master primary before conversion, or says 转换 worktree / 迁移到 bare-root. Safety gate for destructive dry-run-first repo layout migration; requires confirmed primary. Not for creating feature worktrees or editing shell helpers.
---

# Git Worktree Converter

Convert a normal Git checkout into the user's preferred layout:

```text
repo-root/
├── .bare/          # Git database, formerly .git
├── .git            # pointer file: gitdir: ./.bare
├── main/           # current branch checkout when current == primary
├── feature-dir/    # future peer worktrees
├── .coco/ .ai_doc/ .trae/ [openspec/] [specs/]
└── AGENTS_meta.md  # shared agent instructions; worktrees link AGENTS.md -> ../AGENTS_meta.md
```

After conversion, future feature directories should be created by the existing `gw-worktree` skill / `gw-add` helper.

Important behavior: `repo-root/` is a bare Git control directory, not a working tree. Git tools that need a worktree, including `lazygit`, must run from `repo-root/main/` or another peer worktree. Do not "fix" this by pointing root `.git` at `.bare/worktrees/main`; that makes Git treat the root itself as the worktree and breaks the intended peer layout. The user's shell wrapper may auto-route `lazygit` from root to `main/`, but the repository layout should stay bare-root.

The converter must guarantee these root-level shared assets exist for future `gw-add` symlinks:

- `.trae/`
- `AGENTS_meta.md`

If they did not exist before conversion, create empty `.trae/` and a small placeholder `AGENTS_meta.md`. Link them into the converted checkout when no real checkout entry would be overwritten.

`openspec/` and `specs/` are shared only when they are untracked root-level directories before conversion. If either directory is tracked by Git, leave the tracked directory inside the checkout (`<repo-root>/<checkout-dir>/openspec` or `.../specs`) and do not create a misleading empty root copy. Create a root-level shared `openspec/` only when the user explicitly asks for that with `--ensure-root-openspec`.

## Before You Mutate Anything

This conversion relocates the Git database and the working tree. It is ordinary filesystem work, but it cannot be cleanly undone in place — so treat every run as a destructive migration, not a cleanup command. Before mutating, ask yourself, and stop to ask the user if any answer is "no" or "unsure":

- **Did the user actually ask to execute?** If they only want a plan, design, or check, stay in dry run.
- **Is the primary branch confirmed by the user** (not merely inferred)? A wrong primary bakes the wrong canonical checkout into the layout.
- **Is the working tree clean?** A dirty tree means uncommitted work gets shuffled mid-conversion; require an explicit `--allow-dirty` otherwise.
- **Is it already converted?** A `.bare/`, a `.git` pointer file, or a `bare` entry in `git worktree list` means re-running risks clobbering a working layout.
- **Does the target checkout directory already exist?** Converting into an existing directory would collide with it.

## NEVER

- NEVER execute a conversion from an inferred primary branch. `--execute` requires a user-confirmed `--primary <branch>`.
- NEVER point root `.git` at `.bare/worktrees/main`; the root must remain a bare Git control directory.
- NEVER hand-roll the migration with ad hoc `git`/`mv` commands when the bundled script can run.
- NEVER extract tracked `openspec/` or `specs/` into root shared copies unless the user explicitly asks to change tracked repository layout.
- NEVER treat missing root `openspec/` as a failed conversion when the source `openspec/` was tracked or absent and `--ensure-root-openspec` was not requested.
- NEVER create feature worktrees here; use the `gw-worktree` skill / `gw-add` after conversion.
- NEVER edit `~/.zshrc`, `gw-add`, or other shell helpers as part of this conversion unless the user asks.
- NEVER improvise recovery after a partial move. Report the script's backup path and stop unless the user explicitly asks for recovery.

## Primary Branch Detection

Do not assume `master`, and do not execute purely from inference.

Use this order to produce a candidate primary branch in the dry-run plan:

1. User-specified primary branch, if provided.
2. `refs/remotes/origin/HEAD`, via `git symbolic-ref --short refs/remotes/origin/HEAD`.
3. Local branch priority: `master`, `main`, `develop`, `dev`.
4. Current branch as fallback only when explaining the plan; ask the user before executing if this feels ambiguous.

Execution rule:

- Always show the detected candidate first.
- Before `--execute`, require explicit user confirmation of the primary branch.
- Pass the confirmed branch as `--primary <branch>` in the execution command, even when the candidate came from `origin/HEAD`.

Good confirmation question:

```text
我检测到主分支候选是 <branch>（来源：<source>）。是否确认用它作为 primary？确认后我会用 --primary <branch> 执行转换。
```

Checkout directory rule:

- If current branch equals primary branch, use `main/` as the canonical directory name. This mirrors `search_loader`, whose primary branch is `master` but primary checkout directory is still `main/`.
- If current branch is not primary, use a sanitized slug of the current branch, or ask the user for `--checkout-dir`.

## Use The Script

Prefer the bundled script instead of hand-writing shell sequences. It is the load-bearing, tested path for a destructive operation: do NOT modify it or substitute hand-rolled `git`/`mv` commands, because the script keeps the backup-on-failure and confirmation gates that ad hoc shell would silently drop.

The script lives with this skill at `scripts/convert_to_worktree_layout.py`. Resolve it relative to this SKILL.md's own directory (shown below as `$SKILL_DIR`) so it runs from whichever copy is active; never hardcode an absolute path into another tree, which breaks when the skill is synced/installed elsewhere.

```bash
python3 "$SKILL_DIR/scripts/convert_to_worktree_layout.py" --repo <repo>
```

The script prints a JSON dry-run plan by default. Only execute after reviewing that plan:

```bash
python3 "$SKILL_DIR/scripts/convert_to_worktree_layout.py" \
  --repo <repo> \
  --primary <branch-if-needed> \
  --checkout-dir <dir-if-needed> \
  --execute
```

The script enforces the confirmation rule: `--execute` without `--primary` returns an error. This prevents a future agent from silently converting a repository using an unreviewed branch guess.

Useful options:

| Option | Use |
| --- | --- |
| `--primary <branch>` | Override primary branch detection when origin/HEAD is absent or wrong. |
| `--checkout-dir <dir>` | Override the target directory for the current checkout. Must be one directory name under repo root. |
| `--allow-dirty` | Permit modified/untracked files. Use only after the user explicitly accepts the risk. |
| `--extract-tracked-shared` | Move tracked shared files such as `AGENTS.md` out to root and symlink them back. This changes Git-tracked paths, so use only when the user wants that normalization. |
| `--ensure-root-openspec` | Force creation of root `openspec/` when no untracked `openspec/` was extracted. Use only when the user explicitly wants root-level shared OpenSpec assets; never use it just because the checkout has a tracked `openspec/`. |
| `--execute` | Actually convert. Without this, the script is dry-run only. |

## `openspec/` and `specs/` Handling

Before conversion, inspect whether these directories are tracked:

```bash
git -C <repo> ls-files openspec specs
```

Use this decision table:

| Original state | Root after conversion | Checkout after conversion |
| --- | --- | --- |
| `openspec/` untracked | `repo-root/openspec/` with original content | symlink `checkout/openspec -> ../openspec` |
| `specs/` untracked | `repo-root/specs/` with original content | symlink `checkout/specs -> ../specs` |
| `openspec/` tracked | no root `openspec/` by default | real tracked `checkout/openspec/` |
| `specs/` tracked | no root `specs/` by default | real tracked `checkout/specs/` |
| no `openspec/` | no root `openspec/` by default | no checkout symlink |

Do not use `--extract-tracked-shared` as a workaround for tracked `openspec/` or
`specs/` unless the user explicitly wants to change tracked repository layout.
It can create two sources of truth for proposal/spec files. Prefer leaving
tracked OpenSpec assets in the checkout.

## Manual Verification Commands

After conversion, run:

```bash
git -C <repo-root>/<checkout-dir> worktree list --porcelain
git -C <repo-root>/<checkout-dir> status --short
cat <repo-root>/.git
cat <repo-root>/<checkout-dir>/.git
git -C <repo-root> rev-parse --show-toplevel  # expected to fail: root is not a worktree
```

Expected shape:

- Root `.git` is a file containing `gitdir: ./.bare`.
- The checkout's `.git` is a file pointing into `.bare/worktrees/<checkout-dir>`.
- `git worktree list --porcelain` includes a `bare` entry for `<repo-root>/.bare` and a normal worktree entry for the checkout directory.
- `git -C <repo-root> rev-parse --show-toplevel` fails with `this operation must be run in a work tree`; this is expected for the bare root.
- Root `.trae/` and `AGENTS_meta.md` exist. Root `openspec/` exists only if it was extracted from an untracked directory or `--ensure-root-openspec` was explicitly used.
- Root `specs/` exists only if it was extracted from an untracked directory.
- Shared untracked directories/files that existed at repo root are linked into the checkout when possible.

## What To Report

You can format the summary yourself; just make sure the safety-critical, non-obvious fields survive:

- **Dry run** — surface the plan the user must confirm before execution: `primary` branch *with its source* (e.g. `origin/HEAD` vs `current branch fallback`), `primary_confirmed` (true/false), the `checkout_dir` and its source, the dirty count, and the exact `--primary <branch> --execute` command to run next. The source attribution is what lets the user catch a wrong primary before it is baked in.
- **Success** — report the new `root`, the `checkout` path, the confirmed `primary`, the `backup` path, and the key result of the verification commands.
- **Failure after files moved** — report the backup path from the script output and stop. Do not improvise recovery unless the user explicitly asks; the backup is the only clean rollback.

## Non-Goals

- Do not create feature worktrees directly; use `gw-worktree` after conversion. This skill only converts the layout; worktree creation is that skill's job and keeps the two concerns testable in isolation.
- Do not rename branches. Conversion preserves history exactly; a rename is a separate, user-visible decision that would surprise someone who only asked to relocate the Git database.
- Do not commit, push, rebase, or fetch unless the user separately asks. Conversion only moves `.git` → `.bare` and adds a worktree; history operations are a distinct concern and risk surprising the user mid-migration.
- Do not edit `~/.zshrc` or `gw-add` unless the user asks to improve those helpers. They are shared tooling outside this conversion's blast radius.
