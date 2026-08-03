---
sidebar_position: 6
---

# Context and Styling

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--book" aria-hidden="true"></span> Composition / Shared inputs</p>
  <p className="lesson-summary">Share typed values, reusable styles, and registered constructors through composition while retaining one surrounding scope.</p>
</div>

## Typed context

```lua
local Locale = Weave.createContext("en")

local parent = Weave.scope()
parent:Provide(Locale, "id")

local child = Weave.scope(parent)
print(child:UseContext(Locale)) -- id
```

Child scopes inherit context without copying the parent table. A nearer
provider shadows the inherited value.

## Named styles

```lua
Weave.defineStyle("PrimaryButton", {
    BackgroundColor3 = Color3.fromRGB(15, 118, 110),
    TextColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = false,
})
```

Apply registered styles through the style prop supported by the reconciler.
Explicit props retain precedence over style defaults.

## Prop shorthands

Weave supports structured padding data and sequence helpers. Prefer the helpers
when theme data must remain serializable:

```lua
local gradient = Weave.colorSequence({
    { Time = 0, Value = { 0.1, 0.6, 0.7 } },
    { Time = 1, Value = { 0.9, 0.4, 0.3 } },
})
```

## Component registration

```lua
scope:RegisterComponent("StatusPill", function(componentScope, props)
    return componentScope:TextLabel {
        Text = props.Text,
    }
end)

local pill = scope:StatusPill { Text = "Online" }
```

Registered constructors compose with the same scope lifecycle as Roblox
Instance constructors.

## In Crystal Run

The [HUD component](./project-crystal-run) receives its model and event hub as
arguments, which makes ownership visible and previewing straightforward. Use
context when those dependencies must cross several intermediate components.
