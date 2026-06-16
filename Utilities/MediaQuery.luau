-- MediaQuery: Responsive breakpoint state.
-- Usage: scope.MediaQuery({ mobile = 0, tablet = 480, desktop = 960 }) -> Value<string>

local Camera = game:GetService("Workspace").CurrentCamera

return function(_Scope, _Signal, _Value)
	return function(self, breakpoints)
		-- Sort breakpoints descending by threshold
		local sorted = {}
		for name, threshold in pairs(breakpoints) do
			table.insert(sorted, { name = name, threshold = threshold })
		end
		table.sort(sorted, function(a, b) return a.threshold > b.threshold end)

		local function resolve(width)
			for _, bp in ipairs(sorted) do
				if width >= bp.threshold then
					return bp.name
				end
			end
			return sorted[#sorted].name -- smallest breakpoint fallback
		end

		local getBp, setBp = self.value(resolve(Camera.ViewportSize.X))

		local conn = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local newBp = resolve(Camera.ViewportSize.X)
			if newBp ~= getBp() then
				setBp(newBp)
			end
		end)
		self.OnDestroy(function() conn:Disconnect() end)

		return getBp
	end
end
