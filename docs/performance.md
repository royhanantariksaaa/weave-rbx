---
sidebar_position: 8
---

# Performance

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Production / Profiling</p>
  <p className="lesson-summary">Measure graph fan-out, computed evaluations, property paints, Instance work, layout invalidation, and animation channels before changing lower-level table code.</p>
</div>

Weave is designed so a state write visits the affected dependency graph rather
than scanning every state. That makes graph shape the first performance tool.
A dense engine cannot compensate for one broad state invalidating an entire
screen or for Roblox layout and text measurement dominating every frame.

## Follow one write through the engine

Outside a batch, a changed source runs this pipeline synchronously:

1. The source ID enters a dense changed queue once.
2. Weave walks reverse dependency edges and marks affected Computed nodes.
3. Computed nodes evaluate in dependency order, adding further changed IDs only
   when their equality rule reports a new value.
4. Direct Instance bindings for changed nodes write their Roblox properties.
5. Temporary queues and scheduling sets are cleared for reuse.

Inside a batch, writes accumulate and the outermost batch runs that pipeline
once.

The cost of a write is therefore closer to:

```text
affected graph edges
+ evaluated computations
+ changed property bindings
+ Roblox work caused by those properties
```

It is not proportional to every allocated Weave state unless your graph makes
every state dependent on the write.

## Shape state for the UI that reads it

Avoid a single mutable table when unrelated panels read unrelated fields.

```lua
-- Broad invalidation: every consumer depends on this table identity.
local model = scope:Value({
    score = 0,
    phase = "Lobby",
    timer = 0,
    inventory = {},
})
```

Prefer independent sources at natural update frequencies:

```lua
local score = scope:Value(0)
local phase = scope:Value("Lobby")
local timer = scope:Value(0)
local inventory = scope:Value({})
```

Then derive presentation-sized outputs:

```lua
local scoreText = score:Map(function(value)
    return `Score: {value}`
end)

local timerText = timer:Map(formatTimer)
```

Splitting state is useful when consumers and update rates differ. Do not split
one coherent value into dozens of nodes merely to increase the state count.

## Bound computed work

Computed callbacks should transform data, not perform external effects or scan
unrelated services. Dynamic dependencies already remove inactive branches, so
write conditional computations directly:

```lua
local details = scope:Computed(function(use)
    if not use(isExpanded) then
        return nil
    end
    return buildDetails(use(selectedItem))
end)
```

When a computation allocates a result table, an equality function can suppress
downstream work:

```lua
local viewportModel = scope:Computed(buildViewportModel, {
    equals = function(previous, nextValue)
        return previous.first == nextValue.first
            and previous.last == nextValue.last
            and previous.version == nextValue.version
    end,
})
```

Do not make equality more expensive than the work it prevents. Deep-comparing
a large table on every write can cost more than repainting one label.

Use `Selector` to expose one stable slice from a larger source, and `Combine`
to make a dependency list explicit. Both accept scoped State wrappers and root
getters.

## Batch commands, not time

Batch writes that form one logical UI command:

```lua
scope:Batch(function()
    activeTab:Set("Inventory")
    search:Set("")
    selectedItem:Set(nil)
end)
```

This prevents intermediate computed and binding passes. Do not hold a batch
open while yielding; batching is a synchronous propagation boundary, not a
frame scheduler.

`Throttle` and `Debounce` solve a different problem. They reduce how often a
derived view publishes over time, which is useful for pointer movement, search
input, and network-backed queries.

## Preserve row identity

Collection choice affects both correctness and allocation:

| Primitive | Reuse key | Performance implication |
|---|---|---|
| `ForValues` | Array value identity | Cheap reorder for stable unique objects |
| `ForKeys` | Map key | Stable rows across value changes and reordering |
| `VirtualList` | Absolute source index | Materializes only the viewport range |

Avoid rebuilding a complete array with new table objects when those tables are
also the `ForValues` keys. Every replacement destroys and recreates the row
scope. Prefer stable item objects or an ID-keyed map.

