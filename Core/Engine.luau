--!strict
--[=[
	@module Engine
	@within Weave.Core

	Core runtime helper used by Weave rendering and reactivity internals.
]=]

-- Engine: Pure Data-Oriented State Engine with Closure Accessor API
-- All state is stored in flat parallel arrays keyed by integer ID.
-- Public API returns lightweight closures (getter/setter) instead of raw IDs.

local Signal = require(game:GetService("ReplicatedStorage").Libraries.Echo)

local Engine = {}

-- ━━ 1. Entity Allocator ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local nextStateId = 1
local freeIds = {}

--[=[
	Allocates a new internal state id.
	@return number
]=]
function Engine.newState(): number
    local id
    local nFree = #freeIds
    if nFree > 0 then
        id = freeIds[nFree]
        freeIds[nFree] = nil
    else
        id = nextStateId
        nextStateId += 1
    end
    return id
end

-- ━━ 2. Struct of Arrays ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Engine.Values       = {} :: { [number]: any }
Engine.Changed      = {} :: { [number]: boolean }
Engine.Bindings     = {} :: { [number]: { { instance: Instance, prop: string } } }
Engine.StateTypes   = {} :: { [number]: string }

Engine.Dependencies = {} :: { [number]: { number } }
Engine.Computeds    = {} :: { [number]: (...any) -> any }
Engine.ComputedOpts = {} :: { [number]: { equals: ((any, any) -> boolean)? }? }
Engine.Initialized  = {} :: { [number]: boolean }
Engine.Pending      = {} :: { [number]: boolean }

Engine.Validators   = {} :: { [number]: (any) -> any }
Engine.Overrides    = {} :: { [number]: boolean }
Engine.Reducers     = {} :: { [number]: (any, any) -> any }
Engine.Threads      = {} :: { [number]: thread }
Engine.Signals      = {} :: { [number]: any }

-- ━━ 3. Accessor Registry ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Weak-key map: getter closure → entity ID
-- This lets the Reconciler, peek(), destroy() etc resolve closures to IDs
Engine.AccessorToId = setmetatable({}, { __mode = "k" }) :: { [any]: number }

-- Resolve any accessor (closure, integer, or animation object) to an entity ID
--[=[
	Resolves a state accessor or raw id to its internal id.
	@param accessor State accessor.
	@return number?
]=]
function Engine.resolveId(accessor: any): number?
    if type(accessor) == "number" then
        return accessor
    end
    if type(accessor) == "function" then
        return Engine.AccessorToId[accessor]
    end
    if type(accessor) == "table" and accessor._id then
        return accessor._id
    end
    return nil
end

-- Create (getter, setter) closures for a state entity
--[=[
	Creates read and write accessors for state.
	@param id Internal state id.
	@return (() -> any, (any) -> ())
]=]
function Engine.createAccessor(id: number): ((() -> any), (any) -> ())
    local getter = function()
        return Engine.get(id)
    end
    local setter = function(newValue: any)
        Engine.set(id, newValue)
    end
    Engine.AccessorToId[getter] = id
    return getter, setter
end

-- Create getter-only closure for read-only states (Computed, Async)
--[=[
	Creates a read-only accessor for a state id.
	@param id Internal state id.
	@return () -> any
]=]
function Engine.createReadAccessor(id: number): () -> any
    local getter = function()
        return Engine.get(id)
    end
    Engine.AccessorToId[getter] = id
    return getter
end

-- ━━ 4. Dependency Tracker ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local activeObserverIds = {}
local observerStackSize = 0

--[=[
	Pushes an active observer.
	@param computedId Computed state id.
]=]
function Engine.pushObserver(computedId: number)
    observerStackSize += 1
    activeObserverIds[observerStackSize] = computedId
end

--[=[
	Pops the active observer.
]=]
function Engine.popObserver()
    activeObserverIds[observerStackSize] = nil
    observerStackSize -= 1
end

local function trackDependency(sourceId: number)
    if observerStackSize > 0 then
        local observerId = activeObserverIds[observerStackSize]
        local deps = Engine.Dependencies[sourceId]
        if not deps then
            deps = {}
            Engine.Dependencies[sourceId] = deps
        end
        if not table.find(deps, observerId) then
            table.insert(deps, observerId)
        end
    end
end

-- Scope tracking
local activeScopes = {}
local scopeStackSize = 0

--[=[
	Pushes a scope as the active owner for newly-created resources.
	@param scope Scope object.
]=]
function Engine.pushScope(scope: any)
    scopeStackSize += 1
    activeScopes[scopeStackSize] = scope
end

--[=[
	Pops the active scope.
]=]
function Engine.popScope()
    activeScopes[scopeStackSize] = nil
    scopeStackSize -= 1
end

--[=[
	Returns the active scope.
	@return any?
]=]
function Engine.getCurrentScope(): any?
    if scopeStackSize > 0 then
        return activeScopes[scopeStackSize]
    end
    return nil
