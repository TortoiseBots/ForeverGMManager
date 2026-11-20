-- tools/preview/scenes.lua
-- Loads the addon on the recording mock and writes one JSON scene per README
-- screenshot. Layout previews, not game screenshots.
--
--   lua5.1 tools/preview/scenes.lua <repo root> <out dir>

local root = arg[1] or "."
local out = arg[2] or "preview-out"
dofile(root .. "/tools/preview/mock.lua")

-- Modern client calls the 1.12 mock does not have.
local W = getmetatable(UIParent).__index
function W:SetColorTexture(r, g, b, a) self.file = nil; self.color = { r, g, b, a or 1 } end
function W:HookScript(name, fn)
    local old = self.scripts[name]
    self.scripts[name] = function(frame, a) if old then old(frame, a) end; return fn(frame, a or arg1) end
end
function W:HasFocus() return false end
function Mixin(o, ...) for _, m in ipairs({ ... }) do for k, v in pairs(m) do o[k] = v end end return o end
C_ChatInfo = { SendChatMessage = function() end }
function ChatEdit_GetActiveWindow() return nil end
function hooksecurefunc() end
function UnitGUID() return nil end

TortoiseGMManagerDB = {}
local toc = io.open(root .. "/ForeverGMManager.toc"):read("*a")
for line in string.gmatch(toc, "[^\r\n]+") do
    if not string.find(line, "^##") and string.find(line, "%.lua%s*$") then
        dofile(root .. "/" .. string.gsub(line, "%s+$", ""))
    end
end

local GM = TortoiseGMManager
GM.InitializeDB()
for _, o in ipairs(Mock.objects) do
    if o.events and o.events.ADDON_LOADED and o.scripts.OnEvent then
        event, arg1 = "ADDON_LOADED", "ForeverGMManager"
        pcall(o.scripts.OnEvent, o)
    end
end

-- ── JSON (same format as the renderer expects) ───────────────────────────
local function esc(s)
    s = string.gsub(s, "\\", "\\\\"); s = string.gsub(s, '"', '\\"')
    s = string.gsub(s, "\n", "\\n"); s = string.gsub(s, "\r", ""); s = string.gsub(s, "\t", " ")
    return (string.gsub(s, "[%z\1-\31]", ""))
end
local function enc(v)
    local t = type(v)
    if t == "nil" then return "null" end
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "0" end
        return string.format("%.4f", v)
    end
    if t == "string" then return '"' .. esc(v) .. '"' end
    if t == "table" then
        if v.id and v.kind then return tostring(v.id) end
        local parts = {}
        if #v > 0 then
            for i = 1, #v do parts[i] = enc(v[i]) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, x in pairs(v) do
            if type(x) ~= "function" then table.insert(parts, '"' .. esc(tostring(k)) .. '":' .. enc(x)) end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end
local FIELDS = { "kind", "name", "template", "width", "height", "shown", "strata", "level", "alpha",
    "backdrop", "bdColor", "bdBorder", "layer", "file", "color", "texCoord", "vertex", "blend", "font",
    "text", "textColor", "justifyH", "justifyV", "enabled", "checked", "disabledTextColor",
    "highlightTextColor", "isButtonText", "stateKey", "isInput", "isScrollBar", "scale", "fontSize",
    "lockHighlight", "isActive", "flatKind", "barColor", "value", "min", "max", "disabledFont" }

local failures = 0
local function dump(name, roots, note)
    -- The client fires OnTextChanged on SetText; the mock does not, so sync placeholders here.
    for _, o in ipairs(Mock.objects) do if o.placeholder then GM.Theme.RefreshInput(o) end end
    local parts = {}
    for _, o in ipairs(Mock.objects) do
        local rec = { '"id":' .. o.id }
        if o.parent then table.insert(rec, '"parent":' .. o.parent.id) end
        for _, f in ipairs(FIELDS) do
            local v = o[f]
            if v ~= nil and type(v) ~= "function" then table.insert(rec, '"' .. f .. '":' .. enc(v)) end
        end
        for _, k in ipairs({ "normalTex", "pushedTex", "disabledTex", "highlightTex", "checkedTex", "fontString" }) do
            if o[k] then table.insert(rec, '"' .. k .. '":' .. o[k].id) end
        end
        local pts = {}
        for _, p in ipairs(o.points or {}) do
            table.insert(pts, string.format('{"point":"%s","rel":%s,"relPoint":"%s","x":%s,"y":%s}',
                p.point, p.rel and p.rel.id or "null", p.relPoint or p.point, enc(p.x or 0), enc(p.y or 0)))
        end
        table.insert(rec, '"points":[' .. table.concat(pts, ",") .. "]")
        table.insert(parts, "{" .. table.concat(rec, ",") .. "}")
    end
    local rootIds = {}
    for _, r in ipairs(roots) do if r then table.insert(rootIds, tostring(r.id)) end end
    local f = io.open(out .. "/" .. name .. ".json", "w")
    f:write('{"name":"' .. name .. '","note":"' .. esc(note or "") .. '","uiparent":' .. UIParent.id
        .. ',"roots":[' .. table.concat(rootIds, ",") .. '],"objects":[' .. table.concat(parts, ",") .. "]}")
    f:close()
    io.write("scene " .. name .. "\n")
