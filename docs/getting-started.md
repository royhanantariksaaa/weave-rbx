---
sidebar_position: 2
title: Getting Started
description: Install Weave and its runtime dependencies, verify the package in Studio, and mount a reactive interface with one cleanup boundary.
---

# Getting Started

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--book" aria-hidden="true"></span> Core lesson / Chapter 2</p>
  <p className="lesson-summary">Assemble Weave's exact runtime tree, prove every dependency resolves, then mount state, computed output, an event, and cleanup as one owned interface.</p>
  <div className="lesson-progress" aria-label="Learn Weave progress: 40 percent"><span className="lesson-progress__fill lesson-progress__fill--40"></span></div>
</div>

<div className="lesson-goals">
  <strong>You will build</strong>
  <ul>
    <li>A verified Weave installation with all four source-required dependencies.</li>
    <li>A button whose text and color derive from one writable value.</li>
    <li>A mount lifetime that releases state, bindings, events, and Instances together.</li>
  </ul>
</div>

## Before you start

Weave's source uses absolute requires beneath
`ReplicatedStorage.Libraries`. Package names and sibling placement therefore
matter. Your running place must contain this tree:

```text
ReplicatedStorage
`- Libraries
   |- Echo       ModuleScript package
   |- Symbol     ModuleScript
   |- Trove      ModuleScript
   |- Tween      ModuleScript
   `- Weave      ModuleScript package
StarterPlayer
`- StarterPlayerScripts
   |- WeaveSetupCheck.client.luau
   `- WeaveQuickstart.client.luau
```

| Dependency | Why Weave loads it |
|---|---|
| `Echo` | State invalidation, bindings, and animation change signals. |
| `Symbol` | Collision-free rendering keys and internal sentinels. |
| `Trove` | Scope-owned Instance, connection, task, and callback cleanup. |
| `Tween` | Shared tween scheduling for animated state and utilities. |

The repository's `default.project.json` maps the Weave package itself. A game
that executes Weave must also map the four siblings above.

## Install the packages

From a game repository where `src/Shared` maps to `ReplicatedStorage`, add the
library repositories:

```sh
git submodule add https://github.com/royhanantariksaaa/echo-rbx.git src/Shared/Libraries/Echo
git submodule add https://github.com/royhanantariksaaa/weave-rbx.git src/Shared/Libraries/Weave
git submodule update --init --recursive
```

Provide your project's `Symbol.luau`, `Trove.luau`, and `Tween.luau` modules at
the sibling paths shown above, then sync the complete game project with Rojo.
Do not nest those modules inside Weave; its source intentionally resolves them
from `Libraries`.

## Verify every dependency

Create a temporary LocalScript so the package is tested in the same client
environment that will own the UI:

```lua title="StarterPlayerScripts/WeaveSetupCheck.client.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local libraries = ReplicatedStorage:WaitForChild("Libraries")
local required = { "Echo", "Symbol", "Trove", "Tween", "Weave" }

for _, name in required do
    assert(libraries:FindFirstChild(name), `Missing ReplicatedStorage.Libraries.{name}`)
end

local loaded, Weave = pcall(require, libraries.Weave)
assert(loaded, `Weave failed to load: {Weave}`)
assert(type(Weave.mount) == "function", "Weave.mount is missing")

local scope = Weave.scope()
local value = scope:Value("ready")
assert(value:Get() == "ready", "Scoped state did not initialize")
scope:Destroy()

print("[Weave setup] ready")
```

Press **Play**. Continue only after Output prints `[Weave setup] ready` without
a require warning. Remove the probe when it passes.

## Mount the first interface

Replace the probe with this LocalScript:

