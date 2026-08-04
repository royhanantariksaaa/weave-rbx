---
sidebar_position: 6
---

# Context and Styling

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--book" aria-hidden="true"></span> Composition / Shared inputs</p>
  <p className="lesson-summary">Share stable dependencies, reusable visual defaults, and component constructors through scope composition without hiding ownership.</p>
</div>

Props should remain the default way to pass feature data. Context is for a
cross-cutting value needed by several levels of one subtree: theme, locale,
input mode, feature flags, or a preview service. Named styles remove repeated
Roblox props, while registered components provide local constructor names.

## Choose props or context

| Situation | Prefer |
|---|---|
| Parent and direct child share feature data | Props |
| Several intermediate components would only forward one dependency | Context |
| Value should differ between two subtrees | `Provider` |
| Visual defaults repeat across unrelated constructors | Named style |
| Constructor is used only in one scope family | Registered component |

Context should not become a hidden global service locator. Keep business state
and commands explicit when a component's behavior depends on them.

## Create and provide context

`Weave.createContext(defaultValue)` returns a unique handle. Consumers see the
default until a nearer scope provides another value.

```lua
local Theme = Weave.createContext({
    surface = Color3.fromRGB(24, 27, 34),
    text = Color3.fromRGB(245, 247, 250),
    accent = Color3.fromRGB(58, 188, 170),
    spacing = 8,
})

local root = Weave.scope()
root:Provide(Theme, {
    surface = Color3.fromRGB(17, 19, 24),
    text = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(105, 210, 191),
    spacing = 10,
})

local child = Weave.scope(root)
local theme = child:UseContext(Theme)
print(theme.accent)
```

Child scopes inherit the parent's context table through a metatable rather than
copying every value. A local provide shadows only that key.

`Provide` accepts one context handle or a map:

```lua
local Locale = Weave.createContext("en")
local InputMode = Weave.createContext("keyboard")

scope:Provide({
    [Locale] = "id",
    [InputMode] = "gamepad",
})
```

Providing `nil` is equivalent to no local value when read through `UseContext`,
so the consumer falls back to the context default. Use a sentinel value when
`nil` itself must be meaningful.

## Bound a subtree with Provider

`scope:Provider(context, value, builder)` creates and owns a child scope,
provides the value, and builds the subtree inside it.

```lua
scope:Provider(Theme, darkTheme, function(themedScope)
    return buildSettingsPanel(themedScope)
end)
```

The builder receives the child scope. Its descendants inherit the provided
value, and replacing or destroying the surrounding branch releases the entire
subtree.

For values that change reactively, provide a State instead of repeatedly
providing raw snapshots:

```lua
local locale = scope:Value("en")

scope:Provider(Locale, locale, function(localizedScope)
    local localeState = localizedScope:UseContext(Locale)
    return localizedScope:TextLabel {
        Text = localeState:Map(resolveGreeting),
    }
end)
```

`UseContext` returns exactly what was provided. It does not unwrap State values.

## Register named styles

Styles are process-wide named prop tables.

```lua
Weave.defineStyle("Panel", {
    BackgroundColor3 = Color3.fromRGB(24, 27, 34),
    BorderSizePixel = 0,
})

Weave.defineStyle("PrimaryButton", {
    BackgroundColor3 = Color3.fromRGB(21, 132, 119),
    TextColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = false,
})
```

Apply one by name:

```lua
scope:TextButton {
    Style = "PrimaryButton",
    Text = "Save",
    BackgroundColor3 = Color3.fromRGB(17, 105, 96), -- explicit override
}
```

The reconciler copies a style property only when the explicit prop is `nil`.
Explicit props therefore win. Reactive values can live in a style because they
are applied through the ordinary property-binding path.

Style definitions are stored by reference, and redefining a name replaces the
registry entry for future constructions. Existing Instances are not
retroactively restyled. Define stable style tables during application setup;
use theme State through context for live theme switching.

