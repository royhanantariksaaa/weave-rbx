--[=[
	@within Weave

	Maps a `ContextActionService` action to a Weave boolean state that is
	`true` while the action is held.

	@param actionName string -- ContextActionService action name
	@param key Enum.KeyCode -- the input key that triggers the action
	@return () -> boolean -- getter that is true while held
]=]

local ContextActionService = game:GetService("ContextActionService")

return function(_Scope, _Signal, _Value)
	return function(self, actionName, ...)
		local getState, setState = self.value(false)
		
		local function handleAction(name, stateObject, inputObject)
			if name == actionName then
				if stateObject == Enum.UserInputState.Begin then
					setState(true)
				elseif stateObject == Enum.UserInputState.End or stateObject == Enum.UserInputState.Cancel then
					setState(false)
				end
			end
			return Enum.ContextActionResult.Pass
		end

		ContextActionService:BindAction(actionName, handleAction, false, ...)

		self.OnDestroy(function()
			ContextActionService:UnbindAction(actionName)
		end)

		return getState
	end
end
