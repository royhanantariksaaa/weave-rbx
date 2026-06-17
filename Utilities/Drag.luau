--!optimize 2
--[=[
	@within Weave
	@module Drag

	Reactive drag utility. Tracks pointer drag on an instance and exposes
	reactive `IsDragging`, `Position`, and `Delta` states.

	@param instance Instance -- the draggable GuiObject
	@param options { axis: "X" | "Y" | "XY" }? -- constrain movement to an axis
	@return { IsDragging, Position, Delta } -- reactive drag state
]=]

local UserInputService = game:GetService("UserInputService")

return function(_Scope, _Signal, Value)
	return function(self, instance, options)
		local axis = (options and options.axis) or "XY"

		local getIsDragging, setIsDragging = self.value(false)
		local getPosition, setPosition = self.value(Vector2.new(0, 0))
		local getDelta, setDelta = self.value(Vector2.new(0, 0))

		local dragStart = Vector2.new(0, 0)
		local startPos = Vector2.new(0, 0)
		local inputConn, endConn

		local function onInputBegan(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				setIsDragging(true)
				dragStart = Vector2.new(input.Position.X, input.Position.Y)
				startPos = getPosition()
				setDelta(Vector2.new(0, 0))
			end
		end

		local function onInputChanged(input)
			if not getIsDragging() then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then return end

			local current = Vector2.new(input.Position.X, input.Position.Y)
			local rawDelta = current - dragStart

			local appliedDelta
			if axis == "X" then
				appliedDelta = Vector2.new(rawDelta.X, 0)
			elseif axis == "Y" then
				appliedDelta = Vector2.new(0, rawDelta.Y)
			else
				appliedDelta = rawDelta
			end

			setDelta(appliedDelta)
			setPosition(startPos + appliedDelta)
		end

		local function onInputEnded(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				setIsDragging(false)
			end
		end

		-- Connect to target instance
		self._trove:Add(instance.InputBegan:Connect(onInputBegan))

		-- Global input tracking (mouse can leave the element while dragging)
		inputConn = UserInputService.InputChanged:Connect(onInputChanged)
		endConn = UserInputService.InputEnded:Connect(onInputEnded)
		self._trove:Add(inputConn)
		self._trove:Add(endConn)

		return {
			IsDragging = getIsDragging,
			Position = getPosition,
			Delta = getDelta,
		}
	end
end