end

-- ━━ 5. Core Read/Write Functions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Reads the current value.
	@param id Internal state id.
	@return any
]=]
function Engine.get(id: number): any
    if Engine.Computeds[id] then
        local stateType = Engine.StateTypes[id]
        if stateType == "Derived" and Engine.Overrides[id] and Engine.Initialized[id] then
            -- Derived with override: skip flush
        elseif not Engine.Initialized[id] or Engine.Pending[id] then
            Engine._flushComputed(id)
        end
    end
    trackDependency(id)
    return Engine.Values[id]
end

--[=[
	Reads the current value without dependency tracking.
	@param accessorOrId State accessor or internal id.
	@return any
]=]
function Engine.peek(accessorOrId: any): any
    local id = Engine.resolveId(accessorOrId)
    if id then
        return Engine.Values[id]
    end
    return nil
end

--[=[
	Writes a new value.
	@param id Internal state id.
	@param newValue Value to write.
]=]
function Engine.set(id: number, newValue: any)
    local validator = Engine.Validators[id]
    if validator then
        newValue = validator(newValue)
    end
    local currentValue = Engine.Values[id]
    if currentValue ~= newValue then
        Engine.Values[id] = newValue
        Engine.Changed[id] = true
        local signal = Engine.Signals[id]
        if signal then
            signal:Fire(newValue)
        end
        Engine.flush()
    end
end

--[=[
	Updates the current value from a callback.
	@param id Internal state id.
	@param updater Callback that receives the current value.
]=]
function Engine.update(id: number, updater: (any) -> any)
    Engine.set(id, updater(Engine.Values[id]))
end

-- ━━ 6. State Constructors ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Creates a mutable state value.
	@param initialValue Value passed to this API.
	@param options Value passed to this API.
	@return (() -> any, (any) -> ())
]=]
function Engine.value(initialValue: any, options: { validate: ((any) -> any)? }?): ((() -> any), (any) -> ())
    local id = Engine.newState()
    local validator = options and options.validate or nil
    if validator then
        Engine.Validators[id] = validator
        initialValue = validator(initialValue)
    end
    Engine.Values[id] = initialValue
    Engine.StateTypes[id] = "Value"
    Engine.Signals[id] = Signal.new()
    return Engine.createAccessor(id)
end

--[=[
	Creates a computed state value.
	@param callback Callback invoked by this API.
	@param options Value passed to this API.
	@return () -> any
]=]
function Engine.computed(callback: () -> any, options: { equals: ((any, any) -> boolean)? }?): () -> any
    local id = Engine.newState()
    Engine.Computeds[id] = callback
    Engine.ComputedOpts[id] = options
    Engine.StateTypes[id] = "Computed"
    Engine.Initialized[id] = false
    Engine.Pending[id] = false
    Engine.Signals[id] = Signal.new()
    Engine._flushComputed(id)
    return Engine.createReadAccessor(id)
end

--[=[
	Creates a derived value with an exposed setter.
	@param callback Callback invoked by this API.
	@param options Optional configuration table.
	@return (() -> any, (any) -> ())
]=]
function Engine.derived(callback: () -> any, options: { equals: ((any, any) -> boolean)? }?): ((() -> any), (any) -> ())
    local id = Engine.newState()
    Engine.Computeds[id] = callback
    Engine.ComputedOpts[id] = options
    Engine.StateTypes[id] = "Derived"
    Engine.Initialized[id] = false
    Engine.Pending[id] = false
    Engine.Overrides[id] = false
    Engine.Signals[id] = Signal.new()
    Engine._flushComputed(id)
    
    local getter = Engine.createReadAccessor(id)
    local setter = function(newValue: any)
        if Engine.Values[id] ~= newValue then
            Engine.Values[id] = newValue
            Engine.Overrides[id] = true
            Engine.Initialized[id] = true
            local signal = Engine.Signals[id]
            if signal then
                signal:Fire(newValue)
            end
        end
    end
    return getter, setter
end

--[=[
	Creates reducer-backed state and a dispatch function.
	@param reducerFn Value passed to the reducer operation.
	@param initialState Value passed to the reducer operation.
	@return (() -> any, (any) -> ())
]=]
function Engine.reducer(reducerFn: (any, any) -> any, initialState: any): ((() -> any), (any) -> ())
    local id = Engine.newState()
    Engine.Values[id] = initialState
    Engine.Reducers[id] = reducerFn
    Engine.StateTypes[id] = "Reducer"
    Engine.Signals[id] = Signal.new()
    
    local getter = Engine.createReadAccessor(id)
    local dispatch = function(action: any)
        local newValue = reducerFn(Engine.Values[id], action)
        if Engine.Values[id] ~= newValue then
            Engine.Values[id] = newValue
            local signal = Engine.Signals[id]
            if signal then
                signal:Fire(newValue)
            end
        end
    end
    return getter, dispatch
end

