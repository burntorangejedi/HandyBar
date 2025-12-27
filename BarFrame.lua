local addonName, addon = ...

addon.Bars = {}

local activeBars = {}

-- Create a single bar frame
function addon.Bars:CreateBar(barID)
    if activeBars[barID] then
        return activeBars[barID]
    end
    
    local barData = addon.db.bars[barID]
    if not barData then
        return nil
    end
    
    -- Create main bar frame
    local bar = CreateFrame("Frame", "HandyBar_Bar" .. barID, UIParent, "SecureHandlerStateTemplate")
    bar.barID = barID
    bar.buttons = {}
    
    -- Set initial size
    bar:SetSize(400, 40)
    bar:SetPoint("CENTER", UIParent, "CENTER", 0, -100 * barID)
    
    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Make movable (will be enhanced with EditMode)
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SavePosition()
    end)
    
    -- Title text
    bar.title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.title:SetPoint("TOP", bar, "TOP", 0, 15)
    bar.title:SetText(barData.name or ("Bar " .. barID))
    
    activeBars[barID] = bar
    
    -- Initial update
    self:UpdateBar(barID)
    
    return bar
end

function addon.Bars:UpdateBar(barID)
    local bar = activeBars[barID]
    if not bar then
        return
    end
    
    local barData = addon.db.bars[barID]
    if not barData then
        return
    end
    
    -- Update title
    bar.title:SetText(barData.name)
    
    -- Clear existing buttons
    for _, btn in ipairs(bar.buttons) do
        btn:Hide()
        btn:ClearAllPoints()
    end
    
    -- Collect all items from categories
    local items = self:GetItemsForBar(barID)
    
    -- Create/update buttons
    local buttonSize = barData.buttonSize or 36
    local spacing = barData.spacing or 2
    local buttonsPerRow = barData.buttonsPerRow or 12
    local numButtons = #items
    
    for i, itemData in ipairs(items) do
        local button = self:GetOrCreateButton(bar, i)
        button:SetSize(buttonSize, buttonSize)
        
        -- Position button
        local row = math.floor((i - 1) / buttonsPerRow)
        local col = (i - 1) % buttonsPerRow
        local xOffset = col * (buttonSize + spacing)
        local yOffset = -row * (buttonSize + spacing)
        
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", bar, "TOPLEFT", xOffset, yOffset - 20)
        
        -- Set item
        self:SetButtonItem(button, itemData)
        button:Show()
    end
    
    -- Hide unused buttons
    for i = numButtons + 1, #bar.buttons do
        bar.buttons[i]:Hide()
    end
    
    -- Update bar size
    local rows = math.ceil(numButtons / buttonsPerRow)
    local cols = math.min(numButtons, buttonsPerRow)
    local width = cols * (buttonSize + spacing) - spacing
    local height = rows * (buttonSize + spacing) - spacing + 20
    bar:SetSize(math.max(width, 100), math.max(height, 40))
    
    -- Apply display rules
    self:UpdateBarVisibility(barID)
    
    -- Set alpha
    bar:SetAlpha(barData.alpha or 1.0)
end

function addon.Bars:GetItemsForBar(barID)
    local barData = addon.db.bars[barID]
    if not barData then
        return {}
    end
    
    local items = {}
    local seenItems = {}
    
    -- Scan bags for each category
    for _, categoryKey in ipairs(barData.categories) do
        local foundItems = addon.Categories:ScanBagsForCategory(categoryKey)
        for _, itemData in ipairs(foundItems) do
            if not seenItems[itemData.itemID] then
                table.insert(items, itemData)
                seenItems[itemData.itemID] = true
            end
        end
    end
    
    return items
end

function addon.Bars:GetOrCreateButton(bar, index)
    if bar.buttons[index] then
        return bar.buttons[index]
    end
    
    local button = CreateFrame("Button", "HandyBar_Bar" .. bar.barID .. "_Button" .. index, bar, "SecureActionButtonTemplate, ItemButtonTemplate")
    button:RegisterForClicks("AnyUp")
    button.barID = bar.barID
    button.index = index
    
    -- Secure attributes for item usage
    button:SetAttribute("type1", "item")
    
    -- Cooldown
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    
    -- Count
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    table.insert(bar.buttons, button)
    return button
end

function addon.Bars:SetButtonItem(button, itemData)
    button.itemID = itemData.itemID
    button.bag = itemData.bag
    button.slot = itemData.slot
    
    -- Set item attribute
    button:SetAttribute("item", "bag " .. itemData.bag .. " " .. itemData.slot)
    
    -- Get item info
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, 
          itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemData.itemID)
    
    if itemTexture then
        button.icon:SetTexture(itemTexture)
        button.icon:Show()
    end
    
    -- Update count
    local info = C_Container.GetContainerItemInfo(itemData.bag, itemData.slot)
    if info and info.stackCount and info.stackCount > 1 then
        button.count:SetText(info.stackCount)
        button.count:Show()
    else
        button.count:Hide()
    end
    
    -- Update cooldown
    local start, duration, enable = GetItemCooldown(itemData.itemID)
    if start and duration and duration > 0 then
        button.cooldown:SetCooldown(start, duration)
    end
end

function addon.Bars:UpdateBarVisibility(barID)
    local bar = activeBars[barID]
    if not bar then
        return
    end
    
    local barData = addon.db.bars[barID]
    if not barData or not barData.enabled then
        bar:Hide()
        return
    end
    
    local rules = barData.displayRules
    
    -- Check combat rules
    local inCombat = InCombatLockdown()
    if rules.inCombat and not inCombat then
        bar:Hide()
        return
    end
    if rules.outOfCombat and inCombat then
        bar:Hide()
        return
    end
    
    -- Mouseover will be handled by OnUpdate or MouseOver events
    if rules.onMouseover then
        bar:SetAlpha(0.3)
        bar.mouseoverEnabled = true
    else
        bar:SetAlpha(barData.alpha or 1.0)
        bar.mouseoverEnabled = false
    end
    
    bar:Show()
end

function addon.Bars:RefreshAll()
    for barID = 1, addon.db.numBars do
        if activeBars[barID] then
            self:UpdateBar(barID)
        else
            self:CreateBar(barID)
        end
    end
    
    -- Hide bars beyond numBars
    for barID = addon.db.numBars + 1, 10 do
        if activeBars[barID] then
            activeBars[barID]:Hide()
        end
    end
end

function addon.Bars:SavePosition(bar)
    local barData = addon.db.bars[bar.barID]
    if barData then
        local point, relativeTo, relativePoint, xOffset, yOffset = bar:GetPoint()
        barData.position = {
            point = point,
            relativePoint = relativePoint,
            x = xOffset,
            y = yOffset,
        }
    end
end

-- Event handlers
function addon.Bars:OnBagUpdate()
    -- Refresh all visible bars
    for barID, bar in pairs(activeBars) do
        if bar:IsShown() then
            self:UpdateBar(barID)
        end
    end
end

function addon.Bars:OnCombatStateChange()
    for barID in pairs(activeBars) do
        self:UpdateBarVisibility(barID)
    end
end

-- Register for necessary events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "BAG_UPDATE" then
        addon.Bars:OnBagUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        addon.Bars:OnCombatStateChange()
    end
end)
