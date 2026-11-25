---
type: Playbook
title: Server Alignment and Checks
description: ForeverCore RBAC verification, unit tests, and offline screenshot rendering.
tags: [testing, verification, rbac, preview]
status: stable
generated: { by: "antigravity/gemini", at: "2026-11-25T14:50:00Z" }
sources:
  - id: verify-script
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/tests/verify_server_catalog.py
    title: ForeverCore command catalogue verifier
  - id: gen-commands
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/tools/gen_commands.py
    title: COMMANDS.md generator
---

# Server Alignment

`tests/verify_server_catalog.py` parses `ChatCommandTable` definitions and RBAC security levels from a local `Karrz1/TrinityCore` (`forever-bots`) checkout (`src/server/scripts/Commands/cs_*.cpp`, `src/server/scripts/Custom/Classic/world/classic_*_commands.cpp`, `src/server/game/Accounts/RBAC.h`, `sql/base/auth_database.sql`) and checks every preset, `SEARCH` route, displayed access level, and `COMMANDS.md` sync.[^verify-script]

Default path is `../forever-local/src`; override with `FOREVER_SERVER_SRC`:

```bash
FOREVER_SERVER_SRC=/path/to/TrinityCore python3 tests/verify_server_catalog.py
```

# Development Checks

```bash
lua5.1 tests/core_spec.lua
lua5.1 tests/lookup_spec.lua
python3 tests/verify_server_catalog.py
luac5.1 -p *.lua
python3 tools/gen_commands.py
```

Regenerate `COMMANDS.md` whenever `Data.lua` changes; `verify_server_catalog.py` fails if `COMMANDS.md` is stale.[^gen-commands]

# Offline Screenshot Rendering

```bash
sh tools/preview/run.sh <out-dir> <asset-dir>
```

Requires Node + Playwright, Python + Pillow, and client fonts `FRIZQT__.ttf` and `ARIALN.ttf` under `<asset-dir>/fonts`; convert the output PNGs to `docs/screenshots/*.webp`.

Related: [Architecture and Command Coverage](architecture.md).

[^verify-script]: ForeverCore command catalogue verifier
[^gen-commands]: COMMANDS.md generator
