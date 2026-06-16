-- Batch: Coalesce multiple state mutations into a single reactive flush.
-- Under WeaveEcs, mutations are implicitly deferred and batched by the Engine,
-- so this utility purely runs the function synchronously for backwards compatibility.
-- Usage: scope.Batch(fn)

return function(_Scope, _Signal)
	return function(_self, fn)
		local ok, err = pcall(fn)
		if not ok then
			error(err, 2)
		end
	end
end
