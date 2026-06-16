--[=[
	@within Weave

	Run a callback on the next frame, after reactive updates settle.

	@param fn () -> () -- the deferred callback
	@return any
]=]

local Helpers = require(script.Parent.Parent.Core.Helpers)

local deferredQueue = {}
local deferredCount = 0
local isConnected = false

local function processQueue()
	local count = deferredCount
	local queue = deferredQueue
	
	deferredCount = 0
	deferredQueue = {}
	isConnected = false
	
	for i = 1, count do
		task.spawn(queue[i])
	end
end

local function queueDefer(fn)
	deferredCount += 1
	deferredQueue[deferredCount] = fn
	
	if not isConnected then
		isConnected = true
		Helpers.ScheduleOnce(processQueue)
	end
end

return function(_Scope, _Signal)
	return function(self, fn)
		local cancelled = false
		queueDefer(function()
			if not cancelled then
				fn()
			end
		end)
		
		self._trove:Add(function()
			cancelled = true
		end)
	end
end
