-- Computed: Creates a Computed entity → returns getter closure.
-- Callback receives NO arguments — dependencies tracked via getter calls.
local Engine = require(script.Parent.Parent.Core.Engine)

return function<T>(callback: () -> T, options: { equals: ((any, any) -> boolean)? }?): () -> T
	return Engine.computed(callback :: any, options)
end
