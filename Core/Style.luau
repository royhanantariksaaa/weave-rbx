--[=[
	@within Weave
	@module Style

	Named style registry. `Weave.defineStyle(name, props)` stores a props
	table that element constructors can resolve by name.
]=]

local Styles = {}

return {
    DefineStyle = function(name: string, props: {[any]: any})
        Styles[name] = props
    end,
    GetStyle = function(name: string)
        return Styles[name]
    end
}
