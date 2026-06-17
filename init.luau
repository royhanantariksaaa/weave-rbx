--!optimize 2
--[=[
	@module Weave
	@class Weave

	A reactive UI framework for Roblox, inspired by SolidJS and Flutter.
	The entry point exposes scope creation, state constructors, rendering
	helpers, and a metatable-backed element namespace.

	Public API surface (all available on the returned `Weave` table):

	- **Scopes & mounting**: `Weave.scope()` / `Weave.mount(parent, builder)`
	- **State constructors**: `Weave.value`, `Weave.computed`, `Weave.spring`,
	  `Weave.tween`, `Weave.async`, `Weave.reducer`, `Weave.derived`
	- **Reactive primitives**: `Weave.effect`, `Weave.peek`, `Weave.destroy`
	- **Element helpers**: `Weave.children`, `Weave.onEvent`, `Weave.onChange`,
	  `Weave.bind`, `Weave.ref`
	- **Styling & context**: `Weave.defineStyle`, `Weave.createContext`
	- **Memoization & lazy**: `Weave.memo`, `Weave.lazy`
	- **Built-in components**: `Weave.Components` (Button, Flex, TextInput, ...)
	- **Element constructors**: accessed via metatable `__index` (e.g. `Weave.Frame`, `Weave.TextLabel`)

	PascalCase aliases (e.g. `Weave.Value`, `Weave.Scope`) exist for backward
	compatibility and mirror the camelCase primary API.

	```lua
	local Weave = require(ReplicatedStorage.Libraries.Weave)
	local scope = Weave.scope()
	local count, setCount = scope:Value(0)
	```
]=]

local Reconciler = require(script.Core.Reconciler)
local Scope = require(script.Scope)
local WeaveTypes = require(script.Types)
local Engine = require(script.Core.Engine)
local Style = require(script.Core.Style)
local Debug = require(script.Core.Debug)
local Helpers = require(script.Core.Helpers)

local contextIdCounter = 0
--[=[
	Creates a context slot with a default value. Contexts let components
	share values down the tree without prop drilling. The returned table
	holds an opaque `_id` and the `DefaultValue`.

	@param defaultValue any -- value seen by consumers that provide none
	@return { _id: string, DefaultValue: any } -- the context handle
]=]
local function CreateContext(defaultValue: any)
    contextIdCounter += 1
    return { _id = "WeaveContext_" .. contextIdCounter, DefaultValue = defaultValue }
end

local function shallowEqual(a, b)
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

--[=[
	Wraps a component so it only re-renders when `scope` or a shallow
	comparison of `props` changes. The previous result is cached.

	@param component (scope, props) -> any -- the component to memoize
	@return (scope, props) -> any -- the memoized component
]=]
local function Memo(component)
    local lastScope, lastProps, lastResult = nil, nil, nil
    return function(scope, props)
        if lastScope == scope and lastProps and shallowEqual(props, lastProps) then return lastResult end
        lastScope = scope
        lastProps = table.clone(props)
        lastResult = component(scope, props)
        return lastResult
    end
end

--[=[
	Returns a lazy reference to a module produced by `factory`. The factory
	runs at most once, on the first `:Preload()` call. Use for code-splitting
	heavy optional components.

	@param factory () -> any -- produces the module on first preload
	@return { Preload: () -> any } -- the lazy handle
]=]
local function lazy(factory: () -> any)
    local ref = { _factory = factory, _resolved = nil, _hasPreloaded = false }
    --[=[
        Preloads the referenced asset.
    ]=]
    function ref:Preload()
        if not self._hasPreloaded then
            self._hasPreloaded = true
            self._resolved = self._factory()
        end
        return self._resolved
    end
    return ref
end

