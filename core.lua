---@alias MerchantItem MerchantItemPolyfill
---@alias MerchantScanner Region
---@alias MerchantItemCostType number
---@alias MerchantItemAvailabilityType number
---@alias MerchantItemCostItem any[]
---@alias TooltipItem any
---@alias ItemRequirement any

---@class MerchantItemPolyfill
---@field public parent MerchantScanner
---@field public index number
---@field public name? string
---@field public texture number|string
---@field public price number
---@field public stackCount number
---@field public numAvailable number
---@field public isPurchasable boolean
---@field public isUsable boolean
---@field public extendedCost number
---@field public currencyID? number
---@field public spellID? number
---@field public canAfford boolean
---@field public costType MerchantItemCostType
---@field public itemLink? string
---@field public merchantItemID? number
---@field public itemLinkOrID? string|number
---@field public isHeirloom boolean
---@field public isKnownHeirloom boolean
---@field public showNonrefundablePrompt boolean
---@field public tintRed boolean
---@field public availabilityType MerchantItemAvailabilityType
---@field public extendedCostCount number
---@field public extendedCostItems MerchantItemCostItem[]
---@field public quality? number
---@field public itemID number
---@field public itemType string
---@field public itemSubType string
---@field public itemEquipLoc string
---@field public itemTexture number|string
---@field public itemClassID number
---@field public itemSubClassID number
---@field public maxStackCount? number
---@field public isLearnable? boolean
---@field public tooltipScannable? boolean
---@field public tooltipData? TooltipItem
---@field public canLearn? boolean
---@field public canLearnRequirement? ItemRequirement
---@field public isLearned? boolean
---@field public isCollected? boolean
---@field public isCollectedNum? number
---@field public isCollectedNumMax? number

---@class DropdownInfoPolyfill
---@field public notCheckable boolean?
---@field public isTitle boolean?
---@field public disabled boolean?
---@field public text string
---@field public func fun()

local CloseDropDownMenus = CloseDropDownMenus ---@type fun(level?: number)
local ToggleDropDownMenu = ToggleDropDownMenu ---@type fun(level?: number, value?: any, dropDownFrame?: Region, anchorName?: Region, xOffset?: number, yOffset?: number, menuList?: table, button?: string, autoHideDelay?: boolean)
local UIDropDownMenu_SetInitializeFunction = UIDropDownMenu_SetInitializeFunction ---@type fun(self: Region, init: fun())
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton ---@type fun(info: DropdownInfoPolyfill, level?: number)

---@class CompactVendorFilterButtonTemplate
local CompactVendorFilterButtonTemplate do

    ---@class CompactVendorFilterButtonTemplate : Button
    ---@field public Icon Texture
    ---@field public All Texture

    CompactVendorFilterButtonTemplate = {}
    _G.CompactVendorFilterButtonTemplate = CompactVendorFilterButtonTemplate

    function CompactVendorFilterButtonTemplate:OnLoad()
        C_Timer.After(0.01, function() self.Menu = CompactVendorFilterFrame end) -- HOTFIX: the template XML loads after the frame runs this code so the reference isn't available just yet
        self:SetParent(MerchantFrameCloseButton)
        self:RegisterForClicks("LeftButtonUp")
        self:SetPoint("RIGHT", MerchantFrameCloseButton, "LEFT", 8 - 4, 0)
        self:SetScale(0.85)
        hooksecurefunc("MerchantFrame_Update", function() self:SetShown(MerchantFrame.selectedTab == 1) end)
    end

    function CompactVendorFilterButtonTemplate:OnEnter()
        self.IsOnButton = true
        self.IsShown = self:IsDropDownShown()
    end

    function CompactVendorFilterButtonTemplate:OnLeave()
        self.IsOnButton = false
        self.IsShown = self:IsDropDownShown()
    end

    function CompactVendorFilterButtonTemplate:OnMouseDown()
        if self.IsOnButton and self.IsShown then
            self.IsShown = false
            CloseDropDownMenus()
        else
            self.IsShown = true
            ToggleDropDownMenu(1, nil, self.Menu, self, 0, 0)
        end
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
    end

    function CompactVendorFilterButtonTemplate:IsDropDownShown()
        return DropDownList1.dropdown == self.Menu and DropDownList1:IsShown()
    end

end

