---
sidebar_position: 9
---

# Integrations

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
    self:onStart(function()
        local stats = Flite.getService("StatsService")

        Weave.mount(playerGui, function(scope)
            local score = scope:Value(stats.Score:get())
            local connection = stats.Score:observe(function(value)
                score:Set(value)
            end)

            scope:OnDestroy(function()
                connection:disconnect()
            end)

            return scope:TextLabel {
                Text = scope:Computed(function()
                    return `Score: {score:Get()}`
                end),
            }
        end)
    end)
end)
```
