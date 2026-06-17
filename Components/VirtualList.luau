--[=[
	@within Weave.Components
	@module VirtualList

	Virtualized scrolling component for large lists. Only renders the visible
	rows based on scroll position and window size.

	```lua
	Weave.Components.VirtualList(scope, { Items = state, ItemHeight = 50, RenderItem = fn })
	```
]=]

local Reconciler = require(script.Parent.Parent.Core.Reconciler)
local Elements = require(script.Parent.Parent.Core.Elements)
local Helpers = require(script.Parent.Parent.Core.Helpers)

return function(Scope, props)
	local itemsState = props.Items
	local itemHeight = props.ItemHeight or 50
	local renderItem = props.RenderItem

	local newProps = Helpers.Omit(props, { "Items", "ItemHeight", "RenderItem" })

	local canvasPos = Scope.Value(Vector2.new(0, 0))
	local windowSize = Scope.Value(Vector2.new(0, 0))
	local visibleRange = Scope.Computed(function(use)
		local pos, size = use(canvasPos), use(windowSize)
		return {
			startIdx = math.max(1, math.floor(pos.Y / itemHeight) + 1),
			endIdx = math.floor((pos.Y + size.Y) / itemHeight) + 2,
		}
	end)
	local visibleItems = Scope.Computed(function(use)
		local allItems, range = use(itemsState) or {}, use(visibleRange)
		local result = {}
		for i = range.startIdx, math.min(#allItems, range.endIdx) do
			table.insert(result, { item = allItems[i], index = i })
		end
		return result
	end)

	if not newProps.Size then newProps.Size = UDim2.fromScale(1, 1) end
	newProps.CanvasSize = Scope.Computed(function(use)
		return UDim2.new(0, 0, 0, #(use(itemsState) or {}) * itemHeight)
	end)
	newProps[Reconciler.OnChange("CanvasPosition")] = function(pos) canvasPos:Set(pos) end
	newProps[Reconciler.OnChange("AbsoluteWindowSize")] = function(size) windowSize:Set(size) end
	newProps[Reconciler.Children] = {
		Scope.ForValues(visibleItems, function(s, data)
			local el = renderItem(s, data.item, data.index)
			if el then
				el.Position = UDim2.new(0, 0, 0, (data.index - 1) * itemHeight)
				el.Size = UDim2.new(1, 0, 0, itemHeight)
			end
			return el
		end),
	}
	return Elements.ScrollingFrame(Scope, newProps)
end
