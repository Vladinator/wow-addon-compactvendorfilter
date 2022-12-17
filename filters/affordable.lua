local CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate ---@type CompactVendorFilterToggleTemplate

local filter = CompactVendorFilterToggleTemplate:New(
    "Affordable", { showAffordable = true },
    "showAffordable", "canAfford"
)

filter:Publish()
