--!optimize 2
--[=[
	@within Weave
	@module Derived

	Creates a computed state with an exposed setter and returns a `(getter,
	setter)` pair. A write temporarily overrides the computed value. The next
	change from a tracked source clears the override and evaluates the callback.

	@param callback () -> T -- compute function with automatic dependency tracking
	@param options { equals: (T, T) -> boolean }? -- optional equality comparison
	@return (() -> T, (T) -> ()) -- getter and override setter
]=]

local Engine = require(script.Parent.Parent.Core.Engine)

return function<T>(callback: () -> T, options: { equals: ((any, any) -> boolean)? }?): ((() -> T), (T) -> ())
	return Engine.derived(callback :: any, options)
end
