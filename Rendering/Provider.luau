--!optimize 2
--[=[
	@within Weave
	@module Provider

	Wraps a subtree to provide a context value (created via
	`Weave.createContext`) to descendants that consume it.

	@param context -- a context handle from `Weave.createContext`
	@param value any -- the value to provide
	@param builderFunc () -> WeaveNode -- the consuming subtree
	@return WeaveNode
]=]

local Engine = require(script.Parent.Parent.Core.Engine)

return function(Scope, _Signal)
	return function(self, context, value, builderFunc)
		local childScope = Scope.new(self)
		self._trove:Add(childScope._trove)

		childScope:Provide(context._id, value)

		Engine.pushScope(childScope)
		local success, result = pcall(builderFunc, childScope)
		Engine.popScope()
		if not success then
			childScope:Destroy()
			error(result, 0)
		end

		return result
	end
end
