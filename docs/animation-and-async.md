---
sidebar_position: 5
---

# Animation and Async

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--play" aria-hidden="true"></span> Reactivity / Time</p>
  <p className="lesson-summary">Keep authoritative values immediate while springs, tweens, transitions, presence, and asynchronous resources become scope-owned projections of time.</p>
</div>

Animation state follows another state. Async state represents the status of
work that has not finished. Both are readable reactive nodes, so ordinary
property bindings and computations can consume them without manual render
loops.

The central rule is to keep the source of truth separate from its delayed
presentation.

## Separate truth from motion

Use ordinary state for the value gameplay or interaction logic should read.
Use an animation state only for the rendered projection.

```lua
local progress = scope:Value(0) -- immediate source of truth
local animatedProgress = scope:Spring(progress, 18, 0.85)

local barSize = scope:Computed(function(use)
    return UDim2.fromScale(use(animatedProgress), 1)
end)

scope:Frame {
    Size = barSize,
}
```

When `progress:Set(0.75)` runs, rules can immediately read `0.75`; the bar
settles toward it over subsequent frames.

## Choose Spring or Tween

| Need | Use |
|---|---|
| Interruptible physical motion that keeps its velocity | `Spring` |
| Fixed duration and easing curve | `Tween` |
| Several imperative property steps in sequence | `Animate` |
| Animate children after layout changes | `AnimateLayout` |
| Delay branch destruction | `Transition` or `AnimatePresence` |

### Spring

```lua
local targetPosition = scope:Value(UDim2.fromScale(0.5, 0.5))
local position = scope:Spring(targetPosition, 20, 0.9)

position:SetSpeed(24)
position:SetDamping(1)

scope:Frame {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = position,
}
```

The second argument controls speed; the third is the damping ratio. A value of
`1` is critically damped. Lower values can overshoot, while larger values
settle more heavily.

Springs decompose `number`, `Vector2`, `Vector3`, `UDim`, `UDim2`, `Color3`,
and `CFrame` values into numeric channels. All active springs share one update
pool. Frame deltas are capped, larger steps are subdivided, and writes are
batched before dependent bindings flush.

Unsupported target types use synchronous passthrough. That keeps animation
states composable, but it does not create interpolation for strings, booleans,
or arbitrary tables.

### Tween

```lua
local targetTransparency = scope:Value(0)
local transparency = scope:Tween(
    targetTransparency,
    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
)

scope:CanvasGroup {
    GroupTransparency = transparency,
}
```

A target change cancels the current tween controller and starts a new one from
the present animated value. Use a Spring when maintaining momentum through
rapid interruptions matters more than a fixed duration.

## Use the animation-state contract

Springs and Tweens are callable states and support:

| Method | Behavior |
|---|---|
| `Get()` or `()` | Tracked read of the current animated value |
| `Peek()` | Untracked read |
| `Map(transform)` | Create a computed projection |
| `Throttle(seconds)` | Limit projection update rate |
| `Debounce(seconds)` | Wait for settled projection input |
| `Awake()` | Resume or force the animation worker |
| `Destroy()` | Disconnect the target and release the animation node |

Spring adds `SetSpeed` and `SetDamping`. Tween has an internal `Set` path used
by its tween controller; application code should normally change the target
state instead.

Root `Weave.spring` and `Weave.tween` resources require manual `Destroy`.
Scope-created animation states are destroyed with the scope.

## Sequence imperative property motion

`Animate` runs property steps in order and returns an idempotent controller.

```lua
local sequence = scope:Animate(notification, {
    {
        Property = "Position",
        To = UDim2.fromScale(0.5, 0.08),
        Duration = 0.18,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out,
    },
    {
        Property = "BackgroundTransparency",
        To = 1,
        Delay = 1.5,
        Duration = 0.2,
    },
})

-- Optional early stop. Scope teardown also cancels it.
sequence.Cancel()
```

Each step controls one property. Steps are scheduled using the accumulated
delay and duration. For continuously reactive UI, prefer Spring or Tween state;
use `Animate` for a finite command with a clear start and end.

`AnimateLayout` snapshots child positions and applies a FLIP transition after
children are added, removed, or reordered:

```lua
local layout = scope:AnimateLayout(listFrame, {
    Duration = 0.22,
    EasingStyle = Enum.EasingStyle.Quint,
})

layout.Refresh() -- remeasure after another layout-affecting change
```

It adjusts `Position`, so avoid combining it with another imperative writer for
that same property.

## Animate branch lifetime

`Transition` is the right primitive for one boolean branch. Its exit function
receives a `done` callback that controls teardown.

```lua
scope:Transition(isOpen, function(menuScope)
    return buildMenu(menuScope)
end, {
    Enter = function(instances)
        playEnter(instances)
    end,
    Exit = function(instances, done)
        playExit(instances, done)
    end,
})
```

`Stagger` delays a per-row alpha state from `0` to `1`. It does not interpolate
the alpha by itself; feed that state into a Tween, Spring, or mapping.

