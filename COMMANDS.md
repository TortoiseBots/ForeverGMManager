# ForeverGMManager Commands

> Generated from `Data.lua` — do not edit by hand.
> These are the commands the addon offers, checked to exist on the server.
> In game, `.commands` lists everything your account may use and `.help <command>` explains one.

## Quick

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| GM mode | `.gm` | Moderator | Enable or disable in-game GM mode. |  |
| Visibility | `.gm visible` | Moderator | Toggle GM visibility to other players. |  |
| GM chat badge | `.gm chat` | Moderator | Toggle the staff GM chat badge. |  |
| God mode | `.cheat god` | Administrator | Enable or disable god mode (no damage taken). |  |
| Instant cast | `.cheat casttime` | Administrator | Toggle zero spell cast time. |  |
| No cooldowns | `.cheat cooldown` | Administrator | Toggle zero spell cooldowns. |  |
| No spell cost | `.cheat power` | Administrator | Toggle zero mana/rage/energy spell cost. |  |
| Cheat status | `.cheat status` | Administrator | Show which cheats are currently enabled. |  |
| GPS | `.gps` | Administrator | Show position, zone, map, and orientation for target or self. |  |
| Revive | `.revive` | Administrator | Revive the selected or named player. |  |
| Repair items | `.repairitems` | GM | Repair all items for the selected player. |  |
| Respawn | `.respawn` | Administrator | Respawn the selected creature or nearby dead creatures/objects. |  |
| Bank | `.bank` | Administrator | Open your bank UI. |  |
| Mailbox | `.mailbox` | Administrator | Open your mailbox UI. |  |
| Combat stop | `.combatstop` | GM | Stop combat for the selected player. |  |
| Recall | `.recall` | Moderator | Return the selected/named player to their previous teleport position. |  |
| Save character | `.save` | Player | Save your character immediately. |  |
| Dismount | `.dismount` | GM | Dismount yourself. |  |
| Whispers | `.whispers` | Moderator | Enable or disable accepting whispers in GM mode. |  |
| Unstuck | `.unstuck` | Player | Teleport a player to bind/home/graveyard. |  |
| Server time | `.time` | Player | Show or set in-game time mode (auto/day/night). |  |

## Travel

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| Teleport | `.tele` | Moderator | Teleport to a saved game_tele destination by name or prefix. Use Lookup -> Tele to search all locations. |  |
| Tele: Stormwind | `.tele Stormwind` | Moderator | Teleport to Stormwind. |  |
| Tele: Ironforge | `.tele Ironforge` | Moderator | Teleport to Ironforge. |  |
| Tele: Darnassus | `.tele Darnassus` | Moderator | Teleport to Darnassus. |  |
| Tele: Orgrimmar | `.tele Orgrimmar` | Moderator | Teleport to Orgrimmar. |  |
| Tele: Thunder Bluff | `.tele ThunderBluff` | Moderator | Teleport to Thunder Bluff. |  |
| Tele: Undercity | `.tele Undercity` | Moderator | Teleport to Undercity. |  |
| Tele: Booty Bay | `.tele BootyBay` | Moderator | Teleport to Booty Bay. |  |
| Tele: Gadgetzan | `.tele Gadgetzan` | Moderator | Teleport to Gadgetzan. |  |
| Tele: Ratchet | `.tele Ratchet` | Moderator | Teleport to Ratchet. |  |
| Tele: Everlook | `.tele Everlook` | Moderator | Teleport to Everlook. |  |
| Tele: Moonglade | `.tele Moonglade` | Moderator | Teleport to Moonglade. |  |
| Tele: GM Island | `.tele GMIsland` | Moderator | Teleport to GM Island. |  |
| Tele: Zephras | `.tele Zephras` | Moderator | Teleport to Zephras (Forever custom zone). |  |
| Tele: Scarlet Enclave | `.tele ScarletEnclave` | Moderator | Teleport to Scarlet Enclave (Forever custom zone). |  |
| Tele: Hyjal Crater | `.tele HyjalCrater` | Moderator | Teleport to Hyjal Crater (Forever custom zone). |  |
| Tele: Drowned City | `.tele DrownedCity` | Moderator | Teleport to The Drowned City (Forever custom zone). |  |
| Tele: Kroldok Stronghold | `.tele KroldokStronghold` | Moderator | Teleport to Kroldok Stronghold (Forever custom zone). |  |
| Tele: Dalaran Forever | `.tele DalaranCityForever` | Moderator | Teleport to Dalaran City (Forever custom zone). |  |
| Tele: Naxxramas | `.tele Naxx` | Moderator | Teleport to Naxxramas. |  |
| Appear at player | `.appear` | Moderator | Teleport yourself to a player (can be offline). |  |
| Summon player | `.summon` | Player | Summon a player to your location. |  |
| Go XYZ | `.go xyz` | Moderator | Teleport to coordinates; z defaults to ground/water level and mapId defaults to current map. |  |
| Go Zone XY | `.go zonexy` | Moderator | Teleport to zone-relative coordinates (0..100). |  |
| Go creature (entry) | `.go creature id` | Moderator | Teleport to the first spawn of a creature template ID. Use FIND to search creatures by name. |  |
| Go creature (spawn) | `.go creature` | Moderator | Teleport to a creature spawn by its spawn GUID. |  |
| Go object (entry) | `.go gameobject id` | Moderator | Teleport to the first spawn of a gameobject template ID. Use FIND to search objects by name. |  |
| Go object (spawn) | `.go gameobject` | Moderator | Teleport to a gameobject spawn by its spawn GUID. |  |
| Go graveyard | `.go graveyard` | Moderator | Teleport to a graveyard by ID. |  |
| Go offset | `.go offset` | Moderator | Teleport relative to your current position and facing. |  |
| Come to me | `.cometome` | Administrator | Move the selected creature to your position. |  |
| Speed | `.modify speed` | Moderator | Set all movement speed multipliers on the selected player or self. |  |
| Fly mode | `.gm fly` | Administrator | Enable or disable GM fly mode. |  |
| Waterwalk | `.cheat waterwalk` | Administrator | Enable or disable waterwalk cheat on selected player or self. |  |
| Taxi cheat | `.cheat taxi` | Administrator | Temporarily unlock or lock all taxi routes on selected player or self. |  |
| Save teleport | `.tele add` | Administrator | Persist your current position as a named game_tele destination. | yes |
| Delete teleport | `.tele del` | Administrator | Delete a saved game_tele destination by name. | yes |
| Teleport player | `.tele name` | Moderator | Teleport the selected or named player (can be offline) to a saved destination. |  |
| Teleport group | `.tele group` | Moderator | Teleport the selected player's group to a saved destination. |  |

