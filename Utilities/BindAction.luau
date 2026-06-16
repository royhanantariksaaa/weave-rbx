-- BindAction: Maps a ContextActionService action to a Weave boolean state (true when held).
-- Usage: local isSprinting = scope.BindAction("Sprint", Enum.KeyCode.Space)

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
