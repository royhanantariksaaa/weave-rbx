---
sidebar_position: 8
title: Testing and Debugging
description: Verify Weave graph semantics, mounted bindings, cleanup, animations, and production UI behavior with repeatable Studio tests.
---

# Testing and Debugging

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--check" aria-hidden="true"></span> Production / Verification</p>
  <p className="lesson-summary">Test Weave as a reactive graph and as a UI runtime: prove dependency edges, observe the smallest expected repaint, unmount every owner, and use the client profiler only after correctness is known.</p>
</div>

<div className="lesson-goals">
  <strong>You will verify</strong>
  <ul>
    <li>State, computed dependencies, batching, dynamic branches, and stale-state protection.</li>
    <li>Instance bindings while mounted and complete binding removal after cleanup.</li>
    <li>Which source write caused unexpected computation, animation, or UI work.</li>
  </ul>
</div>

## Use a verification ladder

Reactive failures are easier to isolate when each test owns one layer:

| Layer | Repository evidence | Add in your game |
|---|---|---|
| State semantics | `tests/Value.spec.luau` and `tests/Computed.spec.luau` | Domain-specific computed rules. |
| Reconciliation | `tests/Reconciler.spec.luau` | One mounted feature regression. |
| Runtime integration | `tests/RuntimeSmoke.luau` | Your exact package tree in Studio. |
| Lifecycle | Smoke unmount checks | Reopen and teardown loops for every screen. |
| Frame behavior | Client profiler and Studio profiling | A realistic device and content matrix. |

The TestEZ specs are useful when your repository already has a TestEZ runner.
The standalone smoke file needs no test framework and is the fastest way to
check the complete package in Studio.

## Run the Studio smoke suite

Sync Weave and its Echo, Symbol, Trove, and Tween dependencies beneath
`ReplicatedStorage.Libraries`. Run `tests/RuntimeSmoke.luau` through Studio's
RunScript facility, or use its contents as a temporary server Script:

```text
ReplicatedStorage
`- Libraries
   |- Echo
   |- Symbol
   |- Trove
   |- Tween
   `- Weave
ServerScriptService
`- RuntimeSmoke         Script using tests/RuntimeSmoke.luau
```

The file is executable Script source and intentionally does not return a
ModuleScript value. Do not `require` it. Start a fresh Studio test and expect:

```text
[Weave RuntimeSmoke] PASS (51 checks)
```

The suite deliberately creates and destroys root state IDs, mounts Instances,
and exercises framework internals. Run it in a disposable test place or clean
test session, not beside the bootstrap for a live game feature.

### What the suite proves

| Area | Contracts exercised |
|---|---|
| Scope factories | Colon and dot construction, state writes, computed reads, and spring targets. |
| Batch settlement | Deferred reads, write coalescing, callback return values, and error unwind. |
| Dynamic dependencies | Old branch edges are removed and the active branch invalidates. |
| State generations | Destroyed closures cannot read, write, or corrupt a recycled state ID. |
| Reconciliation | A TextLabel binds, updates, unmounts, and releases its binding record. |
| Animation graph | Animation state is callable, propagates, and rejects reads after destruction. |

This proves engine contracts. It does not prove that your feature chose a
minimal dependency graph, that every mount has an owner, or that Roblox layout
work fits a frame. Test those in the feature.

## Write a public mount regression

Keep game tests on public APIs. Mount into an unparented Folder, expose the
test setter, and assert both propagation and teardown:

```lua title="ServerScriptService/CounterMount.spec.server.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)

local host = Instance.new("Folder")
host.Name = "CounterMountSpec"

local setCount: (number) -> ()
local cleanup = Weave.mount(host, function(scope)
    local count
    count, setCount = scope:Value(0)

    local text = scope:Computed(function(use)
        return `Count {use(count)}`
    end)

    return scope:TextLabel {
        Name = "CounterLabel",
        Text = text,
    }
end)

local label = host:FindFirstChild("CounterLabel", true)
assert(label and label:IsA("TextLabel"), "mount did not create CounterLabel")
assert(label.Text == "Count 0", "initial binding is wrong")

setCount(3)
assert(label.Text == "Count 3", "state write did not reach the binding")

