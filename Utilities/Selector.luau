-- Selector: Equality-gated derivation. Only fires when the selected slice changes.
-- Usage: scope.Selector(state, selectorFn, equalsFn?) -> read-only closure

return function(_Scope, _Signal, _Value, _Mixins)
	return function(self, state, selectorFn, equalsFn)
		return self.computed(function()
			local v = type(state) == "function" and state() or state
			return selectorFn(v)
		end, { equals = equalsFn })
	end
end
