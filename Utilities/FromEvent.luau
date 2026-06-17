--[=[
	@within Weave
	@module FromEvent

	Bridges an `RBXScriptSignal` into a reactive Weave state. The state holds
	the latest event payload (mapped through `mapperFn` if provided).

	@param signal RBXScriptSignal -- the event to subscribe to
	@param mapperFn ((...any) -> T)? -- optional transform applied to event args
	@return () -> T -- getter for the latest mapped value
]=]

return function(_Scope, _Signal, _Value)
	return function(self, signal, mapperFn)
		local getState, setState = self.value(nil)
		
		local conn = signal:Connect(function(...)
			if mapperFn then
				local result = mapperFn(...)
				if result ~= nil then
					setState(result)
				end
			else
				setState((...))  -- first arg
			end
		end)
		self.OnDestroy(function() conn:Disconnect() end)
		
		return getState
	end
end
