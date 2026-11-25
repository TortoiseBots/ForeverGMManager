<p align="center"><img src="docs/icon.png" alt="ForeverGMManager icon" width="64"></p>

# ForeverGMManager

A compact GM command manager for **WoW Forever** on **ForeverCore** (`Karrz1/TrinityCore`). It turns TrinityCore's
dot-prefixed GM commands into a searchable in-game palette with server-backed lookups, a mail composer, and two-click
confirmation for destructive actions.

> [!NOTE]
> **Client-side only (WIP).** Commands run through the normal GM chat-command path and respect server RBAC permissions.
> The window, icon, colours, and minimap button are verified in-client; the full command panel still needs a complete
> in-game pass.

<p align="center">
  <img src="docs/screenshots/search-configure.webp" alt="Command search and configure" width="440"><br>
  <sub><b>Search &amp; configure</b> — filter 183 presets as you type and preview the exact GM command before execution (offline preview via <code>tools/preview</code>).</sub>
</p>

## Installation

1. Download or clone this repository into `<WoW Forever>/_forever_/Interface/AddOns/ForeverGMManager/` (so
   `ForeverGMManager.toc` sits at the folder root).
2. Restart the client, enable **ForeverGMManager** in **AddOns** (enable **Load out of date AddOns** if prompted).
3. Log into a GM character and click the minimap hammer icon (**Shift-drag** to move, **Right-click** to hide) or run
   `/fgmm` (alias `/tgmm`).

## Documentation

| Area | Topics |
|---|---|
| [Usage](knowledge/usage/index.md) | [Features & Workflow](knowledge/usage/workflow.md), [Lookup Browser](knowledge/usage/lookup-browser.md), [Safety Model](knowledge/usage/safety-model.md) |
| [Development](knowledge/development/index.md) | [Architecture & Command Coverage](knowledge/development/architecture.md), [Server Alignment & Checks](knowledge/development/checks.md) |

Generated command reference: [`COMMANDS.md`](COMMANDS.md) (183 presets, 26 `SEARCH` mappings).

## Licence

Released under **AGPL-3.0** ([`LICENSE`](LICENSE)). Original MIT-licensed code from TortoiseGMManager is documented in
[`NOTICE.md`](NOTICE.md).

This is an unofficial community project made for educational purposes. It does not distribute game-client binaries or
extracted game data, and is not affiliated with Blizzard Entertainment or the WoW Forever project.
