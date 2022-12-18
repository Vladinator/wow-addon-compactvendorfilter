local CompactVendorFilterDropDownTemplate = CompactVendorFilterDropDownTemplate ---@type CompactVendorFilterDropDownTemplate

local statTable = {}

local filter = CompactVendorFilterDropDownTemplate:New(
    "Stats", {},
    "itemLink", {},
    function(self)
        local items = self.parent:GetMerchantItems()
        local itemDataKey = self.itemDataKey
        local values = self.values
        local options = self.options
        table.wipe(values)
        for _, itemData in ipairs(items) do
            local itemLink = itemData[itemDataKey]
            GetItemStats(itemLink, statTable)
            for statKey, _ in pairs(statTable) do
                local statText = _G[statKey]
                values[statText] = true
            end
            table.wipe(statTable)
        end
        for _, option in ipairs(options) do
            option.show = false
        end
        for value, _ in pairs(values) do
            local option = self:GetOption(value)
            if not option then
                option = {}
                options[#options + 1] = option
            end
            option.value = value
            option.text = tostring(value)
            option.show = true
            if option.checked == nil then
                option.checked = true
            end
        end
    end,
    function(_, itemLink)
        GetItemStats(itemLink, statTable)
        return statTable
    end,
    function(_, value, itemValue)
        local count = 0
        for statKey, _ in pairs(itemValue) do
            local statText = _G[statKey]
            if statText == value then
                return false
            end
            count = count + 1
        end
        return count ~= 0
    end
)

-- filter:Publish()
