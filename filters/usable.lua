local CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate ---@type CompactVendorFilterToggleTemplate

local filter = CompactVendorFilterToggleTemplate:New(
    "Usable", { showUsable = nil },
    "showUsable", "isUsable"
)

filter:Publish()
