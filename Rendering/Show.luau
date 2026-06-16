-- Show: Conditional rendering. Shows/hides children based on a boolean state.
-- Usage: scope.Show(conditionState, builderFunc) -> WeaveNode


return function(_Scope, _Signal)
	return function(self, conditionState, builderFunc)
		return self.Switch(conditionState, {
			[true] = builderFunc,
			-- false and nil will evaluate to no-ops automatically in Switch
		})
	end
end
