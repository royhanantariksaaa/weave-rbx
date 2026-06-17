--!optimize 2
--[=[
	@within Weave
	@module Observe

	Like `Watch`, but fires the callback immediately with the current value,
	then on every change.

	@param state -- the state (or getter) to observe
	@param callback (newValue) -> () -- invoked now and on each change
	@return RBXScriptConnection -- disconnect to stop observing
]=]

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
