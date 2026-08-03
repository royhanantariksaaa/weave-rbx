--!native
--!optimize 2
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
local Debug = require(script.Parent.Debug)

local Engine = {}

-- ━━ 1. Entity Allocator ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local nextStateId = 1
local freeIds = {} :: { number }
local stateGenerations = {} :: { [number]: number }

--[=[
	Allocates a new internal state id.
	@return number
]=]
function Engine.newState(): number
    local id: number
    local nFree = #freeIds
    if nFree > 0 then
        id = freeIds[nFree]
        freeIds[nFree] = nil
    else
        id = nextStateId
        nextStateId += 1
    end
    if stateGenerations[id] == nil then
        stateGenerations[id] = 1
    end
    return id
end

-- ━━ 2. Struct of Arrays ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Engine.Values       = {} :: { [number]: any }
Engine.Changed      = {} :: { [number]: boolean }
Engine.Bindings     = {} :: { [number]: { { instance: Instance, prop: string, index: number } } }
Engine.StateTypes   = {} :: { [number]: string }

Engine.Dependencies = {} :: { [number]: { number } }
Engine.Sources      = {} :: { [number]: { number } }
Engine.Computeds    = {} :: { [number]: (...any) -> any }
Engine.ComputedOpts = {} :: { [number]: { equals: ((any, any) -> boolean)? }? }
Engine.Initialized  = {} :: { [number]: boolean }
Engine.Pending      = {} :: { [number]: boolean }

Engine.Validators   = {} :: { [number]: (any) -> any }
Engine.Overrides    = {} :: { [number]: boolean }
Engine.Reducers     = {} :: { [number]: (any, any) -> any }
Engine.Threads      = {} :: { [number]: thread }
Engine.Signals      = {} :: { [number]: any }

-- Dense reusable queues keep mutation and propagation work proportional to
-- the affected graph instead of scanning every allocated state.
local changedQueue = {} :: { number }
local changedQueueCount = 0
local pendingComputedQueue = {} :: { number }
local pendingComputedCount = 0
local scheduledComputeds = {} :: { [number]: boolean }
local traversalStack = {} :: { number }

-- Adjacency metadata supports O(1) edge insertion/removal while preserving
-- Engine.Dependencies as the public dense-array view.
local dependentPositions = {} :: { [number]: { [number]: number } }
local sourceSets = {} :: { [number]: { [number]: number } }
local scratchSources = {} :: { [number]: { number } }
local scratchSourceSets = {} :: { [number]: { [number]: number } }

local batchDepth = 0
local isFlushing = false
local evaluatingComputeds = {} :: { [number]: boolean }

-- ━━ 3. Accessor Registry ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Weak-key map: getter closure → entity ID
-- This lets the Reconciler, peek(), destroy() etc resolve closures to IDs
Engine.AccessorToId = setmetatable({}, { __mode = "k" }) :: { [any]: number }
local accessorGenerations = setmetatable({}, { __mode = "k" }) :: { [any]: number }

local function assertAlive(id: number, generation: number?)
    if Engine.StateTypes[id] == nil
        or (generation ~= nil and stateGenerations[id] ~= generation)
    then
        error("Weave: attempted to use a destroyed state", 3)
    end
end

function Engine.getGeneration(id: number): number?
    return stateGenerations[id]
end

function Engine.isAlive(id: number, generation: number): boolean
    return Engine.StateTypes[id] ~= nil and stateGenerations[id] == generation
end

-- Resolve a public accessor (closure or state object) to an entity ID. Raw
-- numbers are ordinary application values and must never alias internal IDs.
--[=[
	Resolves a state accessor or raw id to its internal id.
	@param accessor State accessor.
	@return number?
]=]
function Engine.resolveId(accessor: any): number?
    if type(accessor) == "function" then
        local id = Engine.AccessorToId[accessor]
        local generation = accessorGenerations[accessor]
        if id and generation == stateGenerations[id] and Engine.StateTypes[id] ~= nil then
            return id
        end
        return nil
    end
    if type(accessor) == "table" and type(accessor._id) == "number" then
        local id = accessor._id
        local generation = accessor._generation
        if Engine.StateTypes[id] ~= nil
            and (generation == nil or generation == stateGenerations[id])
        then
            return id
        end
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
    local generation = stateGenerations[id]
    local getter = function()
        return Engine.get(id, generation)
    end
    local setter = function(newValue: any)
        Engine.set(id, newValue, generation)
    end
    Engine.AccessorToId[getter] = id
    accessorGenerations[getter] = generation
    return getter, setter
end

