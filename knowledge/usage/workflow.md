---
type: Playbook
title: Features and Workflow
description: UI layout, categories, minimap controls, mail composer, and step-by-step usage.
tags: [usage, ui, workflow, minimap, mail]
status: stable
generated: { by: "antigravity/gemini", at: "2026-11-25T14:50:00Z" }
sources:
  - id: ui-lua
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/UI.lua
    title: Main palette and minimap launcher
  - id: mail-ui
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/MailUI.lua
    title: In-game mail composer
---

# Key Features

- **Compact palette:** Uses stock WoW Forever client textures with zero Ace or LibDBIcon dependencies.[^ui-lua]
- **Launcher and minimap:** `/fgmm` (alias `/tgmm`) or minimap icon (`Click` toggle, `Shift-drag` move, `Right-click` hide — restore via `/fgmm minimap` or `/tgmm minimap`). Positions, visibility, and starred favourites persist in `TortoiseGMManagerDB`. `Esc` closes via `UISpecialFrames`.
- **Categories and search:** `Fav`, `All`, `Travel`, `Player`, `World`, `Lookup`, `Admin`, and `Danger` (`Fav` opens by default when populated, else `All`). **Filter actions** ranks by label without altering the executable command.
- **Visual system (`Theme.lua`):** Gold accent, semantic colours (blue lookup, red danger, green success), live target indicator, hover tooltips for syntax/RBAC access levels, and `?` for `.help <command>`.
- **Action modes & Mail:** Safe argument-free actions use **RUN NOW**, state commands use **ON/OFF**, configurable actions open typed controls with a read-only preview, and `MailUI.lua` composes item/gold mail to players.[^mail-ui]

# Basic Workflow

1. Target a player, NPC, or gameobject when target-oriented.
2. Select a category (or **All**) and filter.
3. Click **RUN NOW** / **ON/OFF**, or **CONFIGURE** to fill parameters.
4. For lookup-capable actions, enter a name or ID and press `Enter` or **SEARCH** (see [Lookup Browser](lookup-browser.md)).
5. Press **EXECUTE** (or `Enter`). Destructive actions require two clicks within 5 s (see [Safety Model](safety-model.md)).

[^ui-lua]: Main palette and minimap launcher
[^mail-ui]: In-game mail composer
