---
sidebar_position: 9
---

# Integrations

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Composition / Library stack</p>
  <p className="lesson-summary">Combine Echo events, WeaveKit components, and Flite proxy state while keeping each library responsible for one kind of work.</p>
</div>

## Echo

Register Echo connections with the owning scope:

```lua
local connection = eventBus:connect(function(value)
    state:Set(value)
end)

scope:OnDestroy(function()
    connection:disconnect()
end)
```

## WeaveKit

WeaveKit builders accept a Weave scope and return ordinary Instances or
controls:

```lua
local button = WeaveKit.PillButton.new(scope)
    :SetText("Save")
    :OnActivated(save)
    :Build()
```

## Flite

Controllers can connect replicated Flite state to Weave state or pass readable
state objects directly to adapters that support `Get`:

```lua
return Flite.createController("HudController", function(self)
    local stats = self:useService("StatsService")

    self:onStart(function()
        Weave.mount(playerGui, function(scope)
            return scope:TextLabel {
                Text = scope:Computed(function()
                    return `Score: {stats.Score:Get()}`
                end),
            }
        end)
    end)
end)
```

Flite hydrates replicated fields as Weave state, so direct tracked reads are
the default integration path.

## In Crystal Run

The [complete HUD](./project-crystal-run) is the integration boundary in full:
Flite supplies server-confirmed state, Echo supplies transient local facts,
and Weave owns derivation, rendering, and cleanup.
