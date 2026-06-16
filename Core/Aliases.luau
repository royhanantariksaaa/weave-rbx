--[=[
	@within Weave
	@module Aliases

	Short-name → Roblox class mappings used by the element namespace, so
	`Weave.ListLayout` resolves to `UIListLayout`, and so on.
]=]

local Aliases = {
	-- Layouts
	ListLayout    = "UIListLayout",
	GridLayout    = "UIGridLayout",
	PageLayout    = "UIPageLayout",
	TableLayout   = "UITableLayout",

	-- Constraints & Modifiers
	AspectRatio       = "UIAspectRatioConstraint",
	SizeConstraint    = "UISizeConstraint",
	TextSizeConstraint = "UITextSizeConstraint",
	FlexItem          = "UIFlexItem",

	-- Decorators
	Padding   = "UIPadding",
	Corner    = "UICorner",
	Stroke    = "UIStroke",
	Gradient  = "UIGradient",
	Scale     = "UIScale",

	-- Selection Visuals
	SelectionBox    = "SelectionBox",
	SelectionSphere = "SelectionSphere",
	Highlight       = "Highlight",

	-- 3D/World UI
	Billboard  = "BillboardGui",
	Surface    = "SurfaceGui",
}

return Aliases
