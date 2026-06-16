-- Async: Creates an Async entity → returns getter closure.
local Engine = require(script.Parent.Parent.Core.Engine)

return function(asyncFn: () -> any): () -> any
	return Engine.async(asyncFn)
end