---@class CompactVendorFilterFrameTemplate
local CompactVendorFilterFrameTemplate do

    ---@class CompactVendorFilterFrameTemplate : Frame

    CompactVendorFilterFrameTemplate = {}
    _G.CompactVendorFilterFrameTemplate = CompactVendorFilterFrameTemplate

    ---@type WowEvent[]
    CompactVendorFilterFrameTemplate.Events = {
        "ADDON_LOADED",
        "MERCHANT_SHOW",
        "MERCHANT_CLOSED",
    }

    function CompactVendorFilterFrameTemplate:OnLoad()
        self.MerchantDataProvider = CompactVendorFrame.ScrollBox:GetDataProvider()
        self.Button = CompactVendorFilterButton
        self:SetParent(self.Button)
        self:SetFrameStrata("HIGH")
        self:SetToplevel(true)
        self:EnableMouse(true)
        self:Hide()
        FrameUtil.RegisterFrameForEvents(self, self.Events)
        self.Filters = {} ---@type table<string, CompactVendorFilterTemplate>
        self.DropdownInfo = {} ---@type DropdownInfoPolyfill
        self.DropdownSortedFilters = {} ---@type string[]
        self.VendorOpen = false
        UIDropDownMenu_SetInitializeFunction(self, self.DropdownInitialize)
    end

    ---@param event WowEvent
    ---@param ... any
    function CompactVendorFilterFrameTemplate:OnEvent(event, ...)
        if event == "ADDON_LOADED" then
            self:SetupAddOnSupport()
        elseif event == "MERCHANT_SHOW" then
            self:MerchantOpen()
        elseif event == "MERCHANT_CLOSED" then
            self:MerchantClose()
        end
    end

    function CompactVendorFilterFrameTemplate:MerchantOpen()
        self.VendorOpen = true
        self:Refresh()
    end

    function CompactVendorFilterFrameTemplate:MerchantClose()
		self.VendorOpen = false
		for _, filter in pairs(self.Filters) do
			filter:ClearAll()
		end
		CloseDropDownMenus()
    end

    ---@param filter CompactVendorFilterTemplate
    function CompactVendorFilterFrameTemplate:AddFilter(filter)
        assert(type(filter) == "table", "CompactVendorFilter AddFilter requires a valid filter object.")
        assert(type(filter.name) == "string", "CompactVendorFilter AddFilter requires a filter name.")
        assert(type(filter.defaults) == "table", "CompactVendorFilter AddFilter requires filter defaults.")
        assert(type(filter.OnLoad) == "function", "CompactVendorFilter AddFilter requires a filter object with a OnLoad method.")
        assert(type(filter.ClearAll) == "function", "CompactVendorFilter AddFilter requires a filter object with a ClearAll method.")
        assert(type(filter.ResetFilter) == "function", "CompactVendorFilter AddFilter requires a filter object with a ResetFilter method.")
        assert(type(filter.ShowAll) == "function", "CompactVendorFilter AddFilter requires a filter object with a ShowAll method.")
        assert(type(filter.FilterAll) == "function", "CompactVendorFilter AddFilter requires a filter object with a FilterAll method.")
        assert(type(filter.IsRelevant) == "function", "CompactVendorFilter AddFilter requires a filter object with a IsRelevant method.")
        assert(type(filter.GetDropdown) == "function", "CompactVendorFilter AddFilter requires a filter object with a GetDropdown method.")
        assert(type(filter.IsFiltered) == "function", "CompactVendorFilter AddFilter requires a filter object with a IsFiltered method.")
        filter:OnLoad(self)
        self.Filters[filter.name] = filter
        self.MerchantDataProvider:AddFilter(function(...) return filter:IsFiltered(...) end)
        return true
    end

    function CompactVendorFilterFrameTemplate:RefreshDropdown()
        ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
        ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
        self:Refresh()
    end

    function CompactVendorFilterFrameTemplate:Refresh()
        for _, filter in pairs(self.Filters) do
            if not filter:IsRelevant() then
                filter:ShowAll()
            end
        end
        self.MerchantDataProvider:Refresh()
    end

    ---@return MerchantItem[] items
    function CompactVendorFilterFrameTemplate:GetMerchantItems()
        return self.MerchantDataProvider:GetMerchantItems()
    end

    ---@param level number?
    function CompactVendorFilterFrameTemplate:DropdownInitialize(level)
        if not level then
            return
        end
        if level == 1 then
            local sorted = self.DropdownSortedFilters
            table.wipe(sorted)
            local index = 0
            for name, _ in pairs(self.Filters) do
                index = index + 1
                sorted[index] = name
            end
            table.sort(sorted)
            local info = self:GetDropdownInfo(true)
            info.notCheckable = true
            info.isTitle = true
            info.keepShownOnClick = true
            for i = 1, index do
                local name = sorted[i]
                local filter = self.Filters[name]
                if filter:IsRelevant() then
                    info.text = format("%s%s%s", NORMAL_FONT_COLOR_CODE, filter.name, FONT_COLOR_CODE_CLOSE)
                    UIDropDownMenu_AddButton(info, level)
                    filter:GetDropdown(level)
                end
            end
            info.notCheckable = true
            info.isTitle = nil
            info.disabled = nil
            info.text = format("%s%s%s", GREEN_FONT_COLOR_CODE, COMBAT_LOG_MENU_EVERYTHING, FONT_COLOR_CODE_CLOSE)
            ---@diagnostic disable-next-line: duplicate-set-field
            info.func = function()
                for _, filter in pairs(self.Filters) do
                    filter:ShowAll()
                end
                self:RefreshDropdown()
            end
            UIDropDownMenu_AddButton(info, level)
            info.text = format("%s%s%s", NORMAL_FONT_COLOR_CODE, RESET, FONT_COLOR_CODE_CLOSE)
            ---@diagnostic disable-next-line: duplicate-set-field
            info.func = function()
                for _, filter in pairs(self.Filters) do
                    if filter:IsRelevant() then
                        filter:ResetFilter()
                    end
                end
                self:RefreshDropdown()
            end
            UIDropDownMenu_AddButton(info, level)
            info.text = CLOSE
            ---@diagnostic disable-next-line: duplicate-set-field
            info.func = function()
                if self == UIDROPDOWNMENU_OPEN_MENU then
                    CloseDropDownMenus()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        elseif level == 2 then
            for _, filter in pairs(self.Filters) do
                if filter:IsRelevant() then
                    filter:GetDropdown(level)
                end
            end
        end
    end

    function CompactVendorFilterFrameTemplate:GetDropdownInfo(reset)
        local info = self.DropdownInfo
        if reset then
            table.wipe(info)
        end
        return info
    end

    function CompactVendorFilterFrameTemplate:SetupAddOnSupport()
        if IsAddOnLoaded("ElvUI") then
            self:SetupElvUI()
        end
    end

    function CompactVendorFilterFrameTemplate:SetupElvUI()
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
        ---@type Button
        local button = self:GetParent() ---@diagnostic disable-line: assign-type-mismatch
        S:HandleButton(button)
        button:SetSize(20, 20)
        button.Icon:SetRotation(S.ArrowRotation["down"]) ---@diagnostic disable-line: undefined-field
        button.Icon:Show() ---@diagnostic disable-line: undefined-field
        self.setupElvUI = true
    end

