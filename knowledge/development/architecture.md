---
type: Architecture
title: Architecture and Command Coverage
description: Addon module layout, 183-preset command coverage, and tools.
tags: [architecture, modules, commands]
status: stable
generated: { by: "antigravity/gemini", at: "2026-11-25T14:50:00Z" }
sources:
  - id: toc
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/ForeverGMManager.toc
    title: Addon manifest
  - id: commands-md
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/COMMANDS.md
    title: Generated command reference
---

# Project Structure

- `ForeverGMManager.toc` — addon manifest[^toc]
- `Data.lua` — command catalogue and danger policy
- `Theme.lua` — shared visual system (colours, buttons, tabs, inputs, badges)
- `Core.lua` — execution, history, `.help`, and confirmation logic
- `Lookup.lua` — lookup lifecycle and `CHAT_MSG_SYSTEM` parser
- `UI.lua`, `ResultsUI.lua`, `MailUI.lua`, `Teleports.lua` — main palette, lookup results, mail composer, and teleport shortcuts
- `COMMANDS.md` — generated command reference (from `Data.lua` via `tools/gen_commands.py`)[^commands-md]
- `tools/preview/` — offline Playwright/Pillow screenshot renderer
- `tests/` — `core_spec.lua`, `lookup_spec.lua`, `verify_server_catalog.py`

# Command Coverage

Coverage is **183 presets** with **26 SEARCH mappings** verified against `Karrz1/TrinityCore` (`forever-bots`) command tables and RBAC defaults:[^commands-md]

- GM mode, visibility, chat badge, cheats (`god`, `casttime`, `cooldown`, `power`, `waterwalk`, `taxi`, `explore`), GPS, revive, repair, bank, mailbox, unstuck, and time utilities.
- Saved teleports (`.lookup tele` and `game_tele` including Forever custom zones), player teleport/summon, coordinate/offset movement, and fly mode.
- Items, item sets, spells, auras, cooldowns, skills, reputation, morph/demorph, mail/send, and level/character/reset utilities.
- NPC/gameobject lookup, persistent and temporary spawns, movement, targeting, activation, and deletion.
- Quest, instance bind, game event management, 15+ lookup types, save/reload/server info, announcements, and moderation.

Related: [Server Alignment and Checks](checks.md).

[^toc]: Addon manifest
[^commands-md]: Generated command reference
