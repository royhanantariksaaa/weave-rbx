--!optimize 2
--[=[
	@within Weave.Components
	@module TextInput

	Standardized text input. Handles Weave text binding and common events.
]=]

local Reconciler = require(script.Parent.Parent.Core.Reconciler)
local Elements = require(script.Parent.Parent.Core.Elements)
local Helpers = require(script.Parent.Parent.Core.Helpers)

return function(Scope, props)
	local textState = props.TextState
	local onSubmit = props.OnSubmit
	local onChange = props.OnChange

	local newProps = Helpers.Omit(props, { "TextState", "OnSubmit", "OnChange" })

	if textState then
		newProps[Reconciler.Bind("Text")] = textState
	end

	if onChange then
		newProps[Reconciler.OnChange("Text")] = onChange
	end

	if onSubmit then
		newProps[Reconciler.OnEvent("FocusLost")] = function(enterPressed)
			if enterPressed then
				local textVal = newProps.Text
				if not textVal and textState then
					textVal = type(textState) == "function" and textState() or (type(textState) == "table" and textState.Get and textState:Get()) or textState
				end
				onSubmit(textVal or "")
			end
		end
	end

	return Elements.TextBox(Scope, newProps)
end
