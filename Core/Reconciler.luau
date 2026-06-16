local Symbol = require(script.Parent.Parent.Parent.Symbol)
local Core = script.Parent
local Engine = require(Core.Engine)
local WeaveTypes = require(Core.Parent.Types)
local Debug = require(Core.Debug)
local Style = require(Core.Style)

local ChildrenSymbol = Symbol("WeaveChildren")
local RefSymbol = Symbol("WeaveRef")

local function createSymbolCache(prefix)
    local symbols = {}
    local names = {}
    local function getter(key: string)
        if not symbols[key] then
            local sym = Symbol(prefix .. key)
            symbols[key] = sym
            names[sym] = key
        end
        return symbols[key]
    end
    return getter, names
end

local OnEvent, OnEventNames = createSymbolCache("WeaveOnEvent:")
local OnChange, OnChangeNames = createSymbolCache("WeaveOnChange:")
local Bind, BindNames = createSymbolCache("WeaveBind:")

-- Detect if a value is a reactive state (getter closure or animation wrapper)
local function isReactiveState(value: any): boolean
    if Engine.resolveId(value) ~= nil then
        return true
    end
    if type(value) == "table" then
        if value._WeaveNodeType == WeaveTypes.NodeType.State then
            return true
        end
        if value._isWeaveState or type(value.Get) == "function" then
            return true
        end
    end
    return false
end

-- Get the entity ID from a reactive value
local function getStateId(value: any): number?
    return Engine.resolveId(value)
end

-- Get the current value from a reactive state
local function getStateValue(value: any): any
    if type(value) == "function" and Engine.AccessorToId[value] then
        -- Call the getter (which calls Engine.get internally)
        return value()
    end
    if type(value) == "table" and value.Get then
        return value:Get()
    end
    return value
end

-- Get the signal from a reactive state (for subscriptions)
local function getStateSignal(value: any): any?
    local id = Engine.resolveId(value)
    if id then
        return Engine.Signals[id]
    end
    if type(value) == "table" and value._changed then
        return value._changed
    end
    return nil
end

local function applyProperty(instance, prop, value, trove)
    if isReactiveState(value) then
        local stateId = getStateId(value)
        if stateId then
            local binds = Engine.Bindings[stateId]
            if not binds then
                binds = {}
                Engine.Bindings[stateId] = binds
            end
            table.insert(binds, { instance = instance, prop = prop })
        end
        instance[prop] = getStateValue(value)
    else
        instance[prop] = value
    end
end

local function applyChildren(instance, children, trove)
    for _, child in ipairs(children) do
        if typeof(child) == "Instance" then
            child.Parent = instance
        elseif isReactiveState(child) then
            local currentInstance = getStateValue(child)
            if typeof(currentInstance) == "Instance" then
                currentInstance.Parent = instance
            end
            local signal = getStateSignal(child)
            if signal then
                trove:Add(signal:Connect(function(newInstance)
                    if typeof(currentInstance) == "Instance" then
                        currentInstance.Parent = nil
                    end
                    if typeof(newInstance) == "Instance" then
                        newInstance.Parent = instance
                    end
                    currentInstance = newInstance
                end))
            end
        elseif type(child) == "table" then
            local nodeType = child._WeaveNodeType
            if not nodeType and child[1] ~= nil then
                applyChildren(instance, child, trove)
            elseif nodeType == WeaveTypes.NodeType.Rendering then
                local currentInstances = {}
                local function hydrate(newInstances)
                    for _, inst in ipairs(currentInstances) do
                        if not table.find(newInstances, inst) then
                            inst.Parent = nil
                        end
                    end
                    for _, inst in ipairs(newInstances) do
                        if inst.Parent ~= instance then
                            inst.Parent = instance
                        end
                    end
                    currentInstances = newInstances
                end
                hydrate(child._instances)
                trove:Add(child._changed:Connect(function(newInstances)
                    hydrate(newInstances)
                end))
            end
        end
    end
end

local PADDING_SIDES = { "PaddingTop", "PaddingRight", "PaddingBottom", "PaddingLeft" }
local PADDING_INDEX_MAP = {
    [1] = { 1, 1, 1, 1 },
    [2] = { 1, 2, 1, 2 },
    [4] = { 1, 2, 3, 4 },
}

