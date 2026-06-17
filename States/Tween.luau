--!native
--!optimize 2
--[=[
	@within Weave
	@module Tween

	Animated reactive state driven by `TweenInfo` interpolation. Animates
	toward a target value following the given easing. The target is provided
	as a getter closure, so the tween follows other reactive state.

	@param targetAccessor () -> T -- getter for the value to animate toward
	@param tweenInfo TweenInfo? -- easing config (defaults to linear if omitted)
	@return WeaveTypes.Tween<T> -- a reactive state whose getter returns the animated value
]=]

local AnimationState = require(script.Parent.AnimationState)
local TweenLib = require(script.Parent.Parent.Parent.Tween)
local WeaveTypes = require(script.Parent.Parent.Types)
local Engine = require(script.Parent.Parent.Core.Engine)

local Tween = setmetatable({}, { __index = AnimationState })
Tween.__index = Tween
Tween.Type = "WeaveTween"

function Tween.new<T>(targetAccessor, tweenInfo: TweenInfo?): WeaveTypes.Tween<T>
	local targetId = Engine.resolveId(targetAccessor)
	local self = setmetatable({
		_tweenInfo = tweenInfo or TweenInfo.new(),
		_value = Engine.Values[targetId],
		_tweenController = nil,
	}, Tween)
	AnimationState._init(self, targetAccessor)
	return self :: any
end

--[=[
	Writes a new value.
	@param val Value passed to the Set operation.
]=]
function Tween:Set(val: any)
	if self._value ~= val then
		self._value = val
		Engine.Values[self._id] = val
		self._changed:Fire(val)
	end
end

--[=[
	Documents the _doAwake API.
]=]
function Tween:_doAwake()
	if self._tweenController then
		self._tweenController.Cancel()
		self._tweenController = nil
	end
	local targetValue = Engine.Values[self._targetStateId]
	self._tweenController = TweenLib.Tween(self, self._tweenInfo, { _value = targetValue })
end

--[=[
	Documents the _onBeforeDestroy API.
]=]
function Tween:_onBeforeDestroy()
	if self._tweenController then
		self._tweenController.Cancel()
		self._tweenController = nil
	end
end

return function<T>(targetAccessor, tweenInfo: TweenInfo?): WeaveTypes.Tween<T>
	return Tween.new(targetAccessor, tweenInfo)
end
