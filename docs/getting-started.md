---
sidebar_position: 2
---

# Getting Started

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--book" aria-hidden="true"></span> Core lesson / Chapter 2</p>
  <p className="lesson-summary">Mount a scoped interface, derive UI from tracked state, and release the whole tree through one cleanup boundary.</p>
  <div className="lesson-progress" aria-label="Learn Weave progress: 40 percent"><span className="lesson-progress__fill lesson-progress__fill--40"></span></div>
</div>

<div className="lesson-goals">
  <strong>You will build</strong>
  <ul>
    <li>A mounted UI tree owned by one Weave scope.</li>
    <li>Writable and computed state with reactive property bindings.</li>
    <li>The ownership pattern used by Crystal Run's complete HUD.</li>
  </ul>
</div>

## Installation

Map Weave to `ReplicatedStorage.Libraries.Weave` and provide its runtime
dependencies through your Rojo project. The repository's
`default.project.json` documents the expected package tree.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Weave = require(ReplicatedStorage.Libraries.Weave)
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
```

## Mount a reactive interface

```lua
local cleanup = Weave.mount(playerGui, function(scope)
    local count = scope:Value(0)
    local doubled = scope:Computed(function()
        return count:Get() * 2
    end)

    return scope:TextButton {
        Size = UDim2.fromOffset(220, 48),
        Text = scope:Computed(function()
            return `Count {count:Get()} / Double {doubled:Get()}`
        end),
        [Weave.OnEvent("Activated")] = function()
            count:Set(count:Get() + 1)
        end,
    }
end)
```

Call `cleanup()` when the interface is no longer needed. The mount scope owns
everything created by the builder.

## Batch related writes

```lua
scope:Batch(function()
    first:Set("Ada")
    last:Set("Lovelace")
end)
```

Bindings and dependent computations observe the settled result once.

<div className="chapter-next">
  <p><strong>Next: build one feature completely.</strong><br />Connect state, computed values, Instance bindings, events, and unmount cleanup.</p>
  <a href="./tutorial-reactive-counter">Build the reactive counter</a>
</div>
