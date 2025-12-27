local addonName, addon = ...

-- Default database structure
local defaults = {
    profile = {
        bars = {
            [1] = {
                enabled = true,
                name = "Bar 1",
                categories = {"potions", "flasks"},
                displayRules = {
                    inCombat = false,
                    outOfCombat = false,
                    onMouseover = false,
                },
                buttonSize = 36,
                buttonsPerRow = 12,
                spacing = 2,
                alpha = 1.0,
            },
        },
        numBars = 1,
        categories = {
            -- Pre-defined categories will be added in Categories.lua
        },
        customCategories = {
            -- User-defined categories
        },
    }
}

-- Database management
addon.DB = {}

function addon.DB:Initialize()
    -- Initialize saved variables
    if not HandyBarDB then
        HandyBarDB = {}
    end
    
    -- Set up profile
    if not HandyBarDB.profile then
        HandyBarDB.profile = self:CopyTable(defaults.profile)
    else
        -- Merge with defaults to add any new fields
        HandyBarDB.profile = self:MergeDefaults(HandyBarDB.profile, defaults.profile)
    end
    
    addon.db = HandyBarDB.profile
end

function addon.DB:Reset()
    HandyBarDB.profile = self:CopyTable(defaults.profile)
    addon.db = HandyBarDB.profile
    
    -- Reinitialize everything
    if addon.Bars then
        addon.Bars:RefreshAll()
    end
    
    print("|cff00ff00HandyBar:|r Configuration reset to defaults.")
end

function addon.DB:CopyTable(src, dest)
    dest = dest or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = self:CopyTable(v)
        else
            dest[k] = v
        end
    end
    return dest
end

function addon.DB:MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = self:CopyTable(v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            target[k] = self:MergeDefaults(target[k], v)
        end
    end
    return target
end

function addon.DB:GetDefaults()
    return defaults
end

function addon.DB:EnsureBarExists(barID)
    if not addon.db.bars[barID] then
        addon.db.bars[barID] = {
            enabled = true,
            name = "Bar " .. barID,
            categories = {},
            displayRules = {
                inCombat = false,
                outOfCombat = false,
                onMouseover = false,
            },
            buttonSize = 36,
            buttonsPerRow = 12,
            spacing = 2,
            alpha = 1.0,
        }
    end
end
