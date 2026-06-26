---
name: gw-worktree
description: Create or checkout Git worktree development directories through the user's local `gw-add` zsh helper. Use whenever the user asks to "拉一个 worktree", "checkout 已有分支到 worktree", "用 gw-add 建分支", "新建开发分支目录", or gives a branch-like name such as 004-init-engine-framework. This skill must distinguish existing-branch checkout from new-branch creation, preflight-check target paths, and then run `gw-add`.
---

# GW Worktree

Create or checkout a Git worktree by translating the user's natural-language request into a safe `gw-add` command.

The user's local `gw-add` function is the source of truth for actual worktree creation. This skill should not reimplement `git worktree add`; it should prepare good inputs, check obvious risks, and call `gw-add`.

## What `gw-add` Expects

Current local contract:

```bash
gw-add <branch> [base] [dir]
```

It creates or checks out `<branch>`, places the worktree at `../<dir>` by default, enters the directory inside the spawned shell, and initializes shared symlinks through `gw-init-links`.

When called from a converted bare-root repo such as `<repo>/search_loader`, `gw-add` should place normal generated directories under `./<dir>` rather than `../<dir>`. In normal worktree directories such as `<repo>/search_loader/main`, generated directories remain peer worktrees at `../<dir>`.

`gw-init-links` must not overwrite real files or directories that already exist in the checked-out branch. It may create a shared symlink only when the target path is absent or already a symlink. This matters for branches that carry their own `AGENTS.md`, `.trae`, or `openspec` entries.

Because agent shell commands run in a subprocess, `gw-add` changing directory does not move the user's interactive shell. Always report the final path and a `cd` command after success.

## Workflow

1. Understand the request.
2. Classify the request as either existing-branch checkout or new-branch creation.
3. Derive `branch`, `base`, `dir`, and `target_dir`.
4. For existing-branch checkout, do not require a base branch.
5. For new-branch creation, if `base` is not explicit, stop and ask which base branch to use.
4. Preflight-check that `target_dir` does not already exist.
5. Show the execution plan.
6. Execute `gw-add` through zsh.
7. Report the result and the next `cd` command.

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

If `refs/heads/<branch>` or `refs/remotes/origin/<branch>` exists, treat the request as checkout of that exact branch:

- `branch=<branch>` exactly as provided.
- `base=not_needed`.
- `dir=<last path segment or user-provided dir>`, e.g. `004-init-engine-framework` for branch `004-init-engine-framework`.
- command: `gw-add <branch> -d <dir>`.

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

## Naming Rules

For new branches, use a short slug for the directory and a semantic prefix for the branch.

- `dir`: concise kebab-case slug, no branch prefix.
- `branch`: `<type>/<slug>`.

Default type prefix:

| Intent | Prefix |
| --- | --- |
| Feature, requirement, normal development | `feat/` |
| Bug fix, broken behavior, regression | `fix/` |
| Refactor, cleanup, architecture change | `refactor/` |
| Config, shell, tooling, dependency, maintenance | `chore/` |
| Documentation-only work | `docs/` |

Examples:

| User intent | Branch | Dir |
| --- | --- | --- |
| 图片预加载 topvv 优化 | `feat/image-preload-topvv` | `image-preload-topvv` |
| 修复 telescope 搜索过滤 | `fix/telescope-search-filter` | `telescope-search-filter` |
| 重构 packer 路由 | `refactor/packer-router` | `packer-router` |
| 更新 zsh worktree 命令 | `chore/zsh-worktree-command` | `zsh-worktree-command` |

Prefer stable technical nouns from the user's wording. Keep slugs short enough to scan in `git worktree list`.

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

Target path rules:

- If current directory is a bare-root repo (`.git` file contains `gitdir: ./.bare`), generated target is `./<dir>`.
- If current directory is a normal worktree, generated target is `../<dir>`.
- If the requested directory starts with `./` or `../`, check that exact path.

If `<target_dir>` exists, stop and ask the user for a different directory name. Do not auto-append suffixes such as `-2`.

## Execution

Use zsh interactive mode so the user's `.zshrc` function is available:

```bash
zsh -ic 'gw-add <branch> <base-if-new> <dir>'
```

For existing branch checkout, omit the base:

```bash
zsh -ic 'gw-add <existing-branch> -d <dir>'
```

Quote arguments safely. If a generated name contains spaces or unsafe shell characters, regenerate it as a kebab-case slug instead of passing the unsafe string through.

Before executing, show a compact plan:

```text
Plan:
mode=<existing_branch|new_branch>
base=<base-or-not_needed>
branch=<branch>
dir=<dir>
target=<target_dir>
command=gw-add <branch> <base> <dir>
```

Then execute. If the command fails, report the failing command and the important error lines. Do not retry with a different branch or directory without user confirmation.

## Success Response

After success, keep the response short:

```text
Created worktree:
branch=<branch>
base=<base>
path=<absolute-or-relative-path>

Next:
cd <path>
```

Mention that the agent subprocess entered the directory during execution, but the user's interactive shell still needs the `cd` command.

## Non-Goals

- Do not edit the `gw-add` zsh function unless the user explicitly asks.
- Do not create a worktree when the base branch is missing.
- Do not auto-rename on directory conflicts.
- Do not infer hidden team branch naming conventions beyond the small prefix table above.
- Do not commit, push, or open a merge request.
