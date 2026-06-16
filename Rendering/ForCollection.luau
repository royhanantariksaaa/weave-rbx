-- ForCollection: Unified key/value table iteration with key reuse.
-- ForKeys:   scope.ForKeys(sourceState, renderFunc)
-- ForValues: scope.ForValues(sourceState, renderFunc)

local Shared = require(script.Parent._shared)

return function(Scope, Signal)
	return function(self, sourceState, isArray: boolean, renderFunc)
		return Shared.createCollectionNode(Signal, Scope, self, sourceState, isArray, renderFunc)
	end
end
