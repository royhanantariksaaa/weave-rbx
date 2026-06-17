--[=[
	@within Weave
	@module RenderingShared

	Shared helpers for Rendering primitives. Internal module — eliminates
	boilerplate across Show, Switch, Transition, ErrorBoundary, and Portal.
	Not part of the public API.
]=]

local WeaveTypes = require(script.Parent.Parent.Types)
local Helpers = require(script.Parent.Parent.Core.Helpers)
local Engine = require(script.Parent.Parent.Core.Engine)
local Shared = {}

--[=[
	Resolves a state-backed value.
	@param value Value used by this API.
	@return any
]=]
function Shared.resolveStateValue(value)
	if type(value) == "function" then
		return value()
	end
	if type(value) == "table" and type(value.Get) == "function" then
		return value:Get()
	end
	return value
end

-- Creates a standard WeaveNode definition with signal and cleanup.
--[=[
	Creates the internal definition for a rendered node.
	@param Signal Signal constructor or module.
	@param parentTrove Parent cleanup container.
	@return any
]=]
function Shared.createNodeDef(Signal, parentTrove)
	local nodeDef = {
		_WeaveNodeType = WeaveTypes.NodeType.Rendering,
		_instances = {},
		_changed = Signal.new(),
		_trove = nil,
	}
	parentTrove:Add(nodeDef._changed)
	return nodeDef
end

-- Normalizes a builder result into a flat instance array.
-- Handles: Instance, numeric-array, WeaveNode, WeaveForValues, or nil.
--[=[
	Normalizes render results.
	@param result Render callback result.
	@return { Instance }
]=]
function Shared.normalizeResult(result)
	if result == nil then
		return {}
	elseif typeof(result) == "Instance" then
		return { result }
	elseif type(result) == "table" then
		if result._WeaveNodeType == WeaveTypes.NodeType.Rendering then
			return result._instances
		elseif result[1] ~= nil then
			return result
		end
	end
	return {}
end

-- Shallow-compares two instance arrays. Returns true if they differ.
--[=[
	Returns whether two Instance lists differ.
	@param oldList Previous Instance list.
	@param newList Next Instance list.
	@return boolean
]=]
function Shared.didInstancesChange(oldList, newList)
	if #oldList ~= #newList then return true end
	for i = 1, #newList do
		if newList[i] ~= oldList[i] then return true end
	end
	return false
end

-- Destroys the current trove, creates a new child scope, calls evaluateCallback,
-- normalizes result into _instances, and fires _changed.
-- evaluateCallback receives (childScope) and should return the builder result.
-- If evaluateCallback is nil, clears _instances and fires empty.
--[=[
	Rebuilds a rendered node.
	@param nodeDef Rendered node definition.
	@param Scope Scope object.
	@param parentScope Value passed to this API.
	@param evaluateCallback Value passed to this API.
]=]
function Shared.rebuildNode(nodeDef, Scope, parentScope, evaluateCallback)
	if nodeDef._trove then
		nodeDef._trove:Destroy()
		nodeDef._trove = nil
	end
	nodeDef._instances = {}
	if evaluateCallback then
		local childScope = Scope.new(parentScope)
		nodeDef._trove = childScope._trove
		Engine.pushScope(childScope)
		local result = evaluateCallback(childScope)
		Engine.popScope()
		nodeDef._instances = Shared.normalizeResult(result)
	end
	nodeDef._changed:Fire(nodeDef._instances)
end

-- Subscribes updateFn to state via Scope.effect, calls updateFn() for initial render
-- (which happens automatically in effect), and registers trove cleanup.
--[=[
	Binds a rendered node to state changes.
	@param nodeDef Rendered node definition.
	@param scopeInstance Value passed to the bindNodeToState operation.
	@param updateFn Callback used to update pooled items.
]=]
function Shared.bindNodeToState(nodeDef, scopeInstance, updateFn)
	scopeInstance.effect(updateFn)
	scopeInstance._trove:Add(function() if nodeDef._trove then nodeDef._trove:Destroy() end end)
	return nodeDef
end

