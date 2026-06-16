--[=[
	@within Weave

	Unified key/value table iteration with key reuse. Backs the public
	`ForKeys` and `ForValues` scope methods, which render one node per entry
	in a reactive table and reuse nodes by key.

	@param sourceState -- reactive table to iterate
	@param isArray boolean -- treat the source as an array vs. keyed map
	@param renderFn (scope, key, value) -> WeaveNode -- per-entry renderer
	@return WeaveNode
]=]

local Shared = require(script.Parent._shared)

return function(Scope, Signal)
	return function(self, sourceState, isArray: boolean, renderFunc)
		return Shared.createCollectionNode(Signal, Scope, self, sourceState, isArray, renderFunc)
	end
end
