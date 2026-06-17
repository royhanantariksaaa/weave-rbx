--[=[
	@within Weave
	@module Computed

	Creates a Computed entity and returns a getter closure. The compute
	callback receives NO arguments — dependencies are tracked automatically
	by the getter calls it makes, and it re-runs whenever any of them change.

	@param callback () -> T -- compute function; dependencies auto-tracked
	@param options { equals: (any, any) -> boolean }? -- optional equality to skip redundant updates
	@return () -> T -- getter for the computed value
]=]
local Engine = require(script.Parent.Parent.Core.Engine)

return function<T>(callback: () -> T, options: { equals: ((any, any) -> boolean)? }?): () -> T
	return Engine.computed(callback :: any, options)
end