-- Registers standard trove cleanup for a node and returns nodeDef for chaining.
-- Use for one-shot nodes that don't subscribe to state changes (ErrorBoundary, Portal, Provider).
--[=[
	Registers node cleanup.
	@param nodeDef Rendered node definition.
	@param parentTrove Parent cleanup container.
]=]
function Shared.registerCleanup(nodeDef, parentTrove)
	parentTrove:Add(function() if nodeDef._trove then nodeDef._trove:Destroy() end end)
	return nodeDef
end

-- Destroys the trove, clears instances, and fires an empty change signal.
-- Extracted from Transition where this pattern was duplicated inline.
--[=[
	Clears rendered node state.
	@param nodeDef Rendered node definition.
]=]
function Shared.clearNode(nodeDef)
	if nodeDef._trove then nodeDef._trove:Destroy(); nodeDef._trove = nil end
	nodeDef._instances = {}
	nodeDef._changed:Fire({})
end

--[=[
	Reconciles rendered collection children.
	@param nodeDef Rendered node definition.
	@param Scope Scope object.
	@param parentScope Parent scope object.
	@param mapOrArray Collection source.
	@param isArray Whether the collection is array-like.
	@param renderFunc Callback that renders each collection item.
]=]
function Shared.reconcileCollection(nodeDef, Scope, parentScope, mapOrArray, isArray, renderFunc)
	local newTroveMap = nodeDef._tempTroveMap
	local newInstanceMap = nodeDef._tempInstanceMap
	local newInstances = nodeDef._tempInstances
	table.clear(newTroveMap)
	table.clear(newInstanceMap)
	table.clear(newInstances)

	local instanceCount = 0

	local function processItem(key, val)
		if nodeDef._troveMap[key] then
			-- Reuse existing entry
			newInstanceMap[key] = nodeDef._instanceMap[key]
			newTroveMap[key] = nodeDef._troveMap[key]
			nodeDef._troveMap[key] = nil -- mark consumed
		else
			local childScope = Scope.new(parentScope)
			Engine.pushScope(childScope)
			local inst = renderFunc(childScope, key, val)
			Engine.popScope()
			newInstanceMap[key] = inst
			newTroveMap[key] = childScope._trove
		end
		instanceCount += 1
		newInstances[instanceCount] = newInstanceMap[key]
	end

	if isArray then
		for index, val in ipairs(mapOrArray) do
			processItem(val, index) -- Key is the value for array reuse
		end
	else
		for key, val in pairs(mapOrArray) do
			processItem(key, val) -- Key is the key for map reuse
		end
	end

	-- Clean up removed keys
	Helpers.DestroyAll(nodeDef._troveMap)

	-- Only fire if instances actually changed
	local changed = Shared.didInstancesChange(nodeDef._instances, newInstances)
	
	nodeDef._tempInstanceMap, nodeDef._instanceMap = nodeDef._instanceMap, newInstanceMap
	nodeDef._tempTroveMap, nodeDef._troveMap = nodeDef._troveMap, newTroveMap
	nodeDef._tempInstances, nodeDef._instances = nodeDef._instances, newInstances
	
	if changed then
		nodeDef._changed:Fire(nodeDef._instances)
	end
end

-- Factory for ForValues/ForKeys: eliminates duplicated forDef setup + wiring.
--[=[
	Creates a rendered collection node.
	@param Signal Signal constructor or module.
	@param Scope Scope object.
	@param sourceState State that drives the collection.
	@param isArray Whether the collection is array-like.
	@param renderFunc Callback that renders each collection item.
	@return any
]=]
function Shared.createCollectionNode(Signal, Scope, self, sourceState, isArray, renderFunc)
	local forDef = {
		_WeaveNodeType = WeaveTypes.NodeType.Rendering,
		_instances = {},
		_changed = Signal.new(),
		_troveMap = {},
		_instanceMap = {},
		_tempTroveMap = {},
		_tempInstanceMap = {},
		_tempInstances = {},
	}
	self._trove:Add(forDef._changed)

	local function update()
		local tbl = Shared.resolveStateValue(sourceState)
		if type(tbl) ~= "table" then tbl = {} end
		Shared.reconcileCollection(forDef, Scope, self, tbl, isArray, renderFunc)
	end

	self.effect(update)
	self._trove:Add(function() Helpers.DestroyAll(forDef._troveMap) end)
	return forDef
end

return Shared