-- Create getter-only closure for read-only states (Computed, Async)
--[=[
	Creates a read-only accessor for a state id.
	@param id Internal state id.
	@return () -> any
]=]
function Engine.createReadAccessor(id: number): () -> any
    local generation = stateGenerations[id]
    local getter = function()
        return Engine.get(id, generation)
    end
    Engine.AccessorToId[getter] = id
    accessorGenerations[getter] = generation
    return getter
end

-- ━━ 4. Dependency Tracker ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local activeObserverIds = {}
local observerStackSize = 0

local function addDependent(sourceId: number, observerId: number)
    local positions = dependentPositions[sourceId]
    if positions and positions[observerId] then
        return
    end

    local dependents = Engine.Dependencies[sourceId]
    if not dependents then
        dependents = {}
        Engine.Dependencies[sourceId] = dependents
    end
    if not positions then
        positions = {}
        dependentPositions[sourceId] = positions
    end

    local index = #dependents + 1
    dependents[index] = observerId
    positions[observerId] = index
end

local function removeDependent(sourceId: number, observerId: number)
    local dependents = Engine.Dependencies[sourceId]
    local positions = dependentPositions[sourceId]
    local index = positions and positions[observerId]
    if not dependents or not positions or not index then
        return
    end

    local lastIndex = #dependents
    local lastObserverId = dependents[lastIndex]
    dependents[index] = lastObserverId
    dependents[lastIndex] = nil
    positions[observerId] = nil

    if index ~= lastIndex then
        positions[lastObserverId] = index
    end
    if lastIndex == 1 then
        Engine.Dependencies[sourceId] = nil
        dependentPositions[sourceId] = nil
    end
end

local function prepareDependencyCollection(computedId: number)
    local sources = scratchSources[computedId]
    if not sources then
        sources = {}
        scratchSources[computedId] = sources
    else
        table.clear(sources)
    end

    local sourcesSet = scratchSourceSets[computedId]
    if not sourcesSet then
        sourcesSet = {}
        scratchSourceSets[computedId] = sourcesSet
    else
        table.clear(sourcesSet)
    end
end

local function commitDependencies(computedId: number)
    local previousSources = Engine.Sources[computedId]
    local previousSet = sourceSets[computedId]
    local nextSources = scratchSources[computedId] or {}
    local nextSet = scratchSourceSets[computedId] or {}

    if previousSources then
        for _, sourceId in previousSources do
            if not nextSet[sourceId] then
                removeDependent(sourceId, computedId)
            end
        end
    end
    for _, sourceId in nextSources do
        if not previousSet or not previousSet[sourceId] then
            addDependent(sourceId, computedId)
        end
    end

    Engine.Sources[computedId] = nextSources
    sourceSets[computedId] = nextSet

    local reusableSources = previousSources or {}
    local reusableSet = previousSet or {}
    table.clear(reusableSources)
    table.clear(reusableSet)
    scratchSources[computedId] = reusableSources
    scratchSourceSets[computedId] = reusableSet
end

--[=[
	Pushes an active observer.
	@param computedId Computed state id.
]=]
function Engine.pushObserver(computedId: number)
    prepareDependencyCollection(computedId)
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
        local sourcesSet = scratchSourceSets[observerId]
        if sourcesSet and not sourcesSet[sourceId] then
            local sources = scratchSources[observerId]
            local sourceIndex = #sources + 1
            sources[sourceIndex] = sourceId
            sourcesSet[sourceId] = sourceIndex
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

local function markChanged(id: number)
    if Engine.Changed[id] then
        return
    end
    Engine.Changed[id] = true
    changedQueueCount += 1
    changedQueue[changedQueueCount] = id
end

--[=[
	Begins a nested mutation batch. Values remain immediately readable while
	computed propagation and Instance binding updates wait for the outer batch.
]=]
function Engine.beginBatch()
    batchDepth += 1
end

--[=[
	Ends a mutation batch and flushes when the outermost batch closes.
]=]
function Engine.endBatch()
    assert(batchDepth > 0, "Engine.endBatch called without a matching beginBatch")
    batchDepth -= 1
    if batchDepth == 0 then
        Engine.flush()
    end
end

--[=[
	Runs a callback inside a mutation batch and returns all callback results.
	@param fn Callback containing state mutations.
	@return ...any
]=]
function Engine.batch(fn: () -> any): any
    Engine.beginBatch()
    local results = table.pack(pcall(fn))
    local flushOk, flushError = pcall(Engine.endBatch)

    if not results[1] then
        error(results[2], 2)
    end
    if not flushOk then
        error(flushError, 2)
    end
    return table.unpack(results, 2, results.n)
end

