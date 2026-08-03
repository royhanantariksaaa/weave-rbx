---
sidebar_position: 3
---

# Scopes and State

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--identity" aria-hidden="true"></span> Reactivity / Ownership</p>
  <p className="lesson-summary">Build a dependency graph whose Values, computed work, effects, Instances, and connections all share an explicit scope lifetime.</p>
</div>

## Ownership first

A scope owns every state, Instance, connection, effect, task, and child scope
created through it. Destroying the scope releases those resources once.

```lua
local scope = Weave.scope()
local health = scope:Value(100)

scope:OnDestroy(function()
    print("scope released")
end)

scope:Destroy()
scope:Destroy() -- idempotent
```

Use `Weave.mount` for UI roots. Use `Weave.scope(parentScope)` when composing a
resource owner that does not directly mount an Instance tree.

## Mutable values

```lua
local count = scope:Value(0)

count:Set(1)
count:Update(function(value)
    return value + 1
end)

print(count:Get())
```

Factories accept both dot and colon syntax. Scoped values are callable as a
convenient read form, while `Get` makes intent explicit.

## Computed and derived state

```lua
local subtotal = scope:Value(20)
local taxRate = scope:Value(0.1)

local total = scope:Computed(function()
    return subtotal:Get() * (1 + taxRate:Get())
end)
```

Dependencies are tracked dynamically. When a computation stops reading a
source, the reverse edge is removed during its next evaluation.

`Derived` behaves like computed state but accepts an explicit temporary
override through its setter.

## Reducers

```lua
local count, dispatch = scope:Reducer(function(state, action)
    if action == "increment" then
        return state + 1
    end
    return state
end, 0)

dispatch("increment")
```

## Effects

```lua
scope:Effect(function()
    print("total changed", total:Get())
end)
```

The effect reruns when any tracked state read changes. Return or register
cleanup for external resources through the surrounding scope.

## Batching

```lua
scope:Batch(function()
    subtotal:Set(50)
    taxRate:Set(0.2)
end)
```

Nested batches are supported. The outer batch flushes the affected dependency
queue and property bindings once.

## In Crystal Run

The [reactive HUD](./project-crystal-run) treats Flite proxy fields as source
state, derives labels and progress, then releases the complete graph through
the `HudController` mount cleanup.
