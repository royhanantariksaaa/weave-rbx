-- Snapshot: Serializes and restores purely ephemeral UI state without tracking dependencies.
-- Usage: 
-- local snapData = scope.Snapshot({ tab = tabState, search = searchState })
-- scope.Restore({ tab = tabState, search = searchState }, snapData)

local Engine = require(script.Parent.Parent.Core.Engine)

return function(_Scope, _Signal)
	local function Snapshot(self, stateMapping: { [string]: any })
		local result = {}
		for key, stateNode in pairs(stateMapping) do
			if type(stateNode) == "function" then
				result[key] = Engine.peek(stateNode) -- Peek avoids triggering reactive dependencies
			elseif type(stateNode) == "table" and stateNode.Get then
				result[key] = stateNode:Peek()
			else
				result[key] = stateNode
			end
		end
		return result
	end

	local function Restore(self, stateMapping: { [string]: any }, data: { [string]: any })
		if type(data) ~= "table" then return end
		
		for key, stateNode in pairs(stateMapping) do
			local val = data[key]
			if val ~= nil then
				if type(stateNode) == "function" then
					local id = Engine.resolveId(stateNode)
					if id then
						Engine.set(id, val)
					end
				elseif type(stateNode) == "table" and stateNode.Set then
					stateNode:Set(val)
				end
			end
		end
	end

	return {
		Snapshot = Snapshot,
		Restore = Restore
	}
end
