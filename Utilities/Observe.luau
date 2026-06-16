-- Observe: Like Watch but fires immediately with the current value.
-- Usage: scope.Observe(state, callback) -> connection

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
		local val = resolveStateValue(state)
		callback(val, nil)
		return self.Watch(state, callback)
	end
end
