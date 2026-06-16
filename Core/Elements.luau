--[=[
	@within Weave
	@module Elements

	Dynamic element namespace. Lazily builds element constructors (e.g.
	`Weave.Frame`, `Weave.TextLabel`) from Roblox instance class names via
	`CreateComponent`, accessed through the main module's `__index` metatable.
]=]

local CreateComponent = require(script.Parent.CreateComponent)


local Elements = {}

setmetatable(Elements, {
    __index = function(self, k)
        local success, builder = pcall(CreateComponent, k)
        if success then
            rawset(Elements, k, builder)
            return builder
        end
        return nil
    end
})

return Elements
