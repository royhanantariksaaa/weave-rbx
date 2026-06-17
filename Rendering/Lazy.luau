--[=[
	@within Weave
	@module Lazy

	Async component loading. Suspends and shows `fallback` until the lazy
	reference (from `Weave.lazy`) has preloaded, then renders the resolved
	component.

	@param lazyRef -- a `Weave.lazy(...)` handle (or a factory function)
	@param fallback (() -> WeaveNode)? -- shown while loading
	@return WeaveNode
]=]

return function(_Scope, _Signal)
	return function(self, lazyRef, fallback)
		local asyncState = self.Async(function()
			if type(lazyRef) == "table" and lazyRef.Preload then
				return lazyRef:Preload()
			elseif type(lazyRef) == "function" then
				return lazyRef()
			else
				return lazyRef
			end
		end)
		
		return self.Suspense({
			Resource = asyncState,
			Fallback = fallback,
			Children = function(s, comp)
				if type(comp) == "function" then
					return comp(s, {})
				end
				return comp
			end
		})
	end
end
