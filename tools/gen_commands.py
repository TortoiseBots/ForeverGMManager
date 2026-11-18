#!/usr/bin/env python3
"""Generate COMMANDS.md from Data.lua using Python stdlib only."""

from __future__ import annotations

import pathlib
import re

REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA_PATH = REPO_ROOT / "Data.lua"
OUTPUT_PATH = REPO_ROOT / "COMMANDS.md"

CATEGORY_TITLES = {
    "quick": "Quick",
    "travel": "Travel",
    "player": "Player",
    "world": "World",
    "lookup": "Lookup",
    "admin": "Admin",
    "danger": "Danger",
}


def _extract_string(line: str, field: str) -> str:
    match = re.search(rf'\b{field}\s*=\s*"((?:[^"\\]|\\.)*)"', line)
    if not match:
        return ""
    return match.group(1).replace('\\"', '"').replace("\\\\", "\\")


def _escape_cell(text: str) -> str:
    return text.replace("|", "\\|")


def parse_commands(data_text: str) -> list[tuple[str, list[dict[str, str]]]]:
    sections: dict[str, list[dict[str, str]]] = {}
    order: list[str] = []

    for line in data_text.splitlines():
        if "command =" not in line or "access =" not in line:
            continue
        category = _extract_string(line, "category") or "other"
        if category not in sections:
            sections[category] = []
            order.append(category)

        is_danger = bool(re.search(r"\bdanger\s*=\s*true\b", line))
        sections[category].append(
            {
                "label": _extract_string(line, "label"),
                "command": _extract_string(line, "command"),
                "access": _extract_string(line, "access"),
                "detail": _extract_string(line, "detail"),
                "danger": "yes" if is_danger else "",
            }
        )

    return [(cat, sections[cat]) for cat in order]


def render_commands_md(data_text: str) -> str:
    sections = parse_commands(data_text)
    lines = [
        "# ForeverGMManager Commands",
        "",
        "> Generated from `Data.lua` — do not edit by hand.",
        "> These are the commands the addon offers, checked to exist on the server.",
        "> In game, `.commands` lists everything your account may use and `.help <command>` explains one.",
        "",
    ]

    for category, entries in sections:
        title = CATEGORY_TITLES.get(category, category.capitalize())
        lines.append(f"## {title}")
        lines.append("")
        lines.append("| Label | Command | Access | What it does | Danger |")
        lines.append("| --- | --- | --- | --- | --- |")
        for entry in entries:
            label = _escape_cell(entry["label"])
            command = f"`{_escape_cell(entry['command'])}`"
            access = _escape_cell(entry["access"])
            detail = _escape_cell(entry["detail"])
            danger = entry["danger"]
            lines.append(f"| {label} | {command} | {access} | {detail} | {danger} |")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    data_text = DATA_PATH.read_text(encoding="utf-8")
    OUTPUT_PATH.write_text(render_commands_md(data_text), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
