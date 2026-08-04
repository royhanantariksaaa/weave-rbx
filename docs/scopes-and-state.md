---
sidebar_position: 3
---

# Scopes and State

<div className="lesson-header">
  <p className="lesson-kicker"><span className="streamline-icon streamline-icon--identity" aria-hidden="true"></span> Reactivity / Ownership</p>
  <p className="lesson-summary">Build a dependency graph whose values, computed work, effects, Instances, connections, and timers all end with one explicit UI lifetime.</p>
</div>

Weave has two related APIs: low-level root constructors and scope-owned UI
constructors. Both use the same reactive engine, but they make different
promises about cleanup. Most screen and component code should begin with a
scope.

After this chapter, you should be able to choose the right owner, predict which
computations rerun after a write, use tracked and untracked reads deliberately,
and prove that a complete graph is released when its screen closes.

## Start with the owner

A scope is a lifetime container. State and resources created through the scope
register cleanup with it. `Weave.mount` creates the root scope of a UI tree and
returns the command that ends that lifetime.

```lua
local unmount = Weave.mount(playerGui, "Inventory", function(scope)
    local selectedCategory = scope:Value("Weapons")

    scope:OnDestroy(function()
        print("Inventory graph released")
    end)

    return scope:TextLabel {
        Text = selectedCategory,
    }
end)

-- Run this when the screen's owner stops.
unmount()
```

Use the smallest owner that matches the feature:

| Work | Recommended owner | Teardown |
|---|---|---|
| One mounted screen or HUD | `Weave.mount` root scope | Call the returned function |
| One branch created by `Show`, `Switch`, or a collection | Rendering primitive child scope | Automatic when the branch leaves |
| One reusable non-visual resource group | `Weave.scope()` | Call `scope:Destroy()` |
| Process-level reactive infrastructure | Root constructors such as `Weave.value` | Call `Weave.destroy(getter)` |

`Weave.scope(parentScope)` inherits the parent's context lookup. It does not
make an independently created scope part of the parent's render tree. If you
create that child manually, either destroy it explicitly or register its
destruction with the owner:

```lua
local child = Weave.scope(parent)
parent:OnDestroy(function()
    child:Destroy()
end)
```

Rendering primitives perform that child-scope ownership for you.

## Understand the two state shapes

Root constructors return accessor closures. Scope constructors wrap those
accessors in callable objects and own them.

| Constructor | Return shape | Read | Write | Ownership |
|---|---|---|---|---|
| `Weave.value(0)` | `getter, setter` | `getter()` | `setter(1)` | Manual |
| `Weave.computed(fn)` | getter | `getter()` | Read-only | Manual |
| `scope:Value(0)` | `State, setter` | `state()` or `state:Get()` | `state:Set(1)` | Scope-owned |
| `scope:Computed(fn)` | `State` | `state()` or `state:Get()` | Read-only | Scope-owned |

The following two graphs behave alike while alive, but only the scoped graph
has automatic teardown:

```lua
local rootCount, setRootCount = Weave.value(0)
local rootLabel = Weave.computed(function()
    return `Count: {rootCount()}`
end)

setRootCount(1)
print(rootLabel())

Weave.destroy(rootLabel)
Weave.destroy(rootCount)
```

```lua
local count = scope:Value(0)
local label = scope:Computed(function(use)
    return `Count: {use(count)}`
end)

count:Set(1)
print(label:Get())
-- scope:Destroy() releases both states.
```

## Choose tracked and untracked reads

`state:Get()`, `state()`, and the `use(state)` helper all track a dependency
when called inside `Computed` or `Effect`. `state:Peek()` reads without adding
an edge.

```lua
local score = scope:Value(10)
local debugEnabled = scope:Value(false)

local label = scope:Computed(function(use)
    local currentScore = use(score) -- tracked
    local debug = debugEnabled:Peek() -- intentionally untracked
    return debug and `Score: {currentScore} (debug)` or `Score: {currentScore}`
end)
```

Changing `score` recomputes `label`. Changing `debugEnabled` does not. Use
`Peek` for logging, snapshots, comparison baselines, and imperative work that
must not become part of the graph. Using it accidentally inside a derivation is
a common cause of stale UI.

## Build a feature-shaped graph

This inventory model combines mutable inputs, a reducer, dynamic dependencies,
an overrideable draft, and one batched command.

