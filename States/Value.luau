-- Value: Creates a Value entity → returns (getter, setter) closures.
local Engine = require(script.Parent.Parent.Core.Engine)

return function<T>(initialValue: T, options: {validate: ((T) -> T)?}?): ((() -> T), (T) -> ())
	return Engine.value(initialValue, options :: any)
end
