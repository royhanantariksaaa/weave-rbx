--[=[
	@within Weave
	@module Batch

	Coalesce multiple state mutations into a single reactive flush. Under the
	current Engine, mutations are implicitly deferred/batched, so this runs
	`fn` synchronously for backward compatibility.

	@param fn () -> () -- body containing the mutations
	@return any
]=]

return function(_Scope, _Signal)
	return function(_self, fn)
		local ok, err = pcall(fn)
		if not ok then
			error(err, 2)
		end
	end
end
