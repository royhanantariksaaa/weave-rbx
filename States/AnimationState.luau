--!native
--!optimize 2
--[=[
	@module AnimationState
	@within Weave.States

	State primitive used by Weave reactive data flows.
]=]

-- AnimationState: Base class for animation-driven reactive states (Spring, Tween).
-- Accepts getter closure as target state. Resolves to entity ID via Engine.resolveId.

local Engine = require(script.Parent.Parent.Core.Engine)
local Helpers = require(script.Parent.Parent.Core.Helpers)
local WeaveTypes = require(script.Parent.Parent.Types)
local Signal = require(game:GetService("ReplicatedStorage").Libraries.Echo)
local Mixins = require(script.Parent.Mixins)

local AnimationState = {}
AnimationState.__index = AnimationState
AnimationState._WeaveNodeType = WeaveTypes.NodeType.State

local function wrapComputedAccessor(accessor)
	local id = Engine.resolveId(accessor)
	local state = {
		_id = id,
		_changed = id and Engine.Signals[id] or nil,
		_isWeaveState = true,
		Type = "Computed",
	}

	--[=[
		Reads the current value.
		@return any
	]=]
	function state:Get()
		return accessor()
	end

	--[=[
		Reads without dependency tracking.
		@return any
	]=]
	function state:Peek()
		return id and Engine.peek(id) or accessor()
	end

	--[=[
		Creates derived mapped state.
		@param transformer Value passed to this API.
		@return any
	]=]
	function state:Map(transformer: (any) -> any)
		return wrapComputedAccessor(Mixins.Map(accessor, transformer))
	end

	--[=[
		Documents the Throttle API.
		@param seconds Debounce duration in seconds.
	]=]
	function state:Throttle(seconds: number)
		return wrapComputedAccessor(Mixins.Throttle(accessor, seconds))
	end

	--[=[
		Debounces state changes.
		@param seconds Debounce duration in seconds.
		@return any
	]=]
	function state:Debounce(seconds: number)
		return wrapComputedAccessor(Mixins.Debounce(accessor, seconds))
	end

	--[=[
		Destroys the object and releases resources.
	]=]
	function state:Destroy()
		if id then
			Engine.destroy(id)
		end
	end

	return setmetatable(state, {
		__call = function()
			return accessor()
		end,
	})
end

--[=[
	Handles the _init operation for AnimationState.
	@param targetAccessor Value passed to the _init operation.
]=]
function AnimationState._init(self, targetAccessor)
	-- Resolve getter closure → entity ID
	local targetId = Engine.resolveId(targetAccessor)
	assert(targetId, "AnimationState: target must be a state accessor or ID")
	
	self._id = Engine.newState()
	self._targetStateId = targetId
	
	self._changed = Signal.new()
	
	Engine.Values[self._id] = Engine.peek(targetAccessor)
	Engine.StateTypes[self._id] = "Animation"
	
	local targetSignal = Engine.Signals[targetId]
	if targetSignal then
		self._targetListener = targetSignal:Connect(function()
			self:_onTargetChanged()
			self:Awake()
		end)
	end
end

--[=[
	Handles the _onTargetChanged operation for AnimationState.
]=]
function AnimationState:_onTargetChanged() end

--[=[
	Documents the Awake API.
]=]
function AnimationState:Awake()
	local targetValue = Engine.Values[self._targetStateId]
	local valueType = typeof(targetValue)
	if not Helpers.SUPPORTED_ANIMATABLE_TYPES[valueType] then
		self._value = targetValue
		Engine.Values[self._id] = targetValue
		self._changed:Fire(targetValue)
		return
	end
	self:_doAwake()
end

--[=[
	Documents the _doAwake API.
]=]
function AnimationState:_doAwake() end

--[=[
	Destroys the object and releases resources.
]=]
function AnimationState:Destroy()
	self:_onBeforeDestroy()
	if self._targetListener then
		self._targetListener:Disconnect()
	end
	if self._changed then
		self._changed:Destroy()
	end
	Engine.Values[self._id] = nil
	Engine.StateTypes[self._id] = nil
end

--[=[
	Reads the current value.
	@return any
]=]
function AnimationState:Get()
	return self._value
end

--[=[
	Reads without dependency tracking.
	@return any
]=]
function AnimationState:Peek()
	return self._value
end

--[=[
	Creates derived mapped state.
	@param transformer Value passed to this API.
	@return any
]=]
function AnimationState:Map(transformer: (any) -> any)
	return wrapComputedAccessor(Mixins.Map(self, transformer))
end

--[=[
	Documents the Throttle API.
	@param seconds Debounce duration in seconds.
]=]
function AnimationState:Throttle(seconds: number)
	return wrapComputedAccessor(Mixins.Throttle(self, seconds))
end

--[=[
	Debounces state changes.
	@param seconds Debounce duration in seconds.
	@return any
]=]
function AnimationState:Debounce(seconds: number)
	return wrapComputedAccessor(Mixins.Debounce(self, seconds))
end

--[=[
	Documents the _onBeforeDestroy API.
]=]
function AnimationState:_onBeforeDestroy() end

return AnimationState
