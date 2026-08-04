--!optimize 2
--[=[
	@within Weave
	@module Batch

	Coalesce multiple state mutations into a single reactive flush. Batches may
	be nested; only the outermost batch propagates computed values and bindings.

	@param fn () -> () -- body containing the mutations
	@return any
]=]

local Engine = require(script.Parent.Parent.Core.Engine)

return function(_Scope, _Signal)
	return function(_self, fn)
		return Engine.batch(fn)
	end
end
