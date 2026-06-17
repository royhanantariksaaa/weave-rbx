--!optimize 2
--[=[
	@within Weave
	@module History

	Undo/redo state wrapper. Tracks a history of values for a source state
	and exposes `Undo`/`Redo` plus reactive `CanUndo`/`CanRedo` flags.

	@param valueState -- the state to track history for
	@param options { maxDepth: number }? -- cap on retained history entries
	@return { Undo, Redo, CanUndo, CanRedo } -- history controller
]=]

local Engine = require(script.Parent.Parent.Core.Engine)

return function(_Scope, _Signal, _Value, _Computed)
	return function(self, state, options)
		local maxDepth = (options and options.maxDepth) or 50

		local undoStack = {}
		local redoStack = {}
		local getUndoCount, setUndoCount = self.value(0)
		local getRedoCount, setRedoCount = self.value(0)
		local suppressRecord = false

		-- Track changes
		local lastVal = type(state) == "function" and state() or state
		self.effect(function()
			local newVal = type(state) == "function" and state() or state
			if suppressRecord then return end
			if newVal == lastVal then return end
			
			-- Push old value onto undo stack
			table.insert(undoStack, lastVal)
			if #undoStack > maxDepth then
				table.remove(undoStack, 1)
			end
			-- Clear redo stack on new change
			table.clear(redoStack)
			lastVal = newVal
			setUndoCount(#undoStack)
			setRedoCount(0)
		end)

		local function applyHistory(sourceStack, targetStack)
			if #sourceStack == 0 then return end
			local val = table.remove(sourceStack)
			local current = type(state) == "function" and state() or state
			table.insert(targetStack, current)
			
			suppressRecord = true
			
			local id = Engine.resolveId(state)
			if id then
				Engine.set(id, val)
			end
			
			lastVal = val
			suppressRecord = false
			
			setUndoCount(#undoStack)
			setRedoCount(#redoStack)
		end

		local function undo() applyHistory(undoStack, redoStack) end
		local function redo() applyHistory(redoStack, undoStack) end

		return {
			State = state,
			Undo = undo,
			Redo = redo,
			CanUndo = self.computed(function() return getUndoCount() > 0 end),
			CanRedo = self.computed(function() return getRedoCount() > 0 end),
			UndoCount = getUndoCount,
			RedoCount = getRedoCount,
		}
	end
end
