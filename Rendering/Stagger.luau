-- Stagger: Cascading list entrance animations.
-- Usage: scope.Stagger(itemsState, renderFn, { delay = 0.05 })
-- renderFn receives (childScope, item, index, alphaGetter) where alphaGetter() goes 0 → 1

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
