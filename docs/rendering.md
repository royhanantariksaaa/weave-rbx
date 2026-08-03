---
sidebar_position: 4
---

# Rendering

## Instance construction

Roblox class names resolve lazily on a scope:

```lua
local label = scope:TextLabel {
    Name = "Score",
    Size = UDim2.fromOffset(180, 36),
    Text = scoreText,
    BackgroundTransparency = 1,
}
```

Plain values are assigned once. State values are bound and update when their
source changes.

## Events, changes, refs, and binding

```lua
local inputRef = scope:Ref()
local value = scope:Value("")

scope:TextBox {
    [Weave.Ref] = inputRef,
    [Weave.Bind("Text")] = value,
    [Weave.OnEvent("FocusLost")] = function(enterPressed)
        print("submitted", enterPressed)
    end,
    [Weave.OnChange("AbsoluteSize")] = function(instance)
        print(instance.AbsoluteSize)
    end,
}
```

## Children

Use `Weave.Children` when a normal property name could be ambiguous:

```lua
scope:Frame {
    [Weave.Children] = {
        scope:UIListLayout {
            Padding = UDim.new(0, 8),
        },
        scope:TextLabel { Text = "One" },
        scope:TextLabel { Text = "Two" },
    },
}
```

## Conditional rendering

```lua
scope:Show(isVisible, function(itemScope)
    return itemScope:TextLabel { Text = "Visible" }
end)
```

`Show`, `Switch`, and `ErrorBoundary` own branch scopes so replaced branches
release their resources.

## Collections

```lua
scope:ForValues(items, function(itemScope, item, index)
    return itemScope:TextLabel {
        Text = `{index}. {item.Name}`,
    }
end)
```

Use keyed collection primitives when item identity must survive reordering.
`VirtualList` materializes only the visible range and retains absolute source
indexes as layout keys.

## Existing Instances and portals

`scope:Hydrate(instance, props)` reconciles an existing Instance. `Portal`
renders owned children under a different parent while preserving scope cleanup.
