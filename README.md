# Weave

[![Documentation](https://github.com/royhanantariksaaa/weave-rbx/actions/workflows/docs.yml/badge.svg)](https://royhanantariksaaa.github.io/weave-rbx/)

**Documentation:** [royhanantariksaaa.github.io/weave-rbx](https://royhanantariksaaa.github.io/weave-rbx/)

A reactive UI framework for Roblox, inspired by SolidJS and Flutter.

Weave provides fine-grained reactivity, a declarative element tree, animation
primitives, and a rich set of rendering utilities - all built on top of
[Echo](https://github.com/royhanantariksaaa/echo-rbx) signals.

This is the core reactive/UI framework. [WeaveKit](https://github.com/royhanantariksaaa/weavekit-rbx)
(the component library) and [Flite](https://github.com/royhanantariksaaa/flite-rbx)
(the game framework) both consume it.

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Public API Reference](#public-api-reference)
- [Core Concepts](#core-concepts)
  - [Scopes](#scopes)
  - [States](#states)
  - [Elements & Props](#elements--props)
- [State Types](#state-types)
  - [Value](#value)
  - [Computed](#computed)
  - [Derived](#derived)
  - [Spring & Tween](#spring--tween)
  - [Async & Suspense](#async--suspense)
  - [Reducer](#reducer)
- [Rendering Primitives](#rendering-primitives)
- [Built-in Components](#built-in-components)
- [Utility Hooks](#utility-hooks)
- [Context & Dependency Injection](#context--dependency-injection)
- [Styling](#styling)
- [Debugging](#debugging)
- [Integration with Echo & Flite](#integration-with-echo--flite)
- [Performance Notes](#performance-notes)
- [Tests](#tests)

---

## Installation

### Runtime dependencies

Weave uses **absolute requires** to modules in `ReplicatedStorage.Libraries`.
At runtime, the following must be present:

| Dependency | Path | Purpose |
|------------|------|---------|
| [Echo](https://github.com/royhanantariksaaa/echo-rbx) | `ReplicatedStorage.Libraries.Echo` | Fast pure-Luau signal engine |
| `Symbol` | `ReplicatedStorage.Libraries.Symbol` | Unique keys for internal sentinels |
| `Trove` | `ReplicatedStorage.Libraries.Trove` | Scope-owned resource cleanup |
| `Tween` | `ReplicatedStorage.Libraries.Tween` | SoA tween scheduler |

`Echo` is its own repo. `Symbol`, `Trove`, and `Tween` are leaf utilities.

### As a git submodule

From your game repo root (assuming `src/Shared` maps to `ReplicatedStorage`):

```sh
git submodule add https://github.com/royhanantariksaaa/echo-rbx.git src/Shared/Libraries/Echo
git submodule add https://github.com/royhanantariksaaa/weave-rbx.git src/Shared/Libraries/Weave
```

Then provide `Symbol`, `Trove`, and `Tween` at
`ReplicatedStorage.Libraries/<Name>`.

### Standalone dev

```sh
rojo serve default.project.json
```

Serves Weave at `ReplicatedStorage.Libraries.Weave`.

---

## Quick Start

A reactive counter button:

```lua
local Weave = require(ReplicatedStorage.Libraries.Weave)

local cleanup = Weave.mount(PlayerGui, "CounterGui", function(scope)
    local count, setCount = scope:Value(0)

    return scope:Frame {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),

        scope:TextButton {
            Size = UDim2.fromOffset(200, 50),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = count:Map(function(n) return "Clicks: " .. n end),
            [Weave.OnEvent "Activated"] = function()
                setCount(count() + 1)
            end,
        },
    }
end)

-- Later: cleanup() to unmount and destroy all states
```

### Two-way binding

```lua
local text, setText = scope:Value("")

scope:TextBox {
    PlaceholderText = "Type something...",
    [Weave.Bind "Text"] = text,
    [Weave.OnEvent "FocusLost"] = function()
        print("Final value:", text:Peek())
    end,
}
```

### Conditional & list rendering

```lua
local isVisible = scope:Value(true)
local items = scope:Value({ "Apple", "Banana", "Cherry" })

scope:Show(isVisible, function(s)
    return s:ForValues(items, function(s, fruit, index)
        return s:TextLabel { Text = fruit .. " (#" .. index .. ")" }
    end)
end)
```

---

## Public API Reference

### Root module

| API | Signature | Description |
|---|---|---|
| `scope` / `Scope` | `(parentScope?) -> Scope` | Create a lifecycle scope, optionally inheriting context. |
| `mount` / `Mount` | `(parent, builder)` or `(parent, props, builder) -> cleanup` | Build and parent a scoped UI tree. A string `props` value becomes the wrapping `ScreenGui.Name`. |
| `value` / `Value` | `(initial, options?) -> getter, setter` | Mutable state closure pair. `options.validate` can normalize writes. |
| `computed` / `Computed` | `(callback, options?) -> getter` | Read-only derived state. `options.equals` can suppress equivalent updates. |
| `derived` / `Derived` | `(callback, options?) -> getter, setter` | Computed state with a temporary explicit override. |
| `spring` / `Spring` | `(target, speed?, damping?) -> Spring` | Physics-driven animation state. |
| `tween` / `Tween` | `(target, TweenInfo?) -> Tween` | Tween-driven animation state. |
| `async` / `Async` | `(producer) -> getter` | Async status state with `Status`, `Value`, and `Error`. |
| `reducer` / `Reducer` | `(reducer, initial) -> getter, dispatch` | Reducer-backed state. |
| `effect` | `(callback) -> getter` | Re-run a side effect when its tracked reads change. |
| `batch` / `Batch` | `(callback) -> ...results` | Defer propagation and bindings until the outer batch closes. Nested batches are supported. |
| `peek` / `Peek` | `(state) -> any` | Read without dependency tracking. |
| `destroy` / `Destroy` | `(state) -> ()` | Idempotently release a state. Stale accessors reject later use. |
| `isState` / `IsState` | `(value) -> boolean` | Check a state accessor or wrapper. Ordinary numbers are never treated as internal IDs. |
| `children` / `Children` | symbol | Explicit children prop key. |
| `onEvent` / `OnEvent` | `(eventName) -> symbol` | Explicit Roblox event prop key. |
| `onChange` / `OnChange` | `(propertyName) -> symbol` | Explicit property-change prop key. |
| `bind` / `Bind` | `(propertyName) -> symbol` | Two-way property binding key. |
| `ref` / `Ref` | symbol | Instance capture prop key. |
| `defineStyle` / `DefineStyle` | `(name, props) -> ()` | Register a named style. |
| `createContext` / `CreateContext` | `(defaultValue) -> Context` | Create a context handle. |
| `memo` / `Memo` | `(component) -> component` | Shallow-prop memoization wrapper. |
| `lazy` | `(factory) -> LazyRef` | Resolve a module once on `:Preload()`. |
| `color3` | `(r, g, b) -> Color3` | Build a Color3 from normalized data. |
| `numberSequence` | `(keypoints) -> NumberSequence` | Build a NumberSequence from plain keypoint data. |
| `colorSequence` | `(keypoints) -> ColorSequence` | Build a ColorSequence from plain keypoint data. |
| `Components` | table | Built-in `Button`, `Flex`, `TextInput`, `Tooltip`, and `VirtualList`. |
| `Debug` | boolean, `"overlay"`, or `nil` | Collect counters, mount the client profiler overlay, or disable diagnostics. |

PascalCase aliases are retained for compatibility where listed. `effect`,
`lazy`, and the sequence helpers are camelCase-only.

### Scope lifecycle and composition

| Method | Description |
|---|---|
| `scope:Ref()` | Create a `{ Get, Set }` reference holder. |
| `scope:Hydrate(instance, props)` | Reconcile props and children onto an existing Instance. |
| `scope:RegisterComponent(name, component)` | Add a component constructor to that scope. |
| `scope:Provide(key, value)` | Store one or more context values on the scope. |
| `scope:Consume(key)` | Read a raw scoped context value. |
| `scope:UseContext(context)` | Read a context value or its default. |
| `scope:OnMount(callback)` | Run after the current render turn unless the scope was destroyed. |
| `scope:OnDestroy(callback)` / `scope:onCleanup(callback)` | Register cleanup. |
| `scope:Destroy()` | Destroy all owned states, Instances, tasks, and connections. |
| `scope:Fragment(children)` | Return children without an extra Instance. |
| `scope:createSignal`, `scope:createMemo`, `scope:createEffect` | Solid-style aliases for `value`, `computed`, and `effect`. |

Rendering and utility methods are available in both PascalCase and camelCase.
Roblox element constructors are resolved lazily by name, so `scope:Frame`,
`scope:TextLabel`, and other Instance classes do not require registration.

---

## Core Concepts

### Scopes

A **scope** is the lifecycle container for a subtree of your UI. Every state,
element, event connection, and cleanup callback created within a scope is
automatically tracked and destroyed when the scope is destroyed.

```lua
local scope = Weave.scope()

-- States created on the scope
local count = scope:Value(0)

-- Elements created on the scope
local frame = scope:Frame { ... }

-- Cleanup callbacks
scope:onCleanup(function()
    print("scope destroyed")
end)

-- Destroy everything at once
scope:Destroy()
```

In practice, `Weave.mount` creates a root scope for you and passes it to your
builder function. Child scopes are created automatically by rendering
primitives (`Show`, `ForValues`, etc.).

### States

States are the reactive core. Reading a state inside a `Computed` or `Effect`
automatically tracks it as a dependency — when it changes, the dependent
re-computes.

States created by a scope are **callable**: calling `state()` or `state:Get()`
reads with dependency tracking, while `state:Peek()` reads without tracking.
Root constructors such as `Weave.value` return bare getter closures instead;
use the returned getter plus `Weave.peek` and `Weave.destroy` at that level.

```lua
local a = scope:Value(1)
local b = scope:Value(2)

-- Computed auto-tracks a and b
local sum = scope:Computed(function(use)
    return use(a) + use(b)  -- `use` unwraps states
end)

print(sum())  -- 3
a:Set(10)
print(sum())  -- 12
```

All wrapped states support these read and lifecycle methods:

| Method | Description |
|--------|-------------|
| `:Get()` / `()` | Read with dependency tracking. |
| `:Peek()` | Read without tracking. |
| `:Map(fn)` | Returns a new Computed that transforms the value. |
| `:Throttle(seconds)` | Returns a throttled derivative. |
| `:Debounce(seconds)` | Returns a debounced derivative. |
| `:Destroy()` | Destroys the state and releases resources. |

Writable `Value` and `Derived` wrappers also expose `:Set(value)` and
`:Update(updater)`. Springs expose `:SetSpeed()` and `:SetDamping()`; animation
states expose `:Awake()`.

### Elements & Props

Elements are Roblox Instances created declaratively via scope methods. Every
Roblox `Instance` class is available (e.g., `scope:Frame{}`, `scope:TextLabel{}`,
`scope:ScreenGui{}`, `scope:ScrollingFrame{}`). Weave also provides aliases such
as `Corner`, `Stroke`, `Padding`, `Gradient`, `ListLayout`, and `GridLayout`.

Props use the real Roblox property names. Weave adds special prop keys for
reactivity and events:

| Prop Key | Description | Example |
|----------|-------------|---------|
| `OnActivated` (implicit) | Any prop starting with `On` (except `OnChange`) auto-connects to the matching event. | `OnActivated = function() end` |
| `OnChangeText` (implicit) | Props starting with `OnChange` connect to `GetPropertyChangedSignal`. | `OnChangeText = function(new) end` |
| `[Weave.OnEvent "Name"]` | Explicit event connection (for dynamic event names). | `[Weave.OnEvent "Activated"] = fn` |
| `[Weave.OnChange "Name"]` | Explicit property-change connection. | `[Weave.OnChange "Text"] = fn` |
| `[Weave.Bind "Prop"]` | Two-way bind a property to a state. | `[Weave.Bind "Text"] = textState` |
| `[Weave.Ref]` | Capture the instance reference. | `[Weave.Ref] = refState` |
| `[Weave.Children]` | Explicit children array. | `[Weave.Children] = { child1, child2 }` |

**Reactive values as props:** Any state passed as a prop value is automatically
subscribed — the property updates when the state changes:

```lua
local hoverColor = scope:Value(Color3.fromRGB(40, 40, 50))

scope:TextButton {
    BackgroundColor3 = hoverColor,  -- auto-updates when hoverColor changes
}
```

**Children** are passed as positional arguments in the props table (Instances or
rendering nodes), or via `[Weave.Children]`.

---

## State Types

### Value

A read/write reactive primitive.

```lua
local count, setCount = scope:Value(0)

count:Get()          -- 0 (with tracking)
count:Peek()         -- 0 (no tracking)
setCount(5)          -- updates to 5
count:Update(function(n) return n + 1 end)  -- 6
count:Map(function(n) return n * 2 end)     -- Computed<number> = 12
```

### Computed

A read-only derived state. Dependencies are auto-tracked from the `use` helper
or direct state reads inside the callback.

```lua
local fullName = scope:Computed(function(use)
    return use(firstName) .. " " .. use(lastName)
end)

-- With equality function to prevent unnecessary updates
local filtered = scope:Computed(function(use)
    return filterList(use(items))
end, { equals = shallowEqual })
```

### Derived

A settable computed. Its setter installs an explicit value override; the next
source dependency change clears that override and resumes computed evaluation.

```lua
local doubled, setDoubled = scope:Derived(function(use)
    return use(base) * 2
end)
```

### Spring & Tween

Animation states that follow a reactive target value.

```lua
-- Spring: physics-based (default speed=10, damping=1)
local animPos = scope:Spring(targetPosition, 15, 0.8)  -- speed, damping

-- Tween: TweenInfo-driven
local animColor = scope:Tween(targetColor, TweenInfo.new(0.3, Enum.EasingStyle.Quad))
```

Both support number, Vector2, Vector3, UDim, UDim2, Color3, and CFrame types.

```lua
scope:Frame {
    Position = scope:Spring(menuOpen:Map(function(open)
        return open and UDim2.fromScale(0, 0) or UDim2.fromScale(1, 0)
    end)),
}
```

### Async & Suspense

`Async` runs a producer in a task and stores
`{ Status = "Pending" | "Resolved" | "Rejected", Value, Error }`. `Suspense`
renders a fallback until the status resolves.

```lua
local data = scope:Async(function()
    return httpGet("/api/players")
end)

return scope:Suspense {
    Resource = data,
    Fallback = function()
        return scope:TextLabel { Text = "Loading..." }
    end,
    Children = function(s, result)
        return s:TextLabel { Text = "Loaded " .. #result .. " players" }
    end,
}
```

### Reducer

Redux-style state container.

```lua
local state, dispatch = scope:Reducer(function(state, action)
    if action.type == "increment" then
        return { count = state.count + 1 }
    end
    return state
end, { count = 0 })

dispatch({ type = "increment" })
```

---

## Rendering Primitives

These are available as scope methods and handle conditional rendering, lists,
portals, error boundaries, and more:

| Primitive | Usage | Description |
|-----------|-------|-------------|
| `scope:Show(cond, builder)` | `Show(visible, function(s) return s:Frame{} end)` | Renders builder when condition is truthy. |
| `scope:Switch(state, cases)` | `Switch(tab, { home = fn, settings = fn, default = fn })` | Multi-case conditional. |
| `scope:ForValues(arrayState, render)` | `ForValues(items, function(s, item, i) return ... end)` | Render one element per array entry. |
| `scope:ForKeys(mapState, render)` | `ForKeys(map, function(s, key, value) return ... end)` | Render one element per keyed entry (key reuse on re-order). |
| `scope:Transition(cond, build, props)` | `Transition(visible, fn, { Enter = fn, Exit = fn })` | Animated mount/unmount. |
| `scope:Portal(props)` | `Portal { Target = someInstance, [Weave.Children] = {...} }` | Render into a different parent. |
| `scope:ErrorBoundary(builder, fallback)` | `ErrorBoundary(fn, function(s, err) return fallback end)` | Catches render errors in subtree. |
| `scope:Suspense(props)` | `Suspense { Resource = async, Fallback = fn, Children = fn }` | Wait for async resources. |
| `scope:Lazy(ref, fallback)` | `Lazy(Weave.lazy(factory), function() return Loading end)` | Code-split component loading. |
| `scope:Preload(props)` | `Preload { Assets = assets, Fallback = fn, Children = fn }` | Preload content before rendering children. |
| `scope:Provider(ctx, value, builder)` | `Provider(ThemeCtx, theme, function(s) ... end)` | Provide a context value to subtree. |
| `scope:Stagger(items, render, opts)` | `Stagger(list, fn, { delay = 0.05 })` | Cascading entrance animations. |
| `scope:AnimatePresence(items, render, opts)` | `AnimatePresence(list, fn, { Exit = fn })` | Per-item exit animations before removal. |
| `scope:Profiler()` | `Profiler()` | Render the client performance overlay manually. |

### Example: Animated list with exit

```lua
scope:AnimatePresence(
    visibleItems,
    function(s, item)
        return s:Frame {
            -- fade in
            BackgroundTransparency = scope:Spring(item.visible:Map(function(v)
                return v and 0 or 1
            end)),
        }
    end,
    { Exit = function(s, item, finish) finish() end }
)
```

---

## Built-in Components

Available via `Weave.Components.*` or registrable onto a scope:

| Component | Props | Description |
|-----------|-------|-------------|
| `Button` | `HoverState`, `PressState` (optional states) | TextButton with managed hover/press states. Disables `AutoButtonColor`. |
| `Flex` | `Direction`, `Wrap`, `Justify`, `Align`, `Gap`, `Padding` | Flexbox-like container backed by `UIListLayout`. |
| `TextInput` | `TextState` (Value), `OnSubmit`, `OnChange` | TextBox with managed text state. |
| `Tooltip` | `Target` (Instance), `Content` (builder), `PortalTarget` | Hover-portal tooltip. |
| `VirtualList` | `Items`, `ItemHeight` (default 50), `RenderItem` | Virtualized scrolling list. `RenderItem(scope, item, absoluteIndex)` receives stable absolute indexes. |

```lua
local Flex = Weave.Components.Flex

return Flex(scope, {
    Direction = Enum.FillDirection.Vertical,
    Gap = UDim.new(0, 8),
    Padding = UDim.new(0, 16),

    scope:TextLabel { Text = "Item 1" },
    scope:TextLabel { Text = "Item 2" },
})
```

### Custom components

```lua
-- Define a reusable component
local function Card(s, props)
    return s:Frame {
        Size = UDim2.fromOffset(200, 100),
        BackgroundColor3 = props.color or Color3.fromRGB(40, 40, 50),
        s:Corner { Radius = UDim.new(0, 8) },
        s:TextLabel { Text = props.title },
    }
end

-- Register it on a scope for convenience
scope:RegisterComponent("Card", Card)
scope:Card { title = "Hello", color = Color3.fromRGB(50, 50, 60) }
```

---

## Utility Hooks

Weave provides these utility hooks on scopes:

| Hook | Signature | Description |
|------|-----------|-------------|
| `scope:Watch(state, callback)` | `(state, (new, old) -> ())` | Fire callback on each change. |
| `scope:Observe(state, callback)` | `(state, (new, old?) -> ())` | Like Watch but fires immediately. |
| `scope:Effect(callback)` | `((use) -> ())` | Re-runs when tracked deps change. |
| `scope:Batch(callback)` | `(() -> ())` | Coalesce multiple mutations into one flush. |
| `scope:Selector(state, select, equals?)` | `(state, fn, fn?) -> Computed` | Select a slice with optional equality. |
| `scope:Defer(callback)` | `(() -> ())` | Defer to next frame. |
| `scope:Combine(...states, combiner)` | `(...state, fn) -> Computed` | Combine source values with a final callback. |
| `scope:Previous(state)` | `(state) -> Value<T?>` | State holding the previous value. |
| `scope:Timer(interval)` | `(number) -> Value<number>` | Ticking counter. |
| `scope:FromEvent(signal, mapper?)` | `(RBXScriptSignal, fn?) -> Value<T>` | Wrap a Roblox signal into a state. |
| `scope:ObserveNet(source, ...)` | `(RemoteEvent or signal, initial, mapper?) -> Value` | Bridge network or signal events into state. |
| `scope:BindAction(name, key)` | `(string, EnumItem) -> Value<boolean>` | Reactive ContextActionService binding. |
| `scope:Gate(state, predicate)` | `(state, fn) -> Value` | Publish values accepted by a predicate. |
| `scope:Form(initial?)` | `(table?) -> {Values, Errors, Touched, Update, SetError, Submit}` | Reactive form state. |
| `scope:Drag(instance, opts?)` | `(Instance, opts?) -> {IsDragging, Position, Delta}` | Reactive drag tracking. |
| `scope:MediaQuery(breakpoints)` | `({[string]: number}) -> Value<string>` | Reactive viewport breakpoint. |
| `scope:Store(initial, config)` | `(S, {actions, middleware?}) -> {State, Dispatch, Select}` | Redux-like store. |
| `scope:Resource(keyState, fetcher, opts?)` | `(state, fn, opts?) -> {data, error, status, refetch, invalidate}` | Cached data fetching with retry and optional refetch interval. |
| `scope:History(state, opts?)` | `(Value<T>, {maxDepth?}?) -> {State, Undo, Redo, ...}` | Undo/redo for a state. |
| `scope:Queue(opts?)` | `({maxSize?}?) -> {Push, Pop, PeekFront, Clear, Items, Count}` | Reactive bounded FIFO queue. |
| `scope:Animate(instance, steps)` | `(Instance, {{Property, To, Duration?, ...}})` | Sequential property animation. |
| `scope:AnimateLayout(target, opts?)` | `(Instance, opts?)` | Animated layout refresh. |
| `scope:Float(anchor, opts?)` | `(ref/state, opts?) -> {Position, Visible}` | Reactive floating-element placement. |
| `scope:Parallax(scroll, layers)` | `(state, layers) -> ()` | Apply per-layer scroll offsets. |
| `scope:Snapshot(states)` / `scope:Restore(states, data)` | `(map) -> table` / `(map, table) -> ()` | Serialize and restore named states. |
| `scope:Gesture(instance, opts?)` | `(Instance, {swipe?, longPress?, ...}) -> {...}` | Gesture detection. |
| `scope:Accessible(instance, opts?)` | `(Instance, opts?) -> Instance` | Apply accessibility metadata. |
| `scope:FocusGroup(instances)` | `({Instance}) -> {Instance}` | Link GUI selection navigation. |

---

## Context & Dependency Injection

Context allows passing values deep into the tree without prop drilling:

```lua
local ThemeContext = Weave.CreateContext({
    background = Color3.fromRGB(25, 25, 30),
    text = Color3.fromRGB(255, 255, 255),
})

-- Provide at the top
scope:Provider(ThemeContext, { background = Color3.fromRGB(40, 40, 50), text = Color3.fromRGB(200, 200, 210) }, function(s)
    -- Consume anywhere below
    local theme = s:UseContext(ThemeContext)
    return s:Frame { BackgroundColor3 = theme.background }
end)
```

---

## Styling

Register named style sets and apply them via the `Style` prop:

```lua
Weave.DefineStyle("card", {
    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
    BorderSizePixel = 0,
})

scope:Frame {
    Style = "card",  -- applies all registered properties
}
```

---

## Debugging

Set `Weave.Debug` to enable the in-game profiler overlay (client only):

```lua
Weave.Debug = "overlay"  -- mounts a performance overlay into PlayerGui
Weave.Debug = nil        -- disable
```

---

## Integration with Echo & Flite

### With Echo

Weave's entire reactivity engine is built on Echo. You don't need to manage
Echo directly, but you can use standalone Echo signals alongside Weave states
for cross-component event buses or imperative event flows.

### With Flite

Flite's client controllers each receive a **Weave scope** with extensions
(`ScopeExtensions`). This means inside a Flite controller you have the full
power of Weave — reactive states, elements, rendering primitives — plus Flite's
networking hooks:

```lua
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Flite = require(ReplicatedStorage.Libraries.Flite)

Flite.createController("HUDController", function(self)
    -- self IS a Weave scope with Flite extensions
    local coins = self:useServiceState("InventoryService", "coins")
    local playerGui = self:getPlayerGui()

    self:onStart(function()
        Weave.mount(playerGui, "HUD", function(scope)
            return scope:TextLabel {
                Text = coins:Map(function(c) return "Coins: " .. c end),
            }
        end)
    end)
end)
```

### Full stack (Echo + Weave + Flite)

```
Echo (signal engine)
 └─ Weave (reactivity + UI + animations)
     └─ Flite controllers (Weave scope + Flite networking + lifecycle)
```

When all three are combined, a Flite controller's scope gives you:
- **Weave states** (`scope:Value`, `scope:Computed`, `scope:Spring`, etc.)
- **Weave elements** (`scope:Frame`, `scope:TextLabel`, etc.)
- **Weave rendering** (`scope:Show`, `scope:ForValues`, `scope:Suspense`, etc.)
- **Flite service access** (`self:useService`, `self:useServiceState`)
- **Flite domain access** (`self:useDomain`)
- **Flite input hooks** (`self:useKey`, `self:useButton`, `self:useLocalCharacter`)
- **Flite lifecycle** (`self:onInit`, `self:onStart`, `self:onRenderStepped`)

See the [Flite README](https://github.com/royhanantariksaaa/flite-rbx) for the
complete game-framework integration guide.

---

## Performance Notes

Weave keeps its hot paths data-oriented where Luau permits it:

- State IDs index dense value, signal, type, generation, and dependency tables.
- Batched propagation uses a dense queue plus a reverse dependency graph, so a
  source update visits affected nodes without scanning every computed state.
- Dynamic dependencies are removed when a computation stops reading them.
- Property bindings and animation pools use swap removal for constant-time
  teardown without leaving holes in hot arrays.
- Reconciliation hydrates children in linear passes, and `VirtualList` retains
  sparse absolute indexes instead of copying whole source slices.
- Springs share one frame connection and batch their channel writes per frame.

Hot numeric modules request Luau native compilation and optimization. Luau does
not expose portable explicit SIMD or direct L1/L2/L3/L4 cache placement, so
Weave does not claim those controls. Dense arrays, packed animation channels,
linear iteration, and lower allocation pressure are the concrete locality
improvements available at this layer.

---

## Tests

Reference specs under `tests/*.spec.luau` use
[TestEZ](https://github.com/roblox/testez). `tests/RuntimeSmoke.luau` is a
standalone 51-check Studio suite covering dot/colon scope factories, batching,
callable animation states, dynamic dependencies,
recycled state IDs, binding cleanup, async suspense, and animation-state
propagation.

```sh
# Serve with Rojo, then run tests in your test harness
rojo serve default.project.json
```

---

## License

[MIT](./LICENSE).