```lua
scope:Stagger(items, function(rowScope, item, index, alpha)
    local animatedAlpha = rowScope:Tween(alpha, TweenInfo.new(0.16))
    return rowScope:CanvasGroup {
        LayoutOrder = index,
        GroupTransparency = animatedAlpha:Map(function(value)
            return 1 - value
        end),
        rowScope:TextLabel { Text = item.name },
    }
end, { delay = 0.04 })
```

`AnimatePresence` keeps removed array values alive while its `Exit` callback
runs. The callback receives an exit scope and the rendered Instance. It runs in
a task; return only after the exit work is complete.

```lua
scope:AnimatePresence(toasts, renderToast, {
    Exit = function(exitScope, instance)
        local sequence = exitScope:Animate(instance, {
            {
                Property = "BackgroundTransparency",
                To = 1,
                Duration = 0.18,
            },
        })
        task.wait(0.18)
    end,
})
```

Array values are identity keys. If the same value is reinserted before its exit
finishes, Weave cancels the removal and retains that row.

## Model one asynchronous result

`scope:Async` starts its producer immediately in a task and exposes one status
record:

```lua
local profile = scope:Async(function()
    return loadProfile():expect()
end)

local status = profile:Get()
print(status.Status, status.Value, status.Error)
```

The status values are:

| Status | `Value` | `Error` |
|---|---|---|
| `"Pending"` | `nil` | `nil` |
| `"Resolved"` | Producer result | `nil` |
| `"Rejected"` | `nil` | Thrown value |

Destroying the state cancels its producer thread and prevents a late result
from writing into a recycled state ID.

## Render pending and resolved states

`Suspense` takes one props table. It accepts one Async state or an array of
Async states.

```lua
scope:Suspense {
    Resource = profile,
    Fallback = function(pendingScope)
        return pendingScope:TextLabel { Text = "Loading profile..." }
    end,
    Children = function(resolvedScope, value)
        return resolvedScope:TextLabel {
            Text = value.DisplayName,
        }
    end,
}
```

For several resources, `Children` receives a values array in the same order.
Suspense treats a rejection as an error. If the screen needs a local rejected
state with a retry button, render the Async status through `Switch`, or use
`Resource`, whose error is ordinary reactive data.

## Fetch changing data with Resource

`Resource` is for key-driven, repeatable data rather than one producer run.

```lua
local playerId = scope:Value("player:42")
local inventory = scope:Resource(playerId, function(key)
    return fetchInventory(key)
end, {
    staleTime = 30,
    retries = 2,
    refetchInterval = 0,
})

scope:Switch(inventory.status, {
    loading = function(s)
        return s:TextLabel { Text = "Loading inventory..." }
    end,
    success = function(s)
        return buildInventory(s, inventory.data)
    end,
    error = function(s)
        return s:TextButton {
            Text = "Retry",
            OnActivated = inventory.refetch,
        }
    end,
})
```

Resource statuses are lowercase: `idle`, `loading`, `success`, and `error`.
Its cache is shared across scopes using the key value, stale time is measured in
seconds, concurrent requests for one key are deduplicated, and retries use
exponential waits. Keys must be non-nil and stable.

`invalidate()` removes the current cache entry before fetching. `refetch()`
respects a fresh cache entry.

## Lazy-load code and preload assets

`Weave.lazy(factory)` creates a handle whose factory runs at most once.
`scope:Lazy(handle, fallback)` resolves it through Async and renders a component
when ready.

```lua
local SettingsPanel = Weave.lazy(function()
    return require(ReplicatedStorage.UI.SettingsPanel)
end)

scope:Lazy(SettingsPanel, function(s)
    return s:TextLabel { Text = "Loading settings..." }
end)
```

`Preload` uses `ContentProvider:PreloadAsync` before constructing its children:

```lua
scope:Preload {
    Assets = { imageLabel, sound },
    Fallback = function(s)
        return s:TextLabel { Text = "Preparing assets..." }
    end,
    Children = function(s)
        return buildReadyView(s)
    end,
}
```

## Diagnose time-based failures

| Symptom | Likely cause | Check |
|---|---|---|
| Gameplay reads a lagging value | Animated state became authority | Read and write the target Value |
| Spring snaps instead of interpolating | Target type is unsupported or changed shape | Use a supported stable type |
| Transition branch never leaves | Exit did not call `done` | Complete every exit path |
| Stagger row appears instantly | Alpha was bound directly without interpolation | Map it through Spring or Tween |
| Suspense throws after loading | Producer rejected | Render status directly or use Resource |
| Resource refetches constantly | Key identity changes on each computation | Use a stable scalar key |
| Old request wins | Imperative fetches are racing outside Resource | Use key-driven Resource or version the request |
| Animation continues after screen close | Root animation or detached task has no owner | Create it on the screen scope |

The [complete Crystal Run HUD](/weave-rbx/docs/project-crystal-run/) applies this separation to
server-confirmed progress and visual smoothing. Use the generated
[AnimationState](/weave-rbx/api/AnimationState/) and
[Scope](/weave-rbx/api/Scope/) references for exact methods.
