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

function filter:AddItem(index, link)
	self.linkList[link] = index
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.linkList)
end

function filter:IsFiltered(index, link)
	return not self.alreadycollected and self:IsCollected(link)
end

function filter:IsRelevant()
	local numKnown = 0
	local numUnknown = 0

	for link in pairs(self.linkList) do
		if self:IsCollected(link) then
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

function filter:IsCollected(link)
	local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(link)
	if not appearanceID then
		return
	end
	local sources = C_TransmogCollection.GetAppearanceSources(appearanceID)
	if not sources then
		return
	end
	for _, v in pairs(sources) do
		if v.isCollected then
			return true
		end
	end
	return false
end
