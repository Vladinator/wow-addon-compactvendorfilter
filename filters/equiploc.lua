local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.equipLoc = {}
	self.equipLoc_filtered = {}
	self.equipLocChecked = false

	self.options = self.defaults.options
end

function filter:ResetFilter()
	table.wipe(self.equipLoc_filtered)
	for q, v in pairs(self.options) do
		self.equipLoc_filtered[q] = v
	end
end

function filter:FilterAll()
	if self:IsRelevant() then
		for i in pairs(self.options) do
			self.equipLoc_filtered[i] = true
		end
	end
end

function filter:ShowAll()
	table.wipe(self.equipLoc_filtered)
end

function filter:AddItem(itemData)
	local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemData.itemLink)
	if not itemEquipLoc then
		return
	end
	if _G[itemEquipLoc] then
		self.equipLoc[itemEquipLoc] = true
	end
	-- self.options[itemEquipLoc] = true -- TODO: changed the default to true instead of nil/not checked state
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.equipLoc)
end

function filter:IsFiltered(itemData)
	if next(self.equipLoc_filtered) then
		local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemData.itemLink)
		if not itemEquipLoc then
			return
		end
		return not self.equipLoc_filtered[itemEquipLoc]
	end
	return false
end

function filter:IsRelevant()
	local count = 0

	for k in pairs(self.equipLoc) do
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
local dupes = {}

function filter:GetDropdown(level)
	table.wipe(info)
	table.wipe(itemtypesorted)
	table.wipe(dupes)

	info.keepShownOnClick = true

	if level == 1 then

		for l in pairs(self.options) do
			local Lo = _G[l]
			if Lo then
				itemtypesorted[#itemtypesorted + 1] = Lo
				itemtypesortedL[Lo] = l
			end
		end
		table.sort(itemtypesorted)

		info.text = ITEMSLOTTEXT
		info.arg1 = nil
		info.value = ITEMSLOTTEXT
		info.hasArrow = true
		info.checked = nil
		info.isNotRadio = nil
		-- info.hasArrow = true
		-- info.checked = nil
		-- info.isNotRadio = true
		info.func = function()
			local b
			if self.equipLocChecked then
				b = nil
			else
				b = true
			end
			self.equipLocChecked = b
			for el in pairs(self.equipLoc) do
				self.equipLoc_filtered[el] = b
			end
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 and ITEMSLOTTEXT == UIDROPDOWNMENU_MENU_VALUE then

		for l in pairs(self.equipLoc) do
			local L = _G[l]
			if L and not dupes[L] then
				dupes[L] = true
				itemtypesorted[#itemtypesorted + 1] = L
				itemtypesortedL[L] = l
			end
		end
		table.sort(itemtypesorted)

		for i = 1, #itemtypesorted do
			local itemtype = itemtypesorted[i]
			local itemtypeL = itemtypesortedL[itemtype]
			info.text = itemtype
			info.arg1 = itemtypesortedL[itemtype]
			info.checked = self.equipLoc_filtered[itemtypeL]
			info.isNotRadio = true
			info.func = function(button, arg1)
				if self.equipLoc_filtered[arg1] then
					self.equipLoc_filtered[arg1] = nil
				else
					self.equipLoc_filtered[arg1] = true
				end
				self.parent:RefreshFrames()
			end
			UIDropDownMenu_AddButton(info, level)
		end

	end
end

filter.name = "Slot"
filter.defaults = { options = {} }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)
