#!/usr/bin/env python3
"""Convert a normal Git checkout into the user's bare+worktree layout.

The script is intentionally plan-first: without --execute it only prints the
detected repository state and the mutations it would perform.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


SHARED_NAMES = [
    "AGENTS_meta.md",
    "AGENTS.md",
    ".coco",
    ".ai_doc",
    ".trae",
    ".specify",
    "openspec",
    "specs",
]

REQUIRED_ROOT_SHARED = {
    ".trae": "dir",
    "AGENTS_meta.md": "file",
}


def run(cmd: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=check,
    )


def git(root: Path, args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(["git", "-C", str(root), *args], check=check)


def bare_git(root: Path, args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(["git", f"--git-dir={root / '.bare'}", *args], cwd=root, check=check)


def text_or_empty(cp: subprocess.CompletedProcess[str]) -> str:
    return cp.stdout.strip()


def repo_root(path: Path) -> Path:
    cp = run(["git", "-C", str(path), "rev-parse", "--show-toplevel"])
    return Path(cp.stdout.strip()).resolve()


def current_branch(root: Path) -> str:
    cp = git(root, ["branch", "--show-current"])
    branch = cp.stdout.strip()
    if branch:
        return branch
    cp = git(root, ["rev-parse", "--short", "HEAD"])
    return f"detached-{cp.stdout.strip()}"


def remote_head_branch(root: Path) -> str | None:
    cp = git(root, ["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"], check=False)
    if cp.returncode != 0:
        return None
    value = cp.stdout.strip()
    if value.startswith("origin/"):
        return value[len("origin/") :]
    return value or None


def local_branches(root: Path) -> set[str]:
    cp = git(root, ["for-each-ref", "--format=%(refname:short)", "refs/heads"])
    return {line.strip() for line in cp.stdout.splitlines() if line.strip()}


def choose_primary(root: Path, explicit: str | None, current: str) -> tuple[str, str]:
    if explicit:
        return explicit, "explicit --primary"
    remote = remote_head_branch(root)
    if remote:
        return remote, "origin/HEAD"
    branches = local_branches(root)
    for candidate in ("master", "main", "develop", "dev"):
        if candidate in branches:
            return candidate, "local branch priority"
    return current, "current branch fallback"


def slug_branch(branch: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", branch)
    slug = slug.strip("-._")
    return slug or "worktree"


def choose_checkout_dir(explicit: str | None, current: str, primary: str) -> tuple[str, str]:
    if explicit:
        return explicit, "explicit --checkout-dir"
    if current == primary:
        return "main", "canonical primary checkout directory"
    return slug_branch(current), "current non-primary branch name"


def porcelain_status(root: Path) -> list[str]:
    cp = git(root, ["status", "--porcelain=v1", "--untracked-files=all", "--ignored"])
    return [line for line in cp.stdout.splitlines() if line]


def status_path(line: str) -> str:
    path = line[3:] if len(line) > 3 else ""
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    return path.rstrip("/")


def blocking_status(lines: list[str]) -> list[str]:
    blocking: list[str] = []
    for line in lines:
        if line.startswith("!! "):
            continue
        path = status_path(line)
        top = path.split("/", 1)[0]
        if line.startswith("?? ") and top in SHARED_NAMES:
            continue
        blocking.append(line)
    return blocking


def tracked_paths(root: Path) -> set[str]:
    cp = git(root, ["ls-files", "-z"])
    return {p for p in cp.stdout.split("\0") if p}


def top_level_tracked(paths: set[str]) -> set[str]:
    return {p.split("/", 1)[0] for p in paths}


def shared_extraction_plan(root: Path, tracked: set[str], extract_tracked: bool) -> list[dict[str, object]]:
    top_tracked = top_level_tracked(tracked)
    plan: list[dict[str, object]] = []
    for name in SHARED_NAMES:
        path = root / name
        if not path.exists() and not path.is_symlink():
            continue
        tracked_here = name in top_tracked or name in tracked
        destination = "AGENTS_meta.md" if name == "AGENTS.md" else name
        extract = (not tracked_here) or extract_tracked or name == "AGENTS_meta.md"
        plan.append(
            {
                "name": name,
                "destination": destination,
                "tracked": tracked_here,
                "extract_to_root": extract,
            }
        )
    return plan


def build_plan(args: argparse.Namespace) -> dict[str, object]:
    root = repo_root(Path(args.repo).resolve())
    git_path = root / ".git"
    current = current_branch(root)
    primary, primary_source = choose_primary(root, args.primary, current)
    checkout_dir, checkout_source = choose_checkout_dir(args.checkout_dir, current, primary)
    target = root / checkout_dir
    bare = root / ".bare"
    status = porcelain_status(root)
    tracked = tracked_paths(root)

    errors: list[str] = []
    if not git_path.is_dir():
        errors.append(f"{git_path} is not a directory; repository already looks converted or non-standard")
    if bare.exists():
        errors.append(f"{bare} already exists")
    if target.exists():
        errors.append(f"{target} already exists")
    if checkout_dir in {".", "..", ""} or "/" in checkout_dir:
        errors.append("--checkout-dir must be a single directory name under the repository root")
    dirty = blocking_status(status)
    if dirty and not args.allow_dirty:
        errors.append("repository has modified/untracked files; rerun only after cleanup or pass --allow-dirty")
    if args.execute and not args.primary:
        errors.append(
            "primary branch must be explicitly confirmed for execution; "
            f"rerun with --primary {primary!r} after user confirmation"
        )

    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = root / f".worktree-convert-backup-{timestamp}"

    return {
        "repo_root": str(root),
        "current_branch": current,
        "primary_branch": primary,
        "primary_source": primary_source,
        "primary_confirmed": bool(args.primary),
        "primary_confirmation_required": not bool(args.primary),
        "checkout_dir": checkout_dir,
        "checkout_dir_source": checkout_source,
        "target_worktree": str(target),
        "bare_dir": str(bare),
        "backup_dir": str(backup),
        "dirty_entries": dirty,
        "ignored_entries": [line for line in status if line.startswith("!! ")],
        "shared_entries": shared_extraction_plan(root, tracked, args.extract_tracked_shared),
        "required_root_shared": {
            **REQUIRED_ROOT_SHARED,
            **({"openspec": "dir"} if args.ensure_root_openspec else {}),
        },
        "errors": errors,
        "will_execute": bool(args.execute and not errors),
    }


def move_root_entries_to_backup(root: Path, backup: Path) -> None:
    backup.mkdir()
    for entry in list(root.iterdir()):
        if entry.name in {".git", backup.name}:
            continue
        shutil.move(str(entry), str(backup / entry.name))


def configure_bare(root: Path) -> None:
    bare_git(root, ["config", "core.bare", "true"])
    bare_git(root, ["config", "--unset", "core.worktree"], check=False)
    (root / ".git").write_text("gitdir: ./.bare\n", encoding="utf-8")


def restore_shared_entries(root: Path, target: Path, backup: Path, shared_plan: list[dict[str, object]]) -> None:
    for item in shared_plan:
        if not item["extract_to_root"]:
            continue
        source = backup / str(item["name"])
        if not source.exists() and not source.is_symlink():
            continue
        destination_name = str(item["destination"])
        destination = root / destination_name
        if destination.exists() or destination.is_symlink():
            continue
        shutil.move(str(source), str(destination))

        link_name = "AGENTS.md" if destination_name == "AGENTS_meta.md" else destination_name
        link = target / link_name
        if link.exists() or link.is_symlink():
            continue
        os.symlink(f"../{destination_name}", link)


def ensure_required_root_shared(root: Path, target: Path, required: dict[str, str]) -> None:
    for name, kind in required.items():
        root_entry = root / name
        if not root_entry.exists() and not root_entry.is_symlink():
            if kind == "dir":
                root_entry.mkdir(parents=True)
            else:
                root_entry.write_text(
                    "# AGENTS Meta\n\n"
                    "Shared agent instructions for peer worktree directories.\n",
                    encoding="utf-8",
                )

        link_name = "AGENTS.md" if name == "AGENTS_meta.md" else name
        link = target / link_name
        if link.exists() or link.is_symlink():
            continue
        os.symlink(f"../{name}", link)


def overlay_backup_to_target(backup: Path, target: Path) -> None:
    for source in list(backup.iterdir()):
        destination = target / source.name
        if destination.exists() or destination.is_symlink():
            if destination.is_dir() and not destination.is_symlink():
                shutil.rmtree(destination)
            else:
                destination.unlink()
        shutil.move(str(source), str(destination))


def execute_plan(plan: dict[str, object]) -> None:
    root = Path(str(plan["repo_root"]))
    target = Path(str(plan["target_worktree"]))
    backup = Path(str(plan["backup_dir"]))
    current = str(plan["current_branch"])

    move_root_entries_to_backup(root, backup)
    shutil.move(str(root / ".git"), str(root / ".bare"))
    configure_bare(root)
    cp = bare_git(root, ["worktree", "add", str(target), current], check=False)
    if cp.returncode != 0:
        raise RuntimeError(
            "git worktree add failed after moving .git to .bare.\n"
            f"stdout:\n{cp.stdout}\n"
            f"stderr:\n{cp.stderr}\n"
            f"Backup is preserved at: {backup}"
        )
    restore_shared_entries(root, target, backup, list(plan["shared_entries"]))
    overlay_backup_to_target(backup, target)
    ensure_required_root_shared(root, target, dict(plan["required_root_shared"]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="path inside the ordinary Git checkout")
    parser.add_argument("--primary", help="primary branch name if origin/HEAD is absent or wrong")
    parser.add_argument("--checkout-dir", help="directory name for the converted current checkout")
    parser.add_argument("--allow-dirty", action="store_true", help="allow modified or untracked files")
    parser.add_argument(
        "--extract-tracked-shared",
        action="store_true",
        help="move tracked shared entries such as AGENTS.md out to the root and symlink them back",
    )
    parser.add_argument(
        "--ensure-root-openspec",
        action="store_true",
        help="create a root-level shared openspec/ directory when one was not extracted from untracked content",
    )
    parser.add_argument("--execute", action="store_true", help="perform the conversion")
    args = parser.parse_args()

    try:
        plan = build_plan(args)
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or exc.stdout, file=sys.stderr)
        return exc.returncode or 1

    print(json.dumps(plan, ensure_ascii=False, indent=2))
    if plan["errors"]:
        return 2
    if not args.execute:
        print("\nDry run only. Re-run with --execute to convert.")
        return 0

    try:
        execute_plan(plan)
    except Exception as exc:  # noqa: BLE001 - command line tool should surface context
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    target = Path(str(plan["target_worktree"]))
    print("\nConverted successfully.")
    print(f"Worktree path: {target}")
    print(f"Backup path: {plan['backup_dir']}")
    print("Next checks:")
    print(f"  git -C {target} worktree list")
    print(f"  git -C {target} status --short")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
