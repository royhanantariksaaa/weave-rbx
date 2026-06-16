--[=[
	@within Weave

	Creates a Reducer entity (Redux-style) and returns a `(getter, dispatch)`
	pair. Calling `dispatch(action)` runs `reducerFn(currentState, action)`
	and updates the value.

	@param reducerFn (state, action) -> state -- pure state transition
	@param initialState any -- the starting state
	@return (() -> any, (any) -> ()) -- getter and dispatch closures
]=]
local Engine = require(script.Parent.Parent.Core.Engine)

return function(reducerFn: (any, any) -> any, initialState: any): ((() -> any), (any) -> ())
	return Engine.reducer(reducerFn, initialState)
end
