local CompactVendorFilterToggleTemplate = CompactVendorFilterToggleTemplate ---@type CompactVendorFilterToggleTemplate

local filter = CompactVendorFilterToggleTemplate:New(
    "Known", { showKnown = false },
    "showKnown", "isLearned"
)

filter:Publish()
