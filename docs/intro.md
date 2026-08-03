---
sidebar_position: 1
slug: /intro
---

# Weave

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--identity" aria-hidden="true"></span> Introduction / Chapter 1</p>
  <p className="lesson-summary">Weave is a scoped reactive UI runtime for Roblox. State, Instances, connections, effects, and animation resources are created inside explicit lifecycle scopes, making cleanup part of the programming model.</p>
  <div className="lesson-progress" aria-label="Learn Weave progress: 20 percent"><span className="lesson-progress__fill lesson-progress__fill--20"></span></div>
</div>

<div className="lesson-goals">
  <strong>By the end of this chapter</strong>
  <ul>
    <li>Recognize Weave's state, dependency, rendering, and ownership model.</li>
    <li>Choose a focused lesson, practice lab, or the complete game track.</li>
    <li>Know when to use Weave directly and when to reach for WeaveKit.</li>
  </ul>
</div>

<figure className="tutorial-demo intro-demo">
  <img className="tutorial-demo__motion" src="/weave-rbx/tutorials/weave-reactive-counter.gif" alt="A Weave Value propagating through Computed state and Roblox UI bindings" />
  <img className="tutorial-demo__still" src="/weave-rbx/tutorials/weave-reactive-counter.png" alt="Completed Weave reactive counter" />
  <figcaption>One source write updates derived state and only the affected UI bindings.</figcaption>
</figure>

## Choose your path

<div className="learning-path learning-path--four">
  <a className="learning-path__item" href="/weave-rbx/docs/playground/"><span>01 / Experiment</span><strong>Inspect the graph</strong><small>Edit Values, Computed state, and batches with live propagation metrics.</small></a>
  <a className="learning-path__item" href="/weave-rbx/docs/tutorial-reactive-counter/"><span>02 / Focus</span><strong>Mount a counter</strong><small>Learn state, bindings, events, and cleanup in one contained Studio feature.</small></a>
  <a className="learning-path__item" href="/weave-rbx/docs/project-crystal-run/"><span>03 / Complete game</span><strong>Build the Crystal HUD</strong><small>Render the round model, score progress, timer, and pickup feedback.</small></a>
  <a className="learning-path__item" href="/weave-rbx/docs/api-overview/"><span>04 / Reference</span><strong>Explore the runtime</strong><small>Find state types, rendering primitives, animation, context, and signatures.</small></a>
</div>

## What Weave provides

- Mutable, computed, derived, reducer, async, spring, and tween state.
- Declarative Instance construction with reactive property bindings.
- Conditional, collection, portal, suspense, and transition primitives.
- Context, styles, forms, gestures, accessibility, and utility hooks.
- Batched propagation over a reverse dependency graph.

Continue with [Getting Started](getting-started), use the
[interactive playground](playground) to inspect propagation, then build
Crystal Run's [complete reactive HUD](project-crystal-run).

:::info Companion library
WeaveKit provides composed UI builders and production-ready components on top
of Weave. Weave itself remains the lower-level runtime.
:::
