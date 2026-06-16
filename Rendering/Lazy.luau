-- Lazy: Async component loading. Shows component once factory resolves.
-- Usage: scope.Lazy(factory) -> WeaveNode

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
