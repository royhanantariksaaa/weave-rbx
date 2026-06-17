--[=[
	@module Helpers
	@within Weave.Core

	Core runtime helper used by Weave rendering and reactivity internals.
]=]

-- Helpers: Shared low-level helpers used across Rendering and States.
-- Centralises RunService connection logic and type tables.

local RunService = game:GetService("RunService")
local isClient = RunService:IsClient()
local frameEvent = isClient and RunService.RenderStepped or RunService.Heartbeat

local Helpers = {}

-- Supported animatable types for Spring and Tween.
Helpers.SUPPORTED_ANIMATABLE_TYPES = {
	number = true,
	UDim2 = true,
	Vector2 = true,
	Vector3 = true,
	Color3 = true,
	CFrame = true,
	UDim = true,
}

local updateCallbacks = {}
local updateCallbacksCount = 0
local updateConnection = nil

local function onUpdate(dt)
	for i = updateCallbacksCount, 1, -1 do
		updateCallbacks[i](dt)
	end
end

-- Adds a callback to the unified RunService loop.
--[=[
	Registers a callback for per-frame updates.
	@param callback Callback invoked by this API.
]=]
function Helpers.StartUpdating(callback)
	if not table.find(updateCallbacks, callback) then
		updateCallbacksCount += 1
		updateCallbacks[updateCallbacksCount] = callback
		if updateCallbacksCount == 1 then
			updateConnection = frameEvent:Connect(onUpdate)
		end
	end
end

-- Removes a callback from the unified RunService loop.
-- If no callbacks remain, the loop stops on the next tick to save resources.
--[=[
	Stops a per-frame update callback.
	@param callback Callback invoked by this API.
]=]
function Helpers.StopUpdating(callback)
	local index = table.find(updateCallbacks, callback)
	if index then
		-- fast removal (swap with last element)
		updateCallbacks[index] = updateCallbacks[updateCallbacksCount]
		updateCallbacks[updateCallbacksCount] = nil
		updateCallbacksCount -= 1
		
		if updateCallbacksCount == 0 and updateConnection then
			updateConnection:Disconnect()
			updateConnection = nil
		end
	end
end

-- Schedules a callback to run once on the next frame.
-- Centralises the client/server frame event selection.
--[=[
	Schedules a callback to run once on the next update.
	@param callback Callback invoked by this API.
]=]
function Helpers.ScheduleOnce(callback)
	frameEvent:Once(callback)
end

-- Omits specified keys from a dictionary and returns a new dictionary.
--[=[
	Copies a dictionary without selected keys.
	@param dict Value passed to this API.
	@param keysToOmit Value passed to this API.
	@return any
]=]
function Helpers.Omit(dict, keysToOmit)
	local result = {}
	for k, v in pairs(dict) do
		if not table.find(keysToOmit, k) then
			result[k] = v
		end
	end
	return result
end

-- Merges properties from source dictionaries into the target dictionary.
--[=[
	Assigns fields into a target table.
	@param target Value passed to this API.
	@return any
]=]
function Helpers.Assign(target, ...)
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if type(source) == "table" then
			for k, v in pairs(source) do
				target[k] = v
			end
		end
	end
	return target
end

-- Calls :Destroy() on all items in a table (array or dictionary).
--[=[
	Destroys each Instance or cleanup object in a list.
	@param instances Instances or cleanup objects.
]=]
function Helpers.DestroyAll(instances)
	for _, inst in pairs(instances) do
		inst:Destroy()
	end
end

-- Creates a managed swap-remove pool with automatic StartUpdating/StopUpdating lifecycle.
-- updateFn(list, count, dt) is called each frame while pool is non-empty.
-- Returns: { Add(item), Remove(index), list, count }
--[=[
	Creates an update pool.
	@param updateFn Value passed to this API.
	@return any
]=]
function Helpers.CreatePool(updateFn)
	local pool = {
		list = {},
		count = 0,
		_isRunning = false,
		_wrappedUpdate = nil,
	}

	--[=[
		Runs the pool update callback.
		@param dt Delta time.
	]=]
	pool._wrappedUpdate = function(dt)
		updateFn(pool, dt)
		if pool.count == 0 and pool._isRunning then
			Helpers.StopUpdating(pool._wrappedUpdate)
			pool._isRunning = false
		end
	end

	--[=[
		Adds an item to a pool.
		@param item Pool item.
	]=]
	function pool:Add(item)
		self.count += 1
		self.list[self.count] = item
		if not self._isRunning then
			self._isRunning = true
			Helpers.StartUpdating(self._wrappedUpdate)
		end
		return self.count  -- return index
	end

	--[=[
		Removes an item by swapping with the final item.
		@param index Pool index.
	]=]
	function pool:SwapRemove(index)
		local last = self.count
		local swapped = self.list[last]
		self.list[index] = swapped
		self.list[last] = nil
		self.count -= 1
		return swapped  -- return the item that was swapped in (for index updates)
	end
	
	--[=[
		Removes an item from the pool.
		@param item Pool item.
		@param indexKey Optional field storing the pool index.
	]=]
	function pool:RemoveItem(item, indexKey)
		local index = item[indexKey]
		if not index then return end
		local swapped = self:SwapRemove(index)
		if swapped then
			swapped[indexKey] = index
		end
		item[indexKey] = nil
	end

	return pool
end

-- Creates a Color3 from RGB values (0-1 range)
--[=[
	Creates a Color3 from RGB values.
	@param r Red channel value.
	@param g Green channel value.
	@param b Blue channel value.
	@return Color3
]=]
function Helpers.Color3(r, g, b)
	return Color3.new(r, g, b)
end

-- Creates a NumberSequence from an array of {time, value, envelope} keypoints
--[=[
	Creates a NumberSequence.
	@param keypoints Sequence keypoints.
	@return NumberSequence
]=]
function Helpers.NumberSequence(keypoints)
	local sequenceKeypoints = {}
	for _, kp in ipairs(keypoints) do
		table.insert(sequenceKeypoints, NumberSequenceKeypoint.new(kp.time, kp.value, kp.envelope))
	end
	return NumberSequence.new(sequenceKeypoints)
end

-- Creates a ColorSequence from an array of {time, color: {r, g, b}} keypoints
--[=[
	Creates a ColorSequence.
	@param keypoints Sequence keypoints.
	@return ColorSequence
]=]
function Helpers.ColorSequence(keypoints)
	local sequenceKeypoints = {}
	for _, kp in ipairs(keypoints) do
		table.insert(sequenceKeypoints, ColorSequenceKeypoint.new(kp.time, Color3.new(kp.color[1], kp.color[2], kp.color[3])))
	end
	return ColorSequence.new(sequenceKeypoints)
end

return Helpers