--[=[
	Mounts a builder's output into `parent`. Creates a root scope, runs the
	builder inside it, and parents the resulting instance(s).

	Two call forms:
	  - `Weave.mount(parent, builder)` — builder returns an Instance or list
	  - `Weave.mount(parent, props, builder)` — wraps the result in a ScreenGui
	    using `props` (a props table, or a string used as `Name`)

	Returns a cleanup function that destroys the root scope and unmounts.

	@param parent Instance -- the container to mount into
	@param arg2 any -- builder function, or props (when using the 3-arg form)
	@param arg3 (() -> any)? -- builder function (only in the 3-arg form)
	@return () -> () -- cleanup; call to unmount and destroy the scope
]=]
local function Mount(parent: Instance, arg2: any, arg3: (() -> any)?)
    local CreateComponent = require(script.Core.CreateComponent)
    
    if Engine.getCurrentScope() then
        error("Weave: Cannot call Weave.Mount() while already inside a component's render execution!")
    end

    if type(parent) == "function" and typeof(arg2) == "Instance" and arg3 == nil then
        parent, arg2 = arg2, parent
    end

    local builderFunc = arg3 or arg2
    local propsArg = arg3 and arg2 or nil
    if type(builderFunc) ~= "function" then
        if typeof(builderFunc) == "Instance" then
            local instanceValue = builderFunc
            builderFunc = function()
                return instanceValue
            end
        else
            error("Weave: Mount expects a builder function (or an Instance as shorthand).")
        end
    end

    local rootScope = Scope.new()
    Engine.pushScope(rootScope)
    local success, result = pcall(builderFunc, rootScope)
    
    if success and propsArg ~= nil then
        local guiProps = type(propsArg) == "string" and { Name = propsArg } or propsArg
        if typeof(result) == "Instance" then
            guiProps[Reconciler.Children] = { result }
        elseif type(result) == "table" then
            guiProps[Reconciler.Children] = result
        end
        local screenGuiFactory = CreateComponent("ScreenGui")
        local factorySuccess, wrappedResult = pcall(screenGuiFactory, rootScope, guiProps)
        if factorySuccess then result = wrappedResult else success = false; result = wrappedResult end
    end
    
    Engine.popScope()
    
    if not success then
        rootScope:Destroy()
        error("Weave: Error during Weave.Mount execution: " .. tostring(result))
    end
    
    if typeof(parent) ~= "Instance" then
        error("Weave: Mount parent must be an Instance.")
    end

    if typeof(result) == "Instance" then
        if result ~= parent then
            result.Parent = parent
        end
    elseif type(result) == "table" then
        for _, inst in ipairs(result) do
            if typeof(inst) == "Instance" and inst ~= parent then
                inst.Parent = parent
            end
        end
    end
    
    return function()
        rootScope:Destroy()
        if typeof(result) == "Instance" then result:Destroy()
        elseif type(result) == "table" then
            for _, inst in ipairs(result) do if typeof(inst) == "Instance" then inst:Destroy() end end
        end
    end
end

local Weave = {
    -- Core API (camelCase)
    scope = Scope.new :: () -> WeaveTypes.Scope,
    children = Reconciler.Children :: any,
    onEvent = Reconciler.OnEvent,
    onChange = Reconciler.OnChange,
    bind = Reconciler.Bind,
    ref = Reconciler.Ref,
    defineStyle = Style.DefineStyle,
    createContext = CreateContext,
    memo = Memo,
    lazy = lazy,
    mount = Mount,

    -- PascalCase Aliases (backward compat)
    Scope = Scope.new :: () -> WeaveTypes.Scope,
    Children = Reconciler.Children :: any,
    OnEvent = Reconciler.OnEvent,
    OnChange = Reconciler.OnChange,
    Bind = Reconciler.Bind,
    Ref = Reconciler.Ref,
    DefineStyle = Style.DefineStyle,
    CreateContext = CreateContext,
    Memo = Memo,
    Mount = Mount,

    -- camelCase state constructors (primary API)
    value = require(script.States.Value),
    computed = require(script.States.Computed),
    derived = require(script.States.Derived),
    spring = require(script.States.Spring),
    tween = require(script.States.Tween),
    async = require(script.States.Async),
    reducer = require(script.States.Reducer),
    --[=[
	    Run `callback` whenever its tracked dependencies change. Tracks via
	    getter calls made inside the callback (same mechanism as `computed`).
	    @param callback () -> () -- side-effect body
    ]=]
    effect = function(callback)
        return Engine.computed(function()
            callback()
            return nil
        end)
    end,
    
    -- Utility functions (camelCase)
    peek = Engine.peek,
    destroy = Engine.destroy,
    isState = Engine.isState,
    
    -- Sequence builders (camelCase)
    color3 = Helpers.Color3,
    numberSequence = Helpers.NumberSequence,
    colorSequence = Helpers.ColorSequence,
    
    -- PascalCase backward compat aliases
    Value = require(script.States.Value),
    Computed = require(script.States.Computed),
    Derived = require(script.States.Derived),
    Spring = require(script.States.Spring),
    Tween = require(script.States.Tween),
    Async = require(script.States.Async),
    Reducer = require(script.States.Reducer),
    Peek = Engine.peek,
    Destroy = Engine.destroy,
    IsState = Engine.isState,
}

Weave.Components = {
    VirtualList = require(script.Components.VirtualList),
    Button = require(script.Components.Button),
    Flex = require(script.Components.Flex),
    TextInput = require(script.Components.TextInput),
    Tooltip = require(script.Components.Tooltip),
}

local Elements = require(script.Core.Elements)
local RunService = game:GetService("RunService")
local _profilerScope = nil

setmetatable(Weave, {
    __index = function(_, k) 
        if k == "Debug" then return Debug.Enabled end
        local element = Elements[k]
        if element then return element end
        return rawget(Weave, k) 
    end,
    __newindex = function(_, k, v) 
        if k == "Debug" then 
            Debug.Enabled = v
            if v == "overlay" and RunService:IsClient() then
                if not _profilerScope then
                    _profilerScope = Scope.new()
                    _profilerScope.Profiler()
                end
            elseif _profilerScope then
                _profilerScope:Destroy()
                _profilerScope = nil
            end
        else rawset(Weave, k, v) end 
    end
})

export type Scope = WeaveTypes.Scope
return (Weave :: any) :: WeaveTypes.WeaveModule
