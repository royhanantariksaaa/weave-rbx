--[=[
	@within Weave
	@module Queue

	Reactive FIFO queue state for notifications, toasts, and event logs.

	@param options { maxSize: number }? -- cap on retained items
	@return { Push, Pop, PeekFront, Items } -- queue controller; `Items` is a reactive array
]=]
-- q.Count          → reactive state of item count (number)

return function(_Scope, _Signal, _Value, _Computed)
	return function(self, options)
		local maxSize = (options and options.maxSize) or 50

		local items = {}
		local getItems, setItems = self.value({})
		local getCount, setCount = self.value(0)

		local function syncState()
			-- Shallow copy to trigger reactivity
			local copy = table.clone(items)
			setItems(copy)
			setCount(#items)
		end

		local function push(item)
			table.insert(items, item)
			-- Auto-cap: remove oldest if over limit
			while #items > maxSize do
				table.remove(items, 1)
			end
			syncState()
		end

		local function pop()
			if #items == 0 then return nil end
			local item = table.remove(items, 1)
			syncState()
			return item
		end

		local function peekFront()
			return items[1]
		end

		local function clear()
			table.clear(items)
			syncState()
		end

		return {
			Push = push,
			Pop = pop,
			PeekFront = peekFront,
			Clear = clear,
			Items = getItems,
			Count = getCount,
		}
	end
end
