---
title: API Map
description: Navigate every generated Weave API surface by task, ownership, and returned controller type.
---

# Weave API Map

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Reference / Start here</p>
  <p className="lesson-summary">Choose a surface by ownership first. Root constructors are useful for infrastructure; scope methods give UI work one automatic lifetime.</p>
</div>

## Choose a surface

<div className="reference-switchboard">
  <a href="/weave-rbx/api/Weave/"><span className="streamline-icon streamline-icon--identity" aria-hidden="true"></span><span><strong>Weave</strong><br/><small>Mount roots, create unscoped state, and access rendering symbols.</small></span><span>Root module</span></a>
  <a href="/weave-rbx/api/Scope/"><span className="streamline-icon streamline-icon--book" aria-hidden="true"></span><span><strong>Scope</strong><br/><small>Create owned state, Instances, effects, utilities, and cleanup.</small></span><span>Primary UI surface</span></a>
  <a href="/weave-rbx/api/State/"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span><span><strong>State</strong><br/><small>Read, peek, write, update, transform, and destroy state objects.</small></span><span>Shared contract</span></a>
</div>

## Generated reference by job

The generated reference is not limited to the three entry-point types. Use the
type returned by an operation when you need the exact fields and methods
available after construction.

| Job | Reference | What it answers |
|---|---|---|
| Enter the library | [`Weave`](/weave-rbx/api/Weave/) | Root constructors, symbols, helpers, components, mounting, and manual ownership. |
| Build an owned UI tree | [`Scope`](/weave-rbx/api/Scope/) | Every scoped state, rendering, interaction, async, composition, and lifecycle method. |
| Read or transform reactive data | [`State`](/weave-rbx/api/State/) | Tracking reads, untracked reads, writes, mapped views, rate limiting, and early destruction. |
| Control a spring or tween | [`AnimationState`](/weave-rbx/api/AnimationState/) | Animation reads, speed and damping changes, retargeting, and teardown. |
| Inspect an async computation | [`AsyncResult`](/weave-rbx/api/AsyncResult/) | The `Pending`, `Resolved`, and `Rejected` result record. |
| Share dependencies | [`Context`](/weave-rbx/api/Context/) | Context handles and default values. |
| Capture an Instance | [`Ref`](/weave-rbx/api/Ref/) | Reading and writing a reconciler ref. |
| Load a deferred module | [`LazyRef`](/weave-rbx/api/LazyRef/) | One-shot preload behavior. |
| Use bundled UI | [`Components`](/weave-rbx/api/Components/) | Button, Flex, TextInput, Tooltip, and VirtualList contracts. |

| Stateful utility | Reference | What it owns |
|---|---|---|
| Forms | [`Form`](/weave-rbx/api/Form/) | Values, validation errors, touched state, updates, and submit handling. |
| Action stores | [`Store`](/weave-rbx/api/Store/) | Store state, named dispatch, and selected views. |
| Remote or cached data | [`Resource`](/weave-rbx/api/Resource/) | Data, error, status, refetch, invalidation, retry, and shared cache behavior. |
| Undo and redo | [`History`](/weave-rbx/api/History/) | Present state, stacks, counts, and navigation. |
| FIFO work | [`Queue`](/weave-rbx/api/Queue/) | Reactive items and count plus queue commands. |
| Pointer movement | [`DragState`](/weave-rbx/api/DragState/) | Dragging, position, and delta state. |
| Touch and pointer intent | [`GestureState`](/weave-rbx/api/GestureState/) | Swipe, long press, phase, and tap count. |
| Anchored overlays | [`FloatState`](/weave-rbx/api/FloatState/) | Overlay position, visibility, and the ref assigned to floating content. |
| Sequenced animation | [`AnimationController`](/weave-rbx/api/AnimationController/) | Cancel a running `Scope:Animate` sequence. |
| Layout motion | [`LayoutController`](/weave-rbx/api/LayoutController/) | Re-measure a `Scope:AnimateLayout` container. |

## Root lifecycle and composition