end

---@class CompactVendorFilterTemplate
local CompactVendorFilterTemplate do

    ---@alias CompactVendorFilterTemplateDefaults table

    ---@class CompactVendorFilterTemplate
    ---@field public parent CompactVendorFilterFrameTemplate
    ---@field public name string
    ---@field public defaults CompactVendorFilterTemplateDefaults

    CompactVendorFilterTemplate = {}
    _G.CompactVendorFilterTemplate = CompactVendorFilterTemplate

    ---@param parent CompactVendorFilterFrameTemplate
    function CompactVendorFilterTemplate:OnLoad(parent)
        self.parent = parent
        if self.defaults == nil then
            self.defaults = {}
        end
        self:ResetFilter()
    end

    function CompactVendorFilterTemplate:ClearAll()
        self:ResetFilter()
    end

    function CompactVendorFilterTemplate:ResetFilter()
    end

    function CompactVendorFilterTemplate:ShowAll()
    end

    function CompactVendorFilterTemplate:FilterAll()
    end

    function CompactVendorFilterTemplate:IsRelevant()
        return true
    end

    ---@param level number
    function CompactVendorFilterTemplate:GetDropdown(level)
    end

    ---@param itemData MerchantItem
    ---@return boolean? isFiltered #The return should be `nil` if the filter is not relevant to this item, so the item doesn't get filtered, otherwise `true` or `false` is expected.
    function CompactVendorFilterTemplate:IsFiltered(itemData)
        return false
    end

    ---@param name string?
    ---@param defaults CompactVendorFilterTemplateDefaults?
    function CompactVendorFilterTemplate:New(name, defaults)
        local filter = {} ---@type CompactVendorFilterTemplate
        Mixin(filter, self)
        if name ~= nil then
            filter.name = name
        end
        if defaults ~= nil then
            filter.defaults = defaults
        end
        return filter
    end

    function CompactVendorFilterTemplate:Publish()
        CompactVendorFilterFrame:AddFilter(self)
    end

end

