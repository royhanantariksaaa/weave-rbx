-- Combine: Shorthand for Computed over multiple states.
-- Usage: scope.Combine(stateA, stateB, ..., combinerFn) -> Computed

return function(_Scope, _Signal, _Value, _Computed)
	return function(self, ...)
		local args = { ... }
		local combiner = table.remove(args)
		assert(type(combiner) == "function", "Weave: Combine last argument must be a function")
		local values = table.create(#args)
		local comp = self.computed(function()
			table.clear(values)
			for i, s in ipairs(args) do
				values[i] = type(s) == "function" and s() or s
			end
			return combiner(table.unpack(values))
		end)
		return comp
	end
end
