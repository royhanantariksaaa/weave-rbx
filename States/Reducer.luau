-- Reducer: Creates a Reducer entity → returns (getter, dispatch).
local Engine = require(script.Parent.Parent.Core.Engine)

return function(reducerFn: (any, any) -> any, initialState: any): ((() -> any), (any) -> ())
	return Engine.reducer(reducerFn, initialState)
end
