---
title: "Crystal Run: Reactive HUD"
description: Build Crystal Run's complete responsive HUD with replicated Flite state, Echo feedback events, derived Weave state, and scope-owned cleanup.
---

# Crystal Run: Reactive HUD

<div className="project-header">
  <p className="project-kicker"><span className="streamline-icon streamline-icon--identity" aria-hidden="true"></span> Complete game / Layer 3 of 4</p>
  <p className="project-summary">Turn the authoritative round model into the complete in-game HUD: phase, timer, score, collection progress, lifetime total, and short-lived pickup feedback.</p>
  <div className="lesson-progress" aria-label="Complete game progress: layer 3 of 4"><span className="lesson-progress__fill lesson-progress__fill--75"></span></div>
</div>

<div className="project-outcome">
  <strong>What you will finish</strong>
  <ul>
    <li>A responsive HUD mounted and released by one controller.</li>
    <li>Computed labels, colors, and progress from replicated state.</li>
    <li>An Echo-driven pickup banner with stale-timer protection.</li>
    <li>A dependency and repaint checklist for profiling the real graph.</li>
  </ul>
</div>

## The complete project route

The HUD consumes two inputs: Weave-compatible state from the Flite service
proxy and confirmed local events from the Echo bridge. It never polls and it
never writes authoritative game state.

<div className="project-map">
  <a href="https://royhanantariksaaa.github.io/flite-rbx/docs/project-crystal-run/"><span>01 / Flite</span><strong>Authoritative loop</strong><small>Rounds, networking, state, persistence.</small></a>
  <a href="https://royhanantariksaaa.github.io/echo-rbx/docs/project-crystal-run/"><span>02 / Echo</span><strong>Local event bridge</strong><small>Typed fan-out and teardown.</small></a>
  <div className="project-map__current"><span>03 / Weave</span><strong>Reactive HUD</strong><small>Live timer, score, and feedback.</small></div>
  <a href="https://royhanantariksaaa.github.io/weavekit-rbx/docs/project-crystal-run/"><span>04 / WeaveKit</span><strong>Game surfaces</strong><small>Lobby, settings, and results.</small></a>
</div>

<div className="project-contract">
  <div><span>Reactive inputs</span><strong>phase, timer, scores</strong></div>
  <div><span>Derived UI</span><strong>labels, color, progress</strong></div>
  <div><span>Transient input</span><strong>confirmed pickup event</strong></div>
</div>

## 1. Add the HUD files

Continue from the first two layers and add one component module and one
controller:

```text
StarterPlayer
`- StarterPlayerScripts
   |- Components
   |  `- CrystalHud.luau
   |- Controllers
   |  |- RoundController.luau
   |  |- EventBridgeController.luau
   |  `- HudController.luau
   `- ClientBootstrap.client.luau
```

The component receives model and event dependencies as arguments. That keeps
it reusable in a preview place and straightforward to test with local values.

## 2. Build the complete HUD component

The root uses scale width with a maximum constraint, so the same hierarchy
works on phone and desktop viewports. Every dynamic property receives a Weave
state object; no callback mutates an Instance directly.

<p className="project-file">StarterPlayerScripts/Components/CrystalHud.luau</p>

