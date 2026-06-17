--[=[
	@within Weave
	@module Stagger

	Cascading list entrance animations. Renders each item with a per-index
	delay; the render function receives an `alphaGetter` that goes 0 → 1 as
	the item's stagger progress completes.

	@param itemsState -- reactive list of items
	@param renderFn (scope, item, index, alphaGetter) -> WeaveNode -- per-item renderer
	@param options { delay: number }? -- per-item stagger delay (seconds)
	@return WeaveNode
]=]

local Shared = require(script.Parent._shared)

return function(Scope, Signal)
	return function(self, itemsState, renderFn, options)
		local delay = (options and options.delay) or 0.05

		return Shared.createCollectionNode(Signal, Scope, self, itemsState, true, function(childScope, item, index)
			local alpha, setAlpha = childScope.value(0)
			local inst = renderFn(childScope, item, index, alpha)

			task.delay(index * delay, function()
				setAlpha(1)
			end)

			return inst
		end)
	end
end
