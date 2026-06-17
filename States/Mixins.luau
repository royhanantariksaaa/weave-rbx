--[=[
	@module Mixins
	@within Weave.States

	State primitive used by Weave reactive data flows.
]=]

-- Mixins: Shared Throttle / Debounce / Map methods.
-- Adapted for closure accessor API.

local Helpers = require(script.Parent.Parent.Core.Helpers)
local Engine = require(script.Parent.Parent.Core.Engine)
local Computed = require(script.Parent.Computed)

local Mixins = {}

local timeDelayedPool
local function ensurePool()
	if timeDelayedPool then return end
	timeDelayedPool = Helpers.CreatePool(function(pool)
		local now = os.clock()
		for i = pool.count, 1, -1 do
			local data = pool.list[i]
			if not data.isPending then
				pool:RemoveItem(data, "_poolIndex")
				continue
			end
			if now >= data.targetTime then
				data.setHolder(data.pendingValue)
				data.isPending = false
				if not data.isDebounce then
					data.targetTime = now + data.seconds
				end
				pool:RemoveItem(data, "_poolIndex")
			end
		end
	end)
end

--[=[
	Handles the Throttle operation for Mixins.
	@param accessor State accessor.
	@param seconds Value passed to the Throttle operation.
]=]
function Mixins.Throttle(accessor, seconds: number)
	return Mixins._createDelayed(accessor, seconds, false)
end

--[=[
	Debounces state changes.
	@param accessor Value passed to this API.
	@param seconds Debounce duration in seconds.
	@return any
]=]
function Mixins.Debounce(accessor, seconds: number)
	return Mixins._createDelayed(accessor, seconds, true)
end

--[=[
	Creates derived mapped state.
	@param accessor Value passed to this API.
	@param transformer Value passed to this API.
	@return any
]=]
function Mixins.Map(accessor, transformer: (any) -> any)
	return Computed(function()
		local id = Engine.resolveId(accessor)
		if id then
			return transformer(Engine.get(id))
		end
		if type(accessor) == "function" then
			return transformer(accessor())
		end
		if type(accessor) == "table" and type(accessor.Get) == "function" then
			return transformer(accessor:Get())
		end
		return transformer(accessor)
	end)
end

--[=[
	Handles the _createDelayed operation for Mixins.
	@param accessor State accessor.
	@param seconds Value passed to the _createDelayed operation.
	@param isDebounce Value passed to the _createDelayed operation.
]=]
function Mixins._createDelayed(accessor, seconds: number, isDebounce: boolean)
	ensurePool()
	local sourceId = Engine.resolveId(accessor)
	local holderGetter, holderSetter = Engine.value(Engine.peek(accessor))

	local data = {
		setHolder = holderSetter,
		seconds = seconds,
		targetTime = 0,
		pendingValue = nil,
		isDebounce = isDebounce,
		isPending = false,
	}

	local sourceSignal = Engine.Signals[sourceId]
	if sourceSignal then
		sourceSignal:Connect(function(val)
			local now = os.clock()
			data.pendingValue = val
			if isDebounce then
				data.targetTime = now + seconds
				if not data.isPending then
					data.isPending = true
					data._poolIndex = timeDelayedPool:Add(data)
				end
			else
				if now >= data.targetTime then
					holderSetter(val)
					data.targetTime = now + seconds
					data.isPending = false
				elseif not data.isPending then
					data.isPending = true
					data._poolIndex = timeDelayedPool:Add(data)
				end
			end
		end)
	end

	return holderGetter
end

return Mixins
