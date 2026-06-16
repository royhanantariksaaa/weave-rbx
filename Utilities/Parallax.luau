--[=[
	@within Weave

	Scrolling utility that shifts layers at different speeds based on a scroll
	state, producing a parallax effect.

	@param scrollState -- reactive scroll position
	@param layers { { instance: Instance, speed: number } } -- one entry per parallax layer
	@return any
]=]

local RunService = game:GetService("RunService")

return function(_Scope, _Signal)
	return function(self, scrollState, layersSpec)
		-- We expect scrollState to be a Value<Vector2> or Value<number>.
		-- For simplicity, if number, we assume vertical scrolling (Y).

		local function updateParallax()
			local scrollVal = type(scrollState) == "function" and scrollState() or scrollState or 0
			local scrollX = 0
			local scrollY = 0

			if typeof(scrollVal) == "Vector2" then
				scrollX = scrollVal.X
				scrollY = scrollVal.Y
			elseif type(scrollVal) == "number" then
				scrollY = scrollVal
			end

			for _, layer in ipairs(layersSpec) do
				local inst = layer.instance
				local speed = layer.speed or 1.0
				local speedX = layer.speedX or speed
				local speedY = layer.speedY or speed

				if inst and typeof(inst) == "Instance" and inst:IsA("GuiObject") then
					-- We apply it via Position offset.
					-- Note: user must handle the base positioning, we just subtract scroll.
					-- Actually, modifying raw Position might fight with other constraints.
					-- A better Weave-way is to return derived UDim2 states, but if the user passed raw instances, we just mutate them natively.
					
					-- Standard parallax assumes the base setup is at 0,0 and we offset negative scroll.
					-- If the user wants to preserve base UI size/pos, using an overarching container is standard.
					inst.Position = UDim2.fromOffset(
						-scrollX * speedX,
						-scrollY * speedY
					)
				end
			end
		end

		-- We bind to RenderStepped to ensure smooth frame-perfect interpolation
		-- if the scrollState is a Spring or Tween.
		self._trove:Add(RunService.RenderStepped:Connect(updateParallax))
		
		-- Also run once immediately
		updateParallax()
		
		return nil
	end
end