-- ━━ 5. Core Read/Write Functions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Reads the current value.
	@param id Internal state id.
	@return any
]=]
function Engine.get(id: number, generation: number?): any
    assertAlive(id, generation)
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
	@param accessorOrId State accessor or wrapper.
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
function Engine.set(id: number, newValue: any, generation: number?)
    assertAlive(id, generation)
    local validator = Engine.Validators[id]
    if validator then
        newValue = validator(newValue)
    end
    local currentValue = Engine.Values[id]
    if currentValue ~= newValue then
        Engine.Values[id] = newValue
        markChanged(id)
        local signal = Engine.Signals[id]
        if signal then
            signal:Fire(newValue)
        end
        if batchDepth == 0 and not isFlushing then
            Engine.flush()
        end
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
    Engine.Computeds[id] = callback :: (...any) -> any
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
    Engine.Computeds[id] = callback :: (...any) -> any
    Engine.ComputedOpts[id] = options
    Engine.StateTypes[id] = "Derived"
    Engine.Initialized[id] = false
    Engine.Pending[id] = false
    Engine.Overrides[id] = false
    Engine.Signals[id] = Signal.new()
    Engine._flushComputed(id)
    
    local getter = Engine.createReadAccessor(id)
    local generation = stateGenerations[id]
    local setter = function(newValue: any)
        assertAlive(id, generation)
        if Engine.Values[id] ~= newValue then
            Engine.Values[id] = newValue
            Engine.Overrides[id] = true
            Engine.Initialized[id] = true
            markChanged(id)
            local signal = Engine.Signals[id]
            if signal then
                signal:Fire(newValue)
            end
            if batchDepth == 0 and not isFlushing then
                Engine.flush()
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
    local generation = stateGenerations[id]
    local dispatch = function(action: any)
        assertAlive(id, generation)
        local newValue = reducerFn(Engine.Values[id], action)
        if Engine.Values[id] ~= newValue then
            Engine.Values[id] = newValue
            markChanged(id)
            local signal = Engine.Signals[id]
            if signal then
                signal:Fire(newValue)
            end
            if batchDepth == 0 and not isFlushing then
                Engine.flush()
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
    local generation = stateGenerations[id]
    
    Engine.Threads[id] = task.spawn(function()
        local success, result = pcall(asyncFn)
        if not Engine.isAlive(id, generation) then
            return
        end
        if success then
            Engine.set(id, { Status = "Resolved", Value = result, Error = nil }, generation)
        else
            Engine.set(id, { Status = "Rejected", Value = nil, Error = result }, generation)
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
	Debug.Track("ComputedEvaluations")
    
    local callback = Engine.Computeds[id]
    local oldVal = Engine.Values[id]
    local wasInitialized = Engine.Initialized[id] == true

    if evaluatingComputeds[id] then
        error(`Weave: cyclic computed dependency detected at state {id}`, 2)
    end
    evaluatingComputeds[id] = true
    Engine.pushObserver(id)
    local evaluation = table.pack(pcall(callback))
    Engine.popObserver()
    evaluatingComputeds[id] = nil

    if not evaluation[1] then
        local pendingSources = scratchSources[id]
        local pendingSet = scratchSourceSets[id]
        if pendingSources then table.clear(pendingSources) end
        if pendingSet then table.clear(pendingSet) end
        Engine.Pending[id] = true
        error(evaluation[2], 2)
    end

    commitDependencies(id)
    local newVal = evaluation[2]

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
        if wasInitialized then
            markChanged(id)
            local signal = Engine.Signals[id]
            if signal then
                signal:Fire(newVal)
            end
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
    if batchDepth > 0 or isFlushing or changedQueueCount == 0 then
        return
    end

	isFlushing = true
	Debug.Track("SchedulerFlushes")
	local flushStartedAt = if Debug.Enabled then os.clock() else 0
    local dirtyReadIndex = 1
    local computedReadIndex = 1
    local bindingReadIndex = 1
	local computedEvaluations = 0

    local function scheduleDependentTree(sourceId: number)
        local stackCount = 1
        traversalStack[1] = sourceId

        while stackCount > 0 do
            local currentId = traversalStack[stackCount]
            traversalStack[stackCount] = nil
            stackCount -= 1

            local dependents = Engine.Dependencies[currentId]
            if dependents then
                for _, dependentId in dependents do
                    if Engine.Computeds[dependentId] and not scheduledComputeds[dependentId] then
                        scheduledComputeds[dependentId] = true
                        Engine.Pending[dependentId] = true
                        if Engine.StateTypes[dependentId] == "Derived" then
                            Engine.Overrides[dependentId] = false
                        end

                        pendingComputedCount += 1
                        pendingComputedQueue[pendingComputedCount] = dependentId
                        stackCount += 1
                        traversalStack[stackCount] = dependentId
                    end
                end
            end
        end
    end

    local ok, flushError = pcall(function()
        while true do
            -- Mark the complete affected subgraph before evaluation. This lets
            -- Engine.get lazily resolve upstream computeds in dependency order.
            while dirtyReadIndex <= changedQueueCount do
                scheduleDependentTree(changedQueue[dirtyReadIndex])
                dirtyReadIndex += 1
            end

            while computedReadIndex <= pendingComputedCount do
                local computedId = pendingComputedQueue[computedReadIndex]
                computedReadIndex += 1
                scheduledComputeds[computedId] = nil
                if Engine.Computeds[computedId] and Engine.Pending[computedId] then
					computedEvaluations += 1
                    Engine._flushComputed(computedId)
                end
            end

            -- Computed evaluations can append changed IDs. Schedule their
            -- dependents before applying bindings.
            if dirtyReadIndex <= changedQueueCount then
                continue
            end

            while bindingReadIndex <= changedQueueCount do
                local stateId = changedQueue[bindingReadIndex]
                bindingReadIndex += 1
                if Engine.Changed[stateId] then
                    Engine.Changed[stateId] = nil
                    local bindings = Engine.Bindings[stateId]
                    if bindings then
                        local value = Engine.Values[stateId]
                        for _, binding in bindings do
                            (binding.instance :: any)[binding.prop] = value
                        end
                    end
                end
            end

            if dirtyReadIndex > changedQueueCount
                and computedReadIndex > pendingComputedCount
                and bindingReadIndex > changedQueueCount
            then
                break
            end
        end
    end)

    if not ok then
        for index = 1, pendingComputedCount do
            scheduledComputeds[pendingComputedQueue[index]] = nil
        end
        table.clear(pendingComputedQueue)
        table.clear(traversalStack)
        pendingComputedCount = 0
        isFlushing = false
        error(flushError, 2)
    end

	local statesFlushed = changedQueueCount
	if Debug.Enabled then
		local flushMs = (os.clock() - flushStartedAt) * 1000
		if flushMs >= Debug.SlowFlushThreshold then
			local stats = {
				flushMs = flushMs,
				statesFlushed = statesFlushed,
				iterations = computedEvaluations,
			}
			warn(string.format(
				"[Weave] Slow reactive flush: %.2fms (%d states, %d computed evaluations)",
				flushMs,
				statesFlushed,
				computedEvaluations
			))
			if Debug.OnSlowFlush then
				local callbackSuccess, callbackError = pcall(Debug.OnSlowFlush, stats)
				if not callbackSuccess then
					warn("[Weave] Debug.OnSlowFlush failed: " .. tostring(callbackError))
				end
			end
		end
	end

	table.clear(changedQueue)
    table.clear(pendingComputedQueue)
    table.clear(traversalStack)
    changedQueueCount = 0
    pendingComputedCount = 0
    isFlushing = false
end

-- ━━ 9. Cleanup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--[=[
	Destroys the object and releases resources.
	@param accessorOrId State accessor or wrapper.
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
    
    local sources = Engine.Sources[id]
    if sources then
        for _, sourceId in sources do
            removeDependent(sourceId, id)
        end
    end

    local dependents = Engine.Dependencies[id]
    if dependents then
        for _, dependentId in dependents do
            local dependentSources = Engine.Sources[dependentId]
            local dependentSet = sourceSets[dependentId]
            local sourceIndex = dependentSet and dependentSet[id]
            if dependentSources and dependentSet and sourceIndex then
                local lastIndex = #dependentSources
                local lastSourceId = dependentSources[lastIndex]
                dependentSources[sourceIndex] = lastSourceId
                dependentSources[lastIndex] = nil
                if sourceIndex ~= lastIndex then
                    dependentSet[lastSourceId] = sourceIndex
                end
                dependentSet[id] = nil
            end
        end
    end

    Engine.Values[id] = nil
    Engine.Changed[id] = nil
    Engine.Bindings[id] = nil
    Engine.Dependencies[id] = nil
    Engine.Sources[id] = nil
    Engine.Computeds[id] = nil
    Engine.ComputedOpts[id] = nil
    Engine.Initialized[id] = nil
    Engine.Pending[id] = nil
    Engine.Validators[id] = nil
    Engine.StateTypes[id] = nil
    Engine.Overrides[id] = nil
    Engine.Reducers[id] = nil

    dependentPositions[id] = nil
    sourceSets[id] = nil
    scratchSources[id] = nil
    scratchSourceSets[id] = nil
    scheduledComputeds[id] = nil
    evaluatingComputeds[id] = nil

    stateGenerations[id] = (stateGenerations[id] or 0) + 1
    freeIds[#freeIds + 1] = id
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
