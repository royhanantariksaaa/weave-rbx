---
sidebar_position: 1
slug: /intro
---

# Weave

Weave is a scoped reactive UI runtime for Roblox. State, Instances,
connections, effects, and animation resources are created inside explicit
lifecycle scopes, making cleanup part of the programming model rather than an
afterthought.

<figure className="tutorial-demo intro-demo">
  <img className="tutorial-demo__motion" src="/weave-rbx/tutorials/weave-reactive-counter.gif" alt="A Weave Value propagating through Computed state and Roblox UI bindings" />
  <img className="tutorial-demo__still" src="/weave-rbx/tutorials/weave-reactive-counter.png" alt="Completed Weave reactive counter" />
  <figcaption>One source write updates derived state and only the affected UI bindings.</figcaption>
</figure>

## Choose your path

<div className="learning-path">
  <a className="learning-path__item" href="/weave-rbx/docs/playground/"><span>01 / Experiment</span><strong>Inspect the graph</strong><small>Edit Values, Computed state, and batches with live propagation metrics.</small></a>
  <a className="learning-path__item" href="/weave-rbx/docs/tutorial-reactive-counter/"><span>02 / Build</span><strong>Mount a counter</strong><small>Follow a recorded Studio build with state, bindings, events, and cleanup.</small></a>
  <a className="learning-path__item" href="/weave-rbx/docs/api-overview/"><span>03 / Ship</span><strong>Explore the runtime</strong><small>Find state types, rendering primitives, animation, context, and signatures.</small></a>
</div>

## What Weave provides

- Mutable, computed, derived, reducer, async, spring, and tween state.
- Declarative Instance construction with reactive property bindings.
- Conditional, collection, portal, suspense, and transition primitives.
- Context, styles, forms, gestures, accessibility, and utility hooks.
- Batched propagation over a reverse dependency graph.

Start in the [interactive playground](playground), continue with
[Getting Started](getting-started), then learn how
[Scopes and State](scopes-and-state) establish ownership.

:::info Companion library
WeaveKit provides composed UI builders and production-ready components on top
of Weave. Weave itself remains the lower-level runtime.
:::
