# Weave

A reactive UI framework for Roblox, inspired by SolidJS and Flutter.

Weave provides fine-grained reactivity, a declarative element tree, animation
primitives, and a rich set of rendering utilities — all built on top of
[Echo](https://github.com/royhanantariksaaa/echo-rbx) signals.

This is the core reactive/UI framework. [WeaveKit](https://github.com/royhanantariksaaa/weavekit-rbx)
(the component library) and [Flite](https://github.com/royhanantariksaaa/flite-rbx)
(the game framework) both consume it.

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
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

---

## Installation

### Runtime dependencies

Weave uses **absolute requires** to modules in `ReplicatedStorage.Libraries`.
At runtime, the following must be present:

| Dependency | Path | Purpose |
|------------|------|---------|
| [Echo](https://github.com/royhanantariksaaa/echo-rbx) | `ReplicatedStorage.Libraries.Echo` | Fast pure-Luau signal engine |
| `Symbol` | `ReplicatedStorage.Libraries.Symbol` | Unique keys for internal sentinels |
| `Tween` | `ReplicatedStorage.Libraries.Tween` | SoA tween scheduler |

`Echo` is its own repo. `Symbol` and `Tween` are leaf single-file utilities.

### As a git submodule

From your game repo root (assuming `src/Shared` maps to `ReplicatedStorage`):

```sh
git submodule add https://github.com/royhanantariksaaa/echo-rbx.git src/Shared/Libraries/Echo
git submodule add https://github.com/royhanantariksaaa/weave-rbx.git src/Shared/Libraries/Weave
```

Then provide `Symbol` and `Tween` at `ReplicatedStorage.Libraries/<Name>`.

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
        print("Final value:", text():Peek())
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
scope:destroy()
```

In practice, `Weave.mount` creates a root scope for you and passes it to your
builder function. Child scopes are created automatically by rendering
primitives (`Show`, `ForValues`, etc.).

### States

States are the reactive core. Reading a state inside a `Computed` or `Effect`
automatically tracks it as a dependency — when it changes, the dependent
re-computes.

All states are **callable**: calling `state()` (or `state:Get()`) reads the
value with dependency tracking. `state:Peek()` reads without tracking.

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

Every state supports these methods:

| Method | Description |
|--------|-------------|
| `:Get()` / `()` | Read with dependency tracking. |
| `:Peek()` | Read without tracking. |
| `:Map(fn)` | Returns a new Computed that transforms the value. |
| `:Throttle(seconds)` | Returns a throttled derivative. |
| `:Debounce(seconds)` | Returns a debounced derivative. |
| `:Destroy()` | Destroys the state and releases resources. |

### Elements & Props

Elements are Roblox Instances created declaratively via scope methods. Every
Roblox `Instance` class is available (e.g., `scope:Frame{}`, `scope:TextLabel{}`,
`scope:ScreenGui{}`, `scope:ScrollingFrame{}`). Weave also provides short
[aliases](#) like `Corner`, `Stroke`, `Padding`, `Gradient`, etc.

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

A **settable** computed — the setter re-runs the callback with the new input.

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

`Async` wraps a promise-returning function. `Suspense` pauses rendering until
the async resolves, showing a fallback in the meantime.

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
| `scope:Provider(ctx, value, builder)` | `Provider(ThemeCtx, theme, function(s) ... end)` | Provide a context value to subtree. |
| `scope:Stagger(items, render, opts)` | `Stagger(list, fn, { delay = 0.05 })` | Cascading entrance animations. |
| `scope:AnimatePresence(items, render, opts)` | `AnimatePresence(list, fn, { Exit = fn })` | Per-item exit animations before removal. |

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
| `VirtualList` | `Items`, `ItemHeight` (default 50), `RenderItem` | Virtualized scrolling list for large datasets. |

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

Weave provides a rich set of utility hooks on scopes. Here are the most common:

| Hook | Signature | Description |
|------|-----------|-------------|
| `scope:Watch(state, callback)` | `(state, (new, old) -> ())` | Fire callback on each change. |
| `scope:Observe(state, callback)` | `(state, (new, old?) -> ())` | Like Watch but fires immediately. |
| `scope:Effect(callback)` | `((use) -> ())` | Re-runs when tracked deps change. |
| `scope:Batch(callback)` | `(() -> ())` | Coalesce multiple mutations into one flush. |
| `scope:Defer(callback)` | `(() -> ())` | Defer to next frame. |
| `scope:Combine(...states)` | `(...state) -> Computed` | Combine multiple states into one. |
| `scope:Previous(state)` | `(state) -> Value<T?>` | State holding the previous value. |
| `scope:Timer(interval)` | `(number) -> Value<number>` | Ticking counter. |
| `scope:FromEvent(signal, mapper)` | `(RBXScriptSignal, fn) -> Value<T>` | Wrap a Roblox signal into a state. |
| `scope:Drag(instance, opts?)` | `(Instance, opts?) -> {IsDragging, Position, Delta}` | Reactive drag tracking. |
| `scope:MediaQuery(breakpoints)` | `({[string]: number}) -> Value<string>` | Reactive viewport breakpoint. |
| `scope:Store(initial, config)` | `(S, {actions, middleware?}) -> {State, Dispatch, Select}` | Redux-like store. |
| `scope:Resource(keyState, fetcher, opts?)` | `(state, fn, {staleTime?, retries?}?) -> {Data, Error, Status, ...}` | TanStack-Query-style data fetching. |
| `scope:History(state, opts?)` | `(Value<T>, {maxDepth?}?) -> {State, Undo, Redo, ...}` | Undo/redo for a state. |
| `scope:Animate(instance, steps)` | `(Instance, {{Property, To, Duration?, ...}})` | Sequential property animation. |
| `scope:AnimateLayout(target, opts?)` | `(Instance, opts?)` | Animated layout refresh. |
| `scope:Gesture(instance, opts?)` | `(Instance, {swipe?, longPress?, ...}) -> {...}` | Gesture detection. |

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

## Tests

Reference specs live under `tests/` and are written for
[TestEZ](https://github.com/roblox/testez).

```sh
# Serve with Rojo, then run tests in your test harness
rojo serve default.project.json
```

---

## License

[MIT](./LICENSE).
