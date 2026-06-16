local Styles = {}

return {
    DefineStyle = function(name: string, props: {[any]: any})
        Styles[name] = props
    end,
    GetStyle = function(name: string)
        return Styles[name]
    end
}