```lua title="StarterPlayerScripts/Components/CrystalHud.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weave = require(ReplicatedStorage.Libraries.Weave)

local ROUND_TARGET = 12

local COLORS = {
    Lobby = Color3.fromRGB(247, 185, 72),
    Playing = Color3.fromRGB(76, 220, 175),
    Results = Color3.fromRGB(116, 169, 255),
    Surface = Color3.fromRGB(20, 29, 34),
    SurfaceRaised = Color3.fromRGB(29, 41, 47),
    Text = Color3.fromRGB(242, 248, 246),
    Muted = Color3.fromRGB(167, 184, 177),
}

return function(scope, model, events)
    local pickupText = scope:Value("")
    local pickupVisible = scope:Value(false)
    local pickupVersion = 0
    local alive = true

    local phaseLabel = scope:Computed(function()
        local phase = model.phase:Get()
        if phase == "Lobby" then
            return "GET READY"
        elseif phase == "Playing" then
            return "CRYSTAL RUN"
        end
        return "ROUND COMPLETE"
    end)

    local timerLabel = scope:Computed(function()
        local total = math.max(0, model.timeRemaining:Get())
        return string.format("%02d:%02d", math.floor(total / 60), total % 60)
    end)

    local scoreLabel = scope:Computed(function()
        return `{model.roundScore:Get()} / {ROUND_TARGET}`
    end)

    local lifetimeLabel = scope:Computed(function()
        return `Lifetime {model.lifetimeCrystals:Get()}`
    end)

    local progress = scope:Computed(function()
        return math.clamp(model.roundScore:Get() / ROUND_TARGET, 0, 1)
    end)

    local phaseColor = scope:Computed(function()
        return COLORS[model.phase:Get()] or COLORS.Playing
    end)

    local pickupConnection = events.crystalCollected:connect(
        function(score, crystalId)
            pickupVersion += 1
            local version = pickupVersion

            pickupText:Set(`Crystal {crystalId} secured  +1  Score {score}`)
            pickupVisible:Set(true)

            task.delay(1.4, function()
                if alive and pickupVersion == version then
                    pickupVisible:Set(false)
                end
            end)
        end
    )

    scope:OnDestroy(function()
        alive = false
        pickupConnection:disconnect()
    end)

    return scope:Frame {
        Name = "CrystalHudRoot",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        [Weave.Children] = {
            scope:Frame {
                Name = "StatusBar",
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 18),
                Size = UDim2.new(1, -28, 0, 112),
                BackgroundColor3 = COLORS.Surface,
                [Weave.Children] = {
                    scope:UISizeConstraint {
                        MaxSize = Vector2.new(680, 112),
                        MinSize = Vector2.new(300, 112),
                    },
                    scope:UICorner {
                        CornerRadius = UDim.new(0, 6),
                    },
                    scope:UIStroke {
                        Color = phaseColor,
                        Thickness = 1,
                        Transparency = 0.25,
                    },
                    scope:UIPadding {
                        PaddingTop = UDim.new(0, 14),
                        PaddingBottom = UDim.new(0, 14),
                        PaddingLeft = UDim.new(0, 16),
                        PaddingRight = UDim.new(0, 16),
                    },
                    scope:TextLabel {
                        Name = "Phase",
                        Size = UDim2.new(0.5, 0, 0, 28),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        Text = phaseLabel,
                        TextColor3 = phaseColor,
                        TextSize = 18,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    },
                    scope:TextLabel {
                        Name = "Timer",
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.new(0.5, 0, 0, 28),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.RobotoMono,
                        Text = timerLabel,
                        TextColor3 = COLORS.Text,
                        TextSize = 20,
                        TextXAlignment = Enum.TextXAlignment.Right,
                    },
                    scope:Frame {
                        Name = "ProgressTrack",
                        Position = UDim2.new(0, 0, 0, 43),
                        Size = UDim2.new(1, 0, 0, 12),
                        BackgroundColor3 = COLORS.SurfaceRaised,
                        ClipsDescendants = true,
                        [Weave.Children] = {
                            scope:UICorner {
                                CornerRadius = UDim.new(1, 0),
                            },
                            scope:Frame {
                                Name = "ProgressFill",
                                Size = scope:Computed(function()
                                    return UDim2.fromScale(progress:Get(), 1)
                                end),
                                BackgroundColor3 = phaseColor,
                                [Weave.Children] = {
                                    scope:UICorner {
                                        CornerRadius = UDim.new(1, 0),
                                    },
                                },
                            },
                        },
                    },
                    scope:TextLabel {
                        Name = "RoundScore",
                        Position = UDim2.new(0, 0, 0, 65),
                        Size = UDim2.new(0.5, 0, 0, 22),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        Text = scoreLabel,
                        TextColor3 = COLORS.Text,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    },
                    scope:TextLabel {
                        Name = "LifetimeScore",
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, 65),
                        Size = UDim2.new(0.5, 0, 0, 22),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamMedium,
                        Text = lifetimeLabel,
                        TextColor3 = COLORS.Muted,
                        TextSize = 15,
                        TextXAlignment = Enum.TextXAlignment.Right,
                    },
                },
            },
            scope:TextLabel {
                Name = "PickupBanner",
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 144),
                Size = UDim2.new(1, -40, 0, 42),
                BackgroundColor3 = COLORS.SurfaceRaised,
                Visible = pickupVisible,
                Font = Enum.Font.GothamBold,
                Text = pickupText,
                TextColor3 = COLORS.Text,
                TextSize = 15,
                [Weave.Children] = {
                    scope:UISizeConstraint {
                        MaxSize = Vector2.new(520, 42),
                        MinSize = Vector2.new(280, 42),
                    },
                    scope:UICorner {
                        CornerRadius = UDim.new(0, 6),
                    },
                    scope:UIStroke {
                        Color = COLORS.Playing,
                        Thickness = 1,
                        Transparency = 0.35,
                    },
                },
            },
        },
    }
end
```

### Why the pickup timer has a version

If two pickups arrive less than 1.4 seconds apart, the first delayed callback
must not hide the newer message. Incrementing `pickupVersion` lets only the
latest scheduled callback change visibility. The `alive` flag prevents delayed
work from writing after scope teardown.

## 3. Mount the HUD from its owner

