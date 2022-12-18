local CompactVendorFilterDropDownTemplate = CompactVendorFilterDropDownTemplate ---@type CompactVendorFilterDropDownTemplate

local IsCollected do

    local Model = CreateFrame("DressUpModel")

    local InventorySlots = {
        ["INVTYPE_HEAD"] = 1,
        ["INVTYPE_NECK"] = 2,
        ["INVTYPE_SHOULDER"] = 3,
        ["INVTYPE_BODY"] = 4,
        ["INVTYPE_CHEST"] = 5,
        ["INVTYPE_ROBE"] = 5,
        ["INVTYPE_WAIST"] = 6,
        ["INVTYPE_LEGS"] = 7,
        ["INVTYPE_FEET"] = 8,
        ["INVTYPE_WRIST"] = 9,
        ["INVTYPE_HAND"] = 10,
        ["INVTYPE_CLOAK"] = 15,
        ["INVTYPE_WEAPON"] = 16,
        ["INVTYPE_SHIELD"] = 17,
        ["INVTYPE_2HWEAPON"] = 16,
        ["INVTYPE_WEAPONMAINHAND"] = 16,
        ["INVTYPE_RANGED"] = 16,
        ["INVTYPE_RANGEDRIGHT"] = 16,
        ["INVTYPE_WEAPONOFFHAND"] = 17,
        ["INVTYPE_HOLDABLE"] = 17,
        ["INVTYPE_TABARD"] = 19,
    }

    ---@param itemLinkOrID any
    function IsCollected(itemLinkOrID)
        local itemID, _, _, slotName = GetItemInfoInstant(itemLinkOrID)
        if not slotName then
            return
        end
        local slot = InventorySlots[slotName]
        if not slot then
            return
        end
        if itemLinkOrID == itemID then
            itemLinkOrID = format("item:%d", itemID)
        end
        if not C_Item.IsDressableItemByID(itemLinkOrID) then
            return
        end
        Model:SetUnit("player")
        Model:Undress()
        Model:TryOn(itemLinkOrID, slot) ---@diagnostic disable-line: redundant-parameter
        local sourceID ---@type number?
        ---@diagnostic disable-next-line: undefined-field
        if Model.GetItemTransmogInfo then
            local sourceInfo = Model:GetItemTransmogInfo(slot) ---@diagnostic disable-line: undefined-field
            sourceID = sourceInfo and sourceInfo.appearanceID
        else
            sourceID = Model:GetSlotTransmogSources(slot)
        end
        if not sourceID then
            return
        end
        local categoryID, appearanceID, canEnchant, texture, isCollected, itemLink = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
        return isCollected
    end

end

local filter = CompactVendorFilterDropDownTemplate:New(
    "Appearance", {},
    "itemLink", {},
    function(self)
        local items = self.parent:GetMerchantItems()
        local itemDataKey = self.itemDataKey
        local values = self.values
        local options = self.options
        table.wipe(values)
        for _, itemData in ipairs(items) do
            local itemLink = itemData[itemDataKey]
            local value = IsCollected(itemLink)
            if value ~= nil then
                values[value] = true
            end
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
            option.text = value and TRANSMOG_COLLECTED or NOT_COLLECTED
            option.show = true
            if option.checked == nil then
                option.checked = true
            end
        end
    end,
    function(_, itemLink)
        return IsCollected(itemLink)
    end,
    function(_, value, itemValue)
        if itemValue == nil then
            return
        end
        return value == itemValue
    end
)

filter:Publish()
