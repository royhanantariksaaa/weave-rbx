--[=[
	@within Weave.Components
	@module Flex

	Rapid layout builder backed by `UIListLayout`.
]=]

local Reconciler = require(script.Parent.Parent.Core.Reconciler)
local Elements = require(script.Parent.Parent.Core.Elements)
local Helpers = require(script.Parent.Parent.Core.Helpers)

return function(Scope, props)
	local children = props[Reconciler.Children] or props.Children
	local direction = props.Direction or Enum.FillDirection.Horizontal
	local wrap = props.Wrap
	local justify = props.Justify or Enum.HorizontalAlignment.Left
	local align = props.Align or Enum.VerticalAlignment.Top
	local gap = props.Gap or UDim.new(0, 0)
	
	local newProps = Helpers.Omit(props, { Reconciler.Children, "Children", "Direction", "Wrap", "Justify", "Align", "Gap" })

	if newProps.BackgroundTransparency == nil then newProps.BackgroundTransparency = 1 end
	if newProps.Size == nil then newProps.Size = UDim2.fromScale(1, 1) end

	local uiListLayoutProps = {
		FillDirection = direction,
		HorizontalAlignment = justify,
		VerticalAlignment = align,
		Padding = gap,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}
	
	if type(wrap) == "boolean" then
		uiListLayoutProps.Wraps = wrap
	end

	newProps[Reconciler.Children] = {
		Elements.UIListLayout(Scope, uiListLayoutProps),
		children
	}

	return Elements.Frame(Scope, newProps)
end
