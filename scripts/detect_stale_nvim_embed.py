#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from typing import Dict, Iterable, List, Optional, Set


Process = Dict[str, object]
Pair = Dict[str, object]


def run_command(args: List[str]) -> str:
    return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL)


def collect_tmux_panes() -> Dict[str, Dict[str, Dict[str, str]]]:
    try:
        output = run_command(
            [
                "tmux",
                "list-panes",
                "-a",
                "-F",
                "#{pane_id}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_tty}\t#{pane_pid}\t#{pane_current_command}\t#{pane_current_path}",
            ]
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return {}

    panes_by_tty: Dict[str, Dict[str, str]] = {}
    panes_by_id: Dict[str, Dict[str, str]] = {}
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) != 6:
            continue
        pane_id, pane_ref, tty, pane_pid, pane_cmd, pane_path = parts
        tty = tty.replace("/dev/", "")
        pane = {
            "pane_id": pane_id,
            "pane_ref": pane_ref,
            "pane_tty": tty,
            "pane_pid": pane_pid,
            "pane_cmd": pane_cmd,
            "pane_path": pane_path,
        }
        panes_by_tty[tty] = pane
        panes_by_id[pane_id] = pane
    return {"by_tty": panes_by_tty, "by_id": panes_by_id}


def collect_processes() -> Dict[int, Process]:
    output = run_command(["ps", "-eo", "pid=,ppid=,tty=,rss=,etime=,args="])
    processes: Dict[int, Process] = {}
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split(None, 5)
        if len(parts) < 6:
            continue
        pid_s, ppid_s, tty, rss_s, etime, args = parts
        try:
            pid = int(pid_s)
            ppid = int(ppid_s)
            rss_kb = int(rss_s)
        except ValueError:
            continue
        processes[pid] = {
            "pid": pid,
            "ppid": ppid,
            "tty": tty,
            "rss_kb": rss_kb,
            "etime": etime,
            "args": args,
        }
    return processes


def collect_cwds(pids: Iterable[int]) -> Dict[int, str]:
    result: Dict[int, str] = {}
    for pid in pids:
        path = f"/proc/{pid}/cwd"
        try:
            result[pid] = os.readlink(path)
        except OSError:
            continue
    return result


def collect_env_vars(pids: Iterable[int], keys: Set[str]) -> Dict[int, Dict[str, str]]:
    result: Dict[int, Dict[str, str]] = {}
    for pid in pids:
        path = f"/proc/{pid}/environ"
        try:
            raw = open(path, "rb").read()
        except OSError:
            continue
        env: Dict[str, str] = {}
        for item in raw.split(b"\x00"):
            if not item or b"=" not in item:
                continue
            key, value = item.split(b"=", 1)
            key_s = key.decode(errors="ignore")
            if key_s not in keys:
                continue
            env[key_s] = value.decode(errors="ignore")
        if env:
            result[pid] = env
    return result


def build_children_map(processes: Dict[int, Process]) -> Dict[int, List[int]]:
    children: Dict[int, List[int]] = {}
    for pid, proc in processes.items():
        ppid = int(proc["ppid"])
        children.setdefault(ppid, []).append(pid)
    return children


def find_embed_child(nvim_pid: int, children_map: Dict[int, List[int]], processes: Dict[int, Process]) -> Optional[int]:
    for child_pid in children_map.get(nvim_pid, []):
        child = processes.get(child_pid)
        if child and str(child["args"]).startswith("nvim --embed"):
            return child_pid
    return None


def walk_ancestors(pid: int, processes: Dict[int, Process]) -> List[int]:
    chain: List[int] = []
    seen: Set[int] = set()
    current = pid
    while current in processes and current not in seen:
        seen.add(current)
        chain.append(current)
        current = int(processes[current]["ppid"])
        if current <= 0:
            break
    return chain


def find_tmux_ancestor(pid: int, processes: Dict[int, Process]) -> Optional[Process]:
    for ancestor_pid in walk_ancestors(pid, processes)[1:]:
        proc = processes.get(ancestor_pid)
        if not proc:
            continue
        args = str(proc["args"])
        if args == "tmux" or args.startswith("tmux "):
            return proc
    return None


