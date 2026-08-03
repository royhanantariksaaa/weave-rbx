---
sidebar_position: 8
---

# Performance

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Production / Profiling</p>
  <p className="lesson-summary">Measure graph fan-out, binding paints, Instance work, and animation channels before optimizing lower-level table operations.</p>
</div>

Weave organizes hot reactive paths around dense data and batched work:

- State IDs index dense value, type, generation, signal, and dependency data.
- A reverse dependency graph lets source writes visit affected nodes without
  scanning every computation.
- Dynamic edges are removed when computations stop reading a source.
- Bindings and animation pools use swap removal instead of leaving holes.
- Reconciliation processes children in linear passes.
- Springs share one frame connection and batch channel writes.
- `VirtualList` retains sparse absolute indexes without copying source slices.

## Native execution boundary

Hot numeric modules request `--!native` and `--!optimize 2`. Roblox Luau does
not expose portable explicit SIMD instructions or cache-level placement. Dense
arrays, packed animation channels, linear iteration, fewer closures, and lower
allocation pressure are the concrete locality tools available to Weave.

## Profile the right layer

For a UI workload, measure dependency fan-out, binding count, Instance count,
layout invalidation, and callback work. A table microbenchmark cannot predict a
frame dominated by Roblox layout or text measurement.

## Profile Crystal Run

The [HUD verification pass](./project-crystal-run) gives a concrete graph:
score updates should repaint score and progress, not phase, timer, or lifetime.
Use that dependency expectation as a profiling assertion.
