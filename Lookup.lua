TortoiseGMManager = TortoiseGMManager or {}

local LOOKUP_WINDOW_SECONDS = 12
local MAX_RESULTS = 30
local gfind = string.gmatch or string.gfind
local LOOKUP_KINDS = {
    [".lookup item"] = "item",
    [".lookup item id"] = "item",
    [".lookup item set"] = "itemset",
    [".lookup spell"] = "spell",
    [".lookup spell id"] = "spell",
    [".lookup quest"] = "quest",
    [".lookup quest id"] = "quest",
    [".lookup creature"] = "creature",
    [".lookup object"] = "gameobject",
    [".lookup skill"] = "skill",
    [".lookup faction"] = "faction",
    [".lookup event"] = "event",
    [".lookup tele"] = "tele",
    [".lookup area"] = "area",
    [".lookup taxinode"] = "taxinode",
    [".lookup title"] = "title",
    [".lookup map"] = "map",
    [".lookup map id"] = "map",
    [".lookup player account"] = "player",
    [".lookup player email"] = "player",
    [".lookup player ip"] = "player",
}
local LINK_KINDS = {
    item = "item",
    spell = "spell",
    quest = "quest",
    creature_entry = "creature",
    gameobject_entry = "gameobject",
    skill = "skill",
    faction = "faction",
    itemset = "itemset",
    gameevent = "event",
    tele = "tele",
    area = "area",
    taxinode = "taxinode",
    title = "title",
    player = "player",
}
local FALLBACK_COMMANDS = {
    item = ".additem",
    spell = ".cast",
    quest = ".quest add",
    creature = ".go creature id",
    gameobject = ".go gameobject id",
    event = ".event info",
    itemset = ".additem set",
    skill = ".setskill",
    faction = ".modify reputation",
    tele = ".tele",
}

local function trim(value)
    value = value or ""
    value = string.gsub(value, "^%s+", "")
    return string.gsub(value, "%s+$", "")
end

local function lower(value)
    return string.lower(value or "")
end

local function stripFormatting(value)
    value = value or ""
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "|H[^|]+|h%[([^%]]+)%]|h", "%1")
    value = string.gsub(value, "|h", "")
    return trim(value)
end

local function snapshotValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do
        if type(child) ~= "function" then
            copy[snapshotValue(key)] = snapshotValue(child)
        end
    end
    return copy
end

local function snapshotEntry(entry)
    if not entry then return nil end
    return snapshotValue(entry)
end

local function getLookupKind(command)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    local bestCommand = nil
    local bestKind = nil
    for lookupCommand, kind in pairs(LOOKUP_KINDS) do
        if normalized == lookupCommand or string.sub(normalized, 1, string.len(lookupCommand) + 1) == lookupCommand .. " " then
            if not bestCommand or string.len(lookupCommand) > string.len(bestCommand) then
                bestCommand = lookupCommand
                bestKind = kind
            end
        end
    end
    return bestKind, bestCommand
end

function TortoiseGMManager.GetLookupKind(command) return getLookupKind(command) end
function TortoiseGMManager.GetLookupResults() return TortoiseGMManager.lookupResults or {} end

function TortoiseGMManager.ClearLookupResults()
    TortoiseGMManager.lookupResults = {}
    TortoiseGMManager.lookupResultKeys = {}
    if TortoiseGMManager.OnLookupResultsChanged then TortoiseGMManager.OnLookupResultsChanged() end
end

function TortoiseGMManager.AddLookupResult(kind, id, name, link, raw)
    local session = TortoiseGMManager.pendingLookup
    if not session or not kind or not id or tostring(id) == "" then return false end
    id = tostring(id)
    name = stripFormatting(name)
    if name == "" then name = id end
    local key = tostring(kind) .. ":" .. id
    if TortoiseGMManager.lookupResultKeys[key] then return false end
    TortoiseGMManager.lookupResultKeys[key] = true
    table.insert(TortoiseGMManager.lookupResults, {
        kind = kind,
        id = id,
        name = name,
        link = link,
        raw = raw,
        sessionId = session.id,
        sourceEntry = snapshotEntry(session.sourceEntry),
        context = {
            lookupCommand = session.lookupCommand,
            query = session.query,
            kind = session.kind,
            sessionId = session.id,
        },
    })
    while #TortoiseGMManager.lookupResults > MAX_RESULTS do
        table.remove(TortoiseGMManager.lookupResults, 1)
    end
    if TortoiseGMManager.OnLookupResultsChanged then TortoiseGMManager.OnLookupResultsChanged() end
    return true
end

function TortoiseGMManager.BeginLookup(entry, query, lookupCommand)
    local kind, base = getLookupKind(lookupCommand or (entry and entry.lookupCommand) or "")
    if not kind then return false end
    if TortoiseGMManager.pendingLookup then TortoiseGMManager.EndLookup("replaced") end
    TortoiseGMManager.lookupSessionCounter = (TortoiseGMManager.lookupSessionCounter or 0) + 1
    TortoiseGMManager.ClearLookupResults()
    TortoiseGMManager.lookupResultsDismissed = false
    local session = {
        id = TortoiseGMManager.lookupSessionCounter,
        kind = kind,
        lookupCommand = base,
        query = trim(query),
        sourceEntry = snapshotEntry(entry),
        startedAt = GetTime(),
        state = "searching",
    }
    TortoiseGMManager.pendingLookup = session
    TortoiseGMManager.lastLookupSession = session
    if TortoiseGMManager.OnLookupStarted then TortoiseGMManager.OnLookupStarted(session) end
    return true
