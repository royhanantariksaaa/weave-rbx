--!optimize 2
--[=[
	@within Weave
	@module Selector

	Equality-gated derivation. Projects a slice of a source state via
	`selectorFn` and only re-emits when the slice changes per `equalsFn`.

	@param state -- the source state (or getter)
	@param selectorFn (value) -> T -- picks the slice
	@param equalsFn ((T, T) -> boolean)? -- custom equality (defaults to `==`)
	@return () -> T -- read-only getter for the selected slice
]=]

local Shared = require(script.Parent._shared)

return function(_Scope, _Signal, _Value, _Mixins)
	return function(self, state, selectorFn, equalsFn)
		return self.computed(function()
			return selectorFn(Shared.read(state))
		end, { equals = equalsFn })
	end
end
