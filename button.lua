VladsVendorFilterMenuButtonMixin = {}

function VladsVendorFilterMenuButtonMixin:OnLoad()
	self:SetPoint("RIGHT", MerchantFrameCloseButton, "LEFT", 8 - 4, 0)
	self:SetScale(0.85)
end

function VladsVendorFilterMenuButtonMixin:OnClick()
	if not self.Menu then
		self.Menu = _G.VladsVendorFilterMenuFrame
	end
	ToggleDropDownMenu(1, nil, self.Menu, self, 0, 0)
end