For thousands of fixed-height rows, `VirtualList` avoids constructing offscreen
Instances. It does not remove the cost of producing the source array itself, so
filter and sort deliberately.

## Control Roblox-side work

A Weave property write can trigger more expensive engine work:

- `Text` can cause text measurement.
- `AutomaticSize` can invalidate ancestor layout.
- `Size`, `Position`, and `LayoutOrder` can move many siblings.
- Rich text, gradients, strokes, and viewport content add rendering cost.
- Creating and destroying Instances is more expensive than updating one prop.

Measure those effects separately from the reactive flush. A fast computed that
causes several layout passes can still miss the frame budget.

Prefer one derived property binding over an effect that writes several Instance
properties imperatively. Use `AnimateLayout` only on containers where the
visual result justifies the per-child snapshots and tweens.

## Keep animation channels proportional

All active springs share one frame connection. Each Spring stores packed
numeric channels and updates them linearly. Settled springs leave the pool.
Timers share a managed frame pool as well.

The important quantity is active channel count:

- one number Spring has one channel;
- one `UDim2` Spring has four;
- one `CFrame` Spring has twelve.

Animating hundreds of CFrames for UI decoration costs more than animating a
single container. Prefer hierarchy and composition when several children can
move together.

## Use the built-in counters

Enable counters without mounting UI:

```lua
Weave.Debug = true
```

Enable the client overlay:

```lua
Weave.Debug = "overlay"
```

The overlay reports cumulative `SchedulerFlushes`, `ComputedEvaluations`, and
`SpringUpdates`. A timer refreshes the text ten times per second. Disable it
after the profiling session:

```lua
Weave.Debug = nil
```

The engine also warns when one reactive flush exceeds its slow-flush threshold.
Treat the warning as a starting point: identify the source write, then inspect
the affected computations and Roblox properties.

Counters answer different questions:

| Observation | Likely direction |
|---|---|
| Many evaluations per one user action | Graph fan-out or broad source state |
| Many flushes during one command | Missing batch boundary |
| High Spring updates after UI closes | Animation lifetime leak |
| Low Weave counts but slow frame | Roblox layout, text, rendering, or callback work |

## Profile a representative scenario

Use a repeatable interaction instead of an idle screen:

1. Mount the production-shaped screen with realistic row and binding counts.
2. Reset or record the Weave counters.
3. Perform one scripted action, such as collecting ten pickups or filtering a
   500-row inventory.
4. Record changed labels, recreated rows, active animation channels, and frame
   time.
5. Unmount the screen and repeat the source writes.
6. Confirm no counter continues increasing because of the removed UI.

For Crystal Run, one score update should affect score text and progress. It
should not rebuild phase, timer, lifetime, or the complete HUD tree. That is a
testable dependency expectation, not just a visual impression.

## Understand the native boundary

Hot engine, reconciler, helper, Spring, and Tween modules request Luau native
compilation and optimization. The implementation also uses:

- integer IDs indexing parallel state tables;
- dense queues for changed and pending nodes;
- O(1) dependency metadata and swap removal;
- reusable scratch arrays during dependency collection;
- packed animation channels and linear loops;
- shared frame connections for active pools.

Roblox Luau does not expose portable explicit SIMD intrinsics or direct
L1/L2/L3/L4 cache placement. Weave therefore does not claim those controls.
Dense iteration, fewer allocations, smaller hot structures, and predictable
access patterns are the practical locality improvements available at this
layer.

## Avoid false optimizations

Do not optimize from a table microbenchmark alone. The following changes often
make application code harder without proving a frame improvement:

- replacing readable component functions with one giant constructor;
- pooling small UI Instances without measuring allocation pressure;
- memoizing unstable props that always fail shallow equality;
- combining unrelated states to reduce the number of IDs;
- moving ordinary UI work into per-frame callbacks;
- animating every leaf rather than a shared container.

Use [Testing and Debugging](/weave-rbx/docs/testing-and-debugging/) to turn graph expectations
into regressions. The generated [Scope reference](/weave-rbx/api/Scope/) lists
the performance-oriented utilities and their cleanup contracts.
