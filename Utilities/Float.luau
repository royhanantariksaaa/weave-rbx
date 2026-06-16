--[=[
	@within Weave

	General-purpose floating UI positioning engine. Useful for tooltips,
	dropdowns, and context menus that must escape `ClipsDescendants`.

	@param anchorRef Instance -- the element to float relative to
	@param options { placement: string, offset: number, boundary: Instance }? -- positioning config
	@return { Position: Value<UDim2>, Visible: Value<boolean> } -- reactive float state
]=]

local RunService = game:GetService("RunService")

return function(_Scope, _Signal)
	return function(self, anchorState, options)
		local placement = (options and options.placement) or "bottom"
		local offset = (options and options.offset) or 8
		local screenBoundary = options and options.boundary

		local getPos, setPos = self.value(UDim2.new())
		local getVis, setVis = self.value(false)

		local getFloatRef, setFloatRef = self.ref()

		local function updatePosition()
			local anchor = type(anchorState) == "function" and anchorState() or anchorState
			if not anchor or typeof(anchor) ~= "Instance" or not anchor:IsA("GuiObject") then
				setVis(false)
				return
			end

			local floatInst = getFloatRef()
			if not floatInst or typeof(floatInst) ~= "Instance" or not floatInst:IsA("GuiObject") then
				setVis(false)
				return
			end

			if not anchor:IsDescendantOf(game) or not floatInst:IsDescendantOf(game) then
				setVis(false)
				return
			end

			setVis(true)

			local absPos = anchor.AbsolutePosition
			local absSize = anchor.AbsoluteSize
			local floatSize = floatInst.AbsoluteSize

			local x, y = 0, 0

			if placement == "bottom" then
				x = absPos.X + (absSize.X / 2) - (floatSize.X / 2)
				y = absPos.Y + absSize.Y + offset
			elseif placement == "top" then
				x = absPos.X + (absSize.X / 2) - (floatSize.X / 2)
				y = absPos.Y - floatSize.Y - offset
			elseif placement == "left" then
				x = absPos.X - floatSize.X - offset
				y = absPos.Y + (absSize.Y / 2) - (floatSize.Y / 2)
			elseif placement == "right" then
				x = absPos.X + absSize.X + offset
				y = absPos.Y + (absSize.Y / 2) - (floatSize.Y / 2)
			end

			if screenBoundary and typeof(screenBoundary) == "Instance" and screenBoundary:IsA("GuiObject") then
				local boundsPos = screenBoundary.AbsolutePosition
				local boundsSize = screenBoundary.AbsoluteSize

				if x < boundsPos.X then
					x = boundsPos.X + offset
				elseif (x + floatSize.X) > (boundsPos.X + boundsSize.X) then
					x = boundsPos.X + boundsSize.X - floatSize.X - offset
				end

				if y < boundsPos.Y then
					y = boundsPos.Y + offset
				elseif (y + floatSize.Y) > (boundsPos.Y + boundsSize.Y) then
					y = boundsPos.Y + boundsSize.Y - floatSize.Y - offset
				end
			end

			setPos(UDim2.fromOffset(x, y))
		end

		self._trove:Add(RunService.RenderStepped:Connect(updatePosition))

		return {
			Position = getPos,
			Visible = getVis,
			FloatRef = setFloatRef,
		}
	end
end
