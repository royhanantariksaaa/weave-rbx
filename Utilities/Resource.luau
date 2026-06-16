--[=[
	@within Weave

	TanStack-Query-inspired data-fetching primitive for non-player data.
	Exposes reactive `data`, `error`, `status`, and a `refetch` trigger.

	@param keyState -- reactive cache key; changing it refetches
	@param fetcherFn (key) -> any -- produces the data
	@param options { staleTime: number, retries: number, refetchInterval: number }? -- fetch policy
	@return { data, error, status, refetch } -- reactive resource state
]=]
-- res.invalidate() → clear cache and refetch

local Engine = require(script.Parent.Parent.Core.Engine)

return function(_Scope, _Signal, _Value, _Computed)
	-- Shared cross-scope cache: { [cacheKey] = { data, timestamp } }
	local globalCache = {}
	-- Request deduplication: { [cacheKey] = Signal }
	local fetchSignals = {}

	return function(self, keyState, fetcherFn, options)
		local staleTime = (options and options.staleTime) or 30
		local retries = (options and options.retries) or 0
		local refetchInterval = (options and options.refetchInterval) or 0

		local data, setData = self.value(nil)
		local errorVal, setError = self.value(nil)
		local status, setStatus = self.value("idle")
		local activeThread = nil

		local function doFetch(key)
			-- Check cache first
			local cached = globalCache[key]
			if cached and (os.clock() - cached.timestamp) < staleTime then
				setData(cached.data)
				setStatus("success")
				return
			end

			-- Stale-while-revalidate: show old data while fetching
			if cached then
				setData(cached.data)
			end

			setStatus("loading")
			setError(nil)

			-- Cancel previous fetch
			if activeThread then
				task.cancel(activeThread)
				activeThread = nil
			end

			-- Request Deduplication
			if fetchSignals[key] then
				local conn
				conn = fetchSignals[key]:connect(function(isSuccess, result)
					if isSuccess then
						setData(result)
						setError(nil)
						setStatus("success")
					else
						setError(result)
						setStatus("error")
					end
					conn:disconnect()
				end)
				return
			end

			-- Primary fetcher
			fetchSignals[key] = _Signal.new()

			activeThread = task.spawn(function()
				local attemptCount = 0
				local maxAttempts = retries + 1

				while attemptCount < maxAttempts do
					attemptCount += 1
					local success, result = pcall(fetcherFn, key)

					if success then
						globalCache[key] = { data = result, timestamp = os.clock() }
						setData(result)
						setError(nil)
						setStatus("success")
						activeThread = nil
						
						local sig = fetchSignals[key]
						fetchSignals[key] = nil
						if sig then sig:fire(true, result) end
						return
					else
						if attemptCount < maxAttempts then
							task.wait(2 ^ (attemptCount - 1))
						else
							setError(result)
							setStatus("error")
							activeThread = nil
							
							local sig = fetchSignals[key]
							fetchSignals[key] = nil
							if sig then sig:fire(false, result) end
						end
					end
				end
			end)
		end

		-- Watch key state and refetch when it changes
		local currentKey = nil
		local keyId = Engine.resolveId(keyState)
		if keyId then
			-- It's a reactive accessor
			currentKey = Engine.peek(keyState)
			doFetch(currentKey)

			local keySignal = Engine.Signals[keyId]
			if keySignal then
				self._trove:Add(keySignal:Connect(function(newKey)
					currentKey = newKey
					doFetch(newKey)
				end))
			end
		else
			-- Static key
			currentKey = keyState
			doFetch(currentKey)
		end

		-- Refetch interval
		local intervalThread = nil
		if refetchInterval > 0 then
			intervalThread = task.spawn(function()
				while true do
					task.wait(refetchInterval)
					if currentKey then
						doFetch(currentKey)
					end
				end
			end)
		end

		-- Cleanup
		self._trove:Add(function()
			if activeThread then task.cancel(activeThread) end
			if intervalThread then task.cancel(intervalThread) end
		end)

		return {
			data = data,
			error = errorVal,
			status = status,
			refetch = function()
				if currentKey then doFetch(currentKey) end
			end,
			invalidate = function()
				if currentKey then
					globalCache[currentKey] = nil
					doFetch(currentKey)
				end
			end,
		}
	end
end
