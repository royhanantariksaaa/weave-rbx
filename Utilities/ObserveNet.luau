--[=[
	@within Weave

	Bridges a Knit service signal or a raw `RemoteEvent` into a reactive Weave
	state. Supports both for flexibility.

	@param source -- a Knit signal or RBXScriptSignal
	@param initialValue any -- value used before the first event arrives
	@return () -> any -- getter for the latest event payload
]=]
--
-- Usage (RemoteEvent):
--   local money = scope.ObserveNet(remoteEvent, 0, function(amount) return amount end)
--
-- Usage (Knit property):
--   local money = scope.ObserveNet(MoneyService, "Money", 0)

local RunService = game:GetService("RunService")

return function(_Scope, _Signal, _Value)
	-- Shared helper: connect a signal to a state with optional mapping
	local function connectMapped(signal, setter, mapperFn)
		return signal:Connect(function(...)
			if mapperFn then
				setter(mapperFn(...))
			else
				setter((...)) -- first arg
			end
		end)
	end

	return function(self, source, ...)
		local args = { ... }
		local getState, setState
		local conn

		if typeof(source) == "Instance" and source:IsA("RemoteEvent") then
			-- Raw RemoteEvent: ObserveNet(remoteEvent, initialValue, mapperFn?)
			getState, setState = self.value(args[1])
			local signal = RunService:IsClient() and source.OnClientEvent or source.OnServerEvent
			conn = connectMapped(signal, setState, args[2])

		elseif type(source) == "table" and type(args[1]) == "string" then
			-- Knit service property: ObserveNet(service, "PropertyName", initialValue)
			local propName = args[1]
			local signal = source[propName]

			if signal and type(signal) == "table" and signal.Connect then
				getState, setState = self.value(args[2])
				conn = signal:Connect(function(newValue)
					setState(newValue)
				end)
			else
				warn("Weave ObserveNet: '" .. propName .. "' is not a connectable signal on the given service.")
				getState, setState = self.value(args[2])
			end

		elseif type(source) == "table" and source.Connect then
			-- Knit signal / Signal-like object: ObserveNet(signal, initialValue, mapperFn?)
			getState, setState = self.value(args[1])
			conn = connectMapped(source, setState, args[2])

		else
			warn("Weave ObserveNet: Unsupported source type. Expected RemoteEvent, Knit signal, or {service, propName}.")
			getState, setState = self.value(args[1])
		end

		if conn then
			self.OnDestroy(function() conn:Disconnect() end)
		end

		return getState
	end
end
