--[=[
	@within Weave

	Filters updates from a source state through a predicate. The derived state
	only updates when `predicateFn(newVal, oldVal)` returns true.

	@param sourceState -- the source state (or getter)
	@param predicateFn (newVal, oldVal) -> boolean -- gate condition
	@return () -> any -- getter for the gated value
]=]

return function(_Scope, _Signal, _Value)
	return function(self, sourceState, predicateFn)
		local val = type(sourceState) == "function" and sourceState() or sourceState
		local getGate, setGate = self.value(val)
		
		self.Observe(sourceState, function(newVal, oldVal)
			if predicateFn(newVal, oldVal) then
				setGate(newVal)
			end
		end)
		
		return getGate
	end
end
