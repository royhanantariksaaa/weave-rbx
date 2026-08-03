---
sidebar_position: 4
---

# Rendering

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--code" aria-hidden="true"></span> Reactivity / Rendering</p>
  <p className="lesson-summary">Construct Roblox Instances declaratively, bind state to properties, own events, and preserve the intended identity across branches, collections, hydration, and portals.</p>
</div>

Weave rendering is Instance construction plus scoped reconciliation. A factory
creates a Roblox Instance, applies ordinary and reactive props, connects events,
parents children, and registers all of that work with the current scope.

This is not a virtual DOM. State bindings update individual Roblox properties,
and rendering nodes replace only the branch or collection entries they own.

## Create an Instance tree

Every Roblox class name resolves lazily on a scope. Weave also provides readable
aliases such as `Corner`, `Padding`, `ListLayout`, and `Billboard`.

```lua
local panel = scope:Frame {
    Name = "ShopPanel",
    Size = UDim2.fromOffset(420, 320),
    BackgroundColor3 = Color3.fromRGB(24, 27, 34),

    scope:Corner {
        Radius = UDim.new(0, 8),
    },
    scope:Padding {
        offset = { 16, 20 }, -- vertical, horizontal
    },
    scope:ListLayout {
        FillDirection = Enum.FillDirection.Vertical,
        Spacing = UDim.new(0, 10),
    },
}
```

The shorthands map to Roblox properties:

| Weave shorthand | Instance | Roblox property |
|---|---|---|
| `Corner { Radius = value }` | `UICorner` | `CornerRadius` |
| `Padding { offset = { ... } }` | `UIPadding` | Four offset paddings |
| `Padding { scale = { ... } }` | `UIPadding` | Four scale paddings |
| `ListLayout { Spacing = value }` | `UIListLayout` | `Padding` |
| `GridLayout { Spacing = value }` | `UIGridLayout` | `CellPadding` |

Padding arrays accept one value for every side, two for vertical/horizontal,
or four in top/right/bottom/left order.

Props are construction inputs. The reconciler consumes some special keys such
as children, style, and shorthands, so create a fresh props table for each
factory call instead of reusing one mutable table across Instances.

## Bind state to properties

Pass a scoped wrapper, root getter, Spring, or Tween as a property value. Weave
sets the current value immediately and records a direct binding for later
writes.

```lua
local coins = scope:Value(120)
local coinText = coins:Map(function(value)
    return `Coins: {value}`
end)

local label = scope:TextLabel {
    Name = "Balance",
    Size = UDim2.fromOffset(180, 36),
    BackgroundTransparency = 1,
    Text = coinText,
    TextColor3 = Color3.new(1, 1, 1),
}
```

Changing `coins` updates only `label.Text`. It does not rebuild the label or
rerun the surrounding component constructor.

Plain values are assigned once. If a table prop contains nested reactive data,
derive the complete Roblox value first rather than expecting deep observation.

## Connect events and property changes

You can use readable string props or collision-proof symbol keys.

```lua
local text = scope:Value("")
local inputRef = scope:Ref()

scope:TextBox {
    [Weave.ref] = inputRef,
    [Weave.bind("Text")] = text,

    [Weave.onEvent("FocusLost")] = function(enterPressed)
        if enterPressed then
            print("submitted", text:Peek())
        end
    end,

    [Weave.onChange("AbsoluteSize")] = function()
        local input = inputRef:Get()
        print("size", input and input.AbsoluteSize)
    end,
}
```

`GetPropertyChangedSignal` callbacks receive no property value or Instance
argument. Read the changed property from a ref when you need it.

The equivalent string forms are `OnFocusLost = callback` and
`OnChangeAbsoluteSize = callback`. Symbol keys are preferable in shared
component libraries because they cannot be mistaken for Roblox properties.

`bind(property)` is two-way. State changes write the Instance property, and
property changes write back to a mutable state. Passing a read-only Computed to
a two-way binding can update the Instance but cannot accept the reverse write.

All event and property connections are owned by the constructing scope.

## Supply children deliberately

Numeric entries in a props table become children. `Weave.children` makes the
boundary explicit and is useful when assembling arrays elsewhere.

```lua
local rows = {
    scope:TextLabel { Text = "Sword" },
    scope:TextLabel { Text = "Potion" },
}

scope:Frame {
    [Weave.children] = {
        scope:ListLayout { Spacing = UDim.new(0, 8) },
        rows,
    },
}
```

Children can be Instances, nested arrays, reactive Instance states, or Weave
rendering nodes. When a reactive child changes, the old Instance is unparented
and the new one is parented without replacing the surrounding container.

## Model conditional identity

`Show` is a boolean `Switch`. Each active branch gets a child scope. When the
selected branch changes, the old child scope is destroyed before the new one is
built.

