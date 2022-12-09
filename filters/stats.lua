local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.itemstat = {}
	self.itemstat_filtered_EX = {}
	self.itemstatChecked_EX = false
	self.itemstat_filtered_IN = {}
	self.itemstatChecked_IN = false

	self.options = self.defaults.options
	self.include = self.defaults.include
	self.exclude = self.defaults.exclude
end

function filter:ResetFilter()
	table.wipe(self.itemstat_filtered_EX)
	for q, v in pairs(self.include) do
		self.itemstat_filtered_EX[q] = v
	end
	table.wipe(self.itemstat_filtered_IN)
	for q, v in pairs(self.exclude) do
		self.itemstat_filtered_IN[q] = v
	end
end

function filter:FilterAll()
	if self:IsRelevant() then
		for i in pairs(self.options) do
			self.itemstat_filtered_EX[i] = true
		end
	end
end

function filter:ShowAll()
	table.wipe(self.itemstat_filtered_EX)
	table.wipe(self.itemstat_filtered_IN)
end

local tempStats = {}

function filter:AddItem(itemData)
	table.wipe(tempStats)
	GetItemStats(itemData.itemLink, tempStats)
	for stat in pairs(tempStats) do
		if _G[stat] then
			self.itemstat[stat] = true
		end
		self.options[stat] = true
	end
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.itemstat)
end

function filter:IsFiltered(itemData)
	table.wipe(tempStats)
	GetItemStats(itemData.itemLink, tempStats)
	for stat in pairs(tempStats) do
		if self.itemstat_filtered_EX[stat] then
			return true
		end
	end
	if next(self.itemstat_filtered_IN) then
		for stat in pairs(tempStats) do
			if self.itemstat_filtered_IN[stat] then
				return false
			end
		end
		return true
	end
	return false
end

function filter:IsRelevant()
	local count = 0

	for k in pairs(self.itemstat) do
		count = count + 1

		if count > 1 then
			return true
		end
	end

	return false
end

local info = {}
local itemtypesorted = {}
local itemtypesortedL = {}

function filter:GetDropdown(level)
	table.wipe(info)
	table.wipe(itemtypesorted)

	info.keepShownOnClick = true

	if level == 1 then

		info.text = "Want:"
		info.value = "Inclusive_Stats"
		info.hasArrow = true
		info.checked = nil
		info.isNotRadio = nil
		info.func = function()
			local b
			if self.itemstatChecked_IN then
				b = nil
			else
				b = true
			end
			self.itemstatChecked_IN = b
			for el in pairs(self.itemstat) do
				self.itemstat_filtered_IN[el] = b
				if b then
					self.itemstat_filtered_EX[el] = nil
				end
			end
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)

		info.text = "Don't Want:"
		info.value = "Exclusive_Stats"
		info.hasArrow = true
		info.checked = nil
		info.isNotRadio = nil
		info.func = function()
			local b
			if self.itemstatChecked_EX then
				b = nil
			else
				b = true
			end
			self.itemstatChecked_EX = b
			for el in pairs(self.itemstat) do
				self.itemstat_filtered_EX[el] = b
				if b then
					self.itemstat_filtered_IN[el] = nil
				end
			end
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 and (("Exclusive_Stats" == UIDROPDOWNMENU_MENU_VALUE) or ("Inclusive_Stats" == UIDROPDOWNMENU_MENU_VALUE)) then

		for l in pairs(self.itemstat) do
			local L = _G[l]
			if L then
				itemtypesorted[#itemtypesorted + 1] = L
				itemtypesortedL[L] = l
			end
		end
		table.sort(itemtypesorted)

		if "Exclusive_Stats" == UIDROPDOWNMENU_MENU_VALUE then
			for i = 1, #itemtypesorted do
				local itemtype = itemtypesorted[i]
				info.text = itemtype
				info.arg1 = itemtypesortedL[itemtype]
				info.checked = self.itemstat_filtered_EX[itemtypesortedL[itemtype]]
				info.isNotRadio = true
				info.func = function(button, arg1)
					if self.itemstat_filtered_EX[arg1] then
						self.itemstat_filtered_EX[arg1] = nil
					else
						self.itemstat_filtered_EX[arg1] = true
						self.itemstat_filtered_IN[arg1] = nil
					end
					self.parent:RefreshFrames()
				end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif "Inclusive_Stats" == UIDROPDOWNMENU_MENU_VALUE then
			for i = 1, #itemtypesorted do
				local itemtype = itemtypesorted[i]
				info.text = itemtype
				info.arg1 = itemtypesortedL[itemtype]
				info.checked = self.itemstat_filtered_IN[itemtypesortedL[itemtype]]
				info.isNotRadio = true
				info.func = function(button, arg1)
					if self.itemstat_filtered_IN[arg1] then
						self.itemstat_filtered_IN[arg1] = nil
					else
						self.itemstat_filtered_IN[arg1] = true
						self.itemstat_filtered_EX[arg1] = nil
					end
					self.parent:RefreshFrames()
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end

	end
end

filter.name = "Stats"
filter.defaults = { options = {}, include = {}, exclude = {} }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)
