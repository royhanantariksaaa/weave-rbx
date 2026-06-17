--[=[
	@within Weave
	@module Spring

	Physics-based spring animation reactive state. Animates toward a target
	value (number, Vector2/3, UDim/2, Color3, CFrame) using critically-damped
	spring physics. The target is provided as a getter closure, so the spring
	follows other reactive state.

	@param targetAccessor () -> T -- getter for the value to animate toward
	@param speed number? -- spring stiffness (default 10)
	@param damping number? -- damping ratio (default 1)
	@return Types.Spring<T> -- a reactive state whose getter returns the animated value
]=]

local AnimationState = require(script.Parent.AnimationState)
local Types = require(script.Parent.Parent.Types)
local Helpers = require(script.Parent.Parent.Core.Helpers)
local Debug = require(script.Parent.Parent.Core.Debug)
local Engine = require(script.Parent.Parent.Core.Engine)

local MAX_ITERATIONS = 16

local function decompose(value)
	local t = typeof(value)
	if t == "number" then return { value }, "number"
	elseif t == "Vector2" then return { value.X, value.Y }, "Vector2"
	elseif t == "Vector3" then return { value.X, value.Y, value.Z }, "Vector3"
	elseif t == "UDim" then return { value.Scale, value.Offset }, "UDim"
	elseif t == "UDim2" then return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }, "UDim2"
	elseif t == "Color3" then return { value.R, value.G, value.B }, "Color3"
	elseif t == "CFrame" then return { value:GetComponents() }, "CFrame"
	else return nil, "unsupported" end
end

local function decomposeInto(value, out)
	local t = typeof(value)
	if t == "number" then out[1] = value
	elseif t == "Vector2" then out[1] = value.X; out[2] = value.Y
	elseif t == "Vector3" then out[1] = value.X; out[2] = value.Y; out[3] = value.Z
	elseif t == "UDim" then out[1] = value.Scale; out[2] = value.Offset
	elseif t == "UDim2" then out[1] = value.X.Scale; out[2] = value.X.Offset; out[3] = value.Y.Scale; out[4] = value.Y.Offset
	elseif t == "Color3" then out[1] = value.R; out[2] = value.G; out[3] = value.B
	elseif t == "CFrame" then
		out[1], out[2], out[3], out[4], out[5], out[6],
			out[7], out[8], out[9], out[10], out[11], out[12] = value:GetComponents()
	end
end

local function recompose(channels, kind)
	if kind == "number" then return channels[1]
	elseif kind == "Vector2" then return Vector2.new(channels[1], channels[2])
	elseif kind == "Vector3" then return Vector3.new(channels[1], channels[2], channels[3])
	elseif kind == "UDim" then return UDim.new(channels[1], math.round(channels[2]))
	elseif kind == "UDim2" then return UDim2.new(channels[1], math.round(channels[2]), channels[3], math.round(channels[4]))
	elseif kind == "Color3" then return Color3.new(math.clamp(channels[1], 0, 1), math.clamp(channels[2], 0, 1), math.clamp(channels[3], 0, 1))
	elseif kind == "CFrame" then return CFrame.new(table.unpack(channels))
	end
	return channels[1]
end

local function createZeroChannels(n)
	local t = {}
	for i = 1, n do t[i] = 0 end
	return t
end

local springPool = nil
local initialisedPool = false

