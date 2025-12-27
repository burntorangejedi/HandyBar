local addonName, addon = ...

addon.Options = {}

local optionsPanel

function addon.Options:Initialize()
    self:CreateOptionsPanel()
end

function addon.Options:CreateOptionsPanel()
    -- Main options panel as a standalone window
    optionsPanel = CreateFrame("Frame", "HandyBarOptionsPanel", UIParent, "BasicFrameTemplateWithInset")
    optionsPanel:SetSize(500, 600)
    optionsPanel:SetPoint("CENTER")
    optionsPanel:Hide()
    optionsPanel:SetFrameStrata("DIALOG")
    optionsPanel:SetMovable(true)
    optionsPanel:SetClampedToScreen(true)
    optionsPanel:RegisterForDrag("LeftButton")
    optionsPanel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    optionsPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    optionsPanel.TitleText:SetText("HandyBar Options")
    
    -- Subtitle
    local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 20, -30)
    subtitle:SetText("Configure your toolbars and categories")
    
    -- Subtitle
    local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 20, -30)
    subtitle:SetText("Configure your toolbars and categories")
    
    -- Number of bars slider
    local numBarsSlider = CreateFrame("Slider", "HandyBarNumBarsSlider", optionsPanel, "OptionsSliderTemplate")
    numBarsSlider:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -30)
    numBarsSlider:SetMinMaxValues(1, 10)
    numBarsSlider:SetValueStep(1)
    numBarsSlider:SetObeyStepOnDrag(true)
    numBarsSlider.Low:SetText("1")
    numBarsSlider.High:SetText("10")
    numBarsSlider.Text:SetText("Number of Bars: " .. addon.db.numBars)
    numBarsSlider:SetValue(addon.db.numBars)
    numBarsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addon.db.numBars = value
        self.Text:SetText("Number of Bars: " .. value)
        addon.Bars:RefreshAll()
    end)
    
    -- Reset button
    local resetBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPLEFT", numBarsSlider, "BOTTOMLEFT", 0, -30)
    resetBtn:SetSize(150, 25)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("HANDYBAR_RESET_CONFIRM")
    end)
    
    -- Import/Export button
    local importExportBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    importExportBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    importExportBtn:SetSize(150, 25)
    importExportBtn:SetText("Import/Export")
    importExportBtn:SetScript("OnClick", function()
        addon.ImportExport:ShowDialog()
    end)
    
    -- Bar configuration section
    local barConfigTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    barConfigTitle:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -30)
    barConfigTitle:SetText("Bar Configuration:")
    
    -- Create bar selector dropdown
    local barDropdown = CreateFrame("Frame", "HandyBarBarSelector", optionsPanel, "UIDropDownMenuTemplate")
    barDropdown:SetPoint("TOPLEFT", barConfigTitle, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(barDropdown, 150)
    UIDropDownMenu_SetText(barDropdown, "Select Bar...")
    barDropdown.selectedValue = nil
    
    -- Configure selected bar button
    local configureBarBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    configureBarBtn:SetPoint("LEFT", barDropdown, "RIGHT", 0, 2)
    configureBarBtn:SetSize(120, 25)
    configureBarBtn:SetText("Configure Bar")
    configureBarBtn:SetScript("OnClick", function()
        local selectedBar = barDropdown.selectedValue
        if selectedBar then
            self:ShowBarConfigDialog(selectedBar)
        else
            print("|cffff0000HandyBar:|r Please select a bar first.")
        end
    end)
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(barDropdown, function(self, level)
        for i = 1, addon.db.numBars do
            addon.DB:EnsureBarExists(i)
            local info = UIDropDownMenu_CreateInfo()
            info.text = addon.db.bars[i] and (addon.db.bars[i].name or ("Bar " .. i)) or ("Bar " .. i)
            info.value = i
            info.checked = (barDropdown.selectedValue == i)
            info.func = function(btn)
                barDropdown.selectedValue = btn.value
                UIDropDownMenu_SetText(barDropdown, btn:GetText())
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Category management section
    local categoryTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    categoryTitle:SetPoint("TOPLEFT", barDropdown, "BOTTOMLEFT", 15, -40)
    categoryTitle:SetText("Category Management:")
    
    local createCategoryBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    createCategoryBtn:SetPoint("TOPLEFT", categoryTitle, "BOTTOMLEFT", 0, -10)
    createCategoryBtn:SetSize(150, 25)
    createCategoryBtn:SetText("Create Category")
    createCategoryBtn:SetScript("OnClick", function()
        self:ShowCreateCategoryDialog()
    end)
    
    local manageCategoriesBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    manageCategoriesBtn:SetPoint("LEFT", createCategoryBtn, "RIGHT", 10, 0)
    manageCategoriesBtn:SetSize(150, 25)
    manageCategoriesBtn:SetText("Manage Categories")
    manageCategoriesBtn:SetScript("OnClick", function()
        self:ShowManageCategoriesDialog()
    end)
    
    -- Create confirmation dialog
    StaticPopupDialogs["HANDYBAR_RESET_CONFIRM"] = {
        text = "Are you sure you want to reset HandyBar to default settings? This cannot be undone.",
        button1 = "Reset",
        button2 = "Cancel",
        OnAccept = function()
            addon.DB:Reset()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function addon.Options:ShowBarConfigDialog(barID)
    local barData = addon.db.bars[barID]
    if not barData then
        return
    end
    
    -- Hide existing dialog if any
    if _G["HandyBarConfigDialog"] then
        _G["HandyBarConfigDialog"]:Hide()
        _G["HandyBarConfigDialog"] = nil
    end
    
    -- Create dialog frame
    local dialog = CreateFrame("Frame", "HandyBarConfigDialog", UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(400, 500)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(100)
    dialog:EnableMouse(true)
    dialog.TitleText:SetText("Configure " .. (barData.name or ("Bar " .. barID)))
    
    -- Make draggable
    dialog:SetMovable(true)
    dialog:SetClampedToScreen(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
    dialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    local yOffset = -30
    
    -- Bar name
    local nameLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    nameLabel:SetText("Bar Name:")
    
    local nameEditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    nameEditBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 5, -5)
    nameEditBox:SetSize(200, 20)
    nameEditBox:SetAutoFocus(false)
    nameEditBox:SetText(barData.name or ("Bar " .. barID))
    nameEditBox:SetScript("OnEnterPressed", function(self)
        barData.name = self:GetText()
        addon.Bars:UpdateBar(barID)
        self:ClearFocus()
    end)
    
    yOffset = yOffset - 60
    
    -- Enabled checkbox
    local enabledCheck = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    enabledCheck.Text:SetText("Enable this bar")
    enabledCheck:SetChecked(barData.enabled)
    enabledCheck:SetScript("OnClick", function(self)
        barData.enabled = self:GetChecked()
        addon.Bars:UpdateBarVisibility(barID)
    end)
    
    yOffset = yOffset - 40
    
    -- Categories
    local categoriesLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    categoriesLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
    categoriesLabel:SetText("Categories for this bar:")
    
    yOffset = yOffset - 25
    
    -- Category checkboxes (show first 8)
    local allCategories = addon.Categories:GetAllCategories()
    local categoryKeys = {}
    for k in pairs(allCategories) do
        table.insert(categoryKeys, k)
    end
    table.sort(categoryKeys)
    
    for i, key in ipairs(categoryKeys) do
        if i > 8 then break end
        
        local catCheck = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
        catCheck:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, yOffset)
        catCheck.Text:SetText(allCategories[key].name)
        
        -- Check if category is assigned
        local isAssigned = false
        for _, catKey in ipairs(barData.categories) do
            if catKey == key then
                isAssigned = true
                break
            end
        end
        catCheck:SetChecked(isAssigned)
        
        catCheck:SetScript("OnClick", function(self)
            if self:GetChecked() then
                table.insert(barData.categories, key)
            else
                for i, catKey in ipairs(barData.categories) do
                    if catKey == key then
                        table.remove(barData.categories, i)
                        break
                    end
                end
            end
            addon.Bars:UpdateBar(barID)
        end)
        
        yOffset = yOffset - 25
    end
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 10)
    closeBtn:SetSize(100, 25)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function addon.Options:ShowCreateCategoryDialog()
    -- Simple input dialog for creating a new category
    StaticPopupDialogs["HANDYBAR_CREATE_CATEGORY"] = {
        text = "Enter category key (lowercase, no spaces):",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local key = self.editBox:GetText()
            if key and key ~= "" then
                StaticPopupDialogs["HANDYBAR_CREATE_CATEGORY_NAME"] = {
                    text = "Enter category display name:",
                    button1 = "Create",
                    button2 = "Cancel",
                    hasEditBox = true,
                    OnAccept = function(self)
                        local name = self.editBox:GetText()
                        if addon.Categories:CreateCustomCategory(key, name, "Custom category") then
                            print("|cff00ff00HandyBar:|r Category created: " .. name)
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("HANDYBAR_CREATE_CATEGORY_NAME")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("HANDYBAR_CREATE_CATEGORY")
end

function addon.Options:ShowManageCategoriesDialog()
    print("|cff00ff00HandyBar:|r Category management UI coming soon! Use /handybar commands for now.")
end

function addon.Options:Open()
    if optionsPanel then
        optionsPanel:Show()
    end
end
