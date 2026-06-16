-- Store: Redux-like centralized state management for complex client-side UI state.
-- Usage: local store = scope.Store(initialState, { actions = { ... }, middleware = { ... } })
-- store.State  → reactive state (read via use())
-- store.Dispatch("actionName", payload)
-- store.Select(selectorFn) → derived reactive slice

local Engine = require(script.Parent.Parent.Core.Engine)

return function(_Scope, _Signal, _Value, _Computed)
	return function(self, initialState, options)
		local actions = (options and options.actions) or {}
		local middlewareList = (options and options.middleware) or {}

		-- Core state value
		local getState, setState = self.value(initialState)

		-- Dispatch: runs the named action through middleware, then updates state
		local function rawDispatch(actionName, ...)
			local actionFn = actions[actionName]
			if not actionFn then
				warn("[Weave.Store] Unknown action: " .. tostring(actionName))
				return
			end

			-- Shallow-clone current state to prevent mutation of the live value
			local currentState = Engine.peek(getState) or getState()
			local stateCopy = type(currentState) == "table" and table.clone(currentState) or currentState

			local newState = actionFn(stateCopy, ...)
			if newState ~= nil then
				setState(newState)
			end
		end

		-- Build middleware chain (outermost wraps innermost)
		-- Each middleware: function(store, nextDispatch) return function(actionName, ...) end
		local dispatch = rawDispatch
		local storeApi = {
			GetState = function() return getState() end,
			Dispatch = function(actionName, ...) dispatch(actionName, ...) end,
		}

		for i = #middlewareList, 1, -1 do
			local mw = middlewareList[i]
			local next = dispatch
			dispatch = mw(storeApi, next)
		end

		-- Select: creates a derived computed that only updates when the slice changes
		local function selectFn(selectorFn, equalsFn)
			local eq = equalsFn or function(a, b) return a == b end
			local lastResult = selectorFn(Engine.peek(getState) or getState())

			return self.computed(function()
				local fullState = type(getState) == "function" and getState() or getState
				local result = selectorFn(fullState)

				if eq(result, lastResult) then
					return lastResult
				end
				lastResult = result
				return result
			end)
		end

		return {
			State = getState,
			Dispatch = dispatch,
			Select = selectFn,
		}
	end
end
