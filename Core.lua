TortoiseGMManager = TortoiseGMManager or {}

local function trim(value)
    value = value or ""
    value = string.gsub(value, "^%s+", "")
    return string.gsub(value, "%s+$", "")
end

local function lower(value) return string.lower(value or "") end
local function sendSay(message)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(message, "SAY")
    elseif SendChatMessage then
        SendChatMessage(message, "SAY")
    end
end
local function copy(values)
    local result = {}
    local key, value
    for key, value in pairs(values or {}) do result[key] = value end
    return result
end

function TortoiseGMManager.Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffbe04ForeverGMManager:|r " .. tostring(message)) end
end

function TortoiseGMManager.FindEntry(value)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(value))
    local i, j
    for i = 1, #(TortoiseGMManager.commands or {}) do
        local entry = TortoiseGMManager.commands[i]
        if entry.id == value or lower(TortoiseGMManager.NormalizeCommand(entry.command)) == normalized then return entry end
        for j = 1, #(entry.legacyCommands or {}) do
            if lower(TortoiseGMManager.NormalizeCommand(entry.legacyCommands[j])) == normalized then return entry end
        end
    end
    return nil
end

function TortoiseGMManager.MigrateFavourites()
    local old = TortoiseGMManagerDB.favourites or {}
    local migrated, included = {}, {}
    local i
    for i = 1, #old do
        local entry = TortoiseGMManager.FindEntry(old[i])
        local id = entry and entry.id or nil
        if id and not included[id] then table.insert(migrated, id); included[id] = true end
    end
    TortoiseGMManagerDB.favourites = migrated
    TortoiseGMManagerDB.favouritesVersion = 2
end

function TortoiseGMManager.GetDefaultCategory()
    TortoiseGMManager.InitializeDB()
    return #(TortoiseGMManagerDB.favourites or {}) > 0 and "favourites" or "all"
end

function TortoiseGMManager.InitializeDB()
    if not TortoiseGMManagerDB then TortoiseGMManagerDB = {} end
    if not TortoiseGMManagerDB.history then TortoiseGMManagerDB.history = {} end
    if not TortoiseGMManagerDB.favourites then TortoiseGMManagerDB.favourites = {} end
    if not TortoiseGMManagerDB.toggleStates then TortoiseGMManagerDB.toggleStates = {} end
    TortoiseGMManager.MigrateFavourites()
    if TortoiseGMManagerDB.lastCategory == "history" or TortoiseGMManagerDB.lastCategory == "quick" or not TortoiseGMManagerDB.lastCategory then
        TortoiseGMManagerDB.lastCategory = #TortoiseGMManagerDB.favourites > 0 and "favourites" or "all"
    end
    if TortoiseGMManagerDB.minimapX == nil then TortoiseGMManagerDB.minimapX = 52 end
    if TortoiseGMManagerDB.minimapY == nil then TortoiseGMManagerDB.minimapY = 52 end
    if TortoiseGMManagerDB.framePoint == nil then
        TortoiseGMManagerDB.framePoint, TortoiseGMManagerDB.frameRelativePoint = "CENTER", "CENTER"
        TortoiseGMManagerDB.frameX, TortoiseGMManagerDB.frameY = 0, 15
    end
end

function TortoiseGMManager.NormalizeCommand(command)
    command = trim(command)
    command = string.gsub(command, "[\r\n]+", " ")
    command = string.gsub(command, "%s+", " ")
    if command ~= "" and string.sub(command, 1, 1) ~= "." then command = "." .. command end
    return command
end

function TortoiseGMManager.GetEntryArguments(entry)
    if not entry then return {} end
    if entry.arguments and #entry.arguments > 0 then return entry.arguments end
    if entry.hint and entry.hint ~= "" then
        return { { key = "arguments", label = entry.hint, type = "text", required = true, default = "" } }
    end
    return {}
end

function TortoiseGMManager.InitializeValues(entry, current)
    local values = copy(current)
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    local i
    for i = 1, #arguments do
        local argument = arguments[i]
        if values[argument.key] == nil and argument.default ~= nil then values[argument.key] = argument.default end
    end
    return values