## Compose a reactive theme

This component consumes a theme State and derives only the properties it uses.

```lua
local ThemeState = Weave.createContext(nil)

local function Card(cardScope, props)
    local theme = cardScope:UseContext(ThemeState)

    return cardScope:Frame {
        Style = "Panel",
        BackgroundColor3 = theme:Map(function(value)
            return value.surface
        end),

        cardScope:Padding {
            offset = { 12, 16 },
        },
        cardScope:TextLabel {
            BackgroundTransparency = 1,
            Text = props.title,
            TextColor3 = theme:Map(function(value)
                return value.text
            end),
        },
    }
end

local theme = scope:Value(darkTheme)
scope:Provider(ThemeState, theme, function(themedScope)
    return Card(themedScope, { title = "Daily quests" })
end)
```

Changing `theme` updates the two bound properties without reconstructing the
Card.

## Use prop shorthands accurately

The sequence helpers accept lowercase data fields and normalized color
channels:

```lua
local gradient = Weave.colorSequence({
    { time = 0, color = { 0.1, 0.6, 0.7 } },
    { time = 1, color = { 0.9, 0.4, 0.3 } },
})

local transparency = Weave.numberSequence({
    { time = 0, value = 0 },
    { time = 1, value = 1, envelope = 0 },
})

local accent = Weave.color3(0.1, 0.6, 0.7)
```

These helpers return ordinary Roblox datatypes. They are conveniences for
serializable theme data, not reactive states.

## Register local component constructors

Registration adds a named constructor to one scope family.

```lua
scope:RegisterComponent("StatusPill", function(componentScope, props)
    return componentScope:TextLabel {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = props.color,
        Text = props.text,
        componentScope:Corner { Radius = UDim.new(1, 0) },
        componentScope:Padding { offset = { 6, 10 } },
    }
end)

local pill = scope:StatusPill {
    text = "Online",
    color = Color3.fromRGB(30, 142, 92),
}
```

Child scopes inherit registered constructors from their parent, so a component
registered before `Show`, `Switch`, or `Provider` remains available in those
branches. A nearer registration with the same name shadows the inherited one.

Prefer direct component functions for reusable package exports. Registration
is most useful for a locally tailored component vocabulary.

## Memoize with the correct expectations

`Weave.memo(component)` keeps one last `scope`, shallow-cloned props table, and
result. It reuses the result only when the next call has the same scope and all
top-level prop values compare equal.

```lua
local MemoBadge = Weave.memo(Badge)
local badge = MemoBadge(scope, {
    text = "Ready",
    color = theme.accent,
})
```

This is a one-entry cache, not a keyed list cache. Nested tables still compare
by identity. Do not use memoization to hide broad state dependencies; derive
smaller props first.

## Diagnose composition failures

| Symptom | Likely cause | Check |
|---|---|---|
| Consumer always sees default | Wrong context handle or no ancestor provider | Pass the handle itself to `Provide` |
| Provided State appears as a table | Context does not unwrap values | Call `Get`, `Map`, or bind the State |
| Live theme does not update | Raw style snapshot was registered | Provide reactive theme State |
| Style override is ignored | Prop was changed after construction | Supply explicit prop in the factory call |
| Component missing in unrelated scope | Registration is scope-family local | Register there or call exported function directly |
| Memoized result is reused incorrectly | Mutable nested props retained identity | Use immutable props or avoid memoization |
| Sequence helper errors | Uppercase or wrong field shape | Use `time`, `value`, `envelope`, and `color` |

The [Crystal Run HUD](/weave-rbx/docs/project-crystal-run/) keeps its model explicit for easy
previewing, then uses composition where shared display concerns cross several
levels. See the generated [Context](/weave-rbx/api/Context/),
[Components](/weave-rbx/api/Components/), and
[Scope](/weave-rbx/api/Scope/) references for exact surfaces.