```lua
local items = scope:Value({
    { id = "sword", name = "Bronze Sword", category = "Weapons" },
    { id = "potion", name = "Health Potion", category = "Consumables" },
})
local category = scope:Value("Weapons")
local search = scope:Value("")

local selection, dispatchSelection = scope:Reducer(function(state, action)
    if action.type == "select" then
        return action.id
    elseif action.type == "clear" then
        return nil
    end
    return state
end, nil)

local visibleItems = scope:Computed(function(use)
    local source = use(items)
    local activeCategory = use(category)
    local query = string.lower(use(search))
    local result = {}

    for _, item in source do
        local inCategory = item.category == activeCategory
        local matches = query == ""
            or string.find(string.lower(item.name), query, 1, true) ~= nil

        if inCategory and matches then
            table.insert(result, item)
        end
    end

    return result
end)

local selectedLabel = scope:Computed(function(use)
    local selectedId = use(selection)
    if selectedId == nil then
        return "Nothing selected"
    end
    return `Selected: {selectedId}`
end)

local draftSearch, setDraftSearch = scope:Derived(function(use)
    return use(search)
end)

local function openConsumables()
    scope:Batch(function()
        category:Set("Consumables")
        search:Set("")
        dispatchSelection({ type = "clear" })
    end)
end
```

`Derived` follows its computation until its setter installs a temporary
override. The next change from a tracked dependency clears that override and
resumes computed evaluation. That makes it useful for drafts and optimistic UI;
it should not replace authoritative game state.

## Control invalidation

Dependencies are dynamic. If a computation stops reading a source, Weave
removes that reverse edge during the next evaluation.

```lua
local useCompact = scope:Value(true)
local compactText = scope:Value("HP")
local expandedText = scope:Value("Health points")

local title = scope:Computed(function(use)
    if use(useCompact) then
        return use(compactText)
    end
    return use(expandedText)
end)
```

After `useCompact` becomes false, writes to `compactText` no longer invalidate
`title`. Writes to `expandedText` do.

For table-producing computations, pass an equality function when a newly
allocated table can still represent the same result:

```lua
local model = scope:Computed(buildModel, {
    equals = function(previous, nextValue)
        return previous.id == nextValue.id
            and previous.version == nextValue.version
    end,
})
```

Mutable `Value` constructors accept `validate`, which can normalize or reject
every incoming value before storage.

## Use effects for boundaries

An effect is a tracked computation whose purpose is an external action.

```lua
local effectState = scope:Effect(function(use)
    analytics:setScreen("Inventory", use(category))
end)
```

Effects run immediately, then rerun when their tracked reads change. Returning
a cleanup function from the callback has no lifecycle meaning. Register cleanup
with `scope:OnDestroy` or `scope:onCleanup` instead.

For one known source, use `Watch` or `Observe`:

```lua
local watcher = scope:Watch(selection, function(nextId, previousId)
    print("selection", previousId, "->", nextId)
end)

scope:Observe(category, function(current, previous)
    print("category now", current, "previously", previous)
end)

watcher:Destroy() -- optional early stop; scope teardown also stops it
```

`Watch` skips the initial value. `Observe` invokes immediately with
`previous == nil`, then follows the same behavior. Both return the owned
computation so you can stop it early.

## Derive, delay, and batch

Every scoped state supports `Map`, `Throttle`, and `Debounce`:

```lua
local normalizedSearch = search:Map(function(value)
    return string.lower(string.gsub(value, "^%s*(.-)%s*$", "%1"))
end)

local previewSearch = normalizedSearch:Throttle(0.05)
local committedSearch = normalizedSearch:Debounce(0.25)
```

Use `Batch` for one logical command that writes several sources. Nested batches
are supported; only the outer boundary flushes. Return values are preserved,
and an error is rethrown after the batch depth is unwound.

Batching does not make a multi-step command asynchronous or transactional. A
callback error does not roll back values already written.

## Diagnose graph failures

| Symptom | Likely cause | Check |
|---|---|---|
| Computed never updates | Source was read with `Peek` | Replace the read with `Get`, `()`, or `use` |
| UI updates after screen close | Root state or manual connection outlived the mount | Move it into the scope or add explicit cleanup |
| Computed reruns too often | Broad source table or unstable derived allocation | Split state or add an equality function |
| Effect duplicates work | Effect was created on every imperative call | Create it once during scope construction |
| Temporary `Derived` edit disappears | A tracked dependency changed | Keep authoritative edits in `Value` or a server owner |
| Manual child scope leaks | Parent was used only for context inheritance | Register `child:Destroy()` with the owner |

## Verify teardown

Before shipping a screen, run this lifecycle check:

1. Mount the screen and record the expected Instances and active callbacks.
2. Change each source and confirm only its dependent labels or branches update.
3. Close the screen through the returned unmount function.
4. Change any external source again and confirm the removed UI does no work.
5. Mount a second time and confirm callbacks fire once, not twice.

Continue with [Rendering](/weave-rbx/docs/rendering/) to turn this graph into an Instance tree.
Use the generated [Scope](/weave-rbx/api/Scope/) and
[State](/weave-rbx/api/State/) references for exact signatures.
