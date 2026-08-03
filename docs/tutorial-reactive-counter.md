---
sidebar_position: 2.5
title: Build a Reactive Counter
description: Mount a Weave interface with Value, Computed, bindings, events, and deterministic cleanup.
---

# Tutorial: Build a Reactive Counter

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Focused tutorial / Chapter 3</p>
  <p className="lesson-summary">Mount a counter whose label, doubled value, and progress bar derive from one write, then follow Weave's dependency tracking from source state to affected bindings.</p>
  <div className="lesson-progress" aria-label="Learn Weave progress: 60 percent"><span className="lesson-progress__fill lesson-progress__fill--60"></span></div>
</div>

<div className="lesson-goals">
  <strong>What this feature proves</strong>
  <ul>
    <li>One source can drive several computed values without manual redraw code.</li>
    <li>Instance bindings and events share the mount scope's lifetime.</li>
    <li>The same graph scales into Crystal Run's timer, score, phase, and feedback HUD.</li>
  </ul>
</div>

<figure className="tutorial-demo">
  <img className="tutorial-demo__motion" src="/weave-rbx/tutorials/weave-reactive-counter.gif" alt="Weave reactive counter propagating state in Roblox Studio" />
  <img className="tutorial-demo__still" src="/weave-rbx/tutorials/weave-reactive-counter.png" alt="Final Weave reactive counter state in Roblox Studio" />
  <figcaption>One Value update invalidating a Computed value and its UI bindings.</figcaption>
</figure>

:::tip Experiment alongside the tutorial
Open the [Weave Playground](/weave-rbx/docs/playground/) to move writes in and out of Batch
and watch recomputation and binding paint counts change immediately.
:::

## Before you start

Map Weave and its runtime dependencies as siblings:

```text
ReplicatedStorage
`- Libraries
   |- Weave
   |- Echo
   |- Symbol
   |- Trove
   `- Tween
StarterPlayer
`- StarterPlayerScripts
   `- ReactiveCounter.client.luau
```

## Mount the interface

```lua title="StarterPlayerScripts/ReactiveCounter.client.luau"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weave = require(ReplicatedStorage.Libraries.Weave)
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local cleanup = Weave.mount(playerGui, function(scope)
    local count = scope:Value(0)
    local doubled = scope:Computed(function()
        return count:Get() * 2
    end)
    local progress = scope:Computed(function()
        return count:Get() / 8
    end)

    return scope:Frame {
        Name = "ReactiveCounter",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 220),
        BackgroundColor3 = Color3.fromRGB(28, 34, 36),
        [Weave.Children] = {
            scope:UICorner {
                CornerRadius = UDim.new(0, 6),
            },
            scope:TextLabel {
                Position = UDim2.fromOffset(24, 24),
                Size = UDim2.new(1, -48, 0, 52),
                BackgroundTransparency = 1,
                Text = scope:Computed(function()
                    return `Count {count:Get()} / Double {doubled:Get()}`
                end),
                TextColor3 = Color3.fromRGB(235, 242, 242),
                TextSize = 24,
            },
            scope:Frame {
                Position = UDim2.fromOffset(24, 92),
                Size = scope:Computed(function()
                    return UDim2.new(progress:Get(), 0, 0, 12)
                end),
                BackgroundColor3 = Color3.fromRGB(46, 205, 166),
                [Weave.Children] = {
                    scope:UICorner {
                        CornerRadius = UDim.new(1, 0),
                    },
                },
            },
            scope:TextButton {
                Position = UDim2.fromOffset(24, 132),
                Size = UDim2.new(1, -48, 0, 56),
                BackgroundColor3 = Color3.fromRGB(46, 205, 166),
                Text = "Increment",
                TextColor3 = Color3.fromRGB(12, 25, 23),
                TextSize = 18,
                [Weave.OnEvent("Activated")] = function()
                    count:Update(function(current)
                        return (current + 1) % 9
                    end)
                end,
                [Weave.Children] = {
                    scope:UICorner {
                        CornerRadius = UDim.new(0, 6),
                    },
                },
            },
        },
    }
end)

script.Destroying:Connect(cleanup)
```

Press **Play**, then click **Increment**. The counter advances from `0` to
`8`, the doubled value reaches `16`, and the bar fills without any manual
redraw call.

## Follow the propagation

1. `Weave.mount` creates a root scope and parents the returned Instance under
   `PlayerGui`.
2. `scope:Value(0)` creates the only writable state in this example.
3. Each `Computed` records the states read through `Get` while it evaluates.
4. Passing a state as an Instance property creates a live property binding.
5. `Weave.OnEvent("Activated")` owns the Roblox event connection in the same
   scope.
6. `cleanup()` destroys the mounted tree, bindings, states, and connections.

## Batch related writes

When one action changes several source values, settle them together:

```lua
scope:Batch(function()
    count:Set(4)
    selected:Set("Counter")
end)
```

The outer batch flushes each affected computation and property binding once.

## API checkpoints

| API | Role in this tutorial |
|---|---|
| `Weave.mount(parent, builder)` | Creates an owned UI root and returns cleanup. |
| `scope:Value(initial)` | Stores writable reactive state. |
| `scope:Computed(callback)` | Caches derived state with dynamic dependencies. |
| `scope:ClassName(props)` | Constructs and owns a Roblox Instance. |
| `Weave.Children` | Supplies child Instances without colliding with properties. |
| `Weave.OnEvent(name)` | Declares an owned event callback. |
| `scope:Batch(callback)` | Coalesces related writes before propagation. |

## Common mistakes

### Reading with `Peek` inside `Computed`

`Peek` intentionally avoids dependency tracking. Use `Get` when a computed
value should rerun after the source changes.

### Forgetting cleanup

Keep the function returned by `Weave.mount`. Call it when the screen,
controller, or owning script is released.

### Creating state outside the mount

Use the provided scope for UI-owned state. That gives the interface one clear
lifetime and prevents stale bindings after unmount.

## Next steps

Continue with [Scopes and State](/weave-rbx/docs/scopes-and-state/),
[Rendering](/weave-rbx/docs/rendering/), and [Animation and Async](/weave-rbx/docs/animation-and-async/),
then apply those systems to one complete screen.

<div className="chapter-next">
  <p><strong>Continue into the complete game.</strong><br />Build a responsive HUD from Flite's live round model and Echo's pickup events.</p>
  <a href="/weave-rbx/docs/project-crystal-run/">Build the Crystal Run HUD</a>
</div>