## Player

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| Level up/down | `.levelup` | Administrator | Change level by a delta for the selected or named player. |  |
| Set HP | `.modify hp` | Moderator | Set HP on the selected player or self. |  |
| Set mana | `.modify mana` | Moderator | Set mana on the selected player or self. |  |
| Money | `.modify money` | Moderator | Add or remove copper on the selected player or self (10000 = 1g). |  |
| Scale | `.modify scale` | Moderator | Change scale of the selected unit or self. |  |
| Set reputation | `.modify reputation` | GM | Set reputation with a faction on the selected player. Use FIND to resolve a faction name. |  |
| Add item | `.additem` | Administrator | Add item(s) to selected player or self. Use FIND to search items by name. |  |
| Add item set | `.additem set` | Administrator | Add every item in an item set to selected player or self. Use FIND to resolve a set name. |  |
| Set skill | `.setskill` | Administrator | Set a skill on the selected player. Use FIND to resolve a skill name. |  |
| Clear cooldown | `.cooldown` | Administrator | Clear all or a specific spell cooldown on the selected player or self. Use FIND to resolve a spell name. |  |
| Add aura | `.aura` | Administrator | Apply an aura to the selected unit or self. Use FIND to resolve a spell name. |  |
| Remove aura | `.unaura` | Administrator | Remove a specific aura or all auras from the selected unit. Use FIND to resolve a spell name. |  |
| Cast | `.cast` | Administrator | Cast a spell on the selected target or self. Use FIND to resolve a spell name. |  |
| Unlearn | `.unlearn` | Administrator | Unlearn a spell from the selected player. Use FIND to resolve a spell name. |  |
| Player info | `.pinfo` | GM | Show player and account information. |  |
| GUID | `.guid` | GM | Show GUID of the selected unit or object. |  |
| Explore all | `.cheat explore 1` | Administrator | Reveal all map areas for the selected player or self. |  |
| Clear exploration | `.cheat explore 0` | Administrator | Hide all map areas for the selected player or self. |  |
| Morph | `.morph` | GM | Set display ID on selected unit or self. |  |
| Morph: Human | `.morph 49` | GM | Apply the Human display ID. |  |
| Morph: Orc | `.morph 51` | GM | Apply the Orc display ID. |  |
| Morph: Dwarf | `.morph 53` | GM | Apply the Dwarf display ID. |  |
| Morph: Night Elf | `.morph 55` | GM | Apply the Night Elf display ID. |  |
| Morph: Undead | `.morph 57` | GM | Apply the Undead display ID. |  |
| Morph: Tauren | `.morph 59` | GM | Apply the Tauren display ID. |  |
| Morph: Troll | `.morph 1478` | GM | Apply the Troll display ID. |  |
| Morph: Gnome | `.morph 1563` | GM | Apply the Gnome display ID. |  |
| Demorph | `.demorph` | GM | Restore the selected unit's normal display. |  |
| Learn spell | `.learn` | Administrator | Teach a spell to the selected player. Use FIND to resolve a spell name. |  |
| Learn trainer spells | `.learn my trainer` | Administrator | Teach all trainer spells for the selected player's class. | yes |
| Learn quest spells | `.learn my quests` | Administrator | Teach all quest-rewarded spells for the selected player's class. | yes |
| Learn recipes | `.learn all recipes` | Administrator | Teach all profession recipes. | yes |
| Learn crafts | `.learn all crafts` | Administrator | Teach all professions and secondary skills. | yes |
| Learn default spells | `.learn all default` | Administrator | Teach all default race/class spells. | yes |
| Learn all talents | `.learn all talents` | Administrator | Teach all talents for the selected player. | yes |
| Send items | `.send items` | Moderator | Mail item(s) to a player (can be offline). |  |
| Send mail | `.send mail` | GM | Send an in-game mail to a player. |  |
| Send money | `.send money` | GM | Mail copper to a player. |  |
| Send message | `.send message` | GM | Send a system message directly to a player's screen. |  |
| Force customize | `.character customize` | GM | Flag a character for appearance customization on next login. |  |
| Force race change | `.character changerace` | GM | Flag a character for race change on next login. |  |
| Force faction change | `.character changefaction` | GM | Flag a character for faction change on next login. |  |
| Force rename | `.character rename` | GM | Flag a character for rename on next login. |  |
| Reset talents | `.reset talents` | Administrator | Reset talents for the selected or named player. | yes |
| Reset spells | `.reset spells` | Administrator | Remove all non-original spells from spellbook. | yes |
| Reset level | `.reset level` | Administrator | Reset character level to 1 (also resets stats and talents). | yes |

