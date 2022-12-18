local CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate ---@type CompactVendorFilterToggleTemplate

local filter = CompactVendorFilterToggleTemplate:New(
    "Affordable", { showAffordable = nil },
    "showAffordable", "canAfford"
)

filter:Publish()