local function applyPaddingValues(instance, props, key, isScale, trove)
    local vals = props[key]
    if not vals then return end
    local mapping = PADDING_INDEX_MAP[#vals]
    if not mapping then
        warn("Weave: Padding '" .. key .. "' shorthand expects 1, 2, or 4 values, got " .. #vals)
        return
    end
    for i = 1, 4 do
        local udim = isScale and UDim.new(vals[mapping[i]], 0) or UDim.new(0, vals[mapping[i]])
        applyProperty(instance, PADDING_SIDES[i], udim, trove)
    end
    props[key] = nil
end

local function Reconcile(instance, props, trove)
    local explicitChildren = props[ChildrenSymbol]
    if explicitChildren then
        props[ChildrenSymbol] = nil
    end

    if props.scale or props.offset then
        if instance:IsA("UIPadding") then
            applyPaddingValues(instance, props, "scale", true, trove)
            applyPaddingValues(instance, props, "offset", false, trove)
        else
            props.scale = nil
            props.offset = nil
        end
    end

    if props.Radius then
        if instance:IsA("UICorner") then
            applyProperty(instance, "CornerRadius", props.Radius, trove)
        end
        props.Radius = nil
    end

    if props.Spacing then
        if instance:IsA("UIGridLayout") then
            applyProperty(instance, "CellPadding", props.Spacing, trove)
        elseif instance:IsA("UIListLayout") or instance:IsA("UIPageLayout") or instance:IsA("UITableLayout") then
            applyProperty(instance, "Padding", props.Spacing, trove)
        end
        props.Spacing = nil
    end

    if props.Style and type(props.Style) == "string" then
        local styleDef = Style.GetStyle(props.Style)
        if styleDef then
            for k, v in pairs(styleDef) do
                if props[k] == nil then
                    props[k] = v
                end
            end
        end
        props.Style = nil
    end

    for key, value in pairs(props) do
        if type(key) == "string" then
            if type(value) == "function" and not isReactiveState(value) and string.sub(key, 1, 2) == "On" then
                if string.sub(key, 1, 8) == "OnChange" then
                    local propName = string.sub(key, 9)
                    trove:Add(instance:GetPropertyChangedSignal(propName):Connect(value))
                else
                    local eventName = string.sub(key, 3)
                    local success, ev = pcall(function() return instance[eventName] end)
                    if success and typeof(ev) == "RBXScriptSignal" then
                        trove:Add(ev:Connect(value))
                    else
                        applyProperty(instance, key, value, trove)
                    end
                end
            else
                applyProperty(instance, key, value, trove)
            end
        elseif type(key) == "number" then
            if not explicitChildren then
                explicitChildren = {}
            end
            table.insert(explicitChildren, value)
        elseif type(key) == "userdata" then
            local eventName = OnEventNames[key]
            if eventName then
                trove:Add(instance[eventName]:Connect(value))
            else
                local propName = OnChangeNames[key]
                if propName then
                    trove:Add(instance:GetPropertyChangedSignal(propName):Connect(value))
                else
                    local bindProp = BindNames[key]
                    if bindProp then
                        applyProperty(instance, bindProp, value, trove)
                        trove:Add(instance:GetPropertyChangedSignal(bindProp):Connect(function()
                            if isReactiveState(value) then
                                -- For Bind, we need the setter — but we only have the getter
                                -- Use Engine.set directly via resolveId
                                local id = getStateId(value)
                                if id then
                                    Engine.set(id, instance[bindProp])
                                end
                            elseif type(value) == "table" and value.Set then
                                value:Set(instance[bindProp])
                            end
                        end))
                    elseif key == RefSymbol then
                        if isReactiveState(value) then
                            local id = getStateId(value)
                            if id then
                                Engine.set(id, instance)
                            end
                        elseif type(value) == "table" and value.Set then
                            value:Set(instance)
                        end
                    end
                end
            end
        end
    end

    if explicitChildren then
        applyChildren(instance, explicitChildren, trove)
    end

    return instance
end

return {
    Reconcile = Reconcile,
    Children = ChildrenSymbol,
    OnEvent = OnEvent,
    OnChange = OnChange,
    Bind = Bind,
    Ref = RefSymbol,
}
