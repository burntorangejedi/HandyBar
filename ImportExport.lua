local addonName, addon = ...

addon.ImportExport = {}

local importExportFrame

function addon.ImportExport:ShowDialog()
    if importExportFrame then
        importExportFrame:Show()
        return
    end
    
    -- Create dialog frame
    importExportFrame = CreateFrame("Frame", "HandyBarImportExportDialog", UIParent, "BasicFrameTemplateWithInset")
    importExportFrame:SetSize(500, 400)
    importExportFrame:SetPoint("CENTER")
    importExportFrame:SetFrameStrata("DIALOG")
    importExportFrame:EnableMouse(true)
    importExportFrame.TitleText:SetText("Import/Export Configuration")
    
    -- Make draggable
    importExportFrame:SetMovable(true)
    importExportFrame:SetClampedToScreen(true)
    importExportFrame:RegisterForDrag("LeftButton")
    importExportFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    importExportFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Instructions
    local instructions = importExportFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOPLEFT", importExportFrame, "TOPLEFT", 20, -30)
    instructions:SetPoint("TOPRIGHT", importExportFrame, "TOPRIGHT", -20, -30)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Export: Click Export to copy your configuration.\nImport: Paste configuration string and click Import.")
    
    -- Scroll frame for text
    local scrollFrame = CreateFrame("ScrollFrame", nil, importExportFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", importExportFrame, "BOTTOMRIGHT", -30, 80)
    
    -- Edit box
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(440)
    editBox:SetHeight(200)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    scrollFrame:SetScrollChild(editBox)
    importExportFrame.editBox = editBox
    
    -- Export button
    local exportBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate")
    exportBtn:SetPoint("BOTTOMLEFT", importExportFrame, "BOTTOMLEFT", 20, 15)
    exportBtn:SetSize(100, 25)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        local exported = self:ExportConfiguration()
        editBox:SetText(exported)
        editBox:HighlightText()
        editBox:SetFocus()
        print("|cff00ff00HandyBar:|r Configuration exported. Press Ctrl+C to copy.")
    end)
    
    -- Import button
    local importBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate")
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    importBtn:SetSize(100, 25)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text and text ~= "" then
            if self:ImportConfiguration(text) then
                print("|cff00ff00HandyBar:|r Configuration imported successfully!")
                addon.Bars:RefreshAll()
            else
                print("|cffff0000HandyBar:|r Failed to import configuration. Invalid format.")
            end
        end
    end)
    
    -- Clear button
    local clearBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate")
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)
    clearBtn:SetSize(100, 25)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        editBox:SetText("")
    end)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOMRIGHT", importExportFrame, "BOTTOMRIGHT", -20, 15)
    closeBtn:SetSize(100, 25)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        importExportFrame:Hide()
    end)
    
    importExportFrame:Show()
end

function addon.ImportExport:ExportConfiguration()
    -- Serialize the configuration
    local config = {
        version = 1,
        numBars = addon.db.numBars,
        bars = addon.db.bars,
        customCategories = addon.db.customCategories,
    }
    
    local serialized = self:Serialize(config)
    local encoded = self:Encode(serialized)
    
    return encoded
end

function addon.ImportExport:ImportConfiguration(encoded)
    -- Deserialize and apply configuration
    local serialized = self:Decode(encoded)
    if not serialized then
        return false
    end
    
    local config = self:Deserialize(serialized)
    if not config or not config.version then
        return false
    end
    
    -- Apply configuration
    addon.db.numBars = config.numBars or 1
    addon.db.bars = config.bars or {}
    addon.db.customCategories = config.customCategories or {}
    
    return true
end

function addon.ImportExport:Serialize(data)
    -- Simple Lua table serialization
    local function serializeValue(v, indent)
        indent = indent or ""
        local t = type(v)
        
        if t == "number" or t == "boolean" then
            return tostring(v)
        elseif t == "string" then
            return string.format("%q", v)
        elseif t == "table" then
            local lines = {"{"}
            for k, val in pairs(v) do
                local key
                if type(k) == "number" then
                    key = string.format("[%d]", k)
                else
                    key = string.format("[%q]", k)
                end
                table.insert(lines, string.format("%s%s=%s,", indent .. "  ", key, serializeValue(val, indent .. "  ")))
            end
            table.insert(lines, indent .. "}")
            return table.concat(lines, "\n")
        else
            return "nil"
        end
    end
    
    return serializeValue(data)
end

function addon.ImportExport:Deserialize(str)
    -- Convert serialized string back to table
    local func, err = loadstring("return " .. str)
    if not func then
        print("|cffff0000HandyBar:|r Deserialize error: " .. tostring(err))
        return nil
    end
    
    local success, result = pcall(func)
    if not success then
        print("|cffff0000HandyBar:|r Deserialize error: " .. tostring(result))
        return nil
    end
    
    return result
end

function addon.ImportExport:Encode(str)
    -- Base64-like encoding (simplified)
    -- In production, you'd want proper base64 encoding
    -- For now, we'll use compression if available
    if LibStub and LibStub:GetLibrary("LibCompress", true) then
        local LibCompress = LibStub:GetLibrary("LibCompress")
        local encoded = LibCompress:Encode(str)
        return encoded
    end
    
    -- Fallback: just return the serialized string
    return str
end

function addon.ImportExport:Decode(str)
    -- Base64-like decoding (simplified)
    if LibStub and LibStub:GetLibrary("LibCompress", true) then
        local LibCompress = LibStub:GetLibrary("LibCompress")
        local decoded = LibCompress:Decode(str)
        return decoded
    end
    
    -- Fallback: assume it's already decoded
    return str
end