end

function TortoiseGMManager.ValidateValues(entry, values)
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    local i
    for i = 1, #arguments do
        local argument = arguments[i]
        local value = values and values[argument.key]
        if argument.required and (value == nil or trim(tostring(value)) == "") then return false, argument.label .. " is required." end
        if value ~= nil and trim(tostring(value)) ~= "" and argument.type == "number" then
            local number = tonumber(value)
            if not number then return false, argument.label .. " must be a number." end
            if argument.integer and number ~= math.floor(number) then return false, argument.label .. " must be an integer." end
            if argument.min and argument.max and (number < argument.min or number > argument.max) then
                return false, argument.label .. " must be between " .. tostring(argument.min) .. " and " .. tostring(argument.max) .. "."
            end
            if argument.min and number < argument.min then return false, argument.label .. " must be at least " .. tostring(argument.min) .. "." end
            if argument.max and number > argument.max then return false, argument.label .. " must be at most " .. tostring(argument.max) .. "." end
        end
    end
    return true, nil
end

function TortoiseGMManager.ComposeValues(entry, values)
    if not entry then return "" end
    values = TortoiseGMManager.InitializeValues(entry, values)
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    local parts, i = {}, nil
    for i = 1, #arguments do
        local value = values[arguments[i].key]
        if value ~= nil and trim(tostring(value)) ~= "" then table.insert(parts, tostring(value)) end
    end
    local suffix = table.concat(parts, " ")
    return TortoiseGMManager.NormalizeCommand(entry.command .. (suffix ~= "" and " " .. suffix or ""))
end

function TortoiseGMManager.AdjustNumber(argument, value, direction)
    local number = tonumber(value) or tonumber(argument.default) or 0
    number = number + ((tonumber(argument.step) or 1) * direction)
    if argument.min and number < argument.min then number = argument.min end
    if argument.max and number > argument.max then number = argument.max end
    return number
end

function TortoiseGMManager.CycleToggle(argument, value, direction)
    local options = argument.options or {}
    if #options == 0 then return value end
    local index, i = 1, nil
    for i = 1, #options do if options[i].value == value then index = i; break end end
    index = index + (direction or 1)
    if index > #options then index = 1 elseif index < 1 then index = #options end
    return options[index].value
end

function TortoiseGMManager.GetOptionLabel(argument, value)
    local i
    for i = 1, #(argument.options or {}) do if argument.options[i].value == value then return argument.options[i].label end end
    return tostring(value or "")
end

function TortoiseGMManager.GetInteraction(entry)
    if not entry then return "load" end
    if entry.danger or TortoiseGMManager.IsDangerous(entry.command) then return "review" end
    if #TortoiseGMManager.GetEntryArguments(entry) > 0 then return "configure" end
    if entry.direct then return "execute" end
    return "load"
end

function TortoiseGMManager.GetLookupActionLabel(entry)
    if not entry or not entry.label then return "ACTION" end
    return string.upper(trim(entry.label))
end

function TortoiseGMManager.GetDefaultLookupEntry(kind)
    local defaults = {
        item = "additem",
        itemset = "additem-set",
        spell = "cast",
        quest = "quest-add",
        creature = "go-creature",
        gameobject = "go-object",
        skill = "setskill",
    }
    return defaults[kind] and TortoiseGMManager.FindEntry(defaults[kind]) or nil
end

