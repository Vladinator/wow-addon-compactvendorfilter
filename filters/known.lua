local CompactVendorFilterTemplate = CompactVendorFilterTemplate ---@type CompactVendorFilterTemplate

local filter = CompactVendorFilterTemplate:New() ---@class CompactVendorFilterKnown : CompactVendorFilterTemplate

filter.name = "Known"

filter.defaults = {
    showKnown = false,
}

---@param parent CompactVendorFilterFrameTemplate
function filter:OnLoad(parent)
    CompactVendorFilterTemplate.OnLoad(self, parent)
    self.items = {} ---@type MerchantItem[]
    self:ResetFilter()
end

function filter:ResetFilter()
    self.showKnown = self.defaults.showCollected
end

function filter:FilterAll()
    if not self:IsRelevant() then
        return
    end
    self.showKnown = false
end

function filter:ShowAll()
    self.showKnown = true
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
    if itemData.isLearned == nil then
        return
    end
    return not self.showKnown and itemData.isLearned
end

function filter:IsRelevant()
    local known = false
    local unknown = false
    for _, itemData in pairs(self.items) do
        if itemData.isLearned ~= nil then
            if itemData.isLearned then
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
