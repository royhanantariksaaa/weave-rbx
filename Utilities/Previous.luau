--!optimize 2
--[=[
	@within Weave
	@module Previous

	A state that always holds the *previous* value of another state. On the
	source's first read the previous value is `nil`.

	@param state -- the source state (or getter)
	@return () -> any -- getter for the prior value
]=]

local Shared = require(script.Parent._shared)

return function(_Scope, _Signal, _Value)
	return function(self, state)
		local current = nil
		local isFirst = true
		local prev, setPrev = self.value(nil)
		
		self.effect(function()
			local newVal = Shared.read(state)
			if isFirst then
				isFirst = false
				current = newVal
				return
			end
			setPrev(current)
			current = newVal
		end)
		return prev
	end
end