```lua title="StarterPlayerScripts/WeaveQuickstart.client.luau"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weave = require(ReplicatedStorage.Libraries.Weave)
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local cleanup = Weave.mount(playerGui, {
    Name = "WeaveQuickstart",
    ResetOnSpawn = false,
}, function(scope)
    local count = scope:Value(0)

    local label = scope:Computed(function()
        return `Count {count:Get()} / Double {count:Get() * 2}`
    end)

    local color = scope:Computed(function()
        if count:Get() >= 5 then
            return Color3.fromRGB(81, 196, 148)
        end
        return Color3.fromRGB(66, 135, 245)
    end)

    return scope:TextButton {
        Name = "CounterButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(280, 56),
        BackgroundColor3 = color,
        Text = label,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 18,
        [Weave.OnEvent("Activated")] = function()
            count:Update(function(current)
                return current + 1
            end)
        end,
    }
end)

script.Destroying:Connect(cleanup)
```

Press **Play**. The centered button begins at
`Count 0 / Double 0`. Each activation updates both numbers. At five clicks,
the same source value also changes the background color.

## Follow one update

1. The `Activated` connection calls `count:Update`.
2. Weave writes the Value and marks dependent Computed nodes pending.
3. `label` and `color` re-read `count`, preserving their dependency edges.
4. Only the `Text` and `BackgroundColor3` bindings repaint.
5. Roblox owns drawing and input; the Weave scope owns the reactive graph and
   connection that feed those properties.

This is fine-grained propagation. The builder function does not rerun as a
component render loop after every click.

## Understand scoped and root state

The two constructor families have different ownership shapes:

| Constructor | Returned shape | Cleanup |
|---|---|---|
| `scope:Value(initial)` | Callable state wrapper with `Get`, `Peek`, `Set`, `Update`, and `Map`; also returns a setter as a second value. | Automatic when the scope is destroyed. |
| `scope:Computed(callback)` | Read-only callable wrapper with tracked reads. | Automatic with the scope. |
| `Weave.value(initial)` | Getter and setter closures for infrastructure outside a scope. | Call `Weave.destroy(getter)` explicitly. |
| `Weave.computed(callback)` | Getter closure tracked by the root engine. | Call `Weave.destroy(getter)` explicitly. |

Use scoped constructors for screens and components. Root constructors are
useful when the state genuinely outlives every mounted interface, but they
require an owner with a manual destroy path.

## Unmount deliberately

The function returned by `Weave.mount` is the root cleanup boundary. Calling
it releases:

- the generated `ScreenGui` and descendant Instances;
- scoped Values, Computed nodes, springs, tweens, and async state;
- property bindings and event connections;
- jobs and callbacks registered through the scope;
- nested resources added by Weave or your components.

The cleanup function is safe to connect to the owning script's `Destroying`
event. For a screen that opens and closes repeatedly, call it when that screen
closes and create a fresh mount the next time.

## Diagnose common setup failures

| Symptom | Likely cause | Fix |
|---|---|---|
| `Echo`, `Symbol`, `Trove`, or `Tween` is not a valid member | A required sibling is absent or nested in the wrong package. | Match the Explorer tree before debugging UI code. |
| `Weave failed to load` from `pcall(require, ...)` | The Weave package root does not include its `Core`, `Scope`, `States`, and other mapped children. | Map the complete repository package using its project layout. |
| `LocalPlayer` or `PlayerGui` is `nil` | The quickstart was placed in a server Script. | Use a LocalScript under `StarterPlayerScripts`. |
| The button appears but never changes | The event key was written as a normal string or the state was read once into a plain value. | Use `[Weave.OnEvent("Activated")]` and pass reactive state to properties. |
| The UI duplicates after reopening | A previous mount was never cleaned up. | Retain and call the cleanup function before mounting again. |
| A root state survives after its feature closes | `Weave.value` was used without manual destruction. | Prefer `scope:Value` or call `Weave.destroy` from the feature owner. |

## Check your result

- The dependency probe loads all five modules and destroys its test scope.
- One Value drives two Computed outputs and two Instance properties.
- Clicking does not rebuild or duplicate the button.
- The mount cleanup is retained by the owning LocalScript.
- You can explain which resources Roblox owns and which resources the scope owns.

<div className="chapter-next">
  <p><strong>Next: build one feature completely.</strong><br />Add a progress binding, batched state changes, a recorded Studio result, and explicit unmount verification.</p>
  <a href="/weave-rbx/docs/tutorial-reactive-counter/">Build the reactive counter</a>
</div>
