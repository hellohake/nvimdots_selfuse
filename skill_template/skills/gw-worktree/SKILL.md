---
name: gw-worktree
description: Create or checkout Git worktree development directories through the user's local `gw-add` zsh helper. Use whenever the user asks to "拉一个 worktree", "checkout 已有分支到 worktree", "用 gw-add 建分支", "新建开发分支目录", or, in a worktree/branch context, gives a branch-like name such as 004-init-engine-framework. This skill must distinguish existing-branch checkout from new-branch creation, preflight-check target paths, and then run `gw-add`.
---

# GW Worktree

Create or checkout a Git worktree by translating the user's natural-language request into a safe `gw-add` command.

The user's local `gw-add` function is the source of truth for actual worktree creation. This skill should not reimplement `git worktree add`; it should prepare good inputs, check obvious risks, and call `gw-add`.

## What `gw-add` Expects

Verified local contract (from `~/.zshrc`):

```bash
gw-add <branch> [base] [-d <dir>]
```

- 1st positional -> `branch` (created or checked out).
- 2nd positional -> `base` (used only when creating a NEW branch).
- `dir` -> set via the `-d`/`--dir` flag, or as a 3rd positional **only when a base is also given**. If omitted, `dir` defaults to `branch`.

**Positional-order trap.** Positional parsing fills `branch`, then `base`, then `dir`, so a bare `gw-add <branch> <dir>` with no base misreads `<dir>` as `base` and the directory silently falls back to the branch name. Always pass the directory with `-d <dir>`: mandatory in the no-base existing-branch case, and safe (so still preferred) when a base is present.

**Target-directory redirect rules.** Default target is `../<dir>` (peer worktree). It redirects to `./<dir>` in two cases: (1) a bare-root repo whose `.git` file contains `gitdir: ./.bare`, e.g. `<repo>/search_loader`; (2) `./.coco` exists but `../.coco` does not, even in a non-bare repo (`~/.zshrc:273`). Inside a normal worktree such as `<repo>/search_loader/main` neither fires, so the target stays `../<dir>`. Predict `target_dir` with these rules before any preflight check.

On success `gw-add` enters the new worktree in the spawned shell and prints `🚀 Ready: <absolute-path>` as its final line; failures print lines starting with `❌`. Because agent commands run in a subprocess, that `cd` does not move the user's interactive shell — so always report the final path plus a `cd` command after success.

`gw-init-links` runs last and creates a shared symlink only when the target path is absent or already a symlink; it never overwrites a real file or directory. This matters for branches that carry their own `AGENTS.md`, `.trae`, or `openspec` entries.

## Workflow

Think detection-first: identifying an existing branch before naming anything is what prevents wrapping it in a wrong semantic prefix. Each step below leads with the decision it turns on.

1. Understand the request.
2. Ask: does this token already name a branch? Run the detection commands below before inventing any name, then classify as existing-branch checkout or new-branch creation.
3. Derive `branch`, `base`, `dir`, and `target_dir` from that classification.
4. Ask: is this a NEW branch? Only then is a base required — if `base` is not explicit, stop and ask which base branch to use. Existing-branch checkout needs no base.
5. Ask: does `target_dir` already exist? Preflight-check it (remember the `./` vs `../` redirect rules) and stop if it does.
6. Show the execution plan.
7. Execute `gw-add` through zsh, then report the result and the next `cd` command.

## Existing Branch Rule

If the user gives a branch-like token, first test whether it is an existing branch before inventing a semantic branch name.

Branch-like examples:

- `004-init-engine-framework`
- `feature/foo`
- `feat/bar`
- `release/2026`
- `debug/lihao_daily`

Detection commands:

```bash
git show-ref --verify --quiet refs/heads/<branch>
git show-ref --verify --quiet refs/remotes/origin/<branch>
git worktree list --porcelain
```

This `show-ref refs/heads`/`refs/remotes` detection is intentionally stricter than `gw-add`'s internal `git rev-parse --verify` (`~/.zshrc:291,294`), which also resolves tags and commit-ish: a tag named the same as a wanted new branch is the one edge case where your "no branch -> create" classification and `gw-add`'s actual checkout diverge. So report branch-existence facts from these commands rather than silently assuming the create path.

If `refs/heads/<branch>` or `refs/remotes/origin/<branch>` exists, treat the request as checkout of that exact branch:

- `branch=<branch>` exactly as provided.
- `base=not_needed`.
- `dir=<last path segment or user-provided dir>`, e.g. `004-init-engine-framework` for branch `004-init-engine-framework`.
- command: `gw-add <branch> -d <dir>` (`-d` is required with no base positional; see the positional-order trap above).

Do not add `feat/`, `fix/`, or any other semantic prefix to an existing branch. Do not ask for a base branch for an existing branch checkout.

