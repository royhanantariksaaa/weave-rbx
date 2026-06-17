--[=[
	@module Derived
	@within Weave.States

	State primitive used by Weave reactive data flows.
]=]

-- Derived: Creates a Derived entity (settable computed) → returns (getter, setter).
local Engine = require(script.Parent.Parent.Core.Engine)

return function<T>(callback: () -> T, options: { equals: ((any, any) -> boolean)? }?): ((() -> T), (T) -> ())
	return Engine.derived(callback :: any, options)
end
