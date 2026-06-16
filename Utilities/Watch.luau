-- Watch: Targeted side-effects on state changes (without immediate call).
-- Usage: scope.Watch(state, callback) -> connection

local function resolveStateValue(state)
	if type(state) == "function" then
		return state()
	end
	if type(state) == "table" and type(state.Get) == "function" then
		return state:Get()
	end
	return state
end

return function(_Scope, _Signal)
	return function(self, state, callback)
		local isFirst = true
		local lastVal = nil
		
		self.effect(function()
			local newVal = resolveStateValue(state)
			if isFirst then
				isFirst = false
				lastVal = newVal
				return
			end
			callback(newVal, lastVal)
			lastVal = newVal
		end)
	end
end
