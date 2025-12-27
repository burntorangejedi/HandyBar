local addonName, addon = ...

addon.Categories = {}

-- Pre-defined category definitions
local predefinedCategories = {
    potions = {
        name = "Potions",
        description = "Health and Mana potions",
        items = {
            -- Item IDs will be populated dynamically
        },
        filters = {
            itemType = LE_ITEM_CLASS_CONSUMABLE,
            itemSubType = LE_ITEM_CONSUMABLE_POTION,
            keywords = {"Potion"},
        }
    },
    flasks = {
        name = "Flasks",
        description = "Flasks and Elixirs",
        items = {},
        filters = {
            itemType = LE_ITEM_CLASS_CONSUMABLE,
            itemSubType = LE_ITEM_CONSUMABLE_FLASK,
            keywords = {"Flask", "Elixir"},
        }
    },
    food = {
        name = "Food & Drink",
        description = "Food and Drink items",
        items = {},
        filters = {
            itemType = LE_ITEM_CLASS_CONSUMABLE,
            itemSubType = LE_ITEM_CONSUMABLE_FOOD_AND_DRINK,
            keywords = {"Food", "Drink"},
        }
    },
    openables = {
        name = "Openables",
        description = "Containers and openable items",
        items = {},
        filters = {
            keywords = {"Coffer", "Cache", "Chest", "Box", "Container", "Pouch", "Satchel"},
        }
    },
    professionItems = {
        name = "Profession Items",
        description = "Profession tools and materials",
        items = {},
        filters = {
            itemType = LE_ITEM_CLASS_TRADESKILL,
            keywords = {"Tool", "Thread", "Dye"},
        }
    },
    questItems = {
        name = "Quest Items",
        description = "Quest-related items",
        items = {},
        filters = {
            itemType = LE_ITEM_CLASS_QUESTITEM,
        }
    },
    toys = {
        name = "Toys",
        description = "Toy items",
        items = {},
        filters = {
            itemType = LE_ITEM_CLASS_MISCELLANEOUS,
            isToy = true,
        }
    },
    bandages = {
        name = "Bandages",
        description = "First Aid bandages",
        items = {},
        filters = {
            itemType = LE_ITEM_CLASS_CONSUMABLE,
            keywords = {"Bandage"},
        }
    },
}

function addon.Categories:Initialize()
    -- Copy predefined categories to DB if not already there
    if not addon.db.categories then
        addon.db.categories = {}
    end
    
    for key, data in pairs(predefinedCategories) do
        if not addon.db.categories[key] then
            addon.db.categories[key] = {
                name = data.name,
                description = data.description,
                items = {},
                filters = data.filters,
                isPredefined = true,
            }
        end
    end
    
    if not addon.db.customCategories then
        addon.db.customCategories = {}
    end
end

function addon.Categories:GetCategory(categoryKey)
    return addon.db.categories[categoryKey] or addon.db.customCategories[categoryKey]
end

function addon.Categories:GetAllCategories()
    local all = {}
    for k, v in pairs(addon.db.categories) do
        all[k] = v
    end
    for k, v in pairs(addon.db.customCategories) do
        all[k] = v
    end
    return all
end

function addon.Categories:CreateCustomCategory(key, name, description)
    if addon.db.categories[key] or addon.db.customCategories[key] then
        print("|cffff0000HandyBar:|r Category key already exists: " .. key)
        return false
    end
    
    addon.db.customCategories[key] = {
        name = name,
        description = description,
        items = {},
        filters = {},
        isCustom = true,
    }
    
    return true
end

function addon.Categories:DeleteCustomCategory(key)
    if addon.db.customCategories[key] then
        addon.db.customCategories[key] = nil
        
        -- Remove from any bars using it
        for barID, barData in pairs(addon.db.bars) do
            for i = #barData.categories, 1, -1 do
                if barData.categories[i] == key then
                    table.remove(barData.categories, i)
                end
            end
        end
        
        return true
    end
    return false
end

function addon.Categories:AddItemToCategory(categoryKey, itemID)
    local category = self:GetCategory(categoryKey)
    if not category then
        return false
    end
    
    -- Check if item already exists
    for _, id in ipairs(category.items) do
        if id == itemID then
            return true
        end
    end
    
    table.insert(category.items, itemID)
    return true
end

function addon.Categories:RemoveItemFromCategory(categoryKey, itemID)
    local category = self:GetCategory(categoryKey)
    if not category then
        return false
    end
    
    for i, id in ipairs(category.items) do
        if id == itemID then
            table.remove(category.items, i)
            return true
        end
    end
    
    return false
end

function addon.Categories:ScanBagsForCategory(categoryKey)
    local category = self:GetCategory(categoryKey)
    if not category then
        return {}
    end
    
    local foundItems = {}
    
    -- Scan all bags
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then
                local itemID = info.itemID
                
                -- Check if item matches category filters or is in items list
                if self:ItemMatchesCategory(itemID, category) then
                    table.insert(foundItems, {
                        itemID = itemID,
                        bag = bag,
                        slot = slot,
                    })
                end
            end
        end
    end
    
    return foundItems
end

function addon.Categories:ItemMatchesCategory(itemID, category)
    -- Check if item is explicitly listed
    for _, id in ipairs(category.items) do
        if id == itemID then
            return true
        end
    end
    
    -- Check filters
    if category.filters then
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, 
              itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID = 
              GetItemInfo(itemID)
        
        if not itemName then
            return false
        end
        
        -- Check item type
        if category.filters.itemType and classID ~= category.filters.itemType then
            return false
        end
        
        -- Check item subtype
        if category.filters.itemSubType and subclassID ~= category.filters.itemSubType then
            return false
        end
        
        -- Check keywords
        if category.filters.keywords then
            local found = false
            for _, keyword in ipairs(category.filters.keywords) do
                if itemName:find(keyword) then
                    found = true
                    break
                end
            end
            if not found then
                return false
            end
        end
        
        -- Check if toy
        if category.filters.isToy then
            if not C_ToyBox.GetToyInfo(itemID) then
                return false
            end
        end
        
        return true
    end
    
    return false
end

function addon.Categories:GetPredefinedKeys()
    local keys = {}
    for k, v in pairs(predefinedCategories) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end