local function springUpdate(pool, dt)
	dt = math.min(dt, 0.1)
	Debug.Track("SpringUpdates")
	for i = pool.count, 1, -1 do
		local spring = pool.list[i]
		if not spring._isAwake then
			pool:RemoveItem(spring, "_poolIndex")
			continue
		end
		local tgtChannels = spring._targetChannels
		local requiredIterations = math.ceil((dt * spring._speed) / 0.5)
		local iterations = math.clamp(requiredIterations, 2, MAX_ITERATIONS)
		local subDt = dt / iterations
		local channels = spring._channels
		local velocities = spring._velocities
		local spd = spring._speed
		local dmp = spring._damping
		local prevChannels = spring._prevChannels
		local channelCount = #channels
		for j = 1, channelCount do prevChannels[j] = channels[j] end
		for _ = 1, iterations do
			for j = 1, channelCount do
				local force = spd * spd * (tgtChannels[j] - channels[j])
				force = force - 2.0 * spd * dmp * velocities[j]
				velocities[j] = velocities[j] + force * subDt
				channels[j] = channels[j] + velocities[j] * subDt
			end
		end
		local settled = true
		local dirty = false
		for j = 1, channelCount do
			if channels[j] ~= prevChannels[j] then dirty = true end
			if math.abs(channels[j] - tgtChannels[j]) >= 0.001 or math.abs(velocities[j]) >= 0.001 then
				settled = false
			end
			if dirty and not settled then break end
		end
		if settled then
			for j = 1, channelCount do
				channels[j] = tgtChannels[j]
				velocities[j] = 0
			end
			spring._isAwake = false
			dirty = true
			pool:RemoveItem(spring, "_poolIndex")
		end
		if dirty then
			local newValue = recompose(channels, spring._kind)
			if newValue ~= spring._value then
				spring._value = newValue
				Engine.Values[spring._id] = newValue
				spring._changed:Fire(newValue)
			end
		end
	end
end

local Spring = setmetatable({}, { __index = AnimationState })
Spring.__index = Spring
Spring.Type = "WeaveSpring"

function Spring.new<T>(targetAccessor, speed: number?, damping: number?): Types.Spring<T>
	local targetId = Engine.resolveId(targetAccessor)
	local initialValue = Engine.Values[targetId]
	local channels, kind = decompose(initialValue)
	local channelCount = channels and #channels or 1
	local self = setmetatable({
		_speed = speed or 10,
		_damping = damping or 1,
		_value = initialValue,
		_channels = channels or { 0 },
		_velocities = createZeroChannels(channelCount),
		_targetChannels = channels and table.clone(channels) or { 0 },
		_prevChannels = createZeroChannels(channelCount),
		_kind = kind,
		_isAwake = false,
		_poolIndex = nil,
	}, Spring)
	AnimationState._init(self, targetAccessor)
	return self :: any
end

--[=[
	Handles the _onTargetChanged operation for Spring.
]=]
function Spring:_onTargetChanged()
	decomposeInto(Engine.Values[self._targetStateId], self._targetChannels)
end

--[=[
	Documents the _doAwake API.
]=]
function Spring:_doAwake()
	if self._isAwake then return end
	local target = Engine.Values[self._targetStateId]
	local targetKind = typeof(target)
	if targetKind ~= self._kind then
		local targetChannels = decompose(target)
		self._kind = targetKind
		self._channels = targetChannels
		self._targetChannels = table.clone(targetChannels)
		self._velocities = createZeroChannels(#targetChannels)
		self._prevChannels = createZeroChannels(#targetChannels)
		self._value = target
		Engine.Values[self._id] = target
		self._changed:Fire(target)
		return
	end
	self._isAwake = true
	if not initialisedPool then
		initialisedPool = true
		springPool = Helpers.CreatePool(springUpdate)
	end
	if not self._poolIndex then
		self._poolIndex = springPool:Add(self)
	end
end

--[=[
	Handles the _onBeforeDestroy operation for Spring.
]=]
function Spring:_onBeforeDestroy()
	if self._isAwake then self._isAwake = false end
end

--[=[
	Documents the SetSpeed API.
	@param speed Value passed to this API.
]=]
function Spring:SetSpeed(speed: number)
	self._speed = speed
	if not self._isAwake then self:Awake() end
end

--[=[
	Documents the SetDamping API.
	@param damping Value passed to this API.
]=]
function Spring:SetDamping(damping: number)
	self._damping = damping
	if not self._isAwake then self:Awake() end
end

return function<T>(targetAccessor, speed: number?, damping: number?): Types.Spring<T>
	return Spring.new(targetAccessor, speed, damping)
end
