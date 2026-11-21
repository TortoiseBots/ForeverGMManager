TortoiseGMManager = TortoiseGMManager or {}

local Theme = TortoiseGMManager.Theme
local COLORS = Theme.colors

local MAIL_WIDTH = 420
local MAIL_HEIGHT = TortoiseGMManager.frame and TortoiseGMManager.frame:GetHeight() or 0
if MAIL_HEIGHT < 400 then MAIL_HEIGHT = 578 end
local PAD = 14
local CONTENT_WIDTH = MAIL_WIDTH - (PAD * 2)
local HEADER_HEIGHT = 44
local ROWS_PER_PAGE = 5
local ROW_HEIGHT = 30
local ROW_GAP = 4

local frame = CreateFrame("Frame", "TortoiseGMManagerMailFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
frame:SetWidth(MAIL_WIDTH); frame:SetHeight(MAIL_HEIGHT); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true)
frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end); frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
Theme.Window(frame, { title = "Mail Composer", subtitle = "Send items or gold via .send", icon = "Interface\\Icons\\INV_Letter_15", headerHeight = HEADER_HEIGHT })
frame:Hide(); TortoiseGMManager.mailFrame = frame
if TortoiseGMManager.frame then frame:SetPoint("TOPLEFT", TortoiseGMManager.frame, "TOPRIGHT", 10, 0) else frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0) end
if UISpecialFrames then table.insert(UISpecialFrames, "TortoiseGMManagerMailFrame") end
frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

local mailMode = "items"
local mailPage = 1
local currentCommand = ""
local currentValid = false

local modeBtnWidth = math.floor((CONTENT_WIDTH - 6) / 2)
local itemsModeBtn = Theme.Button(frame, "SEND ITEMS", "accent", modeBtnWidth, 24, 10)
itemsModeBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -54)
local moneyModeBtn = Theme.Button(frame, "SEND MONEY", "secondary", modeBtnWidth, 24, 10)
moneyModeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -54)

local recipientLabel = Theme.Caption(frame, "RECIPIENT")
recipientLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 2, -88)
local recipientEdit = Theme.Input(frame, nil, CONTENT_WIDTH - 76, 24, { placeholder = "Player name" })
recipientEdit:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -102)
recipientEdit:SetMaxLetters(40)
Theme.WatchInput(recipientEdit)

local targetBtn = Theme.Button(frame, "TARGET", "secondary", 70, 24, 10)
targetBtn:SetPoint("LEFT", recipientEdit, "RIGHT", 6, 0)

local subjectLabel = Theme.Caption(frame, "SUBJECT")
subjectLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 2, -134)
local subjectEdit = Theme.Input(frame, nil, CONTENT_WIDTH, 24, { placeholder = "Mail subject" })
subjectEdit:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -148)
subjectEdit:SetMaxLetters(100)
subjectEdit:SetText("GM Mail")
Theme.WatchInput(subjectEdit)

local bodyLabel = Theme.Caption(frame, "MESSAGE")
bodyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 2, -180)
local bodyEdit = Theme.Input(frame, nil, CONTENT_WIDTH, 24, { placeholder = "Optional mail text" })
bodyEdit:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -194)
bodyEdit:SetMaxLetters(200)
Theme.WatchInput(bodyEdit)

local sectionDivider = Theme.Divider(frame)
sectionDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -226)
sectionDivider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -226)

-- Items mode panel
local itemsPanel = CreateFrame("Frame", nil, frame)
itemsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -234)
itemsPanel:SetWidth(CONTENT_WIDTH); itemsPanel:SetHeight(248)

local itemIdLabel = Theme.Caption(itemsPanel, "ITEM ID (OR SHIFT+CLICK)")
itemIdLabel:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 2, 0)
local itemIdEdit = Theme.Input(itemsPanel, nil, 210, 24, { placeholder = "Item ID" })
itemIdEdit:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 0, -14)
itemIdEdit:SetMaxLetters(16)
Theme.WatchInput(itemIdEdit)

local countLabel = Theme.Caption(itemsPanel, "COUNT")
countLabel:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 218, 0)
local countEdit = Theme.Input(itemsPanel, nil, 76, 24, { justify = "CENTER" })
countEdit:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 216, -14)
countEdit:SetMaxLetters(6)
countEdit:SetText("1")
Theme.WatchInput(countEdit)

local addBtn = Theme.Button(itemsPanel, "ADD", "primary", 92, 24, 10)
addBtn:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 298, -14)

local attachHeader = Theme.Caption(itemsPanel, "ATTACHMENTS (0 / 12)")
attachHeader:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 2, -48)

