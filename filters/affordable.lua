local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.affordablelist = {}
	self.notaffordablelist = {}

	self.affordable = self.defaults.affordable
end

function filter:ResetFilter()
	self.affordable = self.defaults.affordable
end

function filter:FilterAll()
	if self:IsRelevant() then
		self.affordable = true
	end
end

function filter:ShowAll()
	self.affordable = false
end

function filter:AddItem(itemData)
	if itemData.canAfford ~= false then
		self.affordablelist[itemData.index] = true
	else
		self.notaffordablelist[itemData.index] = true
	end
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.affordablelist)
	table.wipe(self.notaffordablelist)
end

function filter:IsFiltered(itemData)
	if self.affordable then
		return self.notaffordablelist[itemData.index]
	else
		return false
	end
end

function filter:IsRelevant()
	return next(self.affordablelist) and next(self.notaffordablelist)
end

local info = {}

function filter:GetDropdown(level)
	table.wipe(info)

	info.keepShownOnClick = true

	if level == 1 then
		info.text = self.name
		info.checked = self.affordable
		info.isNotRadio = true
		info.func = function()
			self.affordable = not self.affordable
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

filter.name = "Affordable"
filter.defaults = { affordable = false }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)