def find_shell_ancestor(pid: int, processes: Dict[int, Process]) -> Optional[Process]:
    chain = walk_ancestors(pid, processes)
    for ancestor_pid in chain[1:]:
        proc = processes.get(ancestor_pid)
        if not proc:
            continue
        args = str(proc["args"])
        basename = args.split()[0] if args else ""
        if basename.endswith("zsh") or basename.endswith("bash") or basename in {"-zsh", "-bash"}:
            return proc
    return None


def detect_stale_nvim_embed_pairs(
    processes: Dict[int, Process],
    active_pane_ttys: Set[str],
    cwd_by_pid: Dict[int, str],
    tmux_env_by_pid: Dict[int, Dict[str, str]],
    pane_map_by_id: Dict[str, Dict[str, str]],
) -> List[Pair]:
    children_map = build_children_map(processes)
    pairs: List[Pair] = []

    for pid, proc in processes.items():
        args = str(proc["args"])
        tty = str(proc["tty"])
        if not (args == "nvim" or args.startswith("nvim ")):
            continue
        if tty == "?" or tty in active_pane_ttys:
            continue

        embed_pid = find_embed_child(pid, children_map, processes)
        if embed_pid is None:
            continue

        tmux_proc = find_tmux_ancestor(pid, processes)
        if tmux_proc is None:
            continue

        embed = processes[embed_pid]
        shell_proc = find_shell_ancestor(pid, processes)
        shell_pid = int(shell_proc["pid"]) if shell_proc else None
        shell_env = tmux_env_by_pid.get(shell_pid or -1, {})
        historical_pane_id = shell_env.get("TMUX_PANE")
        live_pane = pane_map_by_id.get(historical_pane_id or "") if historical_pane_id else None
        if historical_pane_id:
            tmux_pane_state = "live" if live_pane else "missing"
        else:
            tmux_pane_state = "unknown"
        pairs.append(
            {
                "tty": tty,
                "shell_pid": shell_pid,
                "shell_args": shell_proc["args"] if shell_proc else None,
                "nvim_pid": pid,
                "nvim_args": args,
                "nvim_rss_kb": int(proc["rss_kb"]),
                "embed_pid": embed_pid,
                "embed_args": embed["args"],
                "embed_rss_kb": int(embed["rss_kb"]),
                "embed_etime": embed["etime"],
                "cwd": cwd_by_pid.get(pid, "<unknown>"),
                "tmux_pid": tmux_proc["pid"],
                "tmux_args": tmux_proc["args"],
                "historical_tmux_pane_id": historical_pane_id,
                "historical_tmux": shell_env.get("TMUX"),
                "tmux_pane_state": tmux_pane_state,
                "live_tmux_pane_ref": live_pane["pane_ref"] if live_pane else None,
                "live_tmux_pane_tty": live_pane["pane_tty"] if live_pane else None,
            }
        )

    pairs.sort(key=lambda item: (-int(item["embed_rss_kb"]), str(item["tty"])))
    return pairs


def format_rss_mb(rss_kb: int) -> str:
    return f"{rss_kb / 1024:.1f}"


