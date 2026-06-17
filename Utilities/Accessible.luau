--[=[
	@within Weave
	@module Accessible

	Simplifies UI accessibility, gamepad navigation routing, and focus groups.

	@param instance Instance -- the GuiObject to make accessible
	@param options { role: string, selectionOrder: number } -- accessibility metadata
	@return any
]=]

local Reconciler = require(script.Parent.Parent.Core.Reconciler)

return function(_Scope, _Signal)
	local function Accessible(self, instance, options)
		local opts = options or {}
		
		-- Simple property injections utilizing Reconciler to apply them cleanly
		local propsToApply = {}
		
		if opts.selectionOrder then
			propsToApply.SelectionOrder = opts.selectionOrder
		end
		
		if opts.role == "button" then
			-- In Roblox, standard GUI navigation prefers active elements. We can manually set Selectable.
			propsToApply.Selectable = true
		end
		
		-- If it needs a focus trap (like a Modal), we hook into GuiService
		if opts.focusTrap then
			-- Minimal implementation of a trap: push to GuiService bounds
			-- For a full implementation, you'd iterate over children and define NextSelection bindings
			-- But for this MVP API:
			propsToApply.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
			propsToApply.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
			propsToApply.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
			propsToApply.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
		end
		
		Reconciler.Reconcile(instance, propsToApply, self._trove)
		
		return instance
	end
	
	local function FocusGroup(self, instances)
		-- Programmatically link an array of instances for circular gamepad navigation.
		for i = 1, #instances do
			local current = instances[i]
			local prevInst = instances[i - 1] or instances[#instances]
			local nextInst = instances[i + 1] or instances[1]
			
			current.NextSelectionUp = prevInst
			current.NextSelectionDown = nextInst
			current.NextSelectionLeft = prevInst
			current.NextSelectionRight = nextInst
		end
		
		-- Cleans up NextSelection when the scope dies
		self.OnDestroy(function()
			for _, current in ipairs(instances) do
				if current and current.Parent then
					current.NextSelectionUp = nil
					current.NextSelectionDown = nil
					current.NextSelectionLeft = nil
					current.NextSelectionRight = nil
				end
			end
		end)
		
		return instances
	end

	return {
		Accessible = Accessible,
		FocusGroup = FocusGroup
	}
end
