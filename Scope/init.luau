--!optimize 2
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
local BoundMethods = {} :: { [string]: any }

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

local StateMethods = {}

function StateMethods:Get()
	return self._getter()
end

function StateMethods:Peek()
	return self._id and Engine.peek(self) or self._getter()
end

function StateMethods:Set(value: any)
	if self._setter then
		self._setter(value)
	end
end

function StateMethods:Update(updater: (any) -> any)
	if self._setter then
		self._setter(updater(self._getter()))
	end
end

function StateMethods:Map(transformer: (any) -> any)
	return self._scope:_wrapState(Mixins.Map(self._getter, transformer), nil, "Computed")
end

function StateMethods:Throttle(seconds: number)
	return self._scope:_wrapState(Mixins.Throttle(self._getter, seconds), nil, "Computed")
end

function StateMethods:Debounce(seconds: number)
	return self._scope:_wrapState(Mixins.Debounce(self._getter, seconds), nil, "Computed")
end

function StateMethods:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self._id then
		Engine.destroy(self)
	end
end

local StateMetatable = {
	__index = StateMethods,
	__call = function(state)
		return state._getter()
	end,
}

function Scope:_wrapState(getter: any, setter: any?, stateType: string)
	if type(getter) ~= "function" then
		return getter
	end

	local id = Engine.resolveId(getter)
	local state = setmetatable({
		_id = id,
		_generation = id and Engine.getGeneration(id) or nil,
		_getter = getter,
		_setter = setter,
		_changed = id and Engine.Signals[id] or nil,
		_isWeaveState = true,
		_destroyed = false,
		_scope = self,
		Type = stateType,
	}, StateMetatable)

	if id then
		self._trove:Add(function()
			StateMethods.Destroy(state)
		end)
	end

	return state
end

--[=[
	Creates a new instance of the module object.
	@param parentScope Parent scope object.
	@return any
]=]
function Scope.new(parentScope: any?)
	local self = {
		_trove = Trove.new(),
		_components = setmetatable({}, { __index = parentScope and parentScope._components or {} }),
		_context = setmetatable({}, { __index = parentScope and parentScope._context or {} }),
	}

	local function stripScopeArg(...)
		if select("#", ...) > 0 and select(1, ...) == self then
			return select(2, ...)
		end
		return ...
	end

	local function createValueFactory(constructor, stateType: string)
		return function(...)
			local getter, setter = constructor(stripScopeArg(...))
			local state = self:_wrapState(getter, setter, stateType)
			return state, setter
		end
	end

	local function createReadFactory(constructor, stateType: string)
		local function construct(callback, ...)
			local adaptedCallback = callback
			if type(callback) == "function" then
				adaptedCallback = function()
					return callback(unwrapState)
				end
			end
			local getter = constructor(adaptedCallback, ...)
			return self:_wrapState(getter, nil, stateType)
		end
		return function(...)
			return construct(stripScopeArg(...))
		end
	end

	local function createObjectFactory(constructor)
		return function(...)
			local obj = constructor(stripScopeArg(...))
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
				return callback(unwrapState)
			end
		end
		return Derived(adaptedCallback, ...)
	end, "Derived")
	self.async = createReadFactory(Async, "Async")
	self.reducer = createValueFactory(Reducer, "Reducer")
	self.spring = createObjectFactory(Spring)
	self.tween = createObjectFactory(Tween)

	--[=[
		Handles the effect operation for self.
		@param callback Callback invoked by this API.
	]=]
	self.effect = function(...)
		local callback = stripScopeArg(...)
		return self.computed(function(use)
			callback(use)
			return nil
		end)
	end

	self.createSignal = self.value
	self.createMemo = self.computed
	self.createEffect = self.effect
	--[=[
		Creates a fragment from child nodes.
	]=]
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
	--[=[
		Registers a scope cleanup callback.
		@param callback Callback invoked by this API.
	]=]
	self.onCleanup = function(...)
		local callback = stripScopeArg(...)
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

	--[=[
		Handles the Ref operation for self.
	]=]
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

	--[=[
		Applies properties and children to an existing Instance.
	]=]
	self.Hydrate = function(...)
		local instance, props = stripScopeArg(...)
		if typeof(instance) ~= "Instance" then
			error("Weave: Hydrate expects Instance")
		end
		self._trove:Add(instance)
		Reconciler.Reconcile(instance, type(props) == "table" and props or {}, self._trove)
		return instance
	end

	--[=[
		Handles the RegisterComponent operation for self.
	]=]
	self.RegisterComponent = function(...)
		local name, componentFunc = stripScopeArg(...)
		self._components[name] = componentFunc
	end

	local function resolveContextKey(key)
		if type(key) == "table" and type(key._id) == "string" then
			return key._id
		end
		return key
	end

	--[=[
		Provides scoped context values.
	]=]
	self.Provide = function(...)
		local key, value = stripScopeArg(...)
		if type(key) == "table" and type(key._id) ~= "string" and value == nil then
			for ctxKey, ctxValue in key do
				self._context[resolveContextKey(ctxKey)] = ctxValue
			end
		else
			self._context[resolveContextKey(key)] = value
		end
	end

	--[=[
		Consumes a scoped context value.
	]=]
	self.Consume = function(...)
		local key = stripScopeArg(...)
		return self._context[key]
	end

	--[=[
		Reads a scoped context value.
	]=]
	self.UseContext = function(...)
		local context = stripScopeArg(...)
		local value = self.Consume(context._id)
		if value == nil then
			return context.DefaultValue
		end
		return value
	end

	--[=[
		Handles the OnMount operation for self.
	]=]
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

	--[=[
		Registers cleanup for scope destruction.
	]=]
	self.OnDestroy = function(...)
		local callback = stripScopeArg(...)
		self._trove:Add(callback)
	end

	--[=[
		Destroys the object and releases resources.
	]=]
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

			local boundMethod = BoundMethods[key]
			if boundMethod then
				local wrapper = function(...)
					return boundMethod(self, stripScopeArg(...))
				end
				self[key] = wrapper
				return wrapper
			end

			return Scope[key]
		end,
	})

	return self
end

Renderings = require(script.RenderingBindings)(Scope)
Utilities = require(script.UtilityBindings)(Scope)

for _, bindings in { Renderings, Utilities } do
	for fnName, fn in pairs(bindings) do
		local methodName = fnName:sub(1, -3)
		local camelMethod = methodName:sub(1, 1):lower() .. methodName:sub(2)
		BoundMethods[methodName] = fn
		BoundMethods[camelMethod] = fn
	end
end

return Scope