## World

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| NPC info | `.npc info` | Administrator | Inspect the selected creature. |  |
| Nearby NPCs | `.npc near` | GM | List nearby creatures. |  |
| Add NPC | `.npc add` | GM | Create a persistent creature spawn at your position. Use FIND to search creatures by name. | yes |
| Spawn temp NPC | `.npc add temp` | GM | Spawn a temporary (non-DB) creature at your position. Use FIND to search creatures by name. |  |
| Move NPC | `.npc move` | GM | Move the selected or specified creature spawn to your position. | yes |
| NPC say | `.npc say` | Moderator | Make the selected creature say text. |  |
| NPC yell | `.npc yell` | Moderator | Make the selected creature yell text. |  |
| NPC emote | `.npc playemote` | Administrator | Play an emote on the selected creature. |  |
| Delete NPC | `.npc delete` | GM | Delete the selected or specified creature spawn. | yes |
| Quest add | `.quest add` | Administrator | Add a quest to the selected player's log. Use FIND to resolve a quest title. |  |
| Quest complete | `.quest complete` | Administrator | Mark all quest objectives as completed for the selected player. Use FIND to resolve a quest title. |  |
| Quest reward | `.quest reward` | Administrator | Grant quest reward to selected player and remove completed quest. Use FIND to resolve a quest title. |  |
| Quest remove | `.quest remove` | Administrator | Remove a quest from the selected player's log. Use FIND to resolve a quest title. | yes |
| Active events | `.event activelist` | Moderator | List currently active game events. |  |
| Event info | `.event info` | Moderator | Show details about a game event. Use FIND to search events by name. |  |
| Event start | `.event start` | Moderator | Start a game event. Use FIND to search events by name. | yes |
| Event stop | `.event stop` | Moderator | Stop a game event. Use FIND to search events by name. | yes |
| List creatures | `.list creature` | Administrator | List creature spawns matching a template ID. Use FIND to resolve a creature name. |  |
| List objects | `.list object` | Administrator | List gameobject spawns matching a template ID. Use FIND to resolve an object name. |  |
| List items | `.list item` | Administrator | List where an item exists (inventories, mail, auctions, guild banks). Use FIND to resolve an item name. |  |
| Add gameobject | `.gobject add` | GM | Create and persist a gameobject at your position. Use FIND to resolve an object name. | yes |
| Spawn temp object | `.gobject add temp` | GM | Spawn a temporary (non-DB) gameobject at your position. Use FIND to resolve an object name. |  |
| Nearby objects | `.gobject near` | GM | List nearby gameobjects. |  |
| Object info | `.gobject info` | GM | Query gameobject information by entry or guid. |  |
| Target gameobject | `.gobject target` | GM | Find the nearest gameobject. |  |
| Activate object | `.gobject activate` | GM | Activate a gameobject (door, chest, button, etc.). |  |
| Delete gameobject | `.gobject delete` | GM | Delete a persistent gameobject spawn. | yes |
| Instance binds | `.instance listbinds` | Moderator | List instance binds for the selected player or self. |  |
| Unbind instances | `.instance unbind` | Moderator | Unbind instances for the selected player or self. | yes |

