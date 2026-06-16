-- Debug: Enhanced debug tooling for Weave.
-- Tracks stat counters, configurable slow-flush threshold, and report generation.

local Debug = {}

-- Master toggle (existing API)
Debug.Enabled = false

-- Configurable slow-flush threshold (ms). Scheduler warns when flush exceeds this.
Debug.SlowFlushThreshold = 5

-- Optional callback fired when a scheduler flush exceeds SlowFlushThreshold.
-- Signature: function(stats: { flushMs: number, statesFlushed: number, iterations: number })
Debug.OnSlowFlush = nil :: ((stats: { flushMs: number, statesFlushed: number, iterations: number }) -> ())?

-- Stat counters. Only incremented when Debug.Enabled == true.
Debug.Stats = {
    ComputedEvaluations = 0,
    SchedulerFlushes = 0,
    SpringUpdates = 0,
}

-- Increment a stat counter. No-ops when Debug.Enabled is false.
function Debug.Track(category: string)
    if not Debug.Enabled then return end
    local current = Debug.Stats[category]
    if current then
        Debug.Stats[category] = current + 1
    else
        Debug.Stats[category] = 1
    end
end

-- Returns a formatted string summary of all tracked stats.
function Debug.Report(): string
    local lines = { "[Weave Debug Report]" }
    for key, value in pairs(Debug.Stats) do
        table.insert(lines, string.format("  %s: %d", key, value))
    end
    return table.concat(lines, "\n")
end

-- Zeros all stat counters.
function Debug.Reset()
    for key in pairs(Debug.Stats) do
        Debug.Stats[key] = 0
    end
end

return Debug
