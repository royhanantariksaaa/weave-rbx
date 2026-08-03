---
sidebar_position: 9
---

# Integrations

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Composition / Library stack</p>
  <p className="lesson-summary">Combine Echo events, WeaveKit components, and Flite proxy state while keeping each library responsible for one kind of work and one teardown boundary.</p>
</div>

The four libraries compose without becoming one indistinguishable framework.
Keep the ownership line visible and adapters small.

| Library | Owns | Does not own |
|---|---|---|
| Echo | Local event fan-out and listener lifetime | UI state or server authority |
| Weave | Client derivation, rendering, animation, and UI cleanup | Gameplay authority |
| WeaveKit | Reusable component construction and controls | Application state ownership |
| Flite | Service/controller lifecycle, networking, replicated state | Low-level visual composition |

## Bridge Echo into a scope

Use Echo for an imperative fact such as "toast requested" or "panel closed".
Use Weave State for the current value the UI renders.

```lua
local toastRequested = Echo.new()

local function ToastRegion(scope)
    local queue = scope:Queue({ maxSize = 4 })

    local connection = toastRequested:connect(function(message)
        queue.Push({
            id = HttpService:GenerateGUID(false),
            message = message,
        })
    end)

    scope:OnDestroy(function()
        connection:disconnect()
    end)

    return scope:ForValues(queue.Items, function(rowScope, toast, index)
        return rowScope:TextLabel {
            LayoutOrder = index,
            Text = toast.message,
        }
    end)
end
```

The Echo connection enters the Weave scope at one adapter. Downstream UI reads
the queue rather than subscribing every component to the event bus.

Do not depend on the Echo signals used internally by Weave's engine. Treat the
public Weave State contract as the integration surface.

## Turn Roblox signals into State

For an `RBXScriptSignal`, `FromEvent` creates an owned State containing the
latest mapped payload:

```lua
local viewport = scope:FromEvent(
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
    function()
        return workspace.CurrentCamera.ViewportSize
    end
)
```

`ObserveNet` supports a raw `RemoteEvent`, a signal-like object with `Connect`,
or a named signal on a service table. It is a compatibility bridge, not a
replacement for Flite's typed proxy state.

```lua
local lastAnnouncement = scope:ObserveNet(
    announcementRemote,
    "",
    function(message)
        return tostring(message)
    end
)
```

Both connections are released with the scope.

## Build WeaveKit controls inside the owner

WeaveKit builders accept a Weave scope. The caller retains state ownership; the
component owns only the Instances and handlers it constructs.

```lua
local saving = scope:Value(false)

local saveButton = WeaveKit.PillButton.new(scope)
    :SetText(saving:Map(function(active)
        return active and "Saving..." or "Save"
    end))
    :OnActivated(function()
        if saving:Peek() then
            return
        end
        saveSettings()
    end)
    :Build()
```

Keep WeaveKit behind a feature component boundary:

```lua
local function SettingsActions(scope, model)
    return scope:Flex {
        Direction = Enum.FillDirection.Horizontal,
        Gap = UDim.new(0, 8),

        WeaveKit.PillButton.new(scope)
            :SetText("Cancel")
            :OnActivated(model.cancel)
            :Build(),

        WeaveKit.PillButton.new(scope)
            :SetText("Save")
            :OnActivated(function()
                if not model.saving:Peek() then
                    model.save()
                end
            end)
            :Build(),
    }
end
```

This keeps the application workflow testable without making the design-system
builder responsible for it.

## Consume Flite replicated state

A Flite controller is backed by a Weave scope. Resolve service and state
dependencies during controller setup, then mount the UI during lifecycle.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Flite = require(ReplicatedStorage.Libraries.Flite)
local Weave = require(ReplicatedStorage.Libraries.Weave)

return Flite.createController("HudController", function(self)
    local score = self:useServiceState("RoundService", "Score")
    local phase = self:useServiceState("RoundService", "Phase")

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    self:onStart(function()
        local unmount = Weave.mount(playerGui, "RoundHud", function(scope)
            local scoreText = scope:Computed(function()
                return `Score: {score:Get()}`
            end)
            local phaseText = scope:Computed(function()
                return `Phase: {phase:Get()}`
            end)

            return scope:Frame {
                BackgroundTransparency = 1,
                scope:TextLabel { Text = scoreText },
                scope:TextLabel { Text = phaseText },
            }
        end)

        self:AddCleanup(unmount)
    end)
end)
```

Flite client state is already a Weave-compatible readable state. Read it
directly inside a Computed instead of copying every update into a second Value.
Create a local Value only when the UI needs a distinct draft, optimistic value,
or animation target.

## Keep commands and presentation separate

An exposed Flite method is a command boundary. Do not invoke it from a Computed
or Effect that can rerun unexpectedly. Call it from an event handler and write
the request status into local state.

```lua
local purchasing = scope:Value(false)
local purchaseError = scope:Value(nil)

local function purchase(itemId)
    if purchasing:Peek() then
        return
    end

    purchasing:Set(true)
    purchaseError:Set(nil)

    task.spawn(function()
        local ok, result = pcall(function()
            return shopService:Purchase(itemId)
        end)

        if ok then
            -- Replicated inventory state will drive the final UI.
        else
            purchaseError:Set(tostring(result))
        end

        purchasing:Set(false)
    end)
end
```

The server remains authoritative. Weave owns only request presentation and
derivations from replicated results.

## Trace a complete update

In a full stack flow:

1. Input invokes one controller handler.
2. The handler calls a Flite service command.
3. The service validates and changes authoritative state.
4. Flite replicates the affected field.
5. The client proxy writes its Weave state.
6. Weave schedules only dependent Computed nodes and bindings.
7. Echo may fan out a local transient event such as feedback or analytics.
8. WeaveKit Instances display the resulting state.

That sequence gives each failure a home. Validation belongs to Flite, local
event listener errors belong to Echo consumers, reactive derivation belongs to
Weave, and component styling belongs to WeaveKit.

## Own teardown once

Choose one top-level owner and register every adapter with it:

```lua
self:onStart(function()
    local unmount = Weave.mount(playerGui, buildHud)
    self:AddCleanup(unmount)

    local connection = localEvents:connect(handleLocalEvent)
    self:AddCleanup(function()
        connection:disconnect()
    end)
end)
```

Do not both destroy a long-lived shared state in a child component and expect a
controller to keep using it. The creator should own cleanup.

## Diagnose integration failures

| Symptom | Boundary to inspect |
|---|---|
| UI never receives server value | Flite state exposure, metadata, or client hydration |
| Value arrives but label stays stale | Weave tracked read or property binding |
| Event fires twice after reopening | Echo or remote connection escaped teardown |
| Button looks correct but workflow fails | Application command handler, not WeaveKit styling |
| Server call repeats unexpectedly | Command was placed in Effect or Computed |
| Optimistic UI disagrees with server | Local draft was treated as authority |
| Screen closes but callbacks continue | Missing controller or mount cleanup registration |

The [complete Crystal Run HUD](/weave-rbx/docs/project-crystal-run/) follows this route with
real files, preview data, replicated state, and teardown. Continue into the
separate [Echo](https://royhanantariksaaa.github.io/echo-rbx/),
[WeaveKit](https://royhanantariksaaa.github.io/weavekit-rbx/), and
[Flite](https://royhanantariksaaa.github.io/flite-rbx/) handbooks for each
boundary's complete API.
