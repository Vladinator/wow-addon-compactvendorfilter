local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.types = {}
	self.types_filtered = {}
	self.subtypes = {}
	self.subtypes_filtered = {}

	self.options = filter.defaults.options
end

function filter:ResetFilter()
	for k, _ in pairs(self.types) do
		self.types[k] = nil
	end
	for k, _ in pairs(self.types_filtered) do
		self.types_filtered[k] = nil
	end
	for k, _ in pairs(self.subtypes) do
		for l, _ in pairs(self.subtypes[k]) do
			self.subtypes[k][l] = nil
		end
	end
	for k, _ in pairs(self.subtypes_filtered) do
		for l, _ in pairs(self.subtypes_filtered[k]) do
			self.subtypes_filtered[k][l] = nil
		end
	end
	table.wipe(self.options)
	local items = VladsVendorDataProvider:GetMerchantItems(function(itemData) return not itemData:IsPending() end)
	for _, itemData in ipairs(items) do
		self:AddItem(itemData)
	end
end

function filter:FilterAll()
	if self:IsRelevant() then
		for t, tTable in pairs(self.types) do
			for st in pairs(tTable) do
				self.subtypes_filtered[t] = self.subtypes_filtered[t] or {}
				self.subtypes_filtered[t][st] = true
			end
			self.types_filtered[t] = true
		end
	end
end

function filter:ShowAll()
	self:ResetFilter()
end

function filter:AddItem(itemData)
	local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemData.itemLink)
	if not itemType or not itemSubType then
		return
	end

	self.types[itemType] = true
	self.subtypes[itemType] = self.subtypes[itemType] or {}
	self.subtypes[itemType][itemSubType] = true

	self.options[itemType] = self.options[itemType] or {}
	self.options[itemType][itemSubType] = true
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)
end

function filter:IsFiltered(itemData)
	local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemData.itemLink)
	if not itemType or not itemSubType then
		return
	end

	local subfilters
	for k, v in pairs(self.subtypes_filtered) do
		if next(v) then
			subfilters = true
			break
		end
	end

	if next(self.types_filtered) or subfilters then
		if self.types_filtered[itemType] or (self.subtypes_filtered[itemType] and self.subtypes_filtered[itemType][itemSubType]) then
			return false
		else
			return true
		end
	else
		return false
	end
end

function filter:IsRelevant()
	local numTypes = 0

	for t in pairs(self.types) do
		numTypes = numTypes + 1
		if numTypes > 1 then
			return true
		end

		local numSubTypes = 0
		for st in pairs(self.subtypes[t]) do
			numSubTypes = numSubTypes + 1
			if numSubTypes > 1 then
				return true
			end
		end
	end

	return false
end

local function CountTableEntries(t)
	local count = 0
	if t then
		for k in pairs(t) do
			count = count + 1
		end
	end
	return count
end

local info = {}
local itemtypesorted = {}

function filter:GetDropdown(level)
	table.wipe(info)
	table.wipe(itemtypesorted)

	info.keepShownOnClick = true

	if level == 1 then

		for t in pairs(self.options) do
			itemtypesorted[#itemtypesorted + 1] = t
		end
		table.sort(itemtypesorted)

		for i = 1, #itemtypesorted do
			local itemtype = itemtypesorted[i]

			info.arg1 = itemtype
			info.value = itemtype
			info.text = itemtype
			info.hasArrow = true
			info.checked = nil
			info.isNotRadio = nil
			-- info.hasArrow = CountTableEntries(self.subtypes[itemtype]) > 1
			-- info.checked = false -- self.types_filtered[itemtype]
			-- info.isNotRadio = true
			info.func = function(button, arg1)
				local b
				if self.types_filtered[arg1] then
					b = nil
				else
					b = true
				end
				self.types_filtered[arg1] = b
				if self.subtypes[arg1] then
					for st in pairs(self.subtypes[arg1]) do
						self.subtypes_filtered[arg1] = self.subtypes_filtered[arg1] or {}
						self.subtypes_filtered[arg1][st] = b
					end
				end
				self.parent:RefreshDropdown()
			end
			UIDropDownMenu_AddButton(info, level)
		end

	elseif level == 2 and self.subtypes[UIDROPDOWNMENU_MENU_VALUE] then

		for st in pairs(self.subtypes[UIDROPDOWNMENU_MENU_VALUE]) do
			itemtypesorted[#itemtypesorted + 1] = st
		end
		table.sort(itemtypesorted)

		for i = 1, #itemtypesorted do
			local itemtype = itemtypesorted[i]

			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = itemtype
			info.value = itemtype
			info.hasArrow = false

			info.text = itemtype
			info.checked = self.subtypes_filtered[UIDROPDOWNMENU_MENU_VALUE] and self.subtypes_filtered[UIDROPDOWNMENU_MENU_VALUE][itemtype]
			info.isNotRadio = true
			info.func = function(button, arg1, arg2)
				self.subtypes_filtered[arg1] = self.subtypes_filtered[arg1] or {}
				if self.subtypes_filtered[arg1][arg2] then
					self.subtypes_filtered[arg1][arg2] = nil
				else
					self.subtypes_filtered[arg1][arg2] = true
				end
				self.parent:RefreshFrames()
			end
			UIDropDownMenu_AddButton(info, level)
		end

	end
end

filter.name = "Type"
filter.defaults = { options = {} }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)
