local CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate ---@type CompactVendorFilterToggleTemplate

local filter = CompactVendorFilterToggleTemplate:New(
    "Collected", { showCollected = false },
    "showCollected", "isCollected"
)

filter:Publish()
