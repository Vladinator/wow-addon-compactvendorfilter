local CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate ---@type CompactVendorFilterToggleTemplate

local filter = CompactVendorFilterToggleTemplate:New(
    "Usable", { showUsable = true },
    "showUsable", "isUsable"
)

filter:Publish()
