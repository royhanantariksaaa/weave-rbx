-- Gate: Filters updates from a source state based on a predicate function.
-- Usage: scope.Gate(sourceState, function(newVal, oldVal) return newVal > 5 end)

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
