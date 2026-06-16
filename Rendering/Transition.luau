-- Transition: Animated mount/unmount rendering.
-- Usage: scope.Transition(conditionState, buildFunc, transitionProps) -> WeaveNode

local Shared = require(script.Parent._shared)

return function(Scope, Signal)
	return function(self, conditionState, buildFunc, transitionProps)
		local nodeDef = Shared.createNodeDef(Signal, self._trove)
		nodeDef._active = false

		local generation = 0

		local function update()
			generation += 1
			local myGen = generation
			local shouldShow = Shared.resolveStateValue(conditionState)

			if shouldShow and not nodeDef._active then
				nodeDef._active = true
				Shared.rebuildNode(nodeDef, Scope, self, function(childScope)
					return buildFunc(childScope)
				end)

				if transitionProps and transitionProps.Enter then
					transitionProps.Enter(nodeDef._instances)
				end
			elseif not shouldShow and nodeDef._active then
				nodeDef._active = false
				if transitionProps and transitionProps.Exit then
					transitionProps.Exit(nodeDef._instances, function()
						-- Only destroy if this generation is still current
						if myGen == generation and not nodeDef._active then
							Shared.clearNode(nodeDef)
						end
					end)
				else
					Shared.clearNode(nodeDef)
				end
			end
		end

		return Shared.bindNodeToState(nodeDef, self, update)
	end
end