local clearBtn = Theme.Button(itemsPanel, "CLEAR", "secondary", 56, 18, 9)
clearBtn:SetPoint("TOPRIGHT", itemsPanel, "TOPRIGHT", 0, -45)
local nextPageBtn = Theme.IconButton(itemsPanel, 18, ">", "secondary")
nextPageBtn:SetPoint("RIGHT", clearBtn, "LEFT", -6, 0)
local pageLabel = Theme.Text(itemsPanel, 10, COLORS.muted, { justify = "CENTER" })
pageLabel:SetPoint("RIGHT", nextPageBtn, "LEFT", -4, 0); pageLabel:SetWidth(38)
local prevPageBtn = Theme.IconButton(itemsPanel, 18, "<", "secondary")
prevPageBtn:SetPoint("RIGHT", pageLabel, "LEFT", -4, 0)

local emptyAttach = Theme.Text(itemsPanel, 11, COLORS.muted, { justify = "CENTER" })
emptyAttach:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 0, -96)
emptyAttach:SetWidth(CONTENT_WIDTH)
emptyAttach:SetText("No items attached. Enter an ID, Shift+Click an item, or use Lookup Results.")

local itemRows = {}
local rowIndex
for rowIndex = 1, ROWS_PER_PAGE do
    local row = CreateFrame("Frame", nil, itemsPanel, BackdropTemplateMixin and "BackdropTemplate" or nil)
    row:SetWidth(CONTENT_WIDTH); row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 0, -68 - ((rowIndex - 1) * (ROW_HEIGHT + ROW_GAP)))
    Theme.Card(row)
    row.title = Theme.Text(row, 11, COLORS.text)
    row.title:SetPoint("LEFT", row, "LEFT", 8, 0); row.title:SetWidth(238); row.title:SetHeight(14)
    row.removeBtn = Theme.Button(row, "X", "secondary", 22, 20, 9)
    row.removeBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.plusBtn = Theme.Button(row, "+", "secondary", 22, 20, 11)
    row.plusBtn:SetPoint("RIGHT", row.removeBtn, "LEFT", -6, 0)
    row.countText = Theme.Text(row, 11, COLORS.gold, { justify = "CENTER" })
    row.countText:SetPoint("RIGHT", row.plusBtn, "LEFT", -2, 0); row.countText:SetWidth(38)
    row.minusBtn = Theme.Button(row, "-", "secondary", 22, 20, 11)
    row.minusBtn:SetPoint("RIGHT", row.countText, "LEFT", -2, 0)
    itemRows[rowIndex] = row
end

-- Money mode panel
local moneyPanel = CreateFrame("Frame", nil, frame)
moneyPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -234)
moneyPanel:SetWidth(CONTENT_WIDTH); moneyPanel:SetHeight(248)
moneyPanel:Hide()

local coinWidth = math.floor((CONTENT_WIDTH - 16) / 3)
local goldLabel = Theme.Caption(moneyPanel, "GOLD")
goldLabel:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", 2, 0)
local goldEdit = Theme.Input(moneyPanel, nil, coinWidth, 24, { justify = "CENTER" })
goldEdit:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", 0, -14); goldEdit:SetMaxLetters(8); goldEdit:SetText("0")
Theme.WatchInput(goldEdit)

local silverLabel = Theme.Caption(moneyPanel, "SILVER")
silverLabel:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", coinWidth + 10, 0)
local silverEdit = Theme.Input(moneyPanel, nil, coinWidth, 24, { justify = "CENTER" })
silverEdit:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", coinWidth + 8, -14); silverEdit:SetMaxLetters(4); silverEdit:SetText("0")
Theme.WatchInput(silverEdit)

local copperLabel = Theme.Caption(moneyPanel, "COPPER")
copperLabel:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", (coinWidth + 8) * 2 + 2, 0)
local copperEdit = Theme.Input(moneyPanel, nil, coinWidth, 24, { justify = "CENTER" })
copperEdit:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", (coinWidth + 8) * 2, -14); copperEdit:SetMaxLetters(4); copperEdit:SetText("0")
Theme.WatchInput(copperEdit)

local totalCopperText = Theme.Text(moneyPanel, 11, COLORS.muted)
totalCopperText:SetPoint("TOPLEFT", moneyPanel, "TOPLEFT", 2, -50)
totalCopperText:SetWidth(CONTENT_WIDTH)

-- Bottom preview & execute bar (matches ResultsUI)
local previewLabel = Theme.Caption(frame, "PREVIEW")
previewLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + 2, 76)
local preview = Theme.Input(frame, nil, CONTENT_WIDTH, 26, { code = true, prefix = ">", placeholder = "Mail command preview" })
preview:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, 46)
preview:EnableKeyboard(false)
Theme.WatchInput(preview)

