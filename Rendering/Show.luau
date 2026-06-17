--!optimize 2
--[=[
	@within Weave
	@module Show

	Conditional rendering. Renders `builderFunc` when `conditionState` is
	truthy, renders nothing otherwise. Sugar over `Switch` for the boolean case.

	@param conditionState () -> boolean -- when truthy, children render
	@param builderFunc () -> WeaveNode -- the conditional subtree
	@return WeaveNode
]=]


return function(_Scope, _Signal)
	return function(self, conditionState, builderFunc)
		return self.Switch(conditionState, {
			[true] = builderFunc,
			-- false and nil will evaluate to no-ops automatically in Switch
		})
	end
end
