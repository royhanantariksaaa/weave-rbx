---
sidebar_position: 2
---

# Getting Started

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
