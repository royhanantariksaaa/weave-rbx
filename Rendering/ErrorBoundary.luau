--!optimize 2
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

		Engine.pushScope(childScope)
		local success, result = pcall(builderFunc, childScope)
		Engine.popScope()

		if success then
			self._trove:Add(childScope._trove)
			return result
		end

		warn("Weave ErrorBoundary caught an error: " .. tostring(result))
		childScope._trove:Destroy()

		if not fallbackFunc then
			return nil
		end

		local fallbackScope = Scope.new(self)
		Engine.pushScope(fallbackScope)
		local fallbackSuccess, fallbackResult = pcall(fallbackFunc, fallbackScope, result)
		Engine.popScope()

		if not fallbackSuccess then
			fallbackScope._trove:Destroy()
			warn("Weave ErrorBoundary fallback failed: " .. tostring(fallbackResult))
			return nil
		end

		self._trove:Add(fallbackScope._trove)
		return fallbackResult
	end
end
