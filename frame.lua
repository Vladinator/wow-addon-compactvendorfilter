VladsVendorFilterMenuFrameMixin = {}

local VladsVendorFilterMenuFrameEvents = {
	"ADDON_LOADED",
	"MERCHANT_SHOW",
	"MERCHANT_CLOSED",
}

function VladsVendorFilterMenuFrameMixin:OnLoad()
	FrameUtil.RegisterFrameForEvents(self, VladsVendorFilterMenuFrameEvents)

	self.Filters = {}

	self.DropdownInfo = {}
	self.DropdownSortedFilters = {}

	self.VendorOpen = false

	UIDropDownMenu_SetInitializeFunction(self, self.DropdownInitialize)

	VladsVendorDataProvider:RegisterCallback(VladsVendorDataProvider.Event.OnMerchantUpdate, function(_, isReady) if isReady then self:RefreshFrames() end end)
end

function VladsVendorFilterMenuFrameMixin:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		self:SetupAddOnSupport()
	elseif event == "MERCHANT_SHOW" then
		self.npc = UnitGUID("npc")
		if self.prevNPC and self.prevNPC ~= self.npc then self:OnEvent("MERCHANT_CLOSED") end
		self.prevNPC = self.npc
		self.VendorOpen = true
		self:RefreshFrames()
	elseif event == "MERCHANT_CLOSED" then
		self.VendorOpen = false
		for k, filter in pairs(self.Filters) do
			filter:ClearAll()
		end
		CloseDropDownMenus()
	end
end

function VladsVendorFilterMenuFrameMixin:AddFilter(filter)
	assert(type(filter) == "table", "CompactVendorFilter AddFilter requires a valid filter.")

	assert(type(filter.name) == "string", "CompactVendorFilter AddFilter requires a filter name.")
	assert(type(filter.defaults) == "table", "CompactVendorFilter AddFilter requires filter defaults.")

	assert(type(filter.OnLoad) == "function", "CompactVendorFilter AddFilter requires a filter object with a OnLoad method.")
	assert(type(filter.ResetFilter) == "function", "CompactVendorFilter AddFilter requires a filter object with a ResetFilter method.")
	assert(type(filter.FilterAll) == "function", "CompactVendorFilter AddFilter requires a filter object with a FilterAll method.")
	assert(type(filter.ShowAll) == "function", "CompactVendorFilter AddFilter requires a filter object with a ShowAll method.")
	assert(type(filter.AddItem) == "function", "CompactVendorFilter AddFilter requires a filter object with a AddItem method.")
	assert(type(filter.ClearAll) == "function", "CompactVendorFilter AddFilter requires a filter object with a ClearAll method.")
	assert(type(filter.IsFiltered) == "function", "CompactVendorFilter AddFilter requires a filter object with a IsFiltered method.")
	assert(type(filter.IsRelevant) == "function", "CompactVendorFilter AddFilter requires a filter object with a IsRelevant method.")
	assert(type(filter.GetDropdown) == "function", "CompactVendorFilter AddFilter requires a filter object with a GetDropdown method.")

	filter:OnLoad(self)
	self.Filters[filter.name] = filter
end

function VladsVendorFilterMenuFrameMixin:RefreshDropdown()
	ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
	ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
	self:RefreshFrames()
end

function VladsVendorFilterMenuFrameMixin:RefreshFrames()
	local items = VladsVendorDataProvider:GetMerchantItems()
	for _, itemData in ipairs(items) do
		if not itemData:IsPending() then
			for _, filter in pairs(self.Filters) do
				filter:AddItem(itemData)
			end
		end
	end
	VladsVendorDataProvider:ApplyFilters(self.Filters)
end

function VladsVendorFilterMenuFrameMixin:DropdownInitialize(level)
	if not level then
		return
	end

	if not self.Button then
		self.Button = _G.VladsVendorFilterMenuButton
	end

	if level == 1 then
		local sorted = self.DropdownSortedFilters
		table.wipe(sorted)

		local sortedIndex = 0
		for k in pairs(self.Filters) do
			sortedIndex = sortedIndex + 1
			sorted[sortedIndex] = k
		end
		table.sort(sorted)

		local info = self:GetDropdownInfo(true)
		info.notCheckable = true
		info.isTitle = true
		info.keepShownOnClick = true

		for i = 1, sortedIndex do
			local filterKey = sorted[i]
			local filter = self.Filters[filterKey]
			if filter:IsRelevant() then
				info.text = NORMAL_FONT_COLOR_CODE .. filter.name
				UIDropDownMenu_AddButton(info, level)

				filter:GetDropdown(level)
			end
		end

		info.notCheckable = true
		info.isTitle = nil
		info.disabled = nil

		info.text = GREEN_FONT_COLOR_CODE .. COMBAT_LOG_MENU_EVERYTHING
		info.func = function()
			for k, filter in pairs(self.Filters) do
				filter:ShowAll()
			end
			self:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)

		info.text = NORMAL_FONT_COLOR_CODE .. RESET
		info.func = function()
			for k, filter in pairs(self.Filters) do
				filter:ResetFilter()
			end
			self:RefreshDropdown()
		end
		UIDropDownMenu_AddButton(info, level)

		info.text = CLOSE
		info.func = function()
			if self == UIDROPDOWNMENU_OPEN_MENU then
				CloseDropDownMenus()
			end
		end
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 then
		for k, filter in pairs(self.Filters) do
			filter:GetDropdown(level)
		end
	end
end

function VladsVendorFilterMenuFrameMixin:GetDropdownInfo(reset)
	local info = self.DropdownInfo
	return reset and table.wipe(info) or info
end

function VladsVendorFilterMenuFrameMixin:SetupAddOnSupport()
	if IsAddOnLoaded("ElvUI") then
		self:SetupElvUI()
	end
end

function VladsVendorFilterMenuFrameMixin:SetupElvUI()
	if self.setupElvUI then
		return
	end

	local E = ElvUI and ElvUI[1]
	local S = E and E:GetModule("Skins")

	if not S then
		return
	end

	if not E.Border or not S.ArrowRotation then
		return
	end

	local button = self:GetParent()
	S:HandleButton(button)
	button:SetSize(20, 20)

	button.Icon:SetRotation(S.ArrowRotation['down'])
	button.Icon:Show()

	self.setupElvUI = true
end
