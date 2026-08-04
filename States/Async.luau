--!optimize 2
--[=[
	@within Weave
	@module Async

	Creates an Async entity and returns a getter closure containing
	`{ Status, Value, Error }`. The producer runs in its own task and may yield;
	use the state with `Suspense` to render fallback content while pending.

	@param asyncFn () -> any -- producer whose return value is stored on resolution
	@return () -> any -- getter for the async status record
]=]
local Engine = require(script.Parent.Parent.Core.Engine)

return function(asyncFn: () -> any): () -> any
	return Engine.async(asyncFn)
end