The controller declares both upstream dependencies. Its `onStart` hook mounts
one root, and `AddCleanup` guarantees the same root is unmounted when the
controller stops.

<p className="project-file">StarterPlayerScripts/Controllers/HudController.luau</p>

```lua title="StarterPlayerScripts/Controllers/HudController.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flite = require(ReplicatedStorage.Libraries.Flite)
local Weave = require(ReplicatedStorage.Libraries.Weave)
local CrystalHud = require(script.Parent.Parent.Components.CrystalHud)

return Flite.createController("HudController", function(self)
    local roundController = self:useController("RoundController")
    local eventBridge = self:useController("EventBridgeController")

    self:onStart(function()
        local playerGui = self:getPlayerGui(5)
        assert(playerGui, "Crystal Run requires PlayerGui")

        local cleanup = Weave.mount(playerGui, {
            Name = "CrystalRunHud",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 20,
        }, function(scope)
            return CrystalHud(
                scope,
                roundController.model,
                eventBridge.events
            )
        end)

        self:AddCleanup(cleanup)
    end)
end)
```

`Flite.loadModules` will discover this controller automatically. Its declared
controller dependencies place it after `RoundController` and
`EventBridgeController` in the startup graph.

## 4. Trace one update through the graph

When a player collects a crystal:

1. Flite updates the local client's `roundScore` state.
2. `scoreLabel` and `progress` become stale.
3. The score label repaints its `Text` property.
4. The progress fill repaints its `Size` property.
5. Echo delivers `crystalCollected` independently.
6. `pickupText` and `pickupVisible` update the banner.

The phase label, timer, and lifetime label do not repaint from a score-only
write. That is the practical value of a tracked dependency graph.

## 5. Preview without a server

Because the component accepts a model, you can mount it with local Weave
values in a UI preview place:

```lua title="CrystalHud.preview.client.luau"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weave = require(ReplicatedStorage.Libraries.Weave)
local CrystalHud = require(script.Parent.Components.CrystalHud)
local CrystalRunEvents = require(script.Parent.Features.CrystalRunEvents)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local cleanup = Weave.mount(playerGui, {
    Name = "CrystalHudPreview",
    ResetOnSpawn = false,
}, function(scope)
    local model = {
        phase = scope:Value("Playing"),
        timeRemaining = scope:Value(42),
        roundScore = scope:Value(5),
        lifetimeCrystals = scope:Value(137),
    }

    local events = CrystalRunEvents.new()
    scope:OnDestroy(function()
        events:destroy()
    end)

    task.delay(1, function()
        events.crystalCollected:fire(6, 11)
    end)

    return CrystalHud(scope, model, events)
end)

script.Destroying:Connect(cleanup)
```

The production and preview paths use the same component. Only the data source
changes.

## 6. Verify the HUD in the complete game

<ul className="project-checklist">
  <li>The top bar remains within the screen on phone and desktop emulation.</li>
  <li>The timer formats 60 as `01:00` and 9 as `00:09`.</li>
  <li>Only score text and progress repaint after a pickup state update.</li>
  <li>Rapid pickups keep the newest banner visible for its full duration.</li>
  <li>The results phase changes the label and accent without rebuilding the tree.</li>
  <li>Respawning does not duplicate the HUD because `ResetOnSpawn` is false.</li>
  <li>Stopping Flite removes the ScreenGui and disconnects the Echo listener.</li>
</ul>

## Failure paths you should test

| Failure | Expected behavior |
|---|---|
| `timeRemaining` becomes negative | Timer clamps visually to `00:00`. |
| Score exceeds twelve | Fill remains clamped while the score text stays truthful. |
| Two pickups arrive quickly | Older delayed work cannot hide the newer banner. |
| Event bridge stops | HUD retains replicated state but receives no new banners. |
| HUD controller stops | Scope destroys the tree, states, effects, and connection. |

<div className="quick-challenge">
  <span className="quick-challenge__label">Production extension</span>
  <p>Add a `scope:Spring` around the progress value, then compare direct score writes with the animated visual value. Keep the authoritative number immediate while only the bar eases.</p>
</div>

## API trail

- [Scopes and State](./scopes-and-state) for ownership and dependencies.
- [Rendering](./rendering) for properties, events, and children.
- [Animation and Async](./animation-and-async) for the progress extension.
- [Performance](./performance) for batching and repaint measurement.
- [Weave API map](./api-overview) for root, Scope, and State signatures.

<div className="chapter-next">
  <p><strong>Final layer:</strong> add a composed lobby, settings panel, ready control, and round-results surface around the in-game HUD.</p>
  <a href="https://royhanantariksaaa.github.io/weavekit-rbx/docs/project-crystal-run/">Continue in WeaveKit</a>
</div>
