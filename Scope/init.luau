--[=[
	@within Weave
	@module Scope

	Scope constructor and lifecycle. A scope owns reactive state, auto-cleans
	its connections/instances on `:Destroy()`, and binds the rendering and
	utility hooks onto each new scope.
]=]

local Trove = require(script.Parent.Parent.Trove)
local Reconciler = require(script.Parent.Core.Reconciler)
local Elements = require(script.Parent.Core.Elements)
local Engine = require(script.Parent.Core.Engine)

local Value = require(script.Parent.States.Value)
local Computed = require(script.Parent.States.Computed)
local Spring = require(script.Parent.States.Spring)
local Tween = require(script.Parent.States.Tween)
local Derived = require(script.Parent.States.Derived)
local Mixins = require(script.Parent.States.Mixins)
local Async = require(script.Parent.States.Async)
local Reducer = require(script.Parent.States.Reducer)

if type(Mixins.InjectComputed) == "function" then
	Mixins.InjectComputed(Computed)
end

local Scope = {}
Scope.__index = Scope

local Renderings, Utilities

local function unwrapState(value: any)
	local id = Engine.resolveId(value)
	if id then
		return Engine.get(id)
	end
	if type(value) == "table" and type(value.Get) == "function" then
		return value:Get()
	end
	return value
end

function Scope.new(parentScope: any?)
	local self = {
		_trove = Trove.new(),
		_components = {},
		_context = setmetatable({}, { __index = parentScope and parentScope._context or {} }),
	}

	local function stripScopeArg(...)
		if select("#", ...) > 0 and select(1, ...) == self then
			return select(2, ...)
		end
		return ...
	end

	local function makeUse()
		return function(value: any)
			return unwrapState(value)
		end
	end

	local function wrapState(getter: any, setter: any?, stateType: string)
		if type(getter) ~= "function" then
			return getter
		end

		local id = Engine.resolveId(getter)
		if id then
			self._trove:Add(function()
				Engine.destroy(id)
			end)
		end

		local state = {
			_id = id,
			_getter = getter,
			_setter = setter,
			_changed = id and Engine.Signals[id] or nil,
			_isWeaveState = true,
			Type = stateType,
		}

		function state:Get()
			return getter()
		end

		function state:Peek()
			return id and Engine.peek(id) or getter()
		end

		function state:Set(value: any)
			if setter then
				setter(value)
			end
		end

		function state:Update(updater: (any) -> any)
			if setter then
				setter(updater(getter()))
			end
		end

		function state:Map(transformer: (any) -> any)
			return wrapState(Mixins.Map(getter, transformer), nil, "Computed")
		end

		function state:Throttle(seconds: number)
			return wrapState(Mixins.Throttle(getter, seconds), nil, "Computed")
		end

		function state:Debounce(seconds: number)
			return wrapState(Mixins.Debounce(getter, seconds), nil, "Computed")
		end

		function state:Destroy()
			if id then
				Engine.destroy(id)
			end
		end

		return setmetatable(state, {
			__call = function()
				return getter()
			end,
		})
	end

	local function createValueFactory(constructor, stateType: string)
		return function(...)
			local getter, setter = constructor(...)
			local state = wrapState(getter, setter, stateType)
			return state, setter
		end
	end

	local function createReadFactory(constructor, stateType: string)
		return function(callback, ...)
			local adaptedCallback = callback
			if type(callback) == "function" then
				adaptedCallback = function()
					return callback(makeUse())
				end
			end
			local getter = constructor(adaptedCallback, ...)
			return wrapState(getter, nil, stateType)
		end
	end

	local function createObjectFactory(constructor)
		return function(...)
			local obj = constructor(...)
			self._trove:Add(obj)
			return obj
		end
	end

	self.value = createValueFactory(Value, "Value")
	self.computed = createReadFactory(Computed, "Computed")
	self.derived = createValueFactory(function(callback, ...)
		local adaptedCallback = callback
		if type(callback) == "function" then
			adaptedCallback = function()
				return callback(makeUse())
			end
		end
		return Derived(adaptedCallback, ...)
	end, "Derived")
	self.async = createReadFactory(Async, "Async")
	self.reducer = createValueFactory(Reducer, "Reducer")
	self.spring = createObjectFactory(Spring)
	self.tween = createObjectFactory(Tween)

	self.effect = function(callback)
		return self.computed(function(use)
			callback(use)
			return nil
		end)
	end

	self.createSignal = self.value
	self.createMemo = self.computed
	self.createEffect = self.effect
	self.fragment = function(...)
		local children = stripScopeArg(...)
		if children == nil then
			return {}
		end
		if type(children) == "table" then
			return children
		end
		return { children }
	end
	self.onCleanup = function(callback)
		self._trove:Add(callback)
	end

	self.Value = self.value
	self.Computed = self.computed
	self.Derived = self.derived
	self.Async = self.async
	self.Reducer = self.reducer
	self.Spring = self.spring
	self.Tween = self.tween
	self.Effect = self.effect
	self.Fragment = self.fragment

	for _, bindings in { Renderings, Utilities } do
		for fnName, fn in pairs(bindings) do
			local methodName = fnName:sub(1, -3)
			local camelMethod = methodName:sub(1, 1):lower() .. methodName:sub(2)

			self[camelMethod] = function(...)
				return fn(self, stripScopeArg(...))
			end
			self[methodName] = function(...)
				return fn(self, stripScopeArg(...))
			end
		end
	end

	self.Ref = function()
		return {
			_value = nil,
			Get = function(refSelf)
				return refSelf._value
			end,
			Set = function(refSelf, value)
				refSelf._value = value
			end,
		}
	end

	self.Hydrate = function(...)
		local instance, props = stripScopeArg(...)
		if typeof(instance) ~= "Instance" then
			error("Weave: Hydrate expects Instance")
		end
		self._trove:Add(instance)
		Reconciler.Reconcile(instance, type(props) == "table" and props or {}, self._trove)
		return instance
	end

	self.RegisterComponent = function(...)
		local name, componentFunc = stripScopeArg(...)
		self._components[name] = componentFunc
	end

	self.Provide = function(...)
		local key, value = stripScopeArg(...)
		if type(key) == "table" then
			for ctxKey, ctxValue in key do
				self._context[ctxKey] = ctxValue
			end
		else
			self._context[key] = value
		end
	end

	self.Consume = function(...)
		local key = stripScopeArg(...)
		return self._context[key]
	end

	self.UseContext = function(...)
		local context = stripScopeArg(...)
		local value = self.Consume(context._id)
		if value == nil then
			return context.DefaultValue
		end
		return value
	end

	self.OnMount = function(...)
		local callback = stripScopeArg(...)
		local mounted = true
		self.Defer(function()
			if mounted then
				callback()
			end
		end)
		self._trove:Add(function()
			mounted = false
		end)
	end

	self.OnDestroy = function(...)
		local callback = stripScopeArg(...)
		self._trove:Add(callback)
	end

	self.Destroy = function(...)
		self._trove:Destroy()
	end

	setmetatable(self, {
		__index = function(_, key)
			local comp = self._components[key]
			if comp then
				return comp
			end

			local element = Elements[key]
			if element then
				self[key] = element
				return element
			end

			return Scope[key]
		end,
	})

	return self
end

Renderings = require(script.RenderingBindings)(Scope)
Utilities = require(script.UtilityBindings)(Scope)

return Scope
