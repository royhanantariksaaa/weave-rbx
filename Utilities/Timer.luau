--[=[
	@within Weave
	@module Timer

	A reactive numeric state that increments every `interval` seconds. Useful
	for time-driven UI (cooldowns, tickers).

	@param interval number -- seconds between increments
	@return () -> number -- getter for the tick count
]=]

local Helpers = require(script.Parent.Parent.Core.Helpers)

local timerPool = nil
local initialisedPool = false

local function onTimerUpdate(pool, dt)
	for i = pool.count, 1, -1 do
		local t = pool.list[i]
		t.elapsed += dt
		if t.elapsed >= t.interval then
			local increments = math.floor(t.elapsed / t.interval)
			t.elapsed -= increments * t.interval
			t.setState(t.state() + increments)
		end
	end
end

return function(_Scope, _Signal, Value)
	return function(self, interval)
		local state = Value(0)
		self._trove:Add(state)

		if not initialisedPool then
			initialisedPool = true
			timerPool = Helpers.CreatePool(onTimerUpdate)
		end

		local timerData = {
			state = state,
			interval = interval,
			elapsed = 0,
		}
		
		timerData.timerIndex = timerPool:Add(timerData)

		self._trove:Add(function()
			if timerPool then
				timerPool:RemoveItem(timerData, "timerIndex")
			end
		end)

		return state
	end
end
