--[=[
	@within Weave

	Serializes and restores purely ephemeral UI state without tracking
	dependencies. Use to capture and replay transient UI (active tab, search
	text) without persisting it.

	@param states { [string]: state } -- map of named states to snapshot
	@return { [string]: any } -- serialized snapshot data
]=]

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
