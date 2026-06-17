--[=[
	@within Weave
	@module ErrorBoundary

	Wraps component building in a `pcall` to prevent a crash in one subtree
	from tearing down the whole tree. If the builder throws, `fallbackFunc`
	renders instead (if provided).

	@param builderFunc () -> WeaveNode -- the protected subtree
	@param fallbackFunc (() -> WeaveNode)? -- optional fallback on error
	@return WeaveNode
]=]

local Engine = require(script.Parent.Parent.Core.Engine)

return function(Scope, _Signal)
	return function(self, builderFunc, fallbackFunc)
		local childScope = Scope.new(self)
		
		local success, result = pcall(function()
			Engine.pushScope(childScope)
			local res = builderFunc(childScope)
			Engine.popScope()
			return res
		end)

		if not success then
			warn("Weave ErrorBoundary caught an error: " .. tostring(result))
			childScope._trove:Destroy()

			if fallbackFunc then
				childScope = Scope.new(self)
				local fallbackSuccess, fallbackResult = pcall(function()
					Engine.pushScope(childScope)
					local res = fallbackFunc(childScope, result)
					Engine.popScope()
					return res
				end)
				result = fallbackSuccess and fallbackResult or nil
			else
				result = nil
			end
		end

		self._trove:Add(childScope._trove)
		return result
	end
end
