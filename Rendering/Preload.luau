-- Preload: Declaratively loads assets and suspends Children render until complete.

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
