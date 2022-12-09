if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
	return
end

local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.linkList = {}

	self.alreadycollected = self.defaults.alreadycollected
end

function filter:ResetFilter()
	self.alreadycollected = self.defaults.alreadycollected
end

function filter:FilterAll()
	if self:IsRelevant() then
		self.alreadycollected = false
	end
end

function filter:ShowAll()
	self.alreadycollected = true
end

function filter:AddItem(itemData)
	self.linkList[itemData.index] = itemData
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.linkList)
end

function filter:IsFiltered(itemData)
	return not self.alreadycollected and self:IsCollected(itemData.itemLink)
end

function filter:IsRelevant()
	local numKnown = 0
	local numUnknown = 0

	for _, itemData in pairs(self.linkList) do
		if self:IsCollected(itemData.itemLink) then
			numKnown = numKnown + 1
		else
			numUnknown = numUnknown + 1
		end

		if numKnown > 0 and numUnknown > 0 then
			return true
		end
	end

	return false
end

local info = {}

function filter:GetDropdown(level)
	table.wipe(info)

	info.keepShownOnClick = true

	if level == 1 then
		info.text = TRANSMOG_COLLECTED
		info.checked = self.alreadycollected
		info.isNotRadio = true
		info.func = function()
			self.alreadycollected = not self.alreadycollected
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

filter.name = "Appearance"
filter.defaults = { alreadycollected = true }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)

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
	-- ["INVTYPE_TABARD"] = 19,
}

function filter:IsCollected(item)
	local itemID, _, _, slotName = GetItemInfoInstant(item)
	if item == itemID then
		item = "item:" .. itemID
	end
	local slot = InventorySlots[slotName]
	if not slot or not C_Item.IsDressableItemByID(item) then return end
	Model:SetUnit("player")
	Model:Undress()
	Model:TryOn(item, slot)
	local sourceID
	if Model.GetItemTransmogInfo then
		local sourceInfo = Model:GetItemTransmogInfo(slot)
		sourceID = sourceInfo and sourceInfo.appearanceID
	else
		sourceID = Model:GetSlotTransmogSources(slot)
	end
	if not sourceID then return end
	local categoryID, appearanceID, canEnchant, texture, isCollected, itemLink = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	return isCollected -- return appearanceID, sourceID, isCollected
end
