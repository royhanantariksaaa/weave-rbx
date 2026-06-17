--!optimize 2
--[=[
	@within Weave
	@module Watch

	Targeted side-effects on state changes. Like `Observe` but does NOT fire
	immediately — only on subsequent changes.

	@param state -- the state (or getter) to watch
	@param callback (newValue) -> () -- invoked on each change
	@return RBXScriptConnection -- disconnect to stop watching
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
