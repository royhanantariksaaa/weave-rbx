---
title: API Map
description: Navigate Weave's root, Scope, and State APIs by task and understand the ownership contract behind each surface.
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

The root module and every scope expose the same core state families. Scope
methods register their result for teardown automatically.

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

## State object contract

| Method | Available on | Behavior |
|---|---|---|
| `Get()` | every state | Read and track inside Computed or Effect. |
| `Peek()` | every state | Read without creating a dependency edge. |
| `Set(value)` | writable state | Replace the current value. |
| `Update(callback)` | writable state | Replace from the current value. |
| `Map(callback)` | every state | Create a transformed computed state. |
| `Throttle(seconds)` | every state | Create a rate-limited computed view. |
| `Debounce(seconds)` | every state | Create a settled computed view. |
| `Destroy()` | every state | Release its graph node idempotently. |

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
| `color3(data)` | none | Build reactive Color3 data. |
| `numberSequence(data)` | none | Build reactive NumberSequence data. |
| `colorSequence(data)` | none | Build reactive ColorSequence data. |

Scope-only utilities include `Observe`, `Watch`, `Timer`, `Batch`, `Selector`,
`Combine`, `Gate`, `Form`, `Resource`, `Queue`, `MediaQuery`, `Gesture`,
`Accessible`, and the remaining hooks documented on the generated Scope page.

## Built-in components

`Weave.Components` exports `VirtualList`, `Button`, `Flex`, `TextInput`, and
`Tooltip`. They use ordinary scopes and Instances, so they compose with custom
components and WeaveKit.

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

- [Scopes and State](./scopes-and-state) for ownership and propagation.
- [Rendering](./rendering) for factories, symbols, and collections.
- [Animation and Async](./animation-and-async) for time-based state.
- [Context and Styling](./context-and-styling) for composition boundaries.
- [Crystal Run](./project-crystal-run) for the complete reactive HUD.
