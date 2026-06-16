--[=[
	@within Weave

	FLIP-based layout transition animations. Smoothly animates child
	GuiObjects when layout order or content changes.

	@param container Instance -- the layout container to observe
	@param options { Duration: number, EasingStyle: EnumItem }? -- animation config
	@return { Refresh: () -> () } -- call to re-measure and animate
]=]

return function(_Scope, _Signal, TweenLib)
	return function(self, container, options)
		local duration = (options and options.Duration) or 0.3
		local easingStyle = (options and options.EasingStyle) or Enum.EasingStyle.Quad
		local easingDir = (options and options.EasingDirection) or Enum.EasingDirection.Out
		local info = TweenInfo.new(duration, easingStyle, easingDir)

		local activeTweens = {}
		local lastSnapshot = {}

		-- Snapshot absolute positions relative to container
		local function snapshot()
			local positions = {}
			local containerAbsPos = container.AbsolutePosition
			for _, child in container:GetChildren() do
				if child:IsA("GuiObject") then
					positions[child] = child.AbsolutePosition - containerAbsPos
				end
			end
			return positions
		end

		-- FLIP: compare old positions and animate the delta
		local function playFlip(oldPositions)
			for _, tw in pairs(activeTweens) do
				tw:Cancel()
			end
			table.clear(activeTweens)

			local containerAbsPos = container.AbsolutePosition
			for _, child in container:GetChildren() do
				if child:IsA("GuiObject") and oldPositions[child] then
					local oldRel = oldPositions[child]
					local newRel = child.AbsolutePosition - containerAbsPos
					local delta = oldRel - newRel

					if delta.Magnitude > 0.5 then
						local origPos = child.Position
						child.Position = origPos + UDim2.fromOffset(delta.X, delta.Y)
						activeTweens[child] = TweenLib.Tween(child, info, { Position = origPos })
					end
				end
			end

			lastSnapshot = snapshot()
		end

		-- Debounce: batch all changes in a frame into one FLIP
		local flipPending = false
		local function scheduleFlip()
			if flipPending then return end
			local oldPositions = lastSnapshot
			flipPending = true
			task.defer(function()
				flipPending = false
				playFlip(oldPositions)
			end)
		end

		-- Initialize snapshot
		lastSnapshot = snapshot()

		-- Track layout-triggering changes
		self._trove:Add(container.ChildAdded:Connect(scheduleFlip))
		self._trove:Add(container.ChildRemoved:Connect(scheduleFlip))

		-- Track LayoutOrder changes on existing + future children
		local function trackChild(child)
			if child:IsA("GuiObject") then
				self._trove:Add(child:GetPropertyChangedSignal("LayoutOrder"):Connect(scheduleFlip))
			end
		end
		for _, child in container:GetChildren() do trackChild(child) end
		self._trove:Add(container.ChildAdded:Connect(trackChild))

		-- Cleanup active tweens on destroy
		self._trove:Add(function()
			for _, tw in pairs(activeTweens) do tw:Cancel() end
		end)

		return { Refresh = scheduleFlip }
	end
end
