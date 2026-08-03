---
sidebar_position: 7
---

# API Overview

## Root module

| API | Purpose |
|---|---|
| `scope` / `Scope` | Creates a lifecycle scope. |
| `mount` / `Mount` | Builds and parents a scoped UI root. |
| `value` / `Value` | Creates mutable state. |
| `computed` / `Computed` | Creates read-only derived state. |
| `derived` / `Derived` | Creates overrideable derived state. |
| `spring` / `Spring` | Creates physics animation state. |
| `tween` / `Tween` | Creates TweenService animation state. |
| `async` / `Async` | Creates async status state. |
| `reducer` / `Reducer` | Creates reducer-backed state. |
| `effect` | Runs a tracked effect. |
| `batch` / `Batch` | Defers propagation until related writes settle. |
| `peek` / `Peek` | Reads without dependency tracking. |
| `destroy` / `Destroy` | Idempotently destroys a state. |
| `isState` / `IsState` | Recognizes state accessors and wrappers. |
| `defineStyle` / `DefineStyle` | Registers a named style. |
| `createContext` / `CreateContext` | Creates a context handle. |
| `memo` / `Memo` | Wraps a shallow-prop memoized component. |
| `lazy` | Creates a lazily preloaded module reference. |

The root also exports `Children`, `OnEvent`, `OnChange`, `Bind`, `Ref`, sequence
helpers, built-in components, and the debug overlay switch.

## Scope aliases

State and rendering methods support PascalCase and camelCase. Solid-style
aliases are available as `createSignal`, `createMemo`, and `createEffect`.

## Generated reference

Use the generated API section for signatures and searchable members:

- [`Weave`](../api/Weave)
- [`Scope`](../api/Scope)
- [`State`](../api/State)
