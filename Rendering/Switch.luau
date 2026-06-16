-- Switch: Multi-case conditional rendering.
-- Usage: scope.Switch(state, { [value] = builderFunc, default = builderFunc }) -> WeaveNode

local Shared = require(script.Parent._shared)

return function(Scope, Signal)
	return function(self, state, cases)
		local nodeDef = Shared.createNodeDef(Signal, self._trove)

		local prevValue = nil

		local function update()
			local value = Shared.resolveStateValue(state)
			if value == prevValue then return end
			prevValue = value
			local builderFunc = cases[value] or cases["default"]
			Shared.rebuildNode(nodeDef, Scope, self, builderFunc and function(childScope)
				return builderFunc(childScope, value)
			end or nil)
		end

		return Shared.bindNodeToState(nodeDef, self, update)
	end
end
