-- Previous: A state that always holds the previous value of another state.
-- Usage: scope.Previous(state) -> getter closure

return function(_Scope, _Signal, _Value)
	return function(self, state)
		local current = nil
		local isFirst = true
		local prev, setPrev = self.value(nil)
		
		self.effect(function()
			local newVal = type(state) == "function" and state() or state
			if isFirst then
				isFirst = false
				current = newVal
				setPrev(current)
				return
			end
			setPrev(current)
			current = newVal
		end)
		return prev
	end
end
