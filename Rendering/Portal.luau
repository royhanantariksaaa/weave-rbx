--!optimize 2
--[=[
	@within Weave
	@module Portal

	Out-of-tree rendering. Renders children into a target `Instance` outside
	the normal parent hierarchy (e.g. into `PlayerGui` or a tooltip layer).

	@param props { Target: Instance, [Weave.Children]: ... } -- target and children
	@return WeaveNode
]=]

local Shared = require(script.Parent._shared)

return function(Scope, _Signal, Reconciler)
	return function(self, props)
		local targetState = props.Target
		local children = props[Reconciler.Children] or props.Children

		local currentTrove = nil

		local function updateTarget()
			if currentTrove then
				currentTrove:Destroy()
				currentTrove = nil
			end
			local targetInstance = Shared.resolveStateValue(targetState)
			if targetInstance and children then
				local childScope = Scope.new(self)
				currentTrove = childScope._trove
				local container = Instance.new("Folder")
				container.Name = "WeavePortal"
				container.Parent = targetInstance
				childScope._trove:Add(container)
				Reconciler.Reconcile(container, { [Reconciler.Children] = children }, childScope._trove)
			end
		end

		self.effect(updateTarget)

		self._trove:Add(function()
			if currentTrove then currentTrove:Destroy() end
		end)

		return {} -- Safely ignored by the reconciler
	end
end