function TortoiseGMManager.GetLookupActionDescriptor(result, currentValues)
    if not result then return { kind = "information", result = result, arguments = {}, values = {} } end
    local entry = result.sourceEntry or TortoiseGMManager.GetDefaultLookupEntry(result.kind)
    if not entry or not entry.command then
        return { kind = "information", result = result, arguments = {}, values = {} }
    end
    local values = TortoiseGMManager.InitializeValues(entry, currentValues)
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    local modifiers, lookupFound, i = {}, false, nil
    for i = 1, #arguments do
        local argument = arguments[i]
        if argument.type == "lookup-id" and not lookupFound then
            values[argument.key] = tostring(result.id)
            lookupFound = true
        elseif #modifiers < 3 then
            table.insert(modifiers, argument)
        end
    end
    if not lookupFound then
        local command = TortoiseGMManager.Compose(entry, tostring(result.id))
        return { kind = "action", result = result, entry = entry, arguments = {}, values = values,
            command = command, valid = true, label = TortoiseGMManager.GetLookupActionLabel(entry),
            dangerous = entry.danger or TortoiseGMManager.IsDangerous(command) }
    end
    local valid, message = TortoiseGMManager.ValidateValues(entry, values)
    local command = TortoiseGMManager.ComposeValues(entry, values)
    return { kind = "action", result = result, entry = entry, arguments = modifiers, values = values,
        command = command, valid = valid, message = message, label = TortoiseGMManager.GetLookupActionLabel(entry),
        dangerous = entry.danger or TortoiseGMManager.IsDangerous(command) }
end

function TortoiseGMManager.ComposeLookupResult(entry, values, id)
    values = TortoiseGMManager.InitializeValues(entry, values)
    local arguments = TortoiseGMManager.GetEntryArguments(entry)
    local i, filled = nil, false
    for i = 1, #arguments do
        if arguments[i].type == "lookup-id" then values[arguments[i].key] = tostring(id); filled = true; break end
    end
    if not filled then return values, TortoiseGMManager.Compose(entry, tostring(id)) end
    return values, TortoiseGMManager.ComposeValues(entry, values)
end

function TortoiseGMManager.IsDangerous(command)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    if TortoiseGMManager.safeCommands and TortoiseGMManager.safeCommands[normalized] then return false end
    local i
    for i = 1, #(TortoiseGMManager.dangerPrefixes or {}) do
        local prefix = lower(TortoiseGMManager.NormalizeCommand(TortoiseGMManager.dangerPrefixes[i]))
        if normalized == prefix or string.sub(normalized, 1, string.len(prefix) + 1) == prefix .. " " then return true end
    end
    return false
end

function TortoiseGMManager.AddHistory(command)
    TortoiseGMManager.InitializeDB()
    local i
    for i = #TortoiseGMManagerDB.history, 1, -1 do if TortoiseGMManagerDB.history[i] == command then table.remove(TortoiseGMManagerDB.history, i) end end
    table.insert(TortoiseGMManagerDB.history, 1, command)
    while #TortoiseGMManagerDB.history > 20 do table.remove(TortoiseGMManagerDB.history) end
end
local toggleSystemReplies = {
    ["gm mode is on"] = { id = "gm-mode", state = "on" },
    ["gm mode is off"] = { id = "gm-mode", state = "off" },
    ["you are now visible."] = { id = "visibility", state = "on" },
    ["you are now invisible."] = { id = "visibility", state = "off" },
    ["you are: visible"] = { id = "visibility", state = "on" },
    ["you are: invisible"] = { id = "visibility", state = "off" },
    ["gm chat badge is on"] = { id = "gm-chat", state = "on" },
    ["gm chat badge is off"] = { id = "gm-chat", state = "off" },
    ["godmode is on. you won't take damage."] = { id = "god-mode", state = "on" },
    ["godmode is off. you can take damage."] = { id = "god-mode", state = "off" },
    ["godmode: on."] = { id = "god-mode", state = "on" },
    ["godmode: off."] = { id = "god-mode", state = "off" },
    ["casttime cheat is on. your spells won't have a casttime."] = { id = "cheat-casttime", state = "on" },
    ["casttime cheat is off. your spells will have a casttime."] = { id = "cheat-casttime", state = "off" },
    ["casttime: on."] = { id = "cheat-casttime", state = "on" },
    ["casttime: off."] = { id = "cheat-casttime", state = "off" },
    ["cooldown cheat is on. you are not on the global cooldown."] = { id = "cheat-cooldown", state = "on" },
    ["cooldown cheat is off. you are on the global cooldown."] = { id = "cheat-cooldown", state = "off" },
    ["cooldown: on."] = { id = "cheat-cooldown", state = "on" },
    ["cooldown: off."] = { id = "cheat-cooldown", state = "off" },
    ["power cheat is on. you don't need mana/rage/energy to use spells."] = { id = "cheat-power", state = "on" },
    ["power cheat is off. you need mana/rage/energy to use spells."] = { id = "cheat-power", state = "off" },
    ["power: on."] = { id = "cheat-power", state = "on" },
    ["power: off."] = { id = "cheat-power", state = "off" },
    ["waterwalking is on. you can walk on water."] = { id = "waterwalk", state = "on" },
    ["waterwalking is off. you can't walk on water."] = { id = "waterwalk", state = "off" },
    ["waterwalk: on."] = { id = "waterwalk", state = "on" },
    ["waterwalk: off."] = { id = "waterwalk", state = "off" },
    ["taxinodes: on."] = { id = "taxicheat", state = "on" },
    ["taxinodes: off."] = { id = "taxicheat", state = "off" },
    ["accepting whisper: on"] = { id = "whispers", state = "on" },
    ["accepting whisper: off"] = { id = "whispers", state = "off" },
}

