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
        self.Menu = CompactVendorFilterFrame
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
        self.Button = CompactVendorFilterButton
        self:SetParent(self.Button)
        self:SetFrameStrata("HIGH")
        self:SetToplevel(true)
        self:EnableMouse(true)
        self:Hide()
        FrameUtil.RegisterFrameForEvents(self, self.Events)
        self.Filters = {}
        self.DropdownInfo = {} ---@type DropdownInfoPolyfill
        self.DropdownSortedFilters = {}
        self.VendorOpen = false
        UIDropDownMenu_SetInitializeFunction(self, self.DropdownInitialize)
        MerchantDataProvider:RegisterCallback(MerchantDataProvider.Event.OnUpdate, function(_, isReady) if not isReady then return end self:RefreshFrames() end)
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
        self:RefreshFrames()
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
        return true
    end

    function CompactVendorFilterFrameTemplate:RefreshDropdown()
        ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
        ToggleDropDownMenu(1, nil, self, self.Button, 0, 0)
        self:RefreshFrames()
    end

    function CompactVendorFilterFrameTemplate:RefreshFrames()
        print("RefreshFrames()") -- TODO: DEPRECATED?
    end

    function CompactVendorFilterFrameTemplate:DropdownInitialize(level)
        if not level then
            return
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
            ---@diagnostic disable-next-line: duplicate-set-field
            info.func = function()
                for k, filter in pairs(self.Filters) do
                    filter:ShowAll()
                end
                self:RefreshDropdown()
            end
            UIDropDownMenu_AddButton(info, level)
            info.text = NORMAL_FONT_COLOR_CODE .. RESET
            ---@diagnostic disable-next-line: duplicate-set-field
            info.func = function()
                for k, filter in pairs(self.Filters) do
                    filter:ResetFilter()
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
            for k, filter in pairs(self.Filters) do
                filter:GetDropdown(level)
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

    ---@class CompactVendorFilterTemplate
    ---@field public parent CompactVendorFilterFrameTemplate
    ---@field public name string
    ---@field public defaults table

    CompactVendorFilterTemplate = {}
    _G.CompactVendorFilterTemplate = CompactVendorFilterTemplate

    ---@param parent CompactVendorFilterFrameTemplate
    function CompactVendorFilterTemplate:OnLoad(parent)
        self.parent = parent
    end

    function CompactVendorFilterTemplate:ResetFilter()
    end

    function CompactVendorFilterTemplate:FilterAll()
    end

    function CompactVendorFilterTemplate:ShowAll()
    end

    ---@param itemData MerchantItem
    function CompactVendorFilterTemplate:AddItem(itemData)
    end

    function CompactVendorFilterTemplate:ClearAll()
        self:ResetFilter()
    end

    ---@param itemData MerchantItem
    function CompactVendorFilterTemplate:IsFiltered(itemData)
        return false
    end

    function CompactVendorFilterTemplate:IsRelevant()
        return true
    end

    ---@param level number
    function CompactVendorFilterTemplate:GetDropdown(level)
    end

    function CompactVendorFilterTemplate:New()
        local filter = {} ---@type CompactVendorFilterTemplate
        Mixin(filter, self)
        return filter
    end

    function CompactVendorFilterTemplate:Publish()
        assert(type(self.parent) == "table", "CompactVendorFilter Publish requires you to have created a `CompactVendorFilterTemplate:New()` filter and publish that one. Ensure that it does have a proper parent, defined when calling the `:OnLoad(parent)` method.")
        CompactVendorFilterFrame:AddFilter(self)
    end

end