--[=[
	Creates reactive state from an asynchronous producer.
	@param asyncFn Value passed to the async operation.
	@return () -> any
]=]
function Engine.async(asyncFn: () -> any): () -> any
    local id = Engine.newState()
    Engine.Values[id] = { Status = "Pending", Value = nil, Error = nil }
    Engine.StateTypes[id] = "Async"
    Engine.Signals[id] = Signal.new()
    
    Engine.Threads[id] = task.spawn(function()
        local success, result = pcall(asyncFn)
        if success then
            Engine.Values[id] = { Status = "Resolved", Value = result, Error = nil }
        else
            Engine.Values[id] = { Status = "Rejected", Value = nil, Error = result }
        end
        local signal = Engine.Signals[id]
        if signal then
            signal:Fire(Engine.Values[id])
        end
    end)
    
    return Engine.createReadAccessor(id)
end

-- ━━ 7. Computed Flush ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Handles the _flushComputed operation for Engine.
	@param id Internal state id.
]=]
function Engine._flushComputed(id: number)
    if Engine.StateTypes[id] == "Derived" and Engine.Overrides[id] and Engine.Initialized[id] then
        Engine.Pending[id] = false
        return
    end
    if not Engine.Pending[id] and Engine.Initialized[id] then return end
    Engine.Pending[id] = false
    
    local callback = Engine.Computeds[id]
    local oldVal = Engine.Values[id]
    
    Engine.pushObserver(id)
    local newVal = callback()
    Engine.popObserver()
    
    local isChanged = false
    if not Engine.Initialized[id] then
        isChanged = true
    else
        local opts = Engine.ComputedOpts[id]
        local equalsFn = opts and opts.equals
        if equalsFn then
            isChanged = not equalsFn(oldVal, newVal)
        else
            isChanged = oldVal ~= newVal
        end
    end
    
    if isChanged then
        Engine.Values[id] = newVal
        Engine.Initialized[id] = true
        Engine.Changed[id] = true
        local signal = Engine.Signals[id]
        if signal then
            signal:Fire(newVal)
        end
    elseif not Engine.Initialized[id] then
        Engine.Initialized[id] = true
    end
end

-- ━━ 8. Reactive Flush Loop ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Flushes pending computed updates.
]=]
function Engine.flush()
    local function evaluateDependentComputeds(id: number)
        local dependents = Engine.Dependencies[id]
        if dependents then
            for _, depId in dependents do
                if Engine.Computeds[depId] then
                    local oldVal = Engine.Values[depId]
                    if Engine.StateTypes[depId] == "Derived" then
                        Engine.Overrides[depId] = false
                    end
                    Engine.Pending[depId] = true
                    Engine._flushComputed(depId)
                    if oldVal ~= Engine.Values[depId] then
                        evaluateDependentComputeds(depId)
                    end
                end
            end
        end
    end
    
    local currentlyChanged = {}
    for k, v in pairs(Engine.Changed) do
        currentlyChanged[k] = v
    end
    for stateId, isChanged in pairs(currentlyChanged) do
        if isChanged then
            evaluateDependentComputeds(stateId)
        end
    end
    
    for stateId, isChanged in pairs(Engine.Changed) do
        if isChanged then
            local val = Engine.Values[stateId]
            local bindings = Engine.Bindings[stateId]
            if bindings then
                for _, bind in bindings do
                    (bind.instance :: any)[bind.prop] = val
                end
            end
            Engine.Changed[stateId] = nil
        end
    end
end

-- ━━ 9. Cleanup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Destroys the object and releases resources.
	@param accessorOrId State accessor or internal id.
]=]
function Engine.destroy(accessorOrId: any)
    local id = Engine.resolveId(accessorOrId)
    if not id then return end
    
    local thread = Engine.Threads[id]
    if thread then
        task.cancel(thread)
        Engine.Threads[id] = nil
    end
    local signal = Engine.Signals[id]
    if signal then
        signal:Destroy()
        Engine.Signals[id] = nil
    end
    
    Engine.Values[id] = nil
    Engine.Changed[id] = nil
    Engine.Bindings[id] = nil
    Engine.Dependencies[id] = nil
    Engine.Computeds[id] = nil
    Engine.ComputedOpts[id] = nil
    Engine.Initialized[id] = nil
    Engine.Pending[id] = nil
    Engine.Validators[id] = nil
    Engine.StateTypes[id] = nil
    Engine.Overrides[id] = nil
    Engine.Reducers[id] = nil
    
    for sourceId, deps in pairs(Engine.Dependencies) do
        local idx = table.find(deps, id)
        if idx then
            table.remove(deps, idx)
        end
    end
    
    table.insert(freeIds, id)
end

--[=[
	Returns whether a value is a Weave state accessor.
	@param value Value passed to the isState operation.
	@return boolean
]=]
function Engine.isState(value: any): boolean
    local id = Engine.resolveId(value)
    return id ~= nil and Engine.StateTypes[id] ~= nil
end

return Engine