local function stripChatFormatting(text)
    text = string.gsub(text or "", "|c%x%x%x%x%x%x%x%x", "")
    return string.gsub(text, "|r", "")
end

local function extractLinkedName(prefix)
    local name = string.match(prefix, "|Hplayer:([^|:]+)")
    if name then return name end
    name = string.match(prefix, "%[([^%]]+)%]")
    return trim(name or prefix)
end

local function isSelfOrUnknown(name)
    if not UnitName then return true end
    local player = UnitName("player")
    if not player or player == "" then return true end
    return lower(name) == lower(player)
end

function TortoiseGMManager.GetToggleState(id)
    TortoiseGMManager.InitializeDB()
    return id and TortoiseGMManagerDB.toggleStates[id] or nil
end

function TortoiseGMManager.SetToggleState(id, state)
    if not id or (state ~= "on" and state ~= "off") then return false end
    TortoiseGMManager.InitializeDB()
    if TortoiseGMManagerDB.toggleStates[id] ~= state then
        TortoiseGMManagerDB.toggleStates[id] = state
        if TortoiseGMManager.RefreshList then TortoiseGMManager.RefreshList() end
    end
    return true
end

function TortoiseGMManager.RecordToggleCommand(command)
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    local i, j
    for i = 1, #(TortoiseGMManager.commands or {}) do
        local entry = TortoiseGMManager.commands[i]
        local arguments = entry.arguments
        if arguments and #arguments == 1 and arguments[1].type == "toggle" then
            local base = lower(TortoiseGMManager.NormalizeCommand(entry.command))
            if normalized == base .. " on" then return TortoiseGMManager.SetToggleState(entry.id, "on") end
            if normalized == base .. " off" then return TortoiseGMManager.SetToggleState(entry.id, "off") end
            for j = 1, #(entry.legacyCommands or {}) do
                local legacy = lower(TortoiseGMManager.NormalizeCommand(entry.legacyCommands[j]))
                if normalized == legacy then
                    if string.sub(legacy, -3) == " on" or string.sub(legacy, -2) == " 1" then
                        return TortoiseGMManager.SetToggleState(entry.id, "on")
                    elseif string.sub(legacy, -4) == " off" or string.sub(legacy, -2) == " 0" then
                        return TortoiseGMManager.SetToggleState(entry.id, "off")
                    end
                end
            end
        end
    end
    return false
end