local validationDot = Theme.Dot(frame, 6)
validationDot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + 2, 23)
local validation = Theme.Text(frame, 10, COLORS.muted)
validation:SetPoint("LEFT", validationDot, "RIGHT", 7, 0)
validation:SetWidth(CONTENT_WIDTH - 160); validation:SetHeight(24)

local executeBtn = Theme.Button(frame, "EXECUTE", "primary", 140, 28, 11)
executeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, 12)

local function setValidation(message, color)
    validation:SetText(message or "")
    Theme.SetTextColor(validation, color or COLORS.muted)
    if message and message ~= "" then
        Theme.SetDotColor(validationDot, color or COLORS.muted)
        validationDot:Show()
    else
        validationDot:Hide()
    end
end

local function paintExecuteLabel()
    if not currentValid or currentCommand == "" then return end
    local armed = TortoiseGMManager.pendingCommand == currentCommand and TortoiseGMManager.pendingUntil and GetTime() <= TortoiseGMManager.pendingUntil
    local label = armed and "CONFIRM EXECUTE" or "EXECUTE"
    if executeBtn:GetText() ~= label then executeBtn:SetText(label) end
end

local function getFields()
    return {
        recipient = recipientEdit:GetText(),
        subject = subjectEdit:GetText(),
        body = bodyEdit:GetText(),
        gold = goldEdit:GetText(),
        silver = silverEdit:GetText(),
        copper = copperEdit:GetText(),
    }
end

function TortoiseGMManager.RefreshMailComposer()
    itemsModeBtn:SetVariant(mailMode == "items" and "accent" or "secondary")
    moneyModeBtn:SetVariant(mailMode == "money" and "accent" or "secondary")
    if mailMode == "items" then
        itemsPanel:Show(); moneyPanel:Hide()
        local items = TortoiseGMManager.mailItems or {}
        local count = #items
        local pages = math.max(1, math.ceil(count / ROWS_PER_PAGE))
        if mailPage > pages then mailPage = pages end
        if mailPage < 1 then mailPage = 1 end
        attachHeader:SetText("ATTACHMENTS (" .. tostring(count) .. " / " .. tostring(TortoiseGMManager.MAX_MAIL_ITEMS) .. ")")
        pageLabel:SetText(tostring(mailPage) .. " / " .. tostring(pages))
        if mailPage <= 1 then prevPageBtn:Disable() else prevPageBtn:Enable() end
        if mailPage >= pages then nextPageBtn:Disable() else nextPageBtn:Enable() end
        if count == 0 then clearBtn:Disable(); emptyAttach:Show() else clearBtn:Enable(); emptyAttach:Hide() end

        local start = ((mailPage - 1) * ROWS_PER_PAGE) + 1
        for rowIndex = 1, ROWS_PER_PAGE do
            local idx = start + rowIndex - 1
            local item = items[idx]
            local row = itemRows[rowIndex]
            if item then
                row.itemIndex = idx
                row.title:SetText(tostring(item.name or ("Item " .. tostring(item.id))) .. "  " .. Theme.Hex(COLORS.muted) .. "#" .. tostring(item.id) .. "|r")
                row.countText:SetText("x" .. tostring(item.count or 1))
                row.minusBtn:SetScript("OnClick", function()
                    TortoiseGMManager.SetMailItemCount(idx, (item.count or 1) - 1)
                    TortoiseGMManager.ClearPendingConfirmation()
                    TortoiseGMManager.RefreshMailComposer()
                end)
                row.plusBtn:SetScript("OnClick", function()
                    TortoiseGMManager.SetMailItemCount(idx, (item.count or 1) + 1)
                    TortoiseGMManager.ClearPendingConfirmation()
                    TortoiseGMManager.RefreshMailComposer()
                end)
                row.removeBtn:SetScript("OnClick", function()
                    TortoiseGMManager.RemoveMailItem(idx)
                    TortoiseGMManager.ClearPendingConfirmation()
                    TortoiseGMManager.RefreshMailComposer()
                end)
                row:Show()
            else
                row.itemIndex = nil
                row:Hide()
            end
        end
    else
        itemsPanel:Hide(); moneyPanel:Show()
        local copper = TortoiseGMManager.ComputeMailCopper(goldEdit:GetText(), silverEdit:GetText(), copperEdit:GetText())
        totalCopperText:SetText("Total copper sent: " .. tostring(copper) .. "c")
    end

    local command, valid, message = TortoiseGMManager.BuildMailCommand(mailMode, getFields(), TortoiseGMManager.mailItems)
    currentCommand, currentValid = command, valid
    preview:SetText(command or "")
    local dangerous = valid and TortoiseGMManager.IsDangerous(command)
    executeBtn:SetVariant(dangerous and "danger" or "primary")
    if valid then
        local byteLen = string.len(command)
        if dangerous then
            setValidation("Requires two identical confirmations (" .. tostring(byteLen) .. "/255).", COLORS.orange)
        else
            setValidation("Ready (" .. tostring(byteLen) .. "/255 bytes).", COLORS.green)
        end
        paintExecuteLabel()
        executeBtn:Enable()
    else
        setValidation(message or "Incomplete mail.", COLORS.red)
        executeBtn:SetText("EXECUTE")
        executeBtn:Disable()
    end