| Primary | Alias | Purpose |
|---|---|---|
| `scope()` | `Scope()` | Create a root lifecycle scope manually. |
| `mount(parent, builder)` | `Mount(...)` | Build, parent, and own one UI root; returns cleanup. |
| `mount(parent, props, builder)` | `Mount(...)` | Wrap builder output in a configured `ScreenGui`. |
| `memo(component)` | `Memo(...)` | Shallow-prop memoize a component function. |
| `lazy(factory)` | none | Create a lazily preloaded module handle. |
| `createContext(default)` | `CreateContext(...)` | Create a typed context key. |
| `defineStyle(name, style)` | `DefineStyle(...)` | Register a named rendering style. |

## State constructors

The root module and every scope expose the same core state families, but they
do not return the same public shape. Root constructors preserve the low-level
getter/setter closure API. Scope constructors adapt those accessors into
callable state wrappers and register them for teardown automatically.

| Primary | Alias | Writable | Role |
|---|---|---:|---|
| `value(initial)` | `Value` | yes | Mutable source state. |
| `computed(callback)` | `Computed` | no | Cached dynamic dependency result. |
| `derived(callback)` | `Derived` | yes | Computed default with an override path. |
| `reducer(reducer, initial)` | `Reducer` | yes | Action-based state transitions. |
| `async(callback)` | `Async` | no | Pending, resolved, or rejected async state. |
| `spring(target, speed, damping)` | `Spring` | target-driven | Physics animation state. |
| `tween(target, info)` | `Tween` | target-driven | TweenService animation state. |
| `effect(callback)` | scope `Effect` | no | Run a tracked side effect. |

### Root accessors and scope wrappers

| Origin | Example return | Read and write style | Ownership |
|---|---|---|---|
| `Weave.value(0)` | `getter, setter` closures | `getter()` and `setter(nextValue)` | Manual; call `Weave.destroy(getter)`. |
| `Weave.computed(callback)` | getter closure | `getter()` | Manual; destroy the getter. |
| `scope:Value(0)` | writable wrapper, plus setter convenience | `state()`, `state:Get()`, `state:Set(value)` | Automatic with the scope. |
| `scope:Computed(callback)` | read-only wrapper | `state()` or `state:Get()` | Automatic with the scope. |
| root or scope Spring/Tween | animation object | callable plus documented methods | Manual at root; automatic in a scope. |

This distinction matters when copying examples. A `scope:Value` wrapper has
methods; a getter returned by `Weave.value` is called directly.

## Scoped state object contract

| Method | Available on | Behavior |
|---|---|---|
| `Get()` or `()` | every scoped wrapper | Read and track inside Computed or Effect. |
| `Peek()` | every scoped wrapper | Read without creating a dependency edge. |
| `Set(value)` | writable scoped wrapper | Replace the current value. |
| `Update(callback)` | writable scoped wrapper | Replace from the current value. |
| `Map(callback)` | every scoped wrapper | Create a scope-owned transformed Computed wrapper. |
| `Throttle(seconds)` | every scoped wrapper | Create a scope-owned rate-limited Computed view. |
| `Debounce(seconds)` | every scoped wrapper | Create a scope-owned settled Computed view. |
| `Destroy()` | every scoped wrapper | Release its graph node idempotently before scope teardown. |

## Rendering symbols

Use symbol keys inside the props table so they cannot collide with Roblox
property names.

| Primary | Alias | Use |
|---|---|---|
| `children` | `Children` | Supply owned child Instances. |
| `onEvent(name)` | `OnEvent(name)` | Connect an RBXScriptSignal event. |
| `onChange(property)` | `OnChange(property)` | Observe one property change. |
| `bind` | `Bind` | Run custom Instance binding work. |
| `ref` | `Ref` | Capture the constructed Instance. |

Every scope also exposes class factories such as `scope:Frame`,
`scope:TextLabel`, and `scope:UICorner`, plus registered custom components.

## Root utilities

| Primary | Alias | Purpose |
|---|---|---|
| `batch(callback)` | `Batch` | Settle related writes before one propagation flush. |
| `peek(state)` | `Peek` | Read a getter or state without tracking. |
| `destroy(state)` | `Destroy` | Release a root-created state. |
| `isState(value)` | `IsState` | Recognize Weave state wrappers and accessors. |
| `color3(r, g, b)` | none | Build a `Color3` from channels in the `0..1` range. |
| `numberSequence(keypoints)` | none | Build a `NumberSequence` from lowercase `time`, `value`, and `envelope` fields. |
| `colorSequence(keypoints)` | none | Build a `ColorSequence` from lowercase `time` and `color` fields. |

