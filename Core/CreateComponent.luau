--[=[
	@module CreateComponent
	@within Weave.Core

	Core runtime helper used by Weave rendering and reactivity internals.
]=]

-- CreateComponent: Shared factory for creating Weave element constructors.
-- Used by Elements.luau (dynamic, lazy-cached) and Scope bindings.

local Reconciler = require(script.Parent.Reconciler)
local Aliases = require(script.Parent.Aliases)
local Engine = require(script.Parent.Parent.Core.Engine)

local function CreateComponent(className: string)
    local actualClassName = Aliases[className] or className
    -- Validate eagerly so Elements.luau can pcall(CreateComponent, k) to detect invalid classes
    local testSuccess, testInst = pcall(Instance.new, actualClassName)
    if not testSuccess then error("Weave: Invalid class: " .. tostring(actualClassName)) end
    testInst:Destroy()

    return function(explicitScope: any, props: any): any
        -- Shift arguments if explicitScope is actually the props table
        if typeof(explicitScope) == "table" and explicitScope._trove == nil and props == nil then
            props = explicitScope
            explicitScope = nil
        end

        local scope = explicitScope or Engine.getCurrentScope()
        if not scope then
            error("Weave: Cannot create element '" .. actualClassName .. "'. No active Scope found! Did you yield? (Use scope:" .. actualClassName .. " if yielding is necessary).")
        end

        local inst = Instance.new(actualClassName)

        if inst:IsA("GuiObject") then
            inst.BorderSizePixel = 0
        end
        if inst:IsA("ScreenGui") then
            inst.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        end

        scope._trove:Add(inst)
        Reconciler.Reconcile(inst, (typeof(props) == "table" and props) or {}, scope._trove)
        
        return inst
    end
end

return CreateComponent
