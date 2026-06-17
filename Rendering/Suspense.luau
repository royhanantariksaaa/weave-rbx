--!optimize 2
--[=[
	@within Weave
	@module Suspense

	Halts rendering of `Children` until an `Async` resource resolves,
	showing `Fallback` while pending. `Resource` may be a single async state
	or a table of them (all must resolve).

	@param props { Resource: any, Fallback: () -> WeaveNode, Children: () -> WeaveNode }
	@return WeaveNode
]=]

local function isSingleAsync(resource)
	return type(resource) == "table" and resource.Type == "WeaveAsync"
end

return function(_Scope, Signal)
	return function(self, props)
		local fallback = props.Fallback
		local resource = props.Resource
		local children = props.Children

		local isSingle = isSingleAsync(resource)
		local resources = isSingle and { resource } or resource

		local statusState = self.Computed(function(use)
			for _, res in ipairs(resources) do
				if use(res).Status == "Pending" then return "Pending" end
				if use(res).Status == "Rejected" then return "Rejected" end
			end
			return "Resolved"
		end)

		return self.Switch(statusState, {
			Pending = fallback,
			Resolved = function(childScope)
				local values = table.create(#resources)
				for i, res in ipairs(resources) do
					values[i] = res:Peek().Value
				end
				return children(childScope, isSingle and values[1] or values)
			end,
			Rejected = function(childScope)
				local err = nil
				for _, res in ipairs(resources) do
					if res:Peek().Status == "Rejected" then
						err = res:Peek().Error
						break
					end
				end
				-- Escalate to ErrorBoundary component if one exists
				error("Weave Suspense: Resource rejected -> " .. tostring(err))
			end
		})
	end
end