---@class CompactVendorFilterToggleTemplate
local CompactVendorFilterToggleTemplate do

    ---@alias CompactVendorFilterToggleTemplateIsChecked fun(self: CompactVendorFilterToggleTemplate): boolean?

    ---@class CompactVendorFilterToggleTemplate : CompactVendorFilterTemplate
    ---@field public key string
    ---@field public itemDataKey string
    ---@field public isChecked? CompactVendorFilterToggleTemplateIsChecked
    ---@field public isLogicReversed? boolean
    ---@field public isCheckLogicReversed? boolean

    CompactVendorFilterToggleTemplate = {}
    _G.CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate

    Mixin(CompactVendorFilterToggleTemplate, CompactVendorFilterTemplate)

    ---@type CompactVendorFilterToggleTemplateIsChecked
    function CompactVendorFilterToggleTemplate:IsCheckedFallback()
        local option = self[self.key]
        if self.isLogicReversed then
            return option
        end
        return not option
    end

    function CompactVendorFilterToggleTemplate:ResetFilter()
        CompactVendorFilterTemplate.ResetFilter(self)
        self[self.key] = self.defaults[self.key]
    end

    function CompactVendorFilterToggleTemplate:FilterAll()
        CompactVendorFilterTemplate.FilterAll(self)
        self[self.key] = self.isLogicReversed
    end

    function CompactVendorFilterToggleTemplate:ShowAll()
        CompactVendorFilterTemplate.FilterAll(self)
        self[self.key] = not self.isLogicReversed
    end

    ---@param itemData MerchantItem
    function CompactVendorFilterToggleTemplate:IsFiltered(itemData)
        local value = itemData[self.itemDataKey]
        if value == nil then
            return
        end
        local option = self:isChecked()
        return not option and value
    end

    function CompactVendorFilterToggleTemplate:IsRelevant()
        local items = self.parent:GetMerchantItems()
        local enabled = true
        local disabled = true
        for _, itemData in pairs(items) do
            local value = itemData[self.itemDataKey]
            if value ~= nil then
                if self.isLogicReversed then
                    value = not value
                end
                if value then
                    enabled = true
                else
                    disabled = true
                end
                if enabled and disabled then
                    return true
                end
            end
        end
        return false
    end

    ---@param level number
    function CompactVendorFilterToggleTemplate:GetDropdown(level)
        if level ~= 1 then
            return
        end
        local info = {} ---@type DropdownInfoPolyfill
        info.keepShownOnClick = true
        info.isNotRadio = true
        info.text = self.name
        if self.isCheckLogicReversed then
            info.checked = not self:isChecked()
        else
            info.checked = self:isChecked()
        end
        info.func = function()
            self[self.key] = not self[self.key]
            self.parent:RefreshDropdown()
        end
        UIDropDownMenu_AddButton(info, level)
    end

    ---@param name string?
    ---@param defaults CompactVendorFilterTemplateDefaults?
    ---@param key string
    ---@param itemDataKey string
    ---@param isChecked CompactVendorFilterToggleTemplateIsChecked?
    ---@param isLogicReversed boolean?
    ---@param isCheckLogicReversed boolean?
    function CompactVendorFilterToggleTemplate:New(name, defaults, key, itemDataKey, isChecked, isLogicReversed, isCheckLogicReversed)
        ---@type CompactVendorFilterToggleTemplate
        local filter = CompactVendorFilterTemplate:New(name, defaults) ---@diagnostic disable-line: assign-type-mismatch
        Mixin(filter, self)
        filter.key = key
        filter.itemDataKey = itemDataKey
        filter.isChecked = isChecked or filter.IsCheckedFallback
        filter.isLogicReversed = isLogicReversed
        filter.isCheckLogicReversed = isCheckLogicReversed ~= false
        return filter
    end

end

---@class CompactVendorFilterDropDownTemplate
local CompactVendorFilterDropDownTemplate do

    ---@class CompactVendorFilterDropDownTemplate : CompactVendorFilterTemplate
    ---@field public test? boolean

    CompactVendorFilterDropDownTemplate = {}
    _G.CompactVendorFilterDropDownTemplate = CompactVendorFilterDropDownTemplate

    ---@param name string?
    ---@param defaults CompactVendorFilterTemplateDefaults?
    ---@param test boolean?
    function CompactVendorFilterDropDownTemplate:New(name, defaults, test)
        ---@type CompactVendorFilterDropDownTemplate
        local filter = CompactVendorFilterTemplate:New(name, defaults) ---@diagnostic disable-line: assign-type-mismatch
        Mixin(filter, self)
        if test ~= nil then
            filter.test = test
        end
        return filter
    end

end
