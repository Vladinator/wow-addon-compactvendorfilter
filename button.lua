VladsVendorFilterMenuButtonMixin = {}

local function UpdateMenuReference(self)
	if not self.Menu then
		self.Menu = _G.VladsVendorFilterMenuFrame
	end
end

local function IsDropDownShown(self)
	return DropDownList1.dropdown == self.Menu and DropDownList1:IsShown()
end

function VladsVendorFilterMenuButtonMixin:OnLoad()
	self:SetPoint("RIGHT", MerchantFrameCloseButton, "LEFT", 8 - 4, 0)
	self:SetScale(0.85)
	hooksecurefunc("MerchantFrame_Update", function() self:SetShown(MerchantFrame.selectedTab == 1) end)
end

function VladsVendorFilterMenuButtonMixin:OnEnter()
	UpdateMenuReference(self)
	self.IsOnButton = true
	self.IsShown = IsDropDownShown(self)
end

function VladsVendorFilterMenuButtonMixin:OnLeave()
	UpdateMenuReference(self)
	self.IsOnButton = false
	self.IsShown = IsDropDownShown(self)
end

function VladsVendorFilterMenuButtonMixin:OnMouseDown()
	UpdateMenuReference(self)
	if self.IsOnButton and self.IsShown then
		self.IsShown = false
		CloseDropDownMenus()
	else
		self.IsShown = true
		ToggleDropDownMenu(1, nil, self.Menu, self, 0, 0)
	end
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
