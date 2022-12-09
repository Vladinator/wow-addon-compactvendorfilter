local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.linkList = {}

	self.usable = self.defaults.usable
end

function filter:ResetFilter()
	self.usable = self.defaults.usable
end

function filter:FilterAll()
	if self:IsRelevant() then
		self.usable = true
	end
end

function filter:ShowAll()
	self.usable = false
end

function filter:AddItem(itemData)
	self.linkList[itemData.index] = itemData
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.linkList)
end

function filter:IsFiltered(itemData)
	if not self.usable then
		return false
	end
	return not itemData.isUsable
end

function filter:IsRelevant()
	local usable = 0
	local unusable = 0

	for _, itemData in pairs(self.linkList) do
		if itemData.isUsable then
			usable = usable + 1
		else
			unusable = unusable + 1
		end

		if usable > 0 and unusable > 0 then
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
		info.text = USABLE_ITEMS
		info.checked = self.usable
		info.isNotRadio = true
		info.func = function()
			self.usable = not self.usable
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

filter.name = "Usable"
filter.defaults = { usable = false }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)
