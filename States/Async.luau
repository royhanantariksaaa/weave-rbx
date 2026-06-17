--[=[
	@within Weave
	@module Async

	Creates an Async entity and returns a getter closure. The getter yields
	to the async function's result; use with `Suspense` to render fallback
	content while pending.

	@param asyncFn () -> any -- function returning a Promise or yieldable result
	@return () -> any -- getter that resolves to the async result
]=]
local Engine = require(script.Parent.Parent.Core.Engine)

return function(asyncFn: () -> any): () -> any
	return Engine.async(asyncFn)
end
