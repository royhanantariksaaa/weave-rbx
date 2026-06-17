--[=[
	@within Weave
	@module Form

	Returns a state container for managing form inputs, including values and
	validation errors.

	@param initialValues { [string]: any }? -- starting field values
	@return any -- form state container with get/set/validate helpers
]=]

return function(_Scope, _Signal, _Value)
	return function(self, initialValues)
		local getFormState, setFormState = self.value(initialValues or {})
		local getErrors, setErrors = self.value({})
		local getTouched, setTouched = self.value({})

		local function setContext(getter, setter, key, value)
			local dict = table.clone(getter())
			dict[key] = value
			setter(dict)
		end

		return {
			Values = getFormState,
			Errors = getErrors,
			Touched = getTouched,
			Update = function(key, value)
				setContext(getFormState, setFormState, key, value)
				setContext(getTouched, setTouched, key, true)
			end,
			SetError = function(key, err)
				setContext(getErrors, setErrors, key, err)
			end,
			Submit = function(callback)
				return function()
					callback(getFormState())
				end
			end
		}
	end
end
