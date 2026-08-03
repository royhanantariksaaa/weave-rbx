---
sidebar_position: 1.5
title: Interactive Playground
description: Edit Weave Value, Computed, Set, Update, and Batch programs and inspect their reactive propagation.
hide_table_of_contents: true
---

# Weave Playground

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--play" aria-hidden="true"></span> Practice lab / Chapter 4</p>
  <p className="lesson-summary">Use a compact subset of Weave state syntax to inspect dependency tracking, recomputation, binding paints, and batch settlement.</p>
  <div className="lesson-progress" aria-label="Learn Weave progress: 80 percent"><span className="lesson-progress__fill lesson-progress__fill--80"></span></div>
</div>

<div className="playground-runbook" aria-label="Weave playground workflow">
  <div><span>01 / Baseline</span><strong>Run the graph</strong><p>Follow one Value through Computed state, invalidation, settlement, and a UI paint.</p></div>
  <div><span>02 / Change</span><strong>Move one write</strong><p>Compare immediate writes with Batch and inspect exactly which work is coalesced.</p></div>
  <div><span>03 / Transfer</span><strong>Mount it in Studio</strong><p>Replace the browser binding with a scope-owned Roblox Instance property.</p></div>
</div>

## Run the dependency baseline

Select **Reactive counter** and run it unchanged. The source graph and runtime
metrics should tell the same story from two angles.

<div className="playground-actions">
  <a className="button button--primary" href="/weave-rbx/playground/" target="_blank" rel="noreferrer">Open full screen</a>
  <a className="button button--secondary" href="/weave-rbx/docs/tutorial-reactive-counter/">Build it in Studio</a>
  <a className="button button--secondary" href="/weave-rbx/docs/project-crystal-run/">Continue to Crystal Run</a>
</div>

<div className="playground-frame">
  <iframe src="/weave-rbx/playground/" title="Weave reactive dependency playground" loading="eager"></iframe>
</div>

<div className="lesson-goals">
  <strong>Expected baseline</strong>
  <ul>
    <li>Count is the only writable source.</li>
    <li>Doubled records one tracked dependency on Count.</li>
    <li>Each settled source change invalidates the affected Computed value.</li>
    <li>The UI binding paints only after the graph has settled.</li>
  </ul>
</div>

## Read graph and runtime together

The left side is the editable state program. The right side separates source
writes, dependency edges, recomputations, propagation flushes, and binding
paints so that a convenient API does not hide its cost model.

| What changes | What to inspect | What it proves |
|---|---|---|
| `count:Set(...)` | Source value, invalidations, and paints | One write settles immediately outside a batch. |
| `count:Update(...)` | Previous and next source values | Update derives a write from the current value. |
| Tracked `Get()` | Graph arrows into Computed nodes | Dependencies come from reads during evaluation. |
| `scope:Batch(...)` | Writes versus propagation flushes | Several writes can settle through one outer flush. |

## Complete three controlled experiments

### 1. Break and restore a dependency

Run **Reactive counter**, then remove the `count:Get()` read from the
Computed declaration. The dependency edge disappears, so later Count writes no
longer invalidate Doubled. Restore the read and verify that the edge returns.

### 2. Measure the batch boundary

Keep two Set calls inside Batch and record the write, recompute, flush, and
paint counts. Move the second Set below the Batch block and run again. The
final value is the same, but the unbatched program performs another settlement
cycle.

### 3. Expand the graph

Select **Cart total**. Change quantity and unit price independently, then put
both writes in one Batch. The Total node depends on both Values but should
settle once for the combined update.

## Transfer the graph to Roblox Studio

The browser models the state scheduler. Studio adds a real Instance property
binding and one scope-owned cleanup boundary:

```lua title="StarterPlayerScripts/ReactiveCounter.client.luau"
local cleanup = Weave.mount(playerGui, function(scope)
    local count = scope:Value(0)
    local doubled = scope:Computed(function()
        return count:Get() * 2
    end)

    return scope:TextButton {
        Text = scope:Computed(function()
            return `Count {count:Get()} / Double {doubled:Get()}`
        end),
        [Weave.OnEvent("Activated")] = function()
            count:Update(function(value)
                return value + 1
            end)
        end,
    }
end)

script.Destroying:Connect(cleanup)
```

<figure className="tutorial-demo playground-proof">
  <img className="tutorial-demo__motion" src="/weave-rbx/tutorials/weave-reactive-counter.gif" alt="Weave state propagating into Roblox UI in Studio" />
  <img className="tutorial-demo__still" src="/weave-rbx/tutorials/weave-reactive-counter.png" alt="Completed Weave reactive counter in Studio" />
  <figcaption>The same dependency graph driving a real Roblox property binding.</figcaption>
</figure>

Use the [Reactive Counter tutorial](./tutorial-reactive-counter) for the full
Explorer tree, complete interface, event binding, progress bar, batch example,
cleanup behavior, and debugging checkpoints.

:::note Browser model versus Roblox runtime
The playground models dependency invalidation and batch settlement. Instance
creation, event ownership, and real property bindings are demonstrated in the
recorded [Reactive Counter tutorial](./tutorial-reactive-counter).
:::

## Continue into the complete game

Crystal Run hydrates one round model, then derives phase text, timer, score,
collection progress, lifetime total, and pickup feedback from it. The
[complete reactive HUD](./project-crystal-run) includes the full component,
mount owner, propagation trace, server-free preview, multiplayer acceptance
pass, and failure paths.

<div className="chapter-next">
  <p><strong>Ready for a full reactive screen?</strong><br />Turn Flite's round model and Echo's event stream into Crystal Run's complete HUD.</p>
  <a href="/weave-rbx/docs/project-crystal-run/">Build the round HUD</a>
</div>