function TortoiseGMManager.ParseToggleSystemMessage(text)
    if type(text) ~= "string" or text == "" then return nil end
    local cleaned = trim(stripChatFormatting(text))
    local match = toggleSystemReplies[lower(cleaned)]
    if match then
        TortoiseGMManager.SetToggleState(match.id, match.state)
        return match.id, match.state
    end
    local flyPrefix, flyState = string.match(cleaned, "^(.-)'s Fly Mode (%a+)$")
    if flyPrefix and (lower(flyState) == "on" or lower(flyState) == "off") and isSelfOrUnknown(extractLinkedName(flyPrefix)) then
        local state = lower(flyState)
        TortoiseGMManager.SetToggleState("gm-fly", state)
        return "gm-fly", state
    end
    local taxiPrefix = string.match(cleaned, "^(.-) has access to all taxi nodes now %(until logout%)%.$")
    if taxiPrefix and isSelfOrUnknown(extractLinkedName(taxiPrefix)) then
        TortoiseGMManager.SetToggleState("taxicheat", "on")
        return "taxicheat", "on"
    end
    taxiPrefix = string.match(cleaned, "^(.-) has no more access to all taxi nodes now %(only visited accessible%)%.$")
    if taxiPrefix and isSelfOrUnknown(extractLinkedName(taxiPrefix)) then
        TortoiseGMManager.SetToggleState("taxicheat", "off")
        return "taxicheat", "off"
    end
    return nil
end

function TortoiseGMManager.SetPendingConfirmation(command) TortoiseGMManager.pendingCommand, TortoiseGMManager.pendingUntil = command, GetTime() + 5 end
function TortoiseGMManager.ClearPendingConfirmation() TortoiseGMManager.pendingCommand, TortoiseGMManager.pendingUntil = nil, nil end

function TortoiseGMManager.Execute(command)
    command = TortoiseGMManager.NormalizeCommand(command)
    if command == "" or command == "." then if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Enter a GM command first.", "error") end; return false end
    if string.len(command) > 255 then if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Command is longer than the chat limit (255 characters).", "error") end; return false end
    if TortoiseGMManager.IsDangerous(command) then
        local now = GetTime()
        if TortoiseGMManager.pendingCommand ~= command or not TortoiseGMManager.pendingUntil or now > TortoiseGMManager.pendingUntil then
            TortoiseGMManager.SetPendingConfirmation(command)
            if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Dangerous command armed. Click EXECUTE again within 5 seconds to confirm.", "warn") end
            return false
        end
    end
    TortoiseGMManager.ClearPendingConfirmation(); TortoiseGMManager.AddHistory(command)
    if TortoiseGMManager.BeginLookupCommand then TortoiseGMManager.BeginLookupCommand(command) end
    sendSay(command)
    TortoiseGMManager.RecordToggleCommand(command)
    if TortoiseGMManager.SetStatus then TortoiseGMManager.SetStatus("Sent: " .. command, "ok") end
    if TortoiseGMManager.RefreshList then TortoiseGMManager.RefreshList() end
    return true
end

function TortoiseGMManager.CommandMatchesEntry(entry, command)
    if not entry then return false end
    local normalized = lower(TortoiseGMManager.NormalizeCommand(command))
    local candidates, i = { entry.command }, nil
    for i = 1, #(entry.legacyCommands or {}) do table.insert(candidates, entry.legacyCommands[i]) end
    for i = 1, #candidates do
        local base = lower(TortoiseGMManager.NormalizeCommand(candidates[i]))
        if normalized == base or string.sub(normalized, 1, string.len(base) + 1) == base .. " " then return true end
    end
    return false
end

function TortoiseGMManager.RequestHelp(value)
    local entry = type(value) == "table" and value or nil
    if not entry then
        local normalized, best, i = TortoiseGMManager.NormalizeCommand(value), nil, nil
        for i = 1, #(TortoiseGMManager.commands or {}) do
            local candidate = TortoiseGMManager.commands[i]
            if TortoiseGMManager.CommandMatchesEntry(candidate, normalized) and (not best or string.len(candidate.command) > string.len(best.command)) then best = candidate end
        end
        entry = best
    end
    local command = entry and entry.command or value
    command = TortoiseGMManager.NormalizeCommand(command)
    if command == "" or command == "." then return false end
    sendSay(".help " .. string.sub(command, 2)); return true
end

function TortoiseGMManager.IsFavourite(value)
    TortoiseGMManager.InitializeDB()
    local entry = TortoiseGMManager.FindEntry(value)
    local id = entry and entry.id or value
    local i
    for i = 1, #TortoiseGMManagerDB.favourites do if TortoiseGMManagerDB.favourites[i] == id then return true end end
    return false
