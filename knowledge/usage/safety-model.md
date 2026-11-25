---
type: Reference
title: Safety Model
description: Two-click five-second confirmation guard for destructive GM commands.
tags: [safety, danger, confirmation]
status: stable
generated: { by: "antigravity/gemini", at: "2026-11-25T14:50:00Z" }
sources:
  - id: core-lua
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/Core.lua
    title: Execution and confirmation logic
  - id: data-lua
    resource: https://github.com/TortoiseBots/ForeverGMManager/blob/main/Data.lua
    title: Command catalogue and danger policy
---

# Two-Click Confirmation Guard

Persistent or destructive commands are never one-click actions (examples: server restart/shutdown, NPC/gameobject persistence edits, saved teleport edits, broad `learn all` / `learn my` commands, moderation actions, quest removal, and `.die`).[^data-lua]

1. First **EXECUTE** arms the exact command, turns the button red, and shows a live **CONFIRM** countdown.[^core-lua]
2. Clicking **EXECUTE** again with the identical command within **5 seconds** executes it.
3. Editing the command, changing a lookup result, or changing parameters clears the pending confirmation.

Cancellation commands such as `.server restart cancel` remain immediate.

Related: [Features and Workflow](workflow.md), [Lookup Browser](lookup-browser.md).

[^core-lua]: Execution and confirmation logic
[^data-lua]: Command catalogue and danger policy
