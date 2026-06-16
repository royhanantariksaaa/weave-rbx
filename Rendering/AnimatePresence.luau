--[=[
	@within Weave

	Per-item exit animations for dynamic lists. Like `Stagger`/`ForValues`,
	but items are not destroyed until their `Exit` function finishes, enabling
	clean leave animations.

	@param itemsState -- reactive list/table of items
	@param renderFn (scope, item, ...) -> WeaveNode -- renders each item
	@param options { Exit: (scope, item, ...) -> () } -- exit animation per item
	@return WeaveNode
]=]

local Shared = require(script.Parent._shared)
local Helpers = require(script.Parent.Parent.Core.Helpers)
local WeaveTypes = require(script.Parent.Parent.Types)

return function(Scope, Signal)
	return function(self, sourceState, renderFunc, options)
		local exitFunc = options and options.Exit
		if not exitFunc then
			-- If no Exit function provided, just behave like a standard ForValues
			return Shared.createCollectionNode(Signal, Scope, self, sourceState, true, renderFunc)
		end

		local presDef = {
			_WeaveNodeType = WeaveTypes.NodeType.Rendering,
			_instances = {},
			_changed = Signal.new(),
			_troveMap = {},
			_instanceMap = {},
			-- state specific
			_activeKeys = {},
			_exitingKeys = {},
		}
		self._trove:Add(presDef._changed)

		local function rebuildList()
			local newInstances = {}
			-- We must render all active + all currently exiting items in order
			-- To keep it simple, we just append exiting items at the end, or we could sort by original index.
			-- For now, active items first, exiting appended.
			
			for i, key in ipairs(presDef._activeKeys) do
				local inst = presDef._instanceMap[key]
				if inst then table.insert(newInstances, inst) end
			end
			
			for key, _ in pairs(presDef._exitingKeys) do
				local inst = presDef._instanceMap[key]
				if inst then table.insert(newInstances, inst) end
			end

			local changed = Shared.didInstancesChange(presDef._instances, newInstances)
			presDef._instances = newInstances
			if changed then
				presDef._changed:Fire(presDef._instances)
			end
		end

		local function processItemEntry(key, index)
			if presDef._exitingKeys[key] then
				-- Cancel exit! It came back.
				presDef._exitingKeys[key] = nil
				return
			end

			if not presDef._troveMap[key] then
				-- New item
				local childScope = Scope.new(self)
				local inst = renderFunc(childScope, key, index)
				presDef._instanceMap[key] = inst
				presDef._troveMap[key] = childScope._trove
			end
		end

		local function processItemExit(key)
			if presDef._exitingKeys[key] then return end -- already exiting
			
			local inst = presDef._instanceMap[key]
			local trove = presDef._troveMap[key]
			
			if inst and trove then
				presDef._exitingKeys[key] = true
				
				-- Run the exit animation
				task.spawn(function()
					-- Temporarily create a dummy scope just for the exit func to use if needed
					-- though usually it just tweens the instance.
					local exitScope = Scope.new(self)
					exitFunc(exitScope, inst)
					
					-- Clean up once it's done
					exitScope:Destroy()
					
					-- Ensure it hasn't re-entered while we were animating
					if presDef._exitingKeys[key] then
						presDef._exitingKeys[key] = nil
						presDef._instanceMap[key] = nil
						presDef._troveMap[key] = nil
						trove:Destroy()
						rebuildList()
					end
				end)
			end
		end

		local function update()
			local currentItems = type(sourceState) == "function" and sourceState() or sourceState
			if type(currentItems) ~= "table" then currentItems = {} end
			
			-- Track what's currently active to find what was removed
			local newKeysMap = {}
			presDef._activeKeys = {}
			
			for index, val in ipairs(currentItems) do
				newKeysMap[val] = true
				table.insert(presDef._activeKeys, val)
				processItemEntry(val, index)
			end
			
			-- Find keys that were in our troveMap but are no longer in newKeysMap
			for key, _ in pairs(presDef._troveMap) do
				if not newKeysMap[key] and not presDef._exitingKeys[key] then
					processItemExit(key)
				end
			end
			
			rebuildList()
		end

		self.effect(update)

		self._trove:Add(function()
			Helpers.DestroyAll(presDef._troveMap)
		end)

		return presDef
	end
end
