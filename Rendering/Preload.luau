--[=[
	@within Weave

	Declaratively preloads assets via `ContentProvider` and suspends the
	children render until all are ready, showing `Fallback` in the meantime.

	@param props { Assets: { Instance }, Fallback: () -> WeaveNode, Children: () -> WeaveNode }
	@return WeaveNode
]=]

local ContentProvider = game:GetService("ContentProvider")

return function(_Scope, Signal)
	return function(self, props)
		local assets = props.Assets
		local fallback = props.Fallback
		local children = props.Children

		if type(assets) ~= "table" then assets = {assets} end

		local loadState = self.Async(function()
			ContentProvider:PreloadAsync(assets)
			return true
		end)

		return self.Suspense {
			Resource = loadState,
			Fallback = fallback,
			Children = children,
		}
	end
end
