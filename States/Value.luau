--[=[
	@within Weave
	@module Value

	Creates a Value entity and returns a `(getter, setter)` pair. The getter
	tracks as a dependency when called inside `computed`/`effect`; the setter
	mutates the value and triggers dependents.

	@param initialValue T -- the starting value
	@param options { validate: (T) -> T }? -- optional validator applied on set
	@return (() -> T, (T) -> ()) -- getter and setter closures
]=]
local Engine = require(script.Parent.Parent.Core.Engine)

return function<T>(initialValue: T, options: {validate: ((T) -> T)?}?): ((() -> T), (T) -> ())
	return Engine.value(initialValue, options :: any)
end