cleanup()
assert(host:FindFirstChild("CounterLabel", true) == nil, "unmount left the UI alive")

host:Destroy()
print("[CounterMount spec] PASS")
```

This harness is intentionally small. If it fails, the package, state graph,
binding, or mount lifetime is broken. If it passes while the real HUD fails,
the fault is in the HUD's dependency or ownership choices.

## Assert the dependency graph you intended

For each feature, write a source-to-output table before profiling:

| Source changes | May update | Must not update |
|---|---|---|
| Score | Score text, progress fill | Phase label, timer format, settings panel. |
| Phase | Phase label, visible panel | Static title, unrelated inventory rows. |
| Settings toggle | Toggle visual, dependent behavior | Server-owned score or timer state. |
| Item collection | The changed row or virtualized range | Every unrelated row. |

Then instrument suspicious computed callbacks with temporary counters:

```lua
local evaluations = 0
local scoreText = scope:Computed(function(use)
    evaluations += 1
    return `Score {use(score)}`
end)
```

Perform one source write and assert the expected delta. A counter that moves
for an unrelated write usually means the computation read too broad a state
object or retained an obsolete branch dependency.

## Use the client profiler overlay

Enable the public overlay only from a client development path:

```lua title="StarterPlayerScripts/WeaveDebug.client.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)

if game:GetService("RunService"):IsStudio() then
    Weave.Debug = "overlay"
end

script.Destroying:Connect(function()
    Weave.Debug = nil
end)
```

The overlay mounts in `PlayerGui` and reports counters instrumented by the
installed Weave runtime. Compare changes while performing one controlled
interaction. Do not interpret an unchanged or zero counter as proof that
Roblox performed no Instance, layout, text, or rendering work.

For a narrow diagnostic, `Weave.Debug = true` enables counters without
mounting the overlay. The report module lives at `Weave.Core.Debug`, which is
a package diagnostic surface rather than the stable root API. If a development
tool requires it, pin your Weave version and remove the dependency from game
runtime code.

## Diagnose by symptom

| Symptom | Inspect first | Likely correction |
|---|---|---|
| Text never updates | Whether the property received state or a one-time plain value. | Pass the state/computed object to the property. |
| Computed runs for unrelated writes | Values read during its last evaluation. | Split broad state or move conditional reads inside the active branch. |
| UI appears twice | Mount call count and retained cleanup function. | Keep one mount owner and call cleanup before remounting. |
| UI disappears but work continues | Scope ownership of timers, events, and root state. | Register work with the scope or manually destroy root state. |
| A batched feature shows an intermediate value | A read or side effect inside the batch. | Treat the batch as a write transaction and observe after settlement. |
| Animation never settles | Target writes, spring parameters, and per-frame source churn. | Stop rewriting an unchanged target and profile the animation channel. |
| Destroyed getter throws | Code retained state beyond its owner. | Move the consumer into the scope or promote state to a deliberate longer-lived owner. |

## Run lifecycle and viewport matrices

Before release, verify:

| Scenario | Required evidence |
|---|---|
| Open, close, reopen 20 times | One UI tree, one event response, and no stale callback warnings. |
| Character respawn | The chosen `ResetOnSpawn` behavior and one active mount. |
| Dynamic branch switch | Old source writes no longer evaluate the selected computation. |
| Batch several writes | Dependent output settles once at the final value. |
| Animation interrupted | The new target wins and cleanup removes frame work. |
| Narrow and wide viewport | No clipped controls or text overlap. |
| Low-end device profile | Instance, layout, and callback work stay within the feature budget. |

Use the [performance chapter](/weave-rbx/docs/performance/) after correctness is established.
For the complete composition, the [Crystal Run HUD](/weave-rbx/docs/project-crystal-run/)
defines exact source-to-output expectations, teardown behavior, and a visual
acceptance pass.

<div className="chapter-next">
  <p><strong>Verify a production-shaped graph.</strong><br />Exercise Crystal Run score, phase, timer, and lifetime state, then prove that unmount removes every binding and event.</p>
  <a href="/weave-rbx/docs/project-crystal-run/">Verify the Crystal Run HUD</a>
</div>
