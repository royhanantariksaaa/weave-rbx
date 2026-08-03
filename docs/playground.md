---
sidebar_position: 1.5
title: Interactive Playground
description: Edit Weave Value, Computed, Set, Update, and Batch programs and inspect their reactive propagation.
---

# Weave Playground

Use a compact subset of real Weave state syntax to see dependency tracking
rather than merely read about it. Every write, recomputation, and binding paint
is counted while the graph settles.

<div className="playground-actions">
  <a className="button button--primary" href="/weave-rbx/playground/" target="_blank" rel="noreferrer">Open full screen</a>
  <a className="button button--secondary" href="/weave-rbx/docs/tutorial-reactive-counter/">Build it in Studio</a>
</div>

<div className="playground-frame">
  <iframe src="/weave-rbx/playground/" title="Weave reactive dependency playground" loading="eager"></iframe>
</div>

## A useful five-minute path

1. Run **Reactive counter** and watch count invalidate doubled before the UI
   binding paints.
2. Compare the standalone Set with the two writes inside Batch. The batch
   performs two writes but only one propagation flush.
3. Move one Set outside the Batch block and compare recompute and paint counts.
4. Try **Cart total** to see one Computed depend on two writable Values.
5. After the run, use **Set +1** and **Batch +3** to keep the graph live.

## Supported experiment syntax

The editor recognizes numeric <code>scope:Value</code> declarations,
<code>scope:Computed</code> arithmetic over tracked <code>Get()</code> reads,
<code>Set</code>, <code>Update</code>, and <code>scope:Batch</code>. It rejects
unsupported statements with a line number instead of pretending to execute
arbitrary Luau.

:::note Browser model versus Roblox runtime
The playground models dependency invalidation and batch settlement. Instance
creation, event ownership, and real property bindings are demonstrated in the
recorded [Reactive Counter tutorial](./tutorial-reactive-counter).
:::

Continue with [Getting Started](./getting-started), then study
[Scopes and State](./scopes-and-state), [Rendering](./rendering), and the
[API overview](./api-overview).
