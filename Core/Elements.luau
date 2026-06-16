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
