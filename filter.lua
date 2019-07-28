VladsVendorFilterMixin = {}

function VladsVendorFilterMixin:OnLoad(parent)
	self.parent = parent
end

function VladsVendorFilterMixin:ResetFilter()
end

function VladsVendorFilterMixin:FilterAll()
end

function VladsVendorFilterMixin:ShowAll()
end

function VladsVendorFilterMixin:AddItem(index, link)
end

function VladsVendorFilterMixin:ClearAll()
	self:ResetFilter()
end

function VladsVendorFilterMixin:IsFiltered(index, link)
	return false
end

function VladsVendorFilterMixin:IsRelevant()
	return true
end

function VladsVendorFilterMixin:GetDropdown(level)
end

-- VladsVendorFilterMixin.name = "Template"
-- VladsVendorFilterMixin.defaults = {}
-- _G.VladsVendorFilterMenuFrame:AddFilter(VladsVendorFilterMixin)