def print_table(pairs: List[Pair], pane_map_by_tty: Dict[str, Dict[str, str]]) -> None:
    if not pairs:
        print("未发现疑似 stale 的 nvim -> nvim --embed 残留进程。")
        return

    headers = ["TTY", "pane_hint", "shell", "nvim", "embed", "embed_MB", "etime", "cwd"]
    rows: List[List[str]] = []
    for pair in pairs:
        pane_hint = str(pair["historical_tmux_pane_id"] or "?")
        state = str(pair["tmux_pane_state"])
        live_ref = pair.get("live_tmux_pane_ref")
        if state == "live" and live_ref:
            pane_hint = f"{pane_hint}->{live_ref}"
        elif state == "missing":
            pane_hint = f"{pane_hint}(missing)"
        else:
            pane_hint = f"{pane_hint}({state})"
        rows.append(
            [
                str(pair["tty"]),
                pane_hint,
                str(pair["shell_pid"] or "-"),
                str(pair["nvim_pid"]),
                str(pair["embed_pid"]),
                format_rss_mb(int(pair["embed_rss_kb"])),
                str(pair["embed_etime"]),
                str(pair["cwd"]),
            ]
        )

    widths = [len(header) for header in headers]
    for row in rows:
        for idx, cell in enumerate(row):
            widths[idx] = min(max(widths[idx], len(cell)), 80)

    def trim(cell: str, width: int) -> str:
        return cell if len(cell) <= width else cell[: width - 1] + "…"

    def emit(row: List[str]) -> None:
        print("  ".join(trim(cell, widths[idx]).ljust(widths[idx]) for idx, cell in enumerate(row)))

    emit(headers)
    emit(["-" * width for width in widths])
    for row in rows:
        emit(row)

    total_embed_kb = sum(int(pair["embed_rss_kb"]) for pair in pairs)
    print()
    print(f"共发现 {len(pairs)} 组疑似残留进程；embed 总内存约 {total_embed_kb / 1024:.1f} MB。")
    print("这些 TTY 当前都不在 tmux list-panes -a 的 pane 集合里。")

    active_count = len(pane_map_by_tty)
    print(f"当前 tmux 活跃 pane 数：{active_count}")
    missing_count = sum(1 for pair in pairs if pair.get("tmux_pane_state") == "missing")
    live_count = sum(1 for pair in pairs if pair.get("tmux_pane_state") == "live")
    unknown_count = sum(1 for pair in pairs if pair.get("tmux_pane_state") == "unknown")
    print(f"历史 pane 识别：missing={missing_count}, live={live_count}, unknown={unknown_count}")
    if missing_count > 0:
        print("说明：对于已从 tmux 活跃 pane 中消失的进程，只能从进程环境里恢复历史 pane_id（例如 %112），无法保证恢复出原始 session/window。")


def make_kill_command(pairs: List[Pair]) -> str:
    pids: List[str] = []
    seen: Set[int] = set()
    for pair in pairs:
        for key in ("nvim_pid", "embed_pid"):
            pid = int(pair[key])
            if pid in seen:
                continue
            seen.add(pid)
            pids.append(str(pid))
    return "kill -TERM " + " ".join(pids) if pids else ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="检测 tmux pane 已消失但 nvim --embed 仍存活的残留进程")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    parser.add_argument("--min-rss-mb", type=float, default=0.0, help="只显示 embed RSS 大于等于该值的进程，单位 MB")
    parser.add_argument("--limit", type=int, default=0, help="最多输出前 N 项，0 表示不限制")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    pane_maps = collect_tmux_panes()
    pane_map_by_tty = pane_maps["by_tty"]
    pane_map_by_id = pane_maps["by_id"]
    active_pane_ttys = set(pane_map_by_tty.keys())
    processes = collect_processes()
    cwd_by_pid = collect_cwds(processes.keys())
    tmux_env_by_pid = collect_env_vars(processes.keys(), {"TMUX", "TMUX_PANE"})
    pairs = detect_stale_nvim_embed_pairs(processes, active_pane_ttys, cwd_by_pid, tmux_env_by_pid, pane_map_by_id)

    if args.min_rss_mb > 0:
        threshold_kb = int(args.min_rss_mb * 1024)
        pairs = [pair for pair in pairs if int(pair["embed_rss_kb"]) >= threshold_kb]
    if args.limit > 0:
        pairs = pairs[: args.limit]

    kill_command = make_kill_command(pairs)

    if args.json:
        payload = {
            "active_pane_count": len(pane_map_by_tty),
            "stale_pair_count": len(pairs),
            "pairs": pairs,
            "suggested_kill_command": kill_command,
        }
        json.dump(payload, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return 0

    print_table(pairs, pane_map_by_tty)
    if kill_command:
        print()
        print("建议先人工确认，再手动执行以下清理命令：")
        print(kill_command)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