end

local function onFieldChanged()
    TortoiseGMManager.ClearPendingConfirmation()
    TortoiseGMManager.RefreshMailComposer()
end

recipientEdit:SetScript("OnTextChanged", onFieldChanged)
subjectEdit:SetScript("OnTextChanged", onFieldChanged)
bodyEdit:SetScript("OnTextChanged", onFieldChanged)
goldEdit:SetScript("OnTextChanged", onFieldChanged)
silverEdit:SetScript("OnTextChanged", onFieldChanged)
copperEdit:SetScript("OnTextChanged", onFieldChanged)

itemsModeBtn:SetScript("OnClick", function() mailMode = "items"; onFieldChanged() end)
moneyModeBtn:SetScript("OnClick", function() mailMode = "money"; onFieldChanged() end)

-- The recipient field is compared and sent later, so a "secret" target name
-- (the client hides some names from addons) is never put into it.
local function plainTargetName()
    local name = UnitName and UnitName("target")
    if not name or (issecretvalue and issecretvalue(name)) or name == "" then return nil end
    return name
end

targetBtn:SetScript("OnClick", function()
    local name = plainTargetName()
    if name then recipientEdit:SetText(name) end
end)

local function addItemFromInputs()
    local idText = itemIdEdit:GetText()
    local countText = countEdit:GetText()
    local itemName
    local idNum = tonumber(idText)
    if idNum and GetItemInfo then
        itemName = GetItemInfo(idNum)
    end
    local ok, err = TortoiseGMManager.AddMailItem(idText, itemName, countText)
    if ok then
        itemIdEdit:SetText("")
        countEdit:SetText("1")
        TortoiseGMManager.ClearPendingConfirmation()
        TortoiseGMManager.RefreshMailComposer()
    elseif err then
        setValidation(err, COLORS.red)
    end
end

addBtn:SetScript("OnClick", addItemFromInputs)
itemIdEdit:SetScript("OnEnterPressed", addItemFromInputs)
countEdit:SetScript("OnEnterPressed", addItemFromInputs)
clearBtn:SetScript("OnClick", function() TortoiseGMManager.ClearMailItems(); onFieldChanged() end)
prevPageBtn:SetScript("OnClick", function() if mailPage > 1 then mailPage = mailPage - 1; TortoiseGMManager.RefreshMailComposer() end end)
nextPageBtn:SetScript("OnClick", function() mailPage = mailPage + 1; TortoiseGMManager.RefreshMailComposer() end)

executeBtn:SetScript("OnClick", function()
    if not currentValid or currentCommand == "" then return end
    if TortoiseGMManager.Execute(currentCommand) then
        if mailMode == "items" then TortoiseGMManager.ClearMailItems() end
    end
    TortoiseGMManager.RefreshMailComposer()
end)

local labelElapsed = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    labelElapsed = labelElapsed + (elapsed or 0)
    if labelElapsed >= 0.2 then labelElapsed = 0; paintExecuteLabel() end
end)

function TortoiseGMManager.GetFocusedMailItemInput()
    if not frame:IsShown() then return nil end
    if itemIdEdit:HasFocus() then return itemIdEdit end
    local edits = { recipientEdit, subjectEdit, bodyEdit, countEdit, goldEdit, silverEdit, copperEdit }
    local i
    for i = 1, #edits do
        if edits[i]:HasFocus() then return itemIdEdit end
    end
    return nil
end

function TortoiseGMManager.ShowMailComposer(mode)
    if mode == "items" or mode == "money" then mailMode = mode end
    if recipientEdit:GetText() == "" and UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
        local name = plainTargetName()
        if name then recipientEdit:SetText(name) end
    end
    TortoiseGMManager.RefreshMailComposer()
    frame:Show()
end

function TortoiseGMManager.OpenMailWithItem(itemId, itemName, count)
    local ok, err = TortoiseGMManager.AddMailItem(itemId, itemName, count or 1)
    TortoiseGMManager.ShowMailComposer("items")
    if not ok and err then setValidation(err, COLORS.red) end
end
