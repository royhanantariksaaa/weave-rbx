--[=[
	@within Weave.Components

	A wrapper that portals content into a `ScreenGui` when hovering a target
	instance.
]=]

local Reconciler = require(script.Parent.Parent.Core.Reconciler)
local Elements = require(script.Parent.Parent.Core.Elements)

return function(Scope, props)
	local target = props.Target
	local content = props.Content or props[Reconciler.Children]
	
	if not target then error("Weave Tooltip requires a Target instance.") end

	local isVisible = Scope.Value(false)
	local targetPosition = Scope.Value(Vector2.new(0, 0))

	Scope._trove:Add(target.MouseEnter:Connect(function()
		isVisible:Set(true)
		targetPosition:Set(target.AbsolutePosition + target.AbsoluteSize / 2)
	end))
	
	Scope._trove:Add(target.MouseLeave:Connect(function()
		isVisible:Set(false)
	end))
	
	Scope._trove:Add(target:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		if isVisible:Peek() then
			targetPosition:Set(target.AbsolutePosition + target.AbsoluteSize / 2)
		end
	end))

	return Scope:Portal {
		Target = props.PortalTarget,
		[Reconciler.Children] = {
			Scope:Show(isVisible, function(scope)
				return Elements.Frame(scope, {
					Position = targetPosition:Map(function(pos: Vector2) return UDim2.fromOffset(pos.X, pos.Y) end),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					[Reconciler.Children] = content
				})
			end)
		}
	}
end
