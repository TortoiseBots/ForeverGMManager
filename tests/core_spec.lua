-- Lightweight behavior tests for the public ForeverGMManager core interface.
-- Run with: lua5.1 tests/core_spec.lua

TortoiseGMManager = nil
TortoiseGMManagerDB = nil

local sent = {}
local chatSent = {}
local now = 100

function GetTime()
    return now
end

function SendChatMessage(message, channel)
    table.insert(sent, { message = message, channel = channel })
end

C_ChatInfo = {
    SendChatMessage = function(message, channel)
        table.insert(chatSent, { message = message, channel = channel })
    end,
}

DEFAULT_CHAT_FRAME = nil

dofile("Data.lua")
dofile("Teleports.lua")
dofile("Core.lua")

-- Keep the behavioral assertions readable while exercising the renamed addon.
local TortoiseGM = TortoiseGMManager

local failures = 0
local checks = 0

local function expectEqual(actual, expected, label)
    checks = checks + 1
    if actual ~= expected then
        failures = failures + 1
        print("FAIL: " .. label .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
    end
end

local function expectTrue(actual, label)
    expectEqual(actual, true, label)
end

local function expectFalse(actual, label)
    expectEqual(actual, false, label)
end

-- UI placement defaults are persistent core state, not frame implementation details.
TortoiseGM.InitializeDB()
local TortoiseGMDB = TortoiseGMManagerDB
expectEqual(TortoiseGMDB.minimapX, 52, "default minimap X offset")
expectEqual(TortoiseGMDB.minimapY, 52, "default minimap Y offset")
expectEqual(TortoiseGMDB.framePoint, "CENTER", "default frame anchor")
expectEqual(TortoiseGMDB.frameX, 0, "default frame X offset")
expectEqual(TortoiseGMDB.frameY, 15, "default frame Y offset")

-- Safety semantics should match command tokens, not arbitrary string prefixes.
expectTrue(TortoiseGM.IsDangerous(".server restart 10"), "restart is dangerous")
expectTrue(TortoiseGM.IsDangerous(".server idlerestart 10"), "idle restart is dangerous")
expectTrue(TortoiseGM.IsDangerous(".server idleshutdown 10"), "idle shutdown is dangerous")
expectFalse(TortoiseGM.IsDangerous(".server restart cancel"), "restart cancel is safe")
expectFalse(TortoiseGM.IsDangerous(".kickstarter"), "unrelated command sharing .kick prefix is safe")
expectTrue(TortoiseGM.IsDangerous(".kick PlayerName"), "kick command is dangerous")
expectTrue(TortoiseGM.IsDangerous(".tele add MySpot"), "persistent teleport creation is dangerous")
expectTrue(TortoiseGM.IsDangerous(".gobject delete 123"), "gameobject deletion is dangerous")
expectTrue(TortoiseGM.IsDangerous(".learn all recipes"), "bulk learn command is dangerous")
expectFalse(TortoiseGM.IsDangerous(".tele name Player Stormwind"), "player teleport is not treated as persistent tele edit")

-- Every catalogue entry explicitly marked danger must participate in the core confirmation guard.
local dangerIndex
for dangerIndex = 1, #TortoiseGM.commands do
    local dangerEntry = TortoiseGM.commands[dangerIndex]
    if dangerEntry.danger then
        expectTrue(TortoiseGM.IsDangerous(dangerEntry.command), "danger preset is guarded: " .. dangerEntry.command)
    end
end

-- Lookup uses an explicit query and never derives it from executable command arguments.
local lookupEntry = { command = ".additem", lookupCommand = ".lookup item", lookupHint = "an item name" }
expectEqual(TortoiseGM.BuildLookupCommand(lookupEntry, "Thunderfury"), ".lookup item Thunderfury", "builds lookup from explicit query")
expectEqual(TortoiseGM.BuildLookupCommand(lookupEntry, ""), nil, "empty explicit query builds nothing")

-- Normalization and composer extraction are the public text-processing seam.
expectEqual(TortoiseGM.NormalizeCommand("  gm   visible   on\n"), ".gm visible on", "normalizes whitespace and dot prefix")
expectEqual(TortoiseGM.GetComposerArgs(lookupEntry, ".ADDITEM Thunderfury"), "Thunderfury", "composer args are extracted case-insensitively")
expectEqual(TortoiseGM.GetComposerArgs(lookupEntry, ".cast Fireball"), ".cast Fireball", "unrelated composer text is preserved")

-- Positive FIND path sends the lookup only, preserving the action for the UI.
local sentBeforeLookup = #chatSent
expectTrue(TortoiseGM.ExecuteLookup(lookupEntry, "Thunderfury"), "explicit lookup executes")
expectEqual(#chatSent, sentBeforeLookup + 1, "matching lookup sends one chat command via C_ChatInfo")
expectEqual(chatSent[#chatSent].message, ".lookup item Thunderfury", "matching lookup sends expected command")
expectEqual(chatSent[#chatSent].channel, "SAY", "lookup uses chat command channel")

-- Help strips user arguments and targets the known catalogue route.
local sentBeforeHelp = #chatSent
expectTrue(TortoiseGM.RequestHelp(".server restart 10"), "help request accepts composed command")
expectEqual(chatSent[#chatSent].message, ".help server restart", "help strips user arguments")
expectEqual(#chatSent, sentBeforeHelp + 1, "help sends once")

-- Dangerous execution is two-step; explicit lifecycle cancel is immediate.
local sentBeforeDanger = #chatSent
expectFalse(TortoiseGM.Execute(".server restart 10"), "first dangerous RUN only arms")
expectEqual(#chatSent, sentBeforeDanger, "armed dangerous command sends nothing")
expectTrue(TortoiseGM.Execute(".server restart 10"), "second identical dangerous RUN executes")
expectEqual(chatSent[#chatSent].message, ".server restart 10", "confirmed dangerous command is sent")

local sentBeforeCancel = #chatSent
expectTrue(TortoiseGM.Execute(".server restart cancel"), "restart cancel executes immediately")
expectEqual(#chatSent, sentBeforeCancel + 1, "restart cancel sends once")

-- Fallback to global SendChatMessage when C_ChatInfo is absent.
local savedChatInfo = C_ChatInfo
C_ChatInfo = nil
local legacyBefore = #sent
expectTrue(TortoiseGM.Execute(".gps"), "fallback SendChatMessage executes when C_ChatInfo is absent")
expectEqual(#sent, legacyBefore + 1, "fallback sends once via SendChatMessage")
expectEqual(sent[#sent].message, ".gps", "fallback sends expected command")
C_ChatInfo = savedChatInfo

-- History deduplicates and keeps most-recent-first ordering.
TortoiseGM.AddHistory(".gps")
TortoiseGM.AddHistory(".server info")
TortoiseGM.AddHistory(".gps")
expectEqual(TortoiseGMDB.history[1], ".gps", "history moves repeated command to front")
expectEqual(TortoiseGMDB.history[2], ".server info", "history retains other recent command")

-- Favourites persist known catalogue commands and toggle cleanly.
local favouriteEntry = TortoiseGM.commands[1]
expectTrue(TortoiseGM.ToggleFavourite(favouriteEntry), "favourite can be added")
expectTrue(TortoiseGM.IsFavourite(favouriteEntry.command), "added command is favourite")
expectEqual(#TortoiseGM.GetFavouriteCommands(), 1, "favourites view returns added command")
expectFalse(TortoiseGM.ToggleFavourite(favouriteEntry), "favourite can be removed")
expectFalse(TortoiseGM.IsFavourite(favouriteEntry.command), "removed command is not favourite")

-- Structured values are initialized, validated and composed through the core seam.
local scaleEntry = TortoiseGM.FindEntry("modify-scale")
local scaleValues = TortoiseGM.InitializeValues(scaleEntry)
expectEqual(scaleValues.scale, 1, "scale default")
expectEqual(TortoiseGM.ComposeValues(scaleEntry, scaleValues), ".modify scale 1", "structured scale composition")
expectEqual(TortoiseGM.AdjustNumber(scaleEntry.arguments[1], 9.95, 1), 10, "numeric increment clamps maximum")
expectEqual(TortoiseGM.AdjustNumber(scaleEntry.arguments[1], 0.1, -1), 0.1, "numeric decrement clamps minimum")

local flyEntry = TortoiseGM.FindEntry("gm-fly")
local flyValues = TortoiseGM.InitializeValues(flyEntry)
expectEqual(TortoiseGM.ComposeValues(flyEntry, flyValues), ".gm fly on", "gm-fly defaults to on token")
flyValues.state = TortoiseGM.CycleToggle(flyEntry.arguments[1], flyValues.state, 1)
expectEqual(flyValues.state, "off", "toggle cycles to exact off token")
expectEqual(TortoiseGM.GetOptionLabel(flyEntry.arguments[1], flyValues.state), "OFF", "toggle display label")
expectEqual(TortoiseGM.ComposeValues(flyEntry, flyValues), ".gm fly off", "toggle off composition")

local addItem = TortoiseGM.FindEntry("additem")
local valid, validationMessage = TortoiseGM.ValidateValues(addItem, TortoiseGM.InitializeValues(addItem))
expectFalse(valid, "required lookup ID validation")
expectEqual(validationMessage, "Item ID is required.", "required validation identifies field")
expectEqual(TortoiseGM.GetInteraction(TortoiseGM.FindEntry("gps")), "execute", "safe argument-free interaction")
expectEqual(TortoiseGM.GetInteraction(addItem), "configure", "structured interaction")
expectEqual(TortoiseGM.GetInteraction(TortoiseGM.FindEntry("npc-add")), "review", "dangerous interaction")
expectEqual(TortoiseGM.GetInteraction(nil), "load", "manual interaction")

local itemValues = TortoiseGM.InitializeValues(addItem)
itemValues.count = 7
local filledValues, filledCommand = TortoiseGM.ComposeLookupResult(addItem, itemValues, 19019)
expectEqual(filledValues.itemId, "19019", "lookup fills lookup-id")
expectEqual(filledValues.count, 7, "lookup preserves count")
expectEqual(filledCommand, ".additem 19019 7", "lookup result composes modifiers")
itemValues.itemId = "19019"
itemValues.count = "10"
expectTrue(TortoiseGM.ValidateValues(addItem, itemValues), "typed count 10 is valid")
expectEqual(TortoiseGM.ComposeValues(addItem, itemValues), ".additem 19019 10", "typed count 10 composes")
itemValues.count = "20"
expectTrue(TortoiseGM.ValidateValues(addItem, itemValues), "typed count 20 is valid")
itemValues.count = "0"
valid, validationMessage = TortoiseGM.ValidateValues(addItem, itemValues)
expectFalse(valid, "zero count is rejected")
expectEqual(validationMessage, "Count must be between 1 and 1000.", "count lower bound is precise")
itemValues.count = "1001"
valid, validationMessage = TortoiseGM.ValidateValues(addItem, itemValues)
expectFalse(valid, "count above maximum is rejected")
expectEqual(validationMessage, "Count must be between 1 and 1000.", "count upper bound is precise")
itemValues.count = "1.5"
valid, validationMessage = TortoiseGM.ValidateValues(addItem, itemValues)
expectFalse(valid, "fractional count is rejected")
expectEqual(validationMessage, "Count must be an integer.", "integer validation is precise")
local optionalPlayerEntry = {
    command = ".additem",
    arguments = {
        { key = "itemId", label = "Item ID", type = "lookup-id", required = true },
        { key = "count", label = "Count", type = "number", required = true, default = 1, min = 1, max = 1000, integer = true },
        { key = "player", label = "Player", type = "text", optional = true },
    },
}
local optionalValues = TortoiseGM.InitializeValues(optionalPlayerEntry)
optionalValues.itemId = "19019"; optionalValues.count = "20"; optionalValues.player = ""
expectTrue(TortoiseGM.ValidateValues(optionalPlayerEntry, optionalValues), "optional blank modifier is valid")

-- Legacy command favourites migrate once to stable IDs, including merged aliases.
TortoiseGMManagerDB.favourites = { ".gm on", ".hover 0", ".not-a-command" }
TortoiseGM.MigrateFavourites()
expectEqual(TortoiseGMManagerDB.favourites[1], "gm-mode", "legacy GM favourite migrates")
expectEqual(TortoiseGMManagerDB.favourites[2], "gm-fly", "merged alias favourite migrates")
expectEqual(#TortoiseGMManagerDB.favourites, 2, "unresolvable favourite is omitted")
TortoiseGM.MigrateFavourites()
expectEqual(#TortoiseGMManagerDB.favourites, 2, "favourite migration is idempotent")
expectTrue(#TortoiseGM.GetFilteredCommands("all", ".gm off") > 0, "search includes merged legacy command")
expectTrue(#TortoiseGM.GetFilteredCommands("all", "OFF") > 0, "search includes option labels")
expectTrue(#TortoiseGM.GetFilteredCommands("all", "item id") > 0, "search includes argument labels")

-- Every hinted command receives a helpful fallback input when no richer schema exists.
local teleEntry = TortoiseGM.FindEntry("tele")
local teleValues = TortoiseGM.InitializeValues(teleEntry)
teleValues.location = "ThunderBluff"
expectEqual(TortoiseGM.ComposeValues(teleEntry, teleValues), ".tele ThunderBluff", "tele location input composes exact command")
local summonEntry = TortoiseGM.FindEntry("summon")
local summonArguments = TortoiseGM.GetEntryArguments(summonEntry)
expectEqual(#summonArguments, 1, "hinted command receives one fallback input")
expectEqual(summonArguments[1].key, "arguments", "fallback input stores raw syntax arguments")
local summonValues = TortoiseGM.InitializeValues(summonEntry)
summonValues.arguments = "Testplayer"
expectEqual(TortoiseGM.ComposeValues(summonEntry, summonValues), ".summon Testplayer", "fallback input updates command preview")
local hpEntry = TortoiseGM.FindEntry("modify-hp")
local hpValues = TortoiseGM.InitializeValues(hpEntry)
hpValues.current = 5000
expectEqual(TortoiseGM.ComposeValues(hpEntry, hpValues), ".modify hp 5000", "HP control composes current HP")

TortoiseGMDB.favourites = {}
expectEqual(TortoiseGM.GetDefaultCategory(), "all", "All is default when no favourites exist")
TortoiseGMDB.favourites = { TortoiseGM.commands[1].id }
expectEqual(TortoiseGM.GetDefaultCategory(), "favourites", "Fav is default when favourites exist")

-- Toggle state starts unknown, records ON/OFF on execution, and confirms from CHAT_MSG_SYSTEM.
expectEqual(TortoiseGM.GetToggleState("gm-mode"), nil, "unknown toggle state starts nil")
expectTrue(TortoiseGM.Execute(".gm on"), "executes .gm on")
expectEqual(TortoiseGM.GetToggleState("gm-mode"), "on", "stores ON toggle state on run")
expectTrue(TortoiseGM.Execute(".gm off"), "executes .gm off")
expectEqual(TortoiseGM.GetToggleState("gm-mode"), "off", "stores OFF toggle state on run")
expectTrue(TortoiseGM.Execute(".hover 1"), "executes legacy fly toggle")
expectEqual(TortoiseGM.GetToggleState("gm-fly"), "on", "stores legacy toggle state on run")

local refreshCount = 0
local savedRefreshList = TortoiseGM.RefreshList
TortoiseGM.RefreshList = function() refreshCount = refreshCount + 1 end

function UnitName(unit)
    if unit == "player" then return "Testgm" end
    return nil
end

local replyCases = {
    { "GM mode is ON", "gm-mode", "on" },
    { "GM mode is OFF", "gm-mode", "off" },
    { "You are now visible.", "visibility", "on" },
    { "You are now invisible.", "visibility", "off" },
    { "You are: visible", "visibility", "on" },
    { "You are: invisible", "visibility", "off" },
    { "GM Chat Badge is ON", "gm-chat", "on" },
    { "GM Chat Badge is OFF", "gm-chat", "off" },
    { "Godmode is ON. You won't take damage.", "god-mode", "on" },
    { "Godmode is OFF. You can take damage.", "god-mode", "off" },
    { "Godmode: ON.", "god-mode", "on" },
    { "Godmode: OFF.", "god-mode", "off" },
    { "CastTime Cheat is ON. Your spells won't have a casttime.", "cheat-casttime", "on" },
    { "CastTime Cheat is OFF. Your spells will have a casttime.", "cheat-casttime", "off" },
    { "Casttime: ON.", "cheat-casttime", "on" },
    { "Casttime: OFF.", "cheat-casttime", "off" },
    { "Cooldown Cheat is ON. You are not on the global cooldown.", "cheat-cooldown", "on" },
    { "Cooldown Cheat is OFF. You are on the global cooldown.", "cheat-cooldown", "off" },
    { "Cooldown: ON.", "cheat-cooldown", "on" },
    { "Cooldown: OFF.", "cheat-cooldown", "off" },
    { "Power Cheat is ON. You don't need mana/rage/energy to use spells.", "cheat-power", "on" },
    { "Power Cheat is OFF. You need mana/rage/energy to use spells.", "cheat-power", "off" },
    { "Power: ON.", "cheat-power", "on" },
    { "Power: OFF.", "cheat-power", "off" },
    { "Waterwalking is ON. You can walk on water.", "waterwalk", "on" },
    { "Waterwalking is OFF. You can't walk on water.", "waterwalk", "off" },
    { "Waterwalk: ON.", "waterwalk", "on" },
    { "Waterwalk: OFF.", "waterwalk", "off" },
    { "Taxinodes: ON.", "taxicheat", "on" },
    { "Taxinodes: OFF.", "taxicheat", "off" },
    { "|cffffffff|Hplayer:Testgm|h[Testgm]|h|r has access to all taxi nodes now (until logout).", "taxicheat", "on" },
    { "|cffffffff|Hplayer:Testgm|h[Testgm]|h|r has no more access to all taxi nodes now (only visited accessible).", "taxicheat", "off" },
    { "Accepting Whisper: ON", "whispers", "on" },
    { "Accepting Whisper: off", "whispers", "off" },
    { "|cffffffff|Hplayer:Testgm|h[Testgm]|h|r's Fly Mode on", "gm-fly", "on" },
    { "|cffffffff|Hplayer:Testgm|h[Testgm]|h|r's Fly Mode off", "gm-fly", "off" },
}

local caseIndex
for caseIndex = 1, #replyCases do
    local reply = replyCases[caseIndex]
    local parsedId, parsedState = TortoiseGM.ParseToggleSystemMessage(reply[1])
    expectEqual(parsedId, reply[2], "parses id for: " .. reply[1])
    expectEqual(parsedState, reply[3], "parses state for: " .. reply[1])
    expectEqual(TortoiseGM.GetToggleState(reply[2]), reply[3], "stores state for: " .. reply[1])
end

local refreshBeforeIgnore = refreshCount
local unknownId, unknownState = TortoiseGM.ParseToggleSystemMessage("Random system message: nothing to toggle")
expectEqual(unknownId, nil, "ignores unknown system message")
expectEqual(unknownState, nil, "unknown system message returns nil state")
local otherFlyId = TortoiseGM.ParseToggleSystemMessage("|cffffffff|Hplayer:Otherplayer|h[Otherplayer]|h|r's Fly Mode on")
expectEqual(otherFlyId, nil, "ignores fly mode reply for another player")
expectEqual(TortoiseGM.GetToggleState("gm-fly"), "off", "other player's fly mode does not overwrite self")
expectEqual(refreshCount, refreshBeforeIgnore, "ignored messages do not trigger UI refresh")

TortoiseGM.RefreshList = savedRefreshList
UnitName = nil

-- Minimap visibility persistence and toggling
expectEqual(TortoiseGMDB.minimapHidden, false, "minimapHidden defaults to false")
expectEqual(TortoiseGM.IsMinimapHidden(), false, "IsMinimapHidden starts false")
local minimapRefreshes = 0
local savedRefreshMinimap = TortoiseGM.RefreshMinimapButton
TortoiseGM.RefreshMinimapButton = function() minimapRefreshes = minimapRefreshes + 1 end
expectEqual(TortoiseGM.ToggleMinimapButton(), true, "ToggleMinimapButton hides minimap button")
expectEqual(TortoiseGMDB.minimapHidden, true, "minimapHidden persists as true")
expectEqual(minimapRefreshes, 1, "RefreshMinimapButton called on toggle")
expectEqual(TortoiseGM.ToggleMinimapButton(), false, "ToggleMinimapButton shows minimap button again")
expectEqual(TortoiseGM.SetMinimapHidden(true), true, "SetMinimapHidden sets hidden true")
expectEqual(TortoiseGM.IsMinimapHidden(), true, "IsMinimapHidden reflects true")
TortoiseGM.RefreshMinimapButton = savedRefreshMinimap

-- New ForeverAdmin-ported commands: composition, danger flags, and lookup support
local gobjectMoveEntry = TortoiseGM.FindEntry("gobject-move")
expectTrue(gobjectMoveEntry ~= nil, "gobject-move entry exists")
expectTrue(gobjectMoveEntry.danger == true, "gobject-move is marked dangerous")
expectTrue(TortoiseGM.IsDangerous(".gobject move 123"), "IsDangerous flags .gobject move")
expectEqual(TortoiseGM.ComposeValues(gobjectMoveEntry, { spawnId = 42 }), ".gobject move 42", "gobject-move composes spawnId")

local npcMovetypeEntry = TortoiseGM.FindEntry("npc-set-movetype")
expectTrue(npcMovetypeEntry ~= nil, "npc-set-movetype entry exists")
expectTrue(npcMovetypeEntry.danger == true, "npc-set-movetype is marked dangerous")
expectEqual(TortoiseGM.ComposeValues(npcMovetypeEntry, { movetype = "random" }), ".npc set movetype random", "npc-set-movetype composes toggle option")

local reloadTableEntry = TortoiseGM.FindEntry("reload-table")
expectTrue(reloadTableEntry ~= nil, "reload-table entry exists")
expectTrue(reloadTableEntry.danger == true, "reload-table is marked dangerous")
expectEqual(TortoiseGM.ComposeValues(reloadTableEntry, { table = "smart_scripts" }), ".reload smart_scripts", "reload-table composes table name")

local loglevelEntry = TortoiseGM.FindEntry("server-set-loglevel")
expectTrue(loglevelEntry ~= nil, "server-set-loglevel entry exists")
expectEqual(TortoiseGM.ComposeValues(loglevelEntry, { type = "l", name = "network", level = 2 }), ".server set loglevel l network 2", "server-set-loglevel composes all args")

-- Ported teleports are direct travel actions searchable by zone and point name.
local stockadeEntry = TortoiseGM.FindEntry("go-xyz-the-stockade")
expectTrue(stockadeEntry ~= nil, "ported teleport entry is loaded")
expectEqual(stockadeEntry.category, "travel", "ported teleport is in travel category")
expectEqual(stockadeEntry.direct, true, "ported teleport is direct")
expectEqual(stockadeEntry.access, "Moderator", "ported teleport uses Moderator access")
expectEqual(stockadeEntry.label, "Stormwind: The Stockade (Dungeon Entrance) (General)", "ported teleport label is Zone: Point")
expectEqual(stockadeEntry.command, ".go xyz -8779.9 834.35 94.68 0", "ported teleport builds .go xyz x y z map")

local thanesEntry = TortoiseGM.FindEntry("go-xyz-hall-of-thanes-entrance")
expectTrue(thanesEntry ~= nil, "teleport with orientation is loaded")
expectEqual(thanesEntry.command, ".go xyz -4820.631836 -936.790649 399.042877 0 1.951188", "ported teleport appends orientation when present")

expectEqual(TortoiseGM.FindEntry("go-xyz-stormwind"), nil, "existing .tele Stormwind shortcut is not duplicated")
expectEqual(TortoiseGM.FindEntry("go-xyz-zephris"), nil, "existing .tele Zephras shortcut is not duplicated")
expectEqual(TortoiseGM.FindEntry("go-xyz-naxxramas-instance"), nil, "existing .tele Naxx shortcut is not duplicated")

local zoneMatches = TortoiseGM.GetFilteredCommands("travel", "duskwood")
local foundDarkshire = false
local matchIndex
for matchIndex = 1, #zoneMatches do
    if zoneMatches[matchIndex].id == "go-xyz-darkshire" then foundDarkshire = true end
end
expectTrue(foundDarkshire, "catalogue search finds ported teleports by zone name")

local pointMatches = TortoiseGM.GetFilteredCommands("travel", "darkshire")
local foundPoint = false
for matchIndex = 1, #pointMatches do
    if pointMatches[matchIndex].id == "go-xyz-darkshire" then foundPoint = true end
end
expectTrue(foundPoint, "catalogue search finds ported teleports by point name")

-- Mail composer catalogue entry and core attachment/command logic.
local mailEntry = TortoiseGM.FindEntry("mail-composer")
expectTrue(mailEntry ~= nil, "mail-composer catalogue entry exists")
expectEqual(mailEntry and mailEntry.category, "player", "mail-composer is in player category")
expectEqual(TortoiseGM.GetInteraction(mailEntry), "open", "mail-composer interaction is open")

TortoiseGM.ClearMailItems()
local okAdd, errAdd = TortoiseGM.AddMailItem("abc", "Bad", 1)
expectFalse(okAdd, "invalid item id rejected")
expectTrue(errAdd ~= nil, "invalid item id returns error")

local idx
for idx = 1, 12 do
    local added = TortoiseGM.AddMailItem(1000 + idx, "Item " .. idx, 1)
    expectTrue(added, "can add attachment #" .. tostring(idx))
end
local overLimit, overErr = TortoiseGM.AddMailItem(9999, "Extra", 1)
expectFalse(overLimit, "13th distinct attachment rejected")
expectTrue(overErr ~= nil, "13th attachment returns error")

-- Stacking an existing item id increases count instead of using a new slot.
local stacked = TortoiseGM.AddMailItem(1001, "Item 1", 4)
expectTrue(stacked, "stacking existing item id succeeds")
expectEqual(TortoiseGM.mailItems[1].count, 5, "stacked item count updated")

TortoiseGM.SetMailItemCount(1, 3)
expectEqual(TortoiseGM.mailItems[1].count, 3, "SetMailItemCount updates count")
TortoiseGM.RemoveMailItem(2)
expectEqual(#TortoiseGM.mailItems, 11, "RemoveMailItem removes entry")

TortoiseGM.ClearMailItems()
expectEqual(#TortoiseGM.mailItems, 0, "ClearMailItems empties list")

TortoiseGM.AddMailItem(6948, "Hearthstone", 1)
TortoiseGM.AddMailItem(2901, "Mining Pick", 2)
local itemsCmd, itemsValid, itemsErr = TortoiseGM.BuildMailCommand("items", {
    recipient = "Thrall",
    subject = 'Gift "Special"',
    body = "Enjoy",
})
expectTrue(itemsValid, "valid .send items command builds")
expectEqual(itemsErr, nil, "no error for valid .send items")
expectEqual(itemsCmd, '.send items Thrall "Gift \'Special\'" "Enjoy" 6948:1 2901:2', "exact .send items command format")

local _, noRecipValid = TortoiseGM.BuildMailCommand("items", { recipient = "", subject = "Hi", body = "" })
expectFalse(noRecipValid, "empty recipient fails validation")
local _, spaceRecipValid = TortoiseGM.BuildMailCommand("items", { recipient = "Bad Name", subject = "Hi", body = "" })
expectFalse(spaceRecipValid, "recipient with space fails validation")
local _, noSubjValid = TortoiseGM.BuildMailCommand("items", { recipient = "Thrall", subject = "", body = "" })
expectFalse(noSubjValid, "empty subject fails validation")
local _, longValid, longErr = TortoiseGM.BuildMailCommand("items", { recipient = "Thrall", subject = "Test", body = string.rep("x", 240) })
expectFalse(longValid, ">255 byte mail command fails validation")
expectTrue(longErr ~= nil and string.find(longErr, "255", 1, true) ~= nil, ">255 byte error mentions 255")

expectEqual(TortoiseGM.ComputeMailCopper(2, 50, 75), 25075, "ComputeMailCopper computes total copper")
local moneyCmd, moneyValid = TortoiseGM.BuildMailCommand("money", {
    recipient = "Jaina",
    subject = "Gold",
    body = "",
    gold = 1,
    silver = 2,
    copper = 3,
})
expectTrue(moneyValid, "valid .send money command builds")
expectEqual(moneyCmd, '.send money Jaina "Gold" "" 10203', "exact .send money command format")
local _, zeroMoneyValid = TortoiseGM.BuildMailCommand("money", { recipient = "Jaina", subject = "Gold", body = "", gold = 0, silver = 0, copper = 0 })
expectFalse(zeroMoneyValid, "zero money fails validation")

-- Shift+Click item link extraction and focus-guarded handling.
local linkId, linkName = TortoiseGM.ExtractItemIdFromLink("|cff9d9d9d|Hitem:6948:0:0:0:0:0:0:0|h[Hearthstone]|h|r")
expectEqual(linkId, 6948, "ExtractItemIdFromLink parses item id")
expectEqual(linkName, "Hearthstone", "ExtractItemIdFromLink parses item name")
local spellLinkId = TortoiseGM.ExtractItemIdFromLink("|cff71d5ff|Hspell:133|h[Fireball]|h|r")
expectEqual(spellLinkId, nil, "ExtractItemIdFromLink ignores non-item links")

local focusedText = nil
local mockTarget = { SetText = function(_, v) focusedText = v end }
TortoiseGM.GetFocusedItemLinkTarget = function() return nil end
expectFalse(TortoiseGM.HandleItemLinkClick("|Hitem:6948:0:0:0|h[Hearthstone]|h"), "ignores item link when no addon field is focused")
expectEqual(focusedText, nil, "unfocused target stays unchanged")

TortoiseGM.GetFocusedItemLinkTarget = function() return mockTarget end
now = 200
expectTrue(TortoiseGM.HandleItemLinkClick("|Hitem:6948:0:0:0|h[Hearthstone]|h"), "fills focused item-ID field on item link")
expectEqual(focusedText, "6948", "focused target receives numeric item ID")
focusedText = nil
expectFalse(TortoiseGM.HandleItemLinkClick("|Hitem:6948:0:0:0|h[Hearthstone]|h"), "deduplicates rapid duplicate hook call for same item")
now = 201
expectTrue(TortoiseGM.HandleItemLinkClick("|Hitem:6948:0:0:0|h[Hearthstone]|h"), "accepts item link again after cooldown")

-- InstallLinkHooks is guarded and hooks Classic 1.15 link functions.
local hookedNames = {}
hooksecurefunc = function(name, fn) hookedNames[name] = fn end
ChatEdit_InsertLink = function() end
HandleModifiedItemClick = function() end
TortoiseGM.linkHooksInstalled = false
TortoiseGM.InstallLinkHooks()
expectTrue(TortoiseGM.linkHooksInstalled, "InstallLinkHooks marks hooks installed")
expectTrue(type(hookedNames["ChatEdit_InsertLink"]) == "function", "ChatEdit_InsertLink hooked")
expectTrue(type(hookedNames["HandleModifiedItemClick"]) == "function", "HandleModifiedItemClick hooked")

if failures > 0 then
    error(tostring(failures) .. " of " .. tostring(checks) .. " checks failed")
end

print("PASS: " .. tostring(checks) .. " core checks")