```lua
local status = scope:Value("loading")

local body = scope:Switch(status, {
    loading = function(branch)
        return branch:TextLabel { Text = "Loading catalog..." }
    end,
    ready = function(branch)
        return buildCatalog(branch)
    end,
    failed = function(branch)
        return branch:TextButton {
            Text = "Retry",
            OnActivated = retry,
        }
    end,
    default = function(branch, value)
        return branch:TextLabel { Text = `Unknown state: {value}` }
    end,
})
```

The branch callback runs when its case becomes active, not on every source
write. State created inside the callback belongs to that branch and disappears
when the case changes.

Use `Transition` when false should delay branch destruction until an exit
callback finishes:

```lua
scope:Transition(isOpen, buildMenu, {
    Enter = function(instances)
        fadeIn(instances)
    end,
    Exit = function(instances, done)
        fadeOut(instances, done)
    end,
})
```

An `Exit` callback must call `done()`. If it never does, the old branch remains
mounted. A later re-entry invalidates the pending completion through an internal
generation check.

## Choose collection identity

`ForValues` treats each array value itself as the reuse key:

```lua
scope:ForValues(visibleItems, function(rowScope, item, index)
    return rowScope:TextLabel {
        LayoutOrder = index,
        Text = item.name,
    }
end)
```

Use it when values are stable, unique identities such as item objects. Duplicate
values collide, and replacing an object creates a new row scope.

`ForKeys` uses map keys as identities:

```lua
scope:ForKeys(itemsById, function(rowScope, itemId, item)
    return buildItemRow(rowScope, itemId, item)
end)
```

For a retained key, Weave retains the existing row and does not call the render
function again merely because the map's value changed. Put changing row fields
in reactive states, or include a version in the key when replacement is the
desired behavior. Map traversal uses `pairs`, so set `LayoutOrder` yourself when
visual order matters.

| Need | Primitive |
|---|---|
| Truthy branch | `Show` |
| One of several cases | `Switch` |
| Delayed branch exit | `Transition` |
| Unique stable values in an array | `ForValues` |
| Explicit keyed identity | `ForKeys` |
| Large scrolling data | `Weave.Components.VirtualList` |

`VirtualList` renders only the visible range, uses absolute source indexes as
keys, and writes row position and height after `RenderItem` returns.

## Hydrate and portal with ownership in mind

`scope:Hydrate(instance, props)` applies the same props and child rules to an
existing Instance. The scope takes ownership of that Instance; destroying the
scope destroys it.

```lua
local existing = template:Clone()
scope:Hydrate(existing, {
    Visible = isVisible,
    OnMouseEnter = showDetails,
})
```

`Portal` renders owned children beneath a target outside the normal hierarchy.
It creates a `Folder` named `WeavePortal` under the current target and moves the
portal when a reactive target changes.

```lua
scope:Portal {
    Target = overlayGui,
    [Weave.children] = {
        buildTooltip(scope),
    },
}
```

The returned portal node is intentionally empty in its original parent. Its
target must be a live Instance.

## Bound synchronous failures

`ErrorBoundary` catches errors thrown while its builder constructs the subtree.
It can render a fallback with the error value.

```lua
scope:ErrorBoundary(function(boundaryScope)
    return buildRiskyPanel(boundaryScope)
end, function(fallbackScope, err)
    return fallbackScope:TextLabel {
        Text = `Panel failed: {err}`,
    }
end)
```

It does not catch arbitrary errors from later tasks, event callbacks, or remote
work. Handle those failures at their asynchronous boundary and expose their
status as state.

## Mount the root correctly

`Weave.mount(parent, builder)` parents the builder result directly.
`Weave.mount(parent, props, builder)` wraps it in a `ScreenGui` configured by
`props`. Both return an idempotent cleanup path for normal ownership use.

Do not call a second `Weave.mount` while another mount builder is executing.
Compose the subtree with the scope passed to the current builder instead.

## Diagnose rendering failures

| Symptom | Likely cause | Check |
|---|---|---|
| Property never changes | Plain value was passed | Pass a state or computed value |
| TextBox changes but state does not | One-way property binding | Use `[Weave.bind("Text")]` with mutable state |
| Change callback reads `nil` argument | Roblox change signals pass no value | Read through a ref |
| Row shows stale fields | `ForKeys` retained the keyed row | Make fields reactive or version the key |
| Duplicate array rows disappear | `ForValues` values are not unique | Use an ID-keyed map and `ForKeys` |
| Closing a transition leaks a branch | `Exit` never called `done` | Complete every exit path |
| Hydrated template vanishes on teardown | Scope owns hydrated Instances | Clone or choose a different owner |
| Portal is invisible | Missing or destroyed target | Verify `Target` and its ancestry |

Continue with [Animation and Async](/weave-rbx/docs/animation-and-async/) for time-based state
and delayed presence. The generated [Scope reference](/weave-rbx/api/Scope/)
lists every rendering and utility method.