end
local function scene(name, fn)
    local ok, err = pcall(fn)
    if not ok then io.write("scene " .. name .. " FAILED: " .. tostring(err) .. "\n"); failures = failures + 1 end
end

local function tick(n)
    for _ = 1, n or 1 do
        Mock.now = Mock.now + 1
        for _, o in ipairs(Mock.objects) do
            if o.scripts and o.scripts.OnUpdate and o.kind ~= "Texture" then pcall(o.scripts.OnUpdate, o, 1) end
        end
    end
end
local function editWithPlaceholder(text)
    for _, o in ipairs(Mock.objects) do
        if o.placeholder and o.placeholder.text == text then return o end
    end
end

local main = GM.frame
main:ClearAllPoints()
main:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -40)
Mock.world.target = { name = "Valguard", player = true }

local function category(id, query)
    if GM.HideLookupResults then GM.HideLookupResults() end
    if GM.mailFrame then GM.mailFrame:Hide() end
    GM.ClearPendingConfirmation()
    GM.currentCategory, GM.page = id, 1
    GM.searchText = query or ""
    GM.searchBox:SetText(query or "")
    GM.ShowUI()
    GM.currentCategory, GM.searchText = id, query or ""
    GM.RefreshCategoryButtons(); GM.RefreshList()
end
local function pick(id)
    local entry = GM.FindEntry(id)
    for _, e in ipairs(GM.commands or {}) do if e.id == id then entry = e end end
    GM.SetComposer(entry)
    return entry
end

scene("search-configure", function()
    category("all", "level")
    pick("levelup")
    dump("search-configure", { main }, "Search and configure a command")
end)

scene("favourites", function()
    TortoiseGMManagerDB.favourites = { "gm-fly", "tele-gm-island", "revive", "levelup", "additem", "god-mode" }
    category("favourites")
    pick("tele-gm-island")
    dump("favourites", { main }, "Favourites")
end)

scene("item-lookup", function()
    category("lookup")
    pick("lookup-item")
    GM.BeginLookupCommand(".lookup item lion")
    GM.AddLookupResult("item", "12640", "Lionheart Helm")
    GM.AddLookupResult("item", "13340", "Cape of the Black Baron")
    GM.AddLookupResult("item", "11815", "Hand of Justice")
    GM.AddLookupResult("item", "19019", "Thunderfury, Blessed Blade of the Windseeker")
    GM.EndLookup("done")
    GM.lookupResultsDismissed = false
    GM.ShowLookupResults()
    local results = GM.lookupResultsFrame
    results:ClearAllPoints()
    results:SetPoint("TOPLEFT", main, "TOPRIGHT", 12, 0)
    dump("item-lookup", { main, results }, "Item lookup results")
end)

scene("mail", function()
    category("player")
    pick("mail-composer")
    GM.ShowMailComposer("items")
    local recipient = editWithPlaceholder("Player name")
    if recipient then recipient:SetText("Valguard") end
    GM.ClearMailItems()
    GM.AddMailItem(12640, "Lionheart Helm", 1)
    GM.AddMailItem(858, "Lesser Healing Potion", 5)
    GM.RefreshMailComposer()
    dump("mail", { main, GM.mailFrame }, "Mail composer")
end)

scene("danger-armed", function()
    category("danger")
    pick("server-restart")
    local args = GM.argumentControls[1].edit
    args:SetText("300 Patch day")
    args:GetScript("OnTextChanged")(args, true)
    GM.Execute(GM.commandBox:GetText())
    tick(1)
    dump("danger-armed", { main }, "Dangerous command armed")
end)

if failures > 0 then os.exit(1) end
