#!/usr/bin/env python3
"""Contract-check ForeverGMManager presets against the local Forever server source.

Uses Python stdlib only. Parses ChatCommandTable definitions and RBAC permissions
from the local TrinityCore (forever-bots) checkout.

Override FOREVER_SERVER_SRC to validate against another local checkout.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys

DEFAULT_SERVER_SRC = pathlib.Path("/mnt/pny-ssd/Tortoise WoW Projects/forever-local/src")
SERVER_SRC = pathlib.Path(os.environ.get("FOREVER_SERVER_SRC", str(DEFAULT_SERVER_SRC)))
DATA_PATH = pathlib.Path(__file__).resolve().parents[1] / "Data.lua"

SECURITY_LABELS = {
    0: "Player",
    1: "Moderator",
    2: "GM",
    3: "Administrator",
    4: "Console",
}


def load_rbac_permissions(src_root: pathlib.Path) -> dict[str, str]:
    rbac_h = (src_root / "src/server/game/Accounts/RBAC.h").read_text(
        encoding="utf-8", errors="replace"
    )
    perm_ids: dict[str, int] = {}
    for match in re.finditer(r"(RBAC_PERM_\w+)\s*=\s*(\d+)", rbac_h):
        perm_ids[match.group(1)] = int(match.group(2))

    auth_sql = (src_root / "sql/base/auth_database.sql").read_text(
        encoding="utf-8", errors="replace"
    )
    default_perms: dict[int, set[int]] = {}
    for match in re.finditer(
        r"INSERT INTO `rbac_default_permissions` VALUES\s*(.*?);", auth_sql, re.S
    ):
        for row in re.finditer(r"\((\d+),(\d+),(-?\d+)\)", match.group(1)):
            default_perms.setdefault(int(row.group(1)), set()).add(int(row.group(2)))

    linked: dict[int, set[int]] = {}

    def parse_linked(text: str) -> None:
        for match in re.finditer(
            r"INSERT(?:\s+IGNORE)?\s+INTO\s+`rbac_linked_permissions`[^V]*VALUES\s*(.*?);",
            text,
            re.S | re.I,
        ):
            for row in re.finditer(r"\(\s*(\d+)\s*,\s*(\d+)\s*\)", match.group(1)):
                linked.setdefault(int(row.group(1)), set()).add(int(row.group(2)))

    parse_linked(auth_sql)
    for folder in (
        src_root / "sql/updates/auth/master",
        src_root / "sql/custom/auth",
    ):
        if folder.exists():
            for sql_file in sorted(folder.glob("*.sql")):
                parse_linked(sql_file.read_text(encoding="utf-8", errors="replace"))

    sec_perms: dict[int, set[int]] = {}
    for sec_id, roots in default_perms.items():
        visited = set(roots)
        stack = list(roots)
        while stack:
            current = stack.pop()
            for nxt in linked.get(current, ()):
                if nxt not in visited:
                    visited.add(nxt)
                    stack.append(nxt)
        sec_perms[sec_id] = visited

    perm_to_sec: dict[str, str] = {}
    for name, pid in perm_ids.items():
        lowest = 4
        for sec_id in sorted(sec_perms):
            if pid in sec_perms[sec_id]:
                lowest = sec_id
                break
        label = SECURITY_LABELS.get(lowest, "Console")
        perm_to_sec[name] = label
        perm_to_sec[f"rbac::{name}"] = label
    return perm_to_sec


def strip_comments(text: str) -> str:
    text = re.sub(r"//[^\n]*", "", text)
    return re.sub(r"/\*.*?\*/", "", text, flags=re.S)


def extract_tables(text: str) -> dict[str, str]:
    tables: dict[str, str] = {}
    pattern = re.compile(r"static\s+ChatCommandTable\s+(\w+)\s*=\s*\{")
    for match in pattern.finditer(text):
        name = match.group(1)
        start = match.end()
        depth = 1
        cursor = start
        while cursor < len(text) and depth > 0:
            if text[cursor] == "{":
                depth += 1
            elif text[cursor] == "}":
                depth -= 1
            cursor += 1
        tables[name] = text[start : cursor - 1]
    return tables


def parse_table_entries(body: str) -> list[tuple[str, str, str | None, str | None]]:
    entries: list[str] = []
    idx = 0
    while idx < len(body):
        if body[idx] == "{":
            depth = 1
            start = idx + 1
            idx += 1
            in_str = False
            while idx < len(body) and depth > 0:
                ch = body[idx]
                if ch == '"' and (idx == 0 or body[idx - 1] != "\\"):
                    in_str = not in_str
                elif not in_str:
                    if ch == "{":
                        depth += 1
                    elif ch == "}":
                        depth -= 1
                idx += 1
            entries.append(body[start : idx - 1].strip())
        else:
            idx += 1

    parsed: list[tuple[str, str, str | None, str | None]] = []
    for entry in entries:
        args: list[str] = []
        cur: list[str] = []
        depth = 0
        in_str = False
        pos = 0
        while pos < len(entry):
            ch = entry[pos]
            if ch == '"' and (pos == 0 or entry[pos - 1] != "\\"):
                in_str = not in_str
                cur.append(ch)
            elif not in_str:
                if ch in "({[":
                    depth += 1
                    cur.append(ch)
                elif ch in ")}]":
                    depth -= 1
                    cur.append(ch)
                elif ch == "," and depth == 0:
                    args.append("".join(cur).strip())
                    cur = []
                else:
                    cur.append(ch)
            else:
                cur.append(ch)
            pos += 1
        if cur:
            tail = "".join(cur).strip()
            if tail:
                args.append(tail)

        if len(args) < 2:
            continue
        m_name = re.fullmatch(r'"([^"]*)"', args[0])
        if not m_name:
            continue
        cmd_name = m_name.group(1)

        if len(args) == 2 and re.fullmatch(r"\w+", args[1]):
            parsed.append(("sub", cmd_name, args[1], None))
        elif len(args) >= 6 and re.fullmatch(r"\w+", args[5]):
            m_rbac = re.search(r"(rbac::RBAC_PERM_\w+|RBAC_PERM_\w+)", args[1])
            parsed.append(("sub", cmd_name, args[5], m_rbac.group(1) if m_rbac else None))
        else:
            m_rbac = re.search(r"(rbac::RBAC_PERM_\w+|RBAC_PERM_\w+)", entry)
            parsed.append(("leaf", cmd_name, None, m_rbac.group(1) if m_rbac else None))
    return parsed


def load_server_routes(src_root: pathlib.Path) -> list[tuple[str, str]]:
    perm_to_sec = load_rbac_permissions(src_root)
    files = sorted((src_root / "src/server/scripts/Commands").glob("cs_*.cpp"))
    files += sorted((src_root / "src/server/scripts/Custom").rglob("*.cpp"))

    routes: dict[str, str] = {}
    for cpp_file in files:
        text = strip_comments(cpp_file.read_text(encoding="utf-8", errors="replace"))
        tables = extract_tables(text)
        if "commandTable" not in tables:
            continue

        def walk(table_name: str, prefix: str = "") -> None:
            if table_name not in tables:
                return
            for kind, name, target, rbac_name in parse_table_entries(tables[table_name]):
                path = f"{prefix} {name}".strip() if name else prefix
                if kind == "sub" and target:
                    walk(target, path)
                elif path:
                    routes[f".{path}"] = perm_to_sec.get(rbac_name or "", "Console")

        walk("commandTable")

    route_list = sorted(routes.items(), key=lambda item: len(item[0]), reverse=True)
    return route_list


def longest_route(command: str, routes: list[tuple[str, str]]) -> tuple[str, str] | None:
    candidates = [
        route
        for route in routes
        if command == route[0] or command.startswith(route[0] + " ")
    ]
    return max(candidates, key=lambda value: len(value[0]), default=None)


def extract_presets(data: str) -> list[tuple[int, str, str, str, list[str]]]:
    presets: list[tuple[int, str, str, str, list[str]]] = []
    for line_number, line in enumerate(data.splitlines(), 1):
        if "command =" not in line or "access =" not in line:
            continue
        command = re.search(r'\bcommand\s*=\s*"([^"]+)"', line)
        access = re.search(r'\baccess\s*=\s*"([^"]+)"', line)
        label = re.search(r'\blabel\s*=\s*"([^"]+)"', line)
        legacy = re.findall(r'"(\.[^"]+)"', re.search(r'\blegacyCommands\s*=\s*\{([^}]*)\}', line).group(1)) if "legacyCommands =" in line else []
        if command and access:
            presets.append(
                (
                    line_number,
                    label.group(1) if label else command.group(1),
                    command.group(1),
                    access.group(1),
                    legacy,
                )
            )
    return presets


def extract_lookup_commands(data: str) -> list[tuple[int, str]]:
    results: list[tuple[int, str]] = []
    for line_number, line in enumerate(data.splitlines(), 1):
        for match in re.finditer(r'\blookupCommand\s*=\s*"([^"]+)"', line):
            results.append((line_number, match.group(1)))
    return results


def main() -> int:
    if not SERVER_SRC.exists():
        print(f"FAIL: server source not found at {SERVER_SRC}", file=sys.stderr)
        return 1

    routes = load_server_routes(SERVER_SRC)
    if not routes:
        print("FAIL: could not parse any server command routes", file=sys.stderr)
        return 1

    data = DATA_PATH.read_text(encoding="utf-8")
    failures: list[str] = []
    ids: set[str] = set()

    for line_number, line in enumerate(data.splitlines(), 1):
        if "command =" not in line or "access =" not in line:
            continue
        identifier = re.search(r'\bid\s*=\s*"([^"]+)"', line)
        if not identifier or "arguments =" not in line or "legacyCommands =" not in line:
            failures.append(
                f"Data.lua:{line_number}: preset lacks id/arguments/legacyCommands metadata"
            )
        elif identifier.group(1) in ids:
            failures.append(
                f"Data.lua:{line_number}: duplicate stable id {identifier.group(1)!r}"
            )
        else:
            ids.add(identifier.group(1))

    presets = extract_presets(data)
    for line_number, label, command, access, legacy in presets:
        route = longest_route(command, routes)
        if not route and legacy:
            # Parent toggle commands like ".gm" dispatch to ".gm on" / ".gm off".
            legacy_routes = [longest_route(item, routes) for item in legacy]
            if all(legacy_routes):
                route = legacy_routes[0]

        if not route:
            failures.append(
                f"Data.lua:{line_number}: {label}: {command} has no route in server registry"
            )
            continue

        expected_access = route[1]
        if access != expected_access:
            failures.append(
                f"Data.lua:{line_number}: {label}: access {access!r} != "
                f"server {expected_access!r} via {route[0]}"
            )

    lookup_commands = extract_lookup_commands(data)
    for line_number, command in lookup_commands:
        if not longest_route(command, routes):
            failures.append(
                f"Data.lua:{line_number}: FIND command {command} has no route in server registry"
            )

    if failures:
        print("FAIL: server catalogue contract")
        for failure in failures:
            print(" - " + failure)
        return 1

    print(
        "PASS: server catalogue contract "
        f"({len(presets)} presets, "
        f"{len(lookup_commands)} FIND mappings, "
        f"{len(routes)} server routes)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
