---
name: git-worktree-converter
description: Use when the user wants to convert an ordinary single-checkout Git repository into the user's bare-root plus peer-worktree layout, migrate a repo to worktree mode, normalize a non-worktree Git directory, or asks to make a repo look like the search_loader worktree format. Also use for main/master/primary-branch detection before conversion.
---

# Git Worktree Converter

Convert a normal Git checkout into the user's preferred layout:

```text
repo-root/
├── .bare/          # Git database, formerly .git
├── .git            # pointer file: gitdir: ./.bare
├── main/           # current branch checkout when current == primary
├── feature-dir/    # future peer worktrees
├── .coco/ .ai_doc/ .trae/ openspec/ specs/
└── AGENTS_meta.md  # shared agent instructions; worktrees link AGENTS.md -> ../AGENTS_meta.md
```

After conversion, future feature directories should be created by the existing `gw-worktree` skill / `gw-add` helper.

Important behavior: `repo-root/` is a bare Git control directory, not a working tree. Git tools that need a worktree, including `lazygit`, must run from `repo-root/main/` or another peer worktree. Do not "fix" this by pointing root `.git` at `.bare/worktrees/main`; that makes Git treat the root itself as the worktree and breaks the intended peer layout. The user's shell wrapper may auto-route `lazygit` from root to `main/`, but the repository layout should stay bare-root.

The converter must guarantee these root-level shared assets exist for future `gw-add` symlinks:

- `.trae/`
- `openspec/`
- `AGENTS_meta.md`

If they did not exist before conversion, create empty `.trae/` and `openspec/` directories and a small placeholder `AGENTS_meta.md`. Link them into the converted checkout when no real checkout entry would be overwritten.

## When To Stop

Stop and ask before mutating anything if:

- The repository is dirty, unless the user explicitly accepts `--allow-dirty`.
- The repo already has `.bare/`, a `.git` pointer file, or `git worktree list` shows it is already converted.
- The target checkout directory already exists.
- The primary branch has not been explicitly confirmed by the user for this conversion.
- The user did not ask to execute conversion and only wants a design, plan, or check.

This conversion moves the Git database and the working tree. It is ordinary filesystem work, but it is not a casual cleanup command.

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

Prefer the bundled script instead of hand-writing shell sequences:

```bash
python3 /data00/home/lihao.hellohake/.agents/skills/git-worktree-converter/scripts/convert_to_worktree_layout.py --repo <repo>
```

The script prints a JSON dry-run plan by default. Only execute after reviewing that plan:

```bash
python3 /data00/home/lihao.hellohake/.agents/skills/git-worktree-converter/scripts/convert_to_worktree_layout.py \
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
| `--execute` | Actually convert. Without this, the script is dry-run only. |

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
- Root `.trae/`, `openspec/`, and `AGENTS_meta.md` exist.
- Shared untracked directories/files that existed at repo root are linked into the checkout when possible.

## Response Format

For dry runs, summarize:

```text
Plan:
repo=<repo-root>
current=<branch>
primary=<branch> (<source>)
primary_confirmed=<true|false>
checkout_dir=<dir> (<source>)
dirty=<count>
shared_entries=<names>

Next command:
python3 ... --primary <confirmed-branch> --execute
```

For successful execution:

```text
Converted:
root=<repo-root>
checkout=<repo-root>/<dir>
primary=<branch>
backup=<backup-path>

Verified:
<commands run and key result>

Next:
cd <repo-root>/<dir>
gw-add <new-branch> <primary-or-base> <dir>
```

If conversion fails after moving files, report the backup path from the script output and stop. Do not improvise recovery unless the user explicitly asks.

## Non-Goals

- Do not create feature worktrees directly; use `gw-worktree` after conversion.
- Do not rename branches.
- Do not commit, push, rebase, or fetch unless the user separately asks.
- Do not edit `~/.zshrc` or `gw-add` unless the user asks to improve those helpers.
