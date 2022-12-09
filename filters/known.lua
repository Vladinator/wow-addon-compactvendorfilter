local filter = CreateFromMixins(VladsVendorFilterMixin)

function filter:OnLoad(parent)
	VladsVendorFilterMixin.OnLoad(self, parent)

	self.linkList = {}

	self.alreadyknown = self.defaults.alreadyknown
end

function filter:ResetFilter()
	self.alreadyknown = self.defaults.alreadyknown
end

function filter:FilterAll()
	if self:IsRelevant() then
		self.alreadyknown = false
	end
end

function filter:ShowAll()
	self.alreadyknown = true
end

function filter:AddItem(itemData)
	self.linkList[itemData.index] = itemData
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.linkList)
end

function filter:IsFiltered(itemData)
	return not self.alreadyknown and self:IsKnown(itemData.itemLink)
end

function filter:IsRelevant()
	local numKnown = 0
	local nunUnknown = 0

	for _, itemData in pairs(self.linkList) do
		if self:IsKnown(itemData.itemLink) then
			numKnown = numKnown + 1
		else
			nunUnknown = nunUnknown + 1
		end

		if numKnown > 0 and nunUnknown > 0 then
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
		info.text = ITEM_SPELL_KNOWN
		info.checked = self.alreadyknown
		info.isNotRadio = true
		info.func = function()
			self.alreadyknown = not self.alreadyknown
			self.parent:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

filter.name = "Known"
filter.defaults = { alreadyknown = false }

local VladsVendorListTooltipMixin = _G.VladsVendorListTooltipMixin

if not VladsVendorListTooltipMixin then -- TODO: remove dependency CompactVendor shouldn't be required if someone wants to use the Filter module alone
	return
end

_G.VladsVendorFilterMenuFrame:AddFilter(filter)

local band = bit.band
local bor = bit.bor
local RecipeMask = VladsVendorListTooltipMixin.RecipeMask

local cache = {}
setmetatable(cache, { __mode = "kv" })

function filter:TooltipCallbackInstant(tip)
	local known = false
	local collected = false

	for i = 1, tip:NumLines(), 1 do
		local textLeft = tip.L[i]
		local colorLeft = tip.LC[i]
		local lineType, canUse = VladsVendorListTooltipMixin:TooltipTextParse(textLeft, colorLeft)
		if lineType == 4 and not canUse then known = true end
		if lineType == 5 and not canUse then collected = true end
	end

	return known or collected, known, collected
end

function filter:IsKnown(link)
	local temp = cache[link]
	if temp ~= nil then
		return temp
	end
	local known = VladsVendorListTooltipMixin:TooltipScanInstant(self, link)
	rawset(cache, link, known)
	return known
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("NEW_RECIPE_LEARNED")
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	frame:RegisterEvent("TOYS_UPDATED")
	frame:RegisterEvent("HEIRLOOMS_UPDATED")
	frame:RegisterEvent("PET_JOURNAL_PET_DELETED")
	frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
	frame:RegisterEvent("NEW_MOUNT_ADDED")
	frame:RegisterEvent("COMPANION_UPDATE")
	frame:RegisterEvent("COMPANION_LEARNED")
	frame:RegisterEvent("COMPANION_UNLEARNED")
end
frame:SetScript("OnEvent", function()
	for k, v in pairs(cache) do
		if v == false then
			rawset(cache, k, nil)
		end
	end
end)
