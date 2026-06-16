-- FromEvent: Bridge an RBXScriptSignal into a reactive Weave state.
-- Usage: scope.FromEvent(signal, mapperFn?) -> Value

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
