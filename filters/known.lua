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

function filter:AddItem(index, link)
	self.linkList[link] = index
end

function filter:ClearAll()
	VladsVendorFilterMixin.ClearAll(self)

	table.wipe(self.linkList)
end

function filter:IsFiltered(index, link)
	return not self.alreadyknown and self:IsKnown(link)
end

function filter:IsRelevant()
	local numKnown = 0
	local nunUnknown = 0

	for link in pairs(self.linkList) do
		if self:IsKnown(link) then
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

if not VladsVendorListTooltipMixin then
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
frame:RegisterEvent("NEW_RECIPE_LEARNED")
frame:RegisterEvent("COMPANION_LEARNED")
frame:RegisterEvent("COMPANION_UNLEARNED")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:SetScript("OnEvent", function()
	for k, v in pairs(cache) do
		if v == false then
			rawset(cache, k, nil)
		end
	end
end)
