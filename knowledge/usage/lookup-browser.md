---
type: Reference
title: Database-Aware Lookup Browser
description: Server-backed CHAT_MSG_SYSTEM lookup workflow and result actions.
tags: [lookup, search, chat-parser]
status: stable
generated: { by: "antigravity/gemini", at: "2026-11-25T14:50:00Z" }
sources:
  - id: lookup-lua
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/Lookup.lua
    title: Lookup lifecycle and CHAT_MSG_SYSTEM parser
  - id: results-ui
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/ResultsUI.lua
    title: Lookup results browser window
---

# How Lookup Works

Lookup-capable actions expose a dedicated name-or-ID input and **SEARCH** button separate from the command bar:[^lookup-lua]

1. Numeric IDs compose the originating command immediately.
2. Names send a server-side lookup (e.g. `.lookup item thunderfury`).
3. `Lookup.lua` listens to `CHAT_MSG_SYSTEM` without hooking `AddMessage` or suppressing server output, and fills the **Lookup Results** window (`ResultsUI.lua`) with name, type, and ID.[^results-ui]
4. Selecting a result populates the originating action, up to three editable modifiers, validation, and a read-only command preview.

# Default Lookup Mappings

```text
item       -> .additem <id>
spell      -> .cast <id>
creature   -> .go creature id <id>
gameobject -> .go gameobject id <id>
skill      -> .setskill <id>
```

Launching **SEARCH** from a specific action (**Quest add**, **NPC add**, **Add item set**, **Cast**, **Set skill**) loads the chosen result back into that action. Standalone lookups stay informational; **LOAD COMMAND** handles actions that cannot execute in place. Dangerous actions retain the two-click confirmation guard (see [Safety Model](safety-model.md)).

[^lookup-lua]: Lookup lifecycle and CHAT_MSG_SYSTEM parser
[^results-ui]: Lookup results browser window
