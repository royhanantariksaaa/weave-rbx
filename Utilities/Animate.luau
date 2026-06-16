--[=[
	@within Weave

	Sequential property animation via the tween library. Plays a list of
	steps in order on `instance` and returns a controller.

	@param instance Instance -- target to animate
	@param steps { ... } -- ordered animation steps
	@return any -- controller for the sequence
]=]

return function(_Scope, _Signal, TweenLib)
	return function(_self, instance, steps)
		local totalTime = 0
		local controllers = {}
		local pendingThreads = {}
		for _, step in ipairs(steps) do
			local delay, duration = step.Delay or 0, step.Duration or 0
			local goals = { [step.Property] = step.To }
			local easeStyle = step.EasingStyle or Enum.EasingStyle.Quad
			local easeDir = step.EasingDirection or Enum.EasingDirection.Out
			local info = TweenInfo.new(duration, easeStyle, easeDir)
			local thread = task.delay(totalTime + delay, function()
				table.insert(controllers, TweenLib.Tween(instance, info, goals))
			end)
			table.insert(pendingThreads, thread)
			totalTime += delay + duration
		end
		return {
			Cancel = function()
				for _, t in ipairs(pendingThreads) do
					task.cancel(t)
				end
				for _, c in ipairs(controllers) do
					c.Cancel()
				end
			end
		}
	end
end