end
function TortoiseGMManager.ToggleFavourite(entry)
    if not entry or not entry.id then return false end
    TortoiseGMManager.InitializeDB()
    local i
    for i = #TortoiseGMManagerDB.favourites, 1, -1 do if TortoiseGMManagerDB.favourites[i] == entry.id then table.remove(TortoiseGMManagerDB.favourites, i); return false end end
    table.insert(TortoiseGMManagerDB.favourites, entry.id); return true
end
function TortoiseGMManager.GetFavouriteCommands()
    TortoiseGMManager.InitializeDB(); local results, i = {}, nil
    for i = 1, #TortoiseGMManagerDB.favourites do local entry = TortoiseGMManager.FindEntry(TortoiseGMManagerDB.favourites[i]); if entry then table.insert(results, entry) end end
    return results
end

function TortoiseGMManager.GetFilteredCommands(category, query)
    local source = category == "favourites" and TortoiseGMManager.GetFavouriteCommands() or (TortoiseGMManager.commands or {})
    local q, ranked, results = lower(trim(query)), { {}, {}, {}, {}, {} }, {}
    local i, j
    for i = 1, #source do
        local entry = source[i]
        if category == "favourites" or category == "all" or entry.category == category then
            if q == "" then table.insert(results, entry) else
                local label, command = lower(entry.label), lower(entry.command)
                local details = lower((entry.id or "") .. " " .. (entry.hint or "") .. " " .. (entry.detail or "") .. " " .. (entry.lookupCommand or ""))
                for j = 1, #(entry.legacyCommands or {}) do details = details .. " " .. lower(entry.legacyCommands[j]) end
                for j = 1, #(entry.arguments or {}) do
                    local argument = entry.arguments[j]; details = details .. " " .. lower(argument.label)
                    local k; for k = 1, #(argument.options or {}) do details = details .. " " .. lower(argument.options[k].label) end
                end
                local rank
                if label == q then rank = 1 elseif string.sub(label, 1, string.len(q)) == q then rank = 2 elseif string.find(label, q, 1, true) then rank = 3 elseif string.find(command, q, 1, true) then rank = 4 elseif string.find(details, q, 1, true) then rank = 5 end
                if rank then table.insert(ranked[rank], entry) end
            end
        end
    end
    if q ~= "" then for i = 1, 5 do for j = 1, #ranked[i] do table.insert(results, ranked[i][j]) end end end
    return results
end

function TortoiseGMManager.GetComposerArgs(entry, command)
    if not entry then return trim(command) end
    command = trim(command); local base = trim(entry.command or "")
    if string.sub(lower(command), 1, string.len(base)) == lower(base) then return trim(string.sub(command, string.len(base) + 1)) end
    return command
end
function TortoiseGMManager.BuildLookupCommand(entry, query) if not entry or not entry.lookupCommand or trim(query) == "" then return nil end; return TortoiseGMManager.NormalizeCommand(entry.lookupCommand .. " " .. trim(query)) end
function TortoiseGMManager.ExecuteLookup(entry, query)
    local lookup = TortoiseGMManager.BuildLookupCommand(entry, query)
    if not lookup then return false end
    if string.find(trim(query), "^%d+$") then
        local values, command = TortoiseGMManager.ComposeLookupResult(entry, TortoiseGMManager.structuredValues, trim(query))
        TortoiseGMManager.structuredValues = values
        if TortoiseGMManager.LoadCommand then TortoiseGMManager.LoadCommand(command, entry, "Numeric ID loaded. Review, then EXECUTE.", values) end
        return true
    end
    TortoiseGMManager.AddHistory(lookup); if TortoiseGMManager.BeginLookup then TortoiseGMManager.BeginLookup(entry, query, lookup) end
    sendSay(lookup); return true
end
function TortoiseGMManager.Compose(entry, args) return TortoiseGMManager.NormalizeCommand((entry and entry.command or "") .. (trim(args) ~= "" and " " .. trim(args) or "")) end