## Scope method map

All of these are scope-owned. Destroying the scope releases their graph nodes,
connections, tasks, Instances, or controllers.

| Area | Methods |
|---|---|
| Reactive state | `Value`, `Computed`, `Derived`, `Reducer`, `Async`, `Spring`, `Tween`, `Effect` |
| Conditional rendering | `Show`, `Switch`, `Transition`, `ErrorBoundary`, `Suspense` |
| Collection rendering | `ForValues`, `ForKeys`, `Stagger`, `AnimatePresence` |
| Tree placement | `Fragment`, `Portal`, `Provider`, `Hydrate`, `Lazy`, `Preload` |
| Derived utilities | `Selector`, `Combine`, `Previous`, `Timer`, `Gate`, `MediaQuery` |
| Observation | `Watch`, `Observe`, `FromEvent`, `ObserveNet`, `BindAction`, `Defer` |
| Application state | `Form`, `Store`, `Resource`, `History`, `Queue`, `Snapshot`, `Restore` |
| Interaction | `Drag`, `Gesture`, `Accessible`, `FocusGroup`, `Float`, `Parallax` |
| Motion | `Animate`, `AnimateLayout`, `Spring`, `Tween`, `Transition` |
| Composition | `RegisterComponent`, `Provide`, `Consume`, `UseContext`, `Ref` |
| Lifecycle | `OnMount`, `OnDestroy`, `onCleanup`, `Destroy` |
| Diagnostics | `Profiler` and the root `Weave.Debug` control |

The [`Scope` reference](/weave-rbx/api/Scope/) documents the exact arguments,
return type, and lifecycle caveat for each method. The concept chapters explain
when to choose one method over another.

## Built-in components

[`Weave.Components`](/weave-rbx/api/Components/) exports `VirtualList`,
`Button`, `Flex`, `TextInput`, and `Tooltip`. They use ordinary scopes and
Instances, so they compose with custom components and WeaveKit. `Tooltip`
expects a `PortalTarget`; the generated method entry calls this requirement out
at the signature rather than leaving it implicit in an example.

## Aliases and dynamic factories

Root PascalCase names are compatibility aliases for the camelCase root API.
Scoped state, rendering, and utility methods accept both forms as well, so
`scope:Value(0)` and `scope:value(0)` select the same implementation. This
handbook uses PascalCase on scopes because it separates constructors from local
variables clearly in larger components.

Instance factories are resolved dynamically. `scope:Frame`,
`scope:TextLabel`, and `scope:UICorner` all create Roblox classes, while the
documented `scope:Corner`, `scope:Padding`, and `scope:ListLayout` shorthands
resolve to their corresponding `UI*` classes. Registered component names share
the same call surface and are inherited by child scopes.

The generated page lists representative factories instead of repeating every
Roblox class. Property, event, child, ref, and binding behavior is common to all
of them and is documented in [Rendering](/weave-rbx/docs/rendering/).

## Ownership rule

```lua
local cleanup = Weave.mount(playerGui, function(scope)
    local count = scope:Value(0) -- owned automatically
    return scope:TextLabel { Text = count }
end)

cleanup() -- releases the Instance tree, state, effects, and connections
```

Prefer scope APIs for screen-owned work. When using root constructors, keep an
explicit destroy path for every long-lived state and animation resource.

## Learn the behavior behind the signatures

- [Scopes and State](/weave-rbx/docs/scopes-and-state/) for ownership and propagation.
- [Rendering](/weave-rbx/docs/rendering/) for factories, symbols, and collections.
- [Animation and Async](/weave-rbx/docs/animation-and-async/) for time-based state.
- [Context and Styling](/weave-rbx/docs/context-and-styling/) for composition boundaries.
- [Crystal Run](/weave-rbx/docs/project-crystal-run/) for the complete reactive HUD.
