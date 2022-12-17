local CompactVendorFilterTemplate = CompactVendorFilterTemplate ---@type CompactVendorFilterTemplate

local filter = CompactVendorFilterTemplate:New() ---@class CompactVendorFilterCollected : CompactVendorFilterTemplate

filter.name = "Collected"

filter.defaults = {
    showCollected = false,
}

---@param parent CompactVendorFilterFrameTemplate
function filter:OnLoad(parent)
    CompactVendorFilterTemplate.OnLoad(self, parent)
    self.items = {} ---@type MerchantItem[]
    self:ResetFilter()
end

function filter:ResetFilter()
    self.showCollected = self.defaults.showCollected
end

function filter:FilterAll()
    if not self:IsRelevant() then
        return
    end
    self.showCollected = false
end

function filter:ShowAll()
    self.showCollected = true
end

---@param itemData MerchantItem
function filter:AddItem(itemData)
    self.items[itemData.index] = itemData
end

function filter:ClearAll()
    CompactVendorFilterTemplate.ClearAll(self)
    table.wipe(self.items)
end

---@param itemData MerchantItem
function filter:IsFiltered(itemData)
    if itemData.isCollected == nil then
        return
    end
    return not self.showCollected and itemData.isCollected
end

function filter:IsRelevant()
    local known = false
    local unknown = false
    for _, itemData in pairs(self.items) do
        if itemData.isCollected ~= nil then
            if itemData.isCollected then
                known = true
            else
                unknown = true
            end
            if known and unknown then
                return true
            end
        end
    end
    return false
end

filter:Publish()
