local filter = CreateFromMixins(VladsVendorFilterMixin)

local qualities = {}

for i = 0, 8 do
	local r, g, b, hex = GetItemQualityColor(i)
	qualities[i] = {
		index = i,
		text = _G["ITEM_QUALITY" .. i .. "_DESC"],
		r = r, g = g, b = b, hex = hex,
	}
end

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.qualities = {}
	self.qualities_filtered = {}
	self.qualitiesChecked = false

	self.options = self.defaults.options
end

function filter:ResetFilter()
	table.wipe(self.qualities_filtered)

	for q, v in ipairs(self.options) do
		self.qualities_filtered[q] = v
	end
end

function filter:FilterAll()
	if self:IsRelevant() then
		for _, q in pairs(qualities) do
			self.qualities_filtered[q.index] = true
		end
	end
end

function filter:ShowAll()
	table.wipe(self.qualities_filtered)
end

function filter:AddItem(itemData)
	if not itemData.quality then
		return
	end
	self.qualities[itemData.quality] = true
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.qualities)
end

function filter:IsFiltered(itemData)
	if next(self.qualities_filtered) then
		if not itemData.quality then
			return
		end
		return not self.qualities_filtered[itemData.quality]
	end
	return false
end

function filter:IsRelevant()
	local count = 0

	for k in pairs(self.qualities) do
		count = count + 1

		if count > 1 then
			return true
		end
	end

	return false
end

local info = {}
local itemtypesorted = {}

function filter:GetDropdown(level)
	table.wipe(info)
	table.wipe(itemtypesorted)

	info.keepShownOnClick = true

	if level == 1 then

		info.text = QUALITY
		info.value = QUALITY
		info.hasArrow = true
		info.arg1 = nil
		info.checked = nil
		info.isNotRadio = nil
		info.func = function()
			local b
			if self.qualitiesChecked then
				b = nil
			else
				b = true
			end
			self.qualitiesChecked = b
			for q in pairs(self.qualities) do
				self.qualities_filtered[q] = b
			end
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 and QUALITY == UIDROPDOWNMENU_MENU_VALUE then

		for q in pairs(self.qualities) do
			itemtypesorted[#itemtypesorted + 1] = q
		end
		table.sort(itemtypesorted)

		for i = 1, #itemtypesorted do
			local itemtype = itemtypesorted[i]
			local quality = qualities[itemtype]
			info.text = "|c" .. quality.hex .. quality.text
			info.value = nil
			info.hasArrow = false
			info.arg1 = itemtype
			info.checked = self.qualities_filtered[itemtype]
			info.isNotRadio = true
			info.func = function(button, arg1)
				if self.qualities_filtered[arg1] then
					self.qualities_filtered[arg1] = nil
				else
					self.qualities_filtered[arg1] = true
				end
				self.parent:RefreshFrames()
			end
			UIDropDownMenu_AddButton(info, level)
		end

	end
end

filter.name = "Quality"
filter.defaults = { options = {} }
_G.VladsVendorFilterMenuFrame:AddFilter(filter)
