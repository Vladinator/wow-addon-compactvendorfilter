VladsVendorFilterMenuFrameMixin = {}

local VladsVendorFilterMenuFrameEvents = {
	"MERCHANT_SHOW",
	"MERCHANT_CLOSED",
}

function VladsVendorFilterMenuFrameMixin:OnLoad()
	FrameUtil.RegisterFrameForEvents(self, VladsVendorFilterMenuFrameEvents)

	self.Filters = {}

	self.IndexLookupCount = 0
	self.IndexLookup = {}

	self.EnableHooks = true
	self.HookedGameTooltip = {}

	self.DropdownInfo = {}
	self.DropdownSortedFilters = {}

	self.VendorOpen = false

	UIDropDownMenu_SetInitializeFunction(self, self.DropdownInitialize)

	self:SetupFirstHook()
end

function VladsVendorFilterMenuFrameMixin:OnEvent(event, arg1)
	if arg1 == "CVF_UPDATE" then
		return
	end
	if event == "MERCHANT_SHOW" then
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

function VladsVendorFilterMenuFrameMixin:SetupFirstHook()
	self.GetMerchantNumItems = _G.GetMerchantNumItems

	_G.GetMerchantNumItems = function()
		return self:GenerateIndexLookup()
	end
end

function VladsVendorFilterMenuFrameMixin:SetupHooks()
	for k, v in pairs({
		-- supports hook disables
		CanAffordMerchantItem = 1,
		GetMerchantItemCostInfo = 1,
		GetMerchantItemCostItem = 1,
		GetMerchantItemInfo = 1,
		GetMerchantItemLink = 1,
		GetMerchantItemMaxStack = 1,
		-- doesn't support hook disables
		BuyMerchantItem = 2,
		PickupMerchantItem = 2,
		ShowMerchantSellCursor = 2,
	}) do
		self[k] = _G[k]

		if v == 1 then
			_G[k] = function(i, ...)
				if not self.EnableHooks then
					return self[k](i, ...)
				else
					local index = self.IndexLookup[i]
					if index then
						return self[k](index, ...)
					end
				end
			end
		elseif v == 2 then
			_G[k] = function(i, ...)
				local index = self.IndexLookup[i]
				if index then
					return self[k](index, ...)
				end
			end
		end
	end

	self.C_MerchantFrame_IsMerchantItemRefundable = _G.C_MerchantFrame.IsMerchantItemRefundable

	_G.C_MerchantFrame.IsMerchantItemRefundable = function(i, ...)
		if not self.EnableHooks then
			return self.C_MerchantFrame_IsMerchantItemRefundable(i, ...)
		else
			local index = self.IndexLookup[i]
			if index then
				return self.C_MerchantFrame_IsMerchantItemRefundable(index, ...)
			end
		end
	end

	self.GameTooltip_SetMerchantItem = _G.GameTooltip.SetMerchantItem
	self.GameTooltip_SetMerchantCostItem = _G.GameTooltip.SetMerchantCostItem

	local function SetMerchantItem(tip, i, ...)
		self.EnableHooks = false
		self.GameTooltip_SetMerchantItem(tip, self.IndexLookup[i], ...)
		self.EnableHooks = true
	end

	local function SetMerchantCostItem(tip, i, ...)
		self.EnableHooks = false
		self.GameTooltip_SetMerchantCostItem(tip, self.IndexLookup[i], ...)
		self.EnableHooks = true
	end

	local frame = EnumerateFrames()
	while frame do
		if frame:GetObjectType() == "GameTooltip" and not self.HookedGameTooltip[frame] then
			self.HookedGameTooltip[frame] = true
			frame.SetMerchantItem = SetMerchantItem
			frame.SetMerchantCostItem = SetMerchantCostItem
		end
		frame = EnumerateFrames(frame)
	end
end

function VladsVendorFilterMenuFrameMixin:GenerateIndexLookup()
	if self.SetupHooks then
		self:SetupHooks()
		self.SetupHooks = nil
	end

	local allDisplayed = true
	local filtered

	table.wipe(self.IndexLookup)

	self.IndexLookupCount = 0
	self.IndexLookup[self.IndexLookupCount] = 0

	-- local debugTemp = 0 -- DEBUG
	-- local debugAddItem = 0 -- DEBUG
	-- local debugIsFiltered = 0 -- DEBUG
	-- local debugIsRelevant = 0 -- DEBUG

	for i = 1, self.GetMerchantNumItems(), 1 do
		local link = self.GetMerchantItemLink(i)

		if link then
			filtered = nil

			for k, filter in pairs(self.Filters) do
				-- debugTemp = GetTimePreciseSec() -- DEBUG
				filter:AddItem(i, link)
				-- debugAddItem = debugAddItem + (GetTimePreciseSec() - debugTemp) -- DEBUG
			end
		end
	end

	for i = 1, self.GetMerchantNumItems(), 1 do
		local link = self.GetMerchantItemLink(i)

		if link then
			filtered = nil

			for k, filter in pairs(self.Filters) do
				-- debugTemp = GetTimePreciseSec() -- DEBUG
				if filter:IsFiltered(i, link) then
					-- debugIsFiltered = debugIsFiltered + (GetTimePreciseSec() - debugTemp) -- DEBUG
					-- debugTemp = GetTimePreciseSec() -- DEBUG
					if filter:IsRelevant() then
						filtered = true
					end
					-- debugIsRelevant = debugIsRelevant + (GetTimePreciseSec() - debugTemp) -- DEBUG
				else
					-- debugIsFiltered = debugIsFiltered + (GetTimePreciseSec() - debugTemp) -- DEBUG
				end
			end

			if filtered then
				allDisplayed = false
			else
				self.IndexLookupCount = self.IndexLookupCount + 1
				self.IndexLookup[self.IndexLookupCount] = i
			end

		else
			self.IndexLookupCount = self.IndexLookupCount + 1
			self.IndexLookup[self.IndexLookupCount] = i
		end
	end

	-- print(format("AddItem %.4f IsFiltered %.4f IsRelevant %.4f", debugAddItem, debugIsFiltered, debugIsRelevant)) -- DEBUG

	return self.IndexLookupCount
end

function VladsVendorFilterMenuFrameMixin:RefreshDropdown()
	ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
	ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
	self:RefreshFrames()
end

function VladsVendorFilterMenuFrameMixin:RefreshFrames()
	local frame = EnumerateFrames()
	while frame do
		if frame:IsEventRegistered("MERCHANT_SHOW") then
			local func = frame:GetScript("OnEvent")
			if func then
				func(frame, "MERCHANT_SHOW", "CVF_UPDATE")
			end
		end
		if frame:IsEventRegistered("MERCHANT_UPDATE") then
			local func = frame:GetScript("OnEvent")
			if func then
				func(frame, "MERCHANT_UPDATE", "CVF_UPDATE")
			end
		end
		frame = EnumerateFrames(frame)
	end
	self:GenerateIndexLookup()
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
