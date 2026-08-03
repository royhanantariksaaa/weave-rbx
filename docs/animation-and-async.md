---
sidebar_position: 5
---

# Animation and Async

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--play" aria-hidden="true"></span> Reactivity / Time</p>
  <p className="lesson-summary">Represent springs, tweens, transitions, and asynchronous work as scope-owned state instead of detached tasks and manual property loops.</p>
</div>

## Springs

```lua
local target = scope:Value(0)
local animated = scope:Spring(target, 18, 0.8)

scope:Frame {
    Position = scope:Computed(function()
        return UDim2.fromScale(animated:Get(), 0.5)
    end),
}
```

Springs share one frame connection and batch channel writes per frame. Numeric,
vector, color, UDim, and UDim2 channels are packed for linear iteration.

## Tweens

```lua
local opacity = scope:Value(0)
local animatedOpacity = scope:Tween(
    opacity,
    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
)
```

Spring and Tween wrappers compose the common animation-state surface and are
callable read states.

## Presence and transitions

Use `AnimatePresence` when an item needs an exit animation before its branch is
destroyed. `Transition` groups related state changes and `Stagger` offsets child
animation timing.

## Async state

```lua
local profile = scope:Async(function()
    return loadProfile():expect()
end)

scope:Suspense(profile, {
    Pending = function(s)
        return s:TextLabel { Text = "Loading" }
    end,
    Resolved = function(s, value)
        return s:TextLabel { Text = value.DisplayName }
    end,
    Rejected = function(s, err)
        return s:TextLabel { Text = tostring(err) }
    end,
})
```

Async status contains `Status`, `Value`, and `Error`. Suspense accepts scoped
Async wrappers and raw async state IDs while retaining branch ownership.

## In Crystal Run

The [HUD project](./project-crystal-run) includes a production extension that
springs only the visual progress bar while keeping the authoritative score
immediate. The distinction prevents animation state from becoming game state.