If the branch is already checked out in another worktree, stop and report that path from `git worktree list --porcelain`; do not create another worktree for the same branch.

## New Branch Base Rule

The base branch must be explicit only when creating a new branch.

Valid explicit bases include:

- `master`
- `main`
- a named development branch in the user's request
- a current branch only if the user explicitly says to use the current branch

If the user omits the base, ask one short question and do not run any command:

```text
你想从哪个 base 创建？请给我 master/main/当前开发分支名中的一个。
```

If useful, include the detected current branch as context, but do not silently choose it.

If `base=main` is requested but no `main` exists while `master` does, `gw-add` silently branches from `master` (`~/.zshrc:281`). Reflect the effective `master` in the reported plan and success output so the recorded `base=` does not mislead.

## Naming Rules

For new branches, the delta-bearing convention is: branch = `<type>/<slug>`, dir = the bare slug with the prefix dropped. Pick `type` from the standard gitflow set (`feat`/`fix`/`refactor`/`chore`/`docs`) by intent; choose a concise kebab-case slug from stable technical nouns in the user's wording, short enough to scan in `git worktree list`.

Examples (note: branch keeps the prefix, dir drops it):

| User intent | Branch | Dir |
| --- | --- | --- |
| 图片预加载 topvv 优化 | `feat/image-preload-topvv` | `image-preload-topvv` |
| 修复 telescope 搜索过滤 | `fix/telescope-search-filter` | `telescope-search-filter` |
| 重构 packer 路由 | `refactor/packer-router` | `packer-router` |
| 更新 zsh worktree 命令 | `chore/zsh-worktree-command` | `zsh-worktree-command` |

For existing branches, preserve the branch name and only simplify the directory when the branch contains path separators. Examples:

| Existing Branch | Dir |
| --- | --- |
| `004-init-engine-framework` | `004-init-engine-framework` |
| `feat/004-init-engine-framework` | `004-init-engine-framework` |
| `debug/lihao_daily` | `lihao_daily` |

## Preflight Checks

Run these checks before `gw-add`:

```bash
git rev-parse --is-inside-work-tree
git branch --show-current
git show-ref --verify --quiet refs/heads/<branch>
git show-ref --verify --quiet refs/remotes/origin/<branch>
git worktree list --porcelain
test -e "<target_dir>"
```

Predict `<target_dir>` with the redirect rules in "What `gw-add` Expects" above (`../<dir>` default; `./<dir>` under bare-root or the `.coco` trigger). One preflight-only addition: if the user's requested directory already starts with `./` or `../`, `gw-add` uses it verbatim — check that exact path.

If `<target_dir>` exists, stop and ask the user for a different directory name. Do not auto-append suffixes such as `-2`.

## Execution

Use zsh interactive mode so the user's `.zshrc` function is loaded:

```bash
# New branch (base required), -d sets the directory unambiguously:
zsh -ic 'gw-add <branch> <base> -d <dir>'

# Existing branch checkout (no base), -d sets the directory:
zsh -ic 'gw-add <existing-branch> -d <dir>'
```

Always pass the directory with `-d` (see the positional-order trap above). If `zsh -ic` reports `command not found: gw-add`, the function did not load — confirm with `zsh -ic 'type gw-add'` and surface the error instead of falling back to raw `git worktree add`.

Quote arguments safely. If a generated name contains spaces or unsafe shell characters, regenerate it as a kebab-case slug instead of passing the unsafe string through.

Before executing, show a compact plan:

```text
Plan:
mode=<existing_branch|new_branch>
base=<base-or-not_needed>
branch=<branch>
dir=<dir>
target=<target_dir>
command=<the exact gw-add command, e.g. gw-add <branch> <base> -d <dir>>
```

Then execute. If the command fails (any `❌` line), report the failing command and the important error lines. Do not retry with a different branch or directory without user confirmation.

## Success Response

`gw-add` prints `🚀 Ready: <absolute-path>` on success; use that exact path. Keep the response short:

```text
Created worktree:
branch=<branch>
base=<base>
path=<absolute-path from the 🚀 Ready line>

Next:
cd <path>
```

The agent subprocess entered the directory during execution, but the user's interactive shell still needs the `cd` command (see the subprocess caveat under "What `gw-add` Expects").

## Non-Goals

- Do not edit the `gw-add` or `gw-init-links` zsh functions unless the user explicitly asks; the helper is the source of truth and silent changes break every future worktree.
- Do not create a new branch when the base is missing — guessing the base can fork work off the wrong commit, which is invisible until much later.
- Do not auto-rename on directory conflicts; a silent `-2` suffix hides that you targeted the wrong parent dir (e.g. running from a worktree instead of the bare root).
- Do not infer hidden team branch naming conventions beyond the small prefix list above.
- Do not commit, push, or open a merge request.
