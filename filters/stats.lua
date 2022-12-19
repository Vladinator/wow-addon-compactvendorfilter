local CompactVendorFilterDropDownTemplate = CompactVendorFilterDropDownTemplate ---@type CompactVendorFilterDropDownTemplate

---@alias StatTablePolyfill table<string, number>

---@type StatTablePolyfill
local statTable = setmetatable({}, { __index = { temp = { link = "", show = 0, hide = 0 } } })

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
            local itemLink = itemData[itemDataKey] ---@type string
            GetItemStats(itemLink, statTable)
            for statKey, _ in pairs(statTable) do
                values[statKey] = true
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
            option.text = tostring(_G[value])
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
    ---@param value string?
    ---@param itemValue StatTablePolyfill
    function(_, value, itemValue, itemData)
        local temp = itemValue.temp ---@type any
        if temp.link ~= itemData.itemLink then
            temp.link = itemData.itemLink
            temp.show = 0
            temp.hide = 0
        end
        local total = 0
        local found = 0
        for statKey, _ in pairs(itemValue) do
            total = total + 1
            if statKey == value then
                found = found + 1
            end
        end
        if total == 0 then
            return true
        elseif found == 0 then
            temp.hide = temp.hide + 1
        else
            temp.show = temp.show + 1
        end
        found = temp.show + temp.hide
        if found ~= total then
            return
        end
        return temp.show ~= 0 -- TODO
    end
)

filter:Publish()
