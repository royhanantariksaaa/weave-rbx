--[=[
	@within Weave.Components

	Standardized text button. Manages Hovering and Pressed states and
	disables `AutoButtonColor` for full visual control.
]=]

local Reconciler = require(script.Parent.Parent.Core.Reconciler)
local Elements = require(script.Parent.Parent.Core.Elements)
local Helpers = require(script.Parent.Parent.Core.Helpers)

return function(Scope, props)
	local isHovering = Scope.Value(false)
	local isPressed = Scope.Value(false)

	local function onEnter() isHovering:Set(true) end
	local function onLeave()
		isHovering:Set(false)
		isPressed:Set(false)
	end
	
	local function onDown() isPressed:Set(true) end
	local function onUp() isPressed:Set(false) end

	if props.HoverState then
		props.HoverState:Set(isHovering)
		props.HoverState = nil
	end
	
	if props.PressState then
		props.PressState:Set(isPressed)
		props.PressState = nil
	end

	local baseProps = {
		[Reconciler.OnEvent("MouseEnter")] = onEnter,
		[Reconciler.OnEvent("MouseLeave")] = onLeave,
		[Reconciler.OnEvent("MouseButton1Down")] = onDown,
		[Reconciler.OnEvent("MouseButton1Up")] = onUp,
		Active = true,
		AutoButtonColor = false,
	}

	Helpers.Assign(baseProps, props)

	return Elements.TextButton(Scope, baseProps)
end
