local addonName, addon = ...

addon.EditMode = {}

local systemInfo = {
    systemName = "HandyBar",
    isLayout = false,
}

function addon.EditMode:Initialize()
    if not EditModeManagerFrame then
        -- EditMode not available, use basic positioning
        return
    end
    
    -- Register each bar with EditMode
    for barID = 1, 10 do
        self:RegisterBarWithEditMode(barID)
    end
end

function addon.EditMode:RegisterBarWithEditMode(barID)
    addon.DB:EnsureBarExists(barID)
    
    local bar = activeBars and activeBars[barID]
    if not bar then
        return
    end
    
    -- Make the bar compatible with EditMode
    local systemFrame = bar
    
    -- Add EditMode system methods
    systemFrame.system = systemInfo
    systemFrame.Selection = CreateFrame("Frame", nil, systemFrame, "EditModeSystemSelectionTemplate")
    
    -- System info for this specific bar
    systemFrame.systemInfo = {
        systemName = "HandyBar" .. barID,
        systemNameString = addon.db.bars[barID].name or ("HandyBar " .. barID),
    }
    
    -- EditMode integration functions
    function systemFrame:UpdateSystem(systemInfo)
        -- Called when EditMode settings change
        if systemInfo then
            local barData = addon.db.bars[self.barID]
            if barData.position then
                self:ClearAllPoints()
                self:SetPoint(
                    barData.position.point or "CENTER",
                    UIParent,
                    barData.position.relativePoint or "CENTER",
                    barData.position.x or 0,
                    barData.position.y or 0
                )
            end
        end
    end
    
    function systemFrame:IsInDefaultPosition()
        local barData = addon.db.bars[self.barID]
        return not barData.position
    end
    
    function systemFrame:SetToDefaultPosition()
        local barData = addon.db.bars[self.barID]
        barData.position = nil
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, -100 * self.barID)
    end
    
    function systemFrame:OnEditModeEnter()
        self.Selection:Show()
        self:SetAlpha(1.0)
    end
    
    function systemFrame:OnEditModeExit()
        self.Selection:Hide()
        addon.Bars:UpdateBarVisibility(self.barID)
    end
    
    function systemFrame:UpdateDisplayInfo()
        -- Update any display-related info
        return addon.db.bars[self.barID].name or ("Bar " .. self.barID)
    end
    
    -- Hook into position saving
    local originalSavePosition = bar.SavePosition
    function systemFrame:SavePosition()
        if originalSavePosition then
            originalSavePosition(self)
        else
            addon.Bars:SavePosition(self)
        end
    end
    
    -- Register with EditMode if possible
    if EditModeManagerFrame and EditModeManagerFrame.RegisterSystemFrame then
        EditModeManagerFrame:RegisterSystemFrame(systemFrame)
    end
end

function addon.EditMode:UnregisterBarFromEditMode(barID)
    local bar = activeBars and activeBars[barID]
    if not bar then
        return
    end
    
    if EditModeManagerFrame and EditModeManagerFrame.UnregisterSystemFrame then
        EditModeManagerFrame:UnregisterSystemFrame(bar)
    end
end

function addon.EditMode:RefreshEditMode()
    if not EditModeManagerFrame then
        return
    end
    
    -- Re-register all active bars
    for barID = 1, addon.db.numBars do
        self:RegisterBarWithEditMode(barID)
    end
end
