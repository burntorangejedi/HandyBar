local addonName, addon = ...

-- Create global addon namespace
_G[addonName] = addon

-- Initialize core addon
local core = CreateFrame("Frame")
core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("PLAYER_LOGIN")

function core:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:OnAddonLoaded()
    elseif event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    end
end

function core:OnAddonLoaded()
    -- Initialize database
    addon.DB:Initialize()
    
    -- Initialize categories
    addon.Categories:Initialize()
    
    print("|cff00ff00HandyBar|r loaded. Type /handybar for options.")
end

function core:OnPlayerLogin()
    -- Initialize options panel
    addon.Options:Initialize()
    
    -- Initialize bars
    addon.Bars:RefreshAll()
    
    -- Initialize EditMode integration
    addon.EditMode:Initialize()
end

core:SetScript("OnEvent", function(self, event, ...)
    self:OnEvent(event, ...)
end)

-- Slash commands
SLASH_HANDYBAR1 = "/handybar"
SLASH_HANDYBAR2 = "/handy"
SLASH_HANDYBAR3 = "/hbar"

SlashCmdList["HANDYBAR"] = function(msg)
    local command, args = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    
    if command == "" or command == "options" or command == "config" then
        addon.Options:Open()
        
    elseif command == "reset" then
        StaticPopup_Show("HANDYBAR_RESET_CONFIRM")
        
    elseif command == "import" or command == "export" then
        addon.ImportExport:ShowDialog()
        
    elseif command == "refresh" then
        addon.Bars:RefreshAll()
        print("|cff00ff00HandyBar:|r Bars refreshed.")
        
    elseif command == "toggle" then
        local barID = tonumber(args)
        if barID and addon.db.bars[barID] then
            addon.db.bars[barID].enabled = not addon.db.bars[barID].enabled
            addon.Bars:UpdateBarVisibility(barID)
            local status = addon.db.bars[barID].enabled and "enabled" or "disabled"
            print("|cff00ff00HandyBar:|r Bar " .. barID .. " " .. status .. ".")
        else
            print("|cffff0000HandyBar:|r Invalid bar ID. Usage: /handybar toggle <barID>")
        end
        
    elseif command == "createcat" then
        local key, name = args:match("^(%S+)%s+(.+)$")
        if key and name then
            if addon.Categories:CreateCustomCategory(key, name, "Custom category") then
                print("|cff00ff00HandyBar:|r Category created: " .. name)
            end
        else
            print("|cffff0000HandyBar:|r Usage: /handybar createcat <key> <name>")
        end
        
    elseif command == "deletecat" then
        local key = args:match("^(%S+)$")
        if key then
            if addon.Categories:DeleteCustomCategory(key) then
                print("|cff00ff00HandyBar:|r Category deleted: " .. key)
                addon.Bars:RefreshAll()
            else
                print("|cffff0000HandyBar:|r Category not found or cannot be deleted: " .. key)
            end
        else
            print("|cffff0000HandyBar:|r Usage: /handybar deletecat <key>")
        end
        
    elseif command == "additem" then
        local catKey, itemID = args:match("^(%S+)%s+(%d+)$")
        if catKey and itemID then
            itemID = tonumber(itemID)
            if addon.Categories:AddItemToCategory(catKey, itemID) then
                print("|cff00ff00HandyBar:|r Item " .. itemID .. " added to category: " .. catKey)
                addon.Bars:RefreshAll()
            else
                print("|cffff0000HandyBar:|r Failed to add item to category.")
            end
        else
            print("|cffff0000HandyBar:|r Usage: /handybar additem <categoryKey> <itemID>")
        end
        
    elseif command == "removeitem" then
        local catKey, itemID = args:match("^(%S+)%s+(%d+)$")
        if catKey and itemID then
            itemID = tonumber(itemID)
            if addon.Categories:RemoveItemFromCategory(catKey, itemID) then
                print("|cff00ff00HandyBar:|r Item " .. itemID .. " removed from category: " .. catKey)
                addon.Bars:RefreshAll()
            else
                print("|cffff0000HandyBar:|r Failed to remove item from category.")
            end
        else
            print("|cffff0000HandyBar:|r Usage: /handybar removeitem <categoryKey> <itemID>")
        end
        
    elseif command == "help" then
        print("|cff00ff00HandyBar Commands:|r")
        print("  Aliases: /handybar, /handy, /hbar")
        print("  /handybar - Open options")
        print("  /handybar reset - Reset to defaults")
        print("  /handybar import|export - Import/Export configuration")
        print("  /handybar refresh - Refresh all bars")
        print("  /handybar toggle <barID> - Toggle bar visibility")
        print("  /handybar createcat <key> <name> - Create custom category")
        print("  /handybar deletecat <key> - Delete custom category")
        print("  /handybar additem <categoryKey> <itemID> - Add item to category")
        print("  /handybar removeitem <categoryKey> <itemID> - Remove item from category")
        
    else
        print("|cffff0000HandyBar:|r Unknown command. Type /handybar help for help.")
    end
end

-- Version info
addon.version = "1.0.0"
addon.author = "YourName"