## Lookup

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| Item | `.lookup item` | Administrator | Search item templates by name and return matching IDs/links. |  |
| Item set | `.lookup item set` | Administrator | Search item sets by name and return IDs. |  |
| Quest | `.lookup quest` | Administrator | Search quests by title and return matching IDs. |  |
| Spell | `.lookup spell` | Administrator | Search spells by name and return matching IDs/links. |  |
| Creature | `.lookup creature` | Administrator | Search creature templates by name and return entry IDs. |  |
| Object | `.lookup object` | Administrator | Search gameobject templates by name and return entry IDs. |  |
| Teleport location | `.lookup tele` | Administrator | Search saved game_tele locations by name. |  |
| Faction | `.lookup faction` | Administrator | Search factions by name and return IDs. |  |
| Skill | `.lookup skill` | Administrator | Search skills by name and return IDs. |  |
| Event | `.lookup event` | Administrator | Search game events by name and return event IDs. |  |
| Area | `.lookup area` | Administrator | Search AreaTable areas by name. |  |
| Map | `.lookup map` | Administrator | Search maps by name. |  |
| Taxinode | `.lookup taxinode` | Administrator | Search flight paths / taxinodes by name. |  |
| Title | `.lookup title` | Administrator | Search character titles by name. |  |
| Player by account | `.lookup player account` | Administrator | Find characters associated with matching account names. |  |
| Player by email | `.lookup player email` | Administrator | Find characters through matching account email. |  |
| Player by IP | `.lookup player ip` | Administrator | Find characters through matching account last-IP data. |  |

## Admin

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| Online GMs | `.gm ingame` | Moderator | List GMs currently in game. |  |
| Full GM list | `.gm list` | Administrator | List all GM accounts and security levels. |  |
| Commands | `.commands` | Player | List commands available to your account. |  |
| Server info | `.server info` | Administrator | Display server version and connected player count. |  |
| Server MOTD | `.server motd` | Administrator | Show the server Message of the Day. |  |
| Save all | `.saveall` | Moderator | Save all online characters. |  |
| Reload config | `.reload config` | Administrator | Reload worldserver.conf settings. | yes |
| Reload all | `.reload all` | Administrator | Reload all safe-reloadable world tables. | yes |
| Reload teleports | `.reload game_tele` | Administrator | Reload the game_tele table. | yes |
| Announce | `.announce` | Moderator | Broadcast a global system message in chat. |  |
| GM announce | `.gmannounce` | Moderator | Broadcast a chat announcement to online GMs only. |  |
| Notify | `.notify` | Moderator | Send a global on-screen notification. |  |
| GM notify | `.gmnotify` | Moderator | Send an on-screen notification to online GMs only. |  |
| Kick | `.kick` | GM | Kick a player from the world. | yes |
| Freeze | `.freeze` | Moderator | Freeze a player in place. | yes |
| Unfreeze | `.unfreeze` | Moderator | Unfreeze a player. | yes |
| Mute | `.mute` | Moderator | Mute an account's chat for N minutes. | yes |
| Unmute | `.unmute` | Moderator | Remove a chat mute. | yes |
| Ban info: account | `.baninfo account` | Administrator | Show ban details for an account. |  |
| Ban info: character | `.baninfo character` | Administrator | Show ban details for a character. |  |
| Ban character | `.ban character` | Administrator | Ban a character (duration e.g. 4d20h or -1 for permanent). | yes |
| Ban account | `.ban account` | Administrator | Ban an account (duration e.g. 4d20h or -1 for permanent). | yes |
| Ban IP | `.ban ip` | Administrator | Ban an IP address. | yes |
| Unban character | `.unban character` | Administrator | Remove a character ban. | yes |
| Unban account | `.unban account` | Administrator | Remove an account ban. | yes |
| Unban IP | `.unban ip` | Administrator | Remove an IP ban. | yes |

## Danger

| Label | Command | Access | What it does | Danger |
| --- | --- | --- | --- | --- |
| Server restart | `.server restart` | Administrator | Schedule a server restart. Requires double-run confirmation in this addon. | yes |
| Cancel restart | `.server restart cancel` | Administrator | Cancel a pending restart timer. |  |
| Cancel shutdown | `.server shutdown cancel` | Administrator | Cancel a pending shutdown timer. |  |
| Server shutdown | `.server shutdown` | Administrator | Schedule a server shutdown. Requires double-run confirmation in this addon. | yes |
| Kill selected | `.die` | Administrator | Kill the selected unit. Requires double-run confirmation. | yes |