end

function TortoiseGMManager.BeginLookupCommand(command)
    local kind, base = getLookupKind(command)
    if not kind or not base then return false end
    local query = trim(string.sub(TortoiseGMManager.NormalizeCommand(command), string.len(base) + 1))
    return TortoiseGMManager.BeginLookup(nil, query, base)
end

function TortoiseGMManager.EndLookup(reason)
    local session = TortoiseGMManager.pendingLookup
    if not session then return false end
    session.endedAt = GetTime()
    session.reason = reason or "ended"
    if session.reason == "timeout" then
        session.state = #TortoiseGMManager.GetLookupResults() == 0 and "timedout" or "results"
    elseif #TortoiseGMManager.GetLookupResults() == 0 then
        session.state = "noresults"
    else
        session.state = "results"
    end
    TortoiseGMManager.pendingLookup = nil
    TortoiseGMManager.lastLookupSession = session
    if TortoiseGMManager.OnLookupEnded then TortoiseGMManager.OnLookupEnded(session) end
    return true
end

function TortoiseGMManager.DismissLookupResults()
    TortoiseGMManager.lookupResultsDismissed = true
    if TortoiseGMManager.pendingLookup then TortoiseGMManager.pendingLookup.dismissed = true end
end

function TortoiseGMManager.IsLookupPending()
    local pending = TortoiseGMManager.pendingLookup
    if not pending then return false end
    if GetTime() - (pending.startedAt or 0) > LOOKUP_WINDOW_SECONDS then
        TortoiseGMManager.EndLookup("timeout")
        return false
    end
    return true
end

local function isNoResultsMessage(clean)
    return string.find(clean, "^no .* found")
        or string.find(clean, "no teleport locations matching", 1, true)
        or string.find(clean, "no results", 1, true)
        or string.find(clean, "nothing found", 1, true)
        or string.find(clean, "not found", 1, true)
end

local function captureLinkedResults(text, expectedKind)
    local captured = 0
    local sawKnownLink = false
    for hyperlink, id, name in gfind(text, "|H([%w_]+):(%d+)[^|]*|h%[(.-)%]|h") do
        local kind = LINK_KINDS[hyperlink]
        if kind then
            sawKnownLink = true
            if not expectedKind or expectedKind == kind then
                local _, _, link = string.find(text, "(|c%x%x%x%x%x%x%x%x|H" .. hyperlink .. ":" .. id .. "[^|]*|h%[.-%]|h|r)")
                if TortoiseGMManager.AddLookupResult(kind, id, name, link, text) then
                    captured = captured + 1
                end
            end
        end
    end
    return captured, sawKnownLink
end

local function captureGenericResult(text, pending)
    if not pending then return 0 end
    local clean = lower(stripFormatting(text))
    if isNoResultsMessage(clean)
        or string.find(clean, "matches found", 1, true)
        or string.find(clean, "result limit reached", 1, true)
        or string.find(clean, "searching", 1, true)
        or string.find(clean, "error", 1, true) then
        return 0
    end
    if pending.kind == "player" then
        local _, _, charName, guid, tail = string.find(text, "^%s*(%S+)%s*%(([^%)]+)%)%s*(.*)$")
        if charName and guid and string.find(guid, "Player%-", 1) then
            local status = trim(tail)
            local display = status ~= "" and (charName .. " " .. status) or charName
            if TortoiseGMManager.AddLookupResult("player", guid, display, nil, text) then return 1 end
            return 0
        end
    end
    local _, _, id, tail = string.find(text, "^%s*(%d+)%s*[%-%:]%s*(.+)$")
    if not id then _, _, id, tail = string.find(text, "^%s*%[(%d+)%]%s*(.+)$") end
    if not id then return 0 end
    local name = stripFormatting(tail)
    if name == "" or string.find(lower(name), "results found", 1, true) then return 0 end
    if TortoiseGMManager.AddLookupResult(pending.kind, id, name, nil, text) then return 1 end
    return 0
end

function TortoiseGMManager.CaptureLookupMessage(text)
    if not text or text == "" or not TortoiseGMManager.IsLookupPending() then return 0 end
    local clean = lower(stripFormatting(text))
    if isNoResultsMessage(clean) then
        TortoiseGMManager.EndLookup("noresults")
        return 0
    end
    local pending = TortoiseGMManager.pendingLookup
    local captured, sawKnownLink = captureLinkedResults(text, pending.kind)
    if captured == 0 and not sawKnownLink then
        captured = captureGenericResult(text, pending)
    end
    if captured > 0 then
        pending.state = "results"
        if not TortoiseGMManager.lookupResultsDismissed and TortoiseGMManager.ShowLookupResults then
            TortoiseGMManager.ShowLookupResults()
        end
    end
    return captured
end

function TortoiseGMManager.GetLookupResultCommand(result, values)
    local descriptor = TortoiseGMManager.GetLookupActionDescriptor(result, values)
    if descriptor.kind == "action" or descriptor.kind == "load" then return descriptor.command, descriptor.values end
    return nil
end

local lookupEventFrame = CreateFrame("Frame")
lookupEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
lookupEventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "CHAT_MSG_SYSTEM" and arg1 then
        TortoiseGMManager.CaptureLookupMessage(arg1)
    end
end)
lookupEventFrame:SetScript("OnUpdate", function(self)
    if TortoiseGMManager.pendingLookup then
        TortoiseGMManager.IsLookupPending()
    end
end)
