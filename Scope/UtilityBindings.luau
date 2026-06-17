--!optimize 2
--[=[
	@within Weave
	@module UtilityBindings

	Binds the utility hooks (`Observe`, `Timer`, `Drag`, etc.) onto a scope.
	Internal — consumed by Scope.
]=]

local Signal = require(game:GetService("ReplicatedStorage").Libraries.Echo)
local Value = require(script.Parent.Parent.States.Value)
local Computed = require(script.Parent.Parent.States.Computed)
local Mixins = require(script.Parent.Parent.States.Mixins)
local TweenLib = require(script.Parent.Parent.Parent.Tween)

local UtilityBatchInit           = require(script.Parent.Parent.Utilities.Batch)
local UtilitySelectorInit        = require(script.Parent.Parent.Utilities.Selector)
local UtilityCombineInit         = require(script.Parent.Parent.Utilities.Combine)
local UtilityPreviousInit        = require(script.Parent.Parent.Utilities.Previous)
local UtilityTimerInit           = require(script.Parent.Parent.Utilities.Timer)
local UtilityObserveInit         = require(script.Parent.Parent.Utilities.Observe)
local UtilityDeferInit           = require(script.Parent.Parent.Utilities.Defer)
local UtilityFromEventInit       = require(script.Parent.Parent.Utilities.FromEvent)
local UtilityWatchInit           = require(script.Parent.Parent.Utilities.Watch)
local UtilityAnimateInit         = require(script.Parent.Parent.Utilities.Animate)
local UtilityBindActionInit      = require(script.Parent.Parent.Utilities.BindAction)
local UtilityObserveNetInit      = require(script.Parent.Parent.Utilities.ObserveNet)
local UtilityGateInit            = require(script.Parent.Parent.Utilities.Gate)
local UtilityFormInit            = require(script.Parent.Parent.Utilities.Form)
local UtilityAnimateLayoutInit   = require(script.Parent.Parent.Utilities.AnimateLayout)
local UtilityHistoryInit         = require(script.Parent.Parent.Utilities.History)
local UtilityMediaQueryInit      = require(script.Parent.Parent.Utilities.MediaQuery)
local UtilityDragInit            = require(script.Parent.Parent.Utilities.Drag)
local UtilityStoreInit           = require(script.Parent.Parent.Utilities.Store)
local UtilityResourceInit        = require(script.Parent.Parent.Utilities.Resource)
local UtilityQueueInit           = require(script.Parent.Parent.Utilities.Queue)
local UtilityFloatInit           = require(script.Parent.Parent.Utilities.Float)
local UtilityParallaxInit        = require(script.Parent.Parent.Utilities.Parallax)
local UtilitySnapshotInit        = require(script.Parent.Parent.Utilities.Snapshot)
local UtilityGestureInit         = require(script.Parent.Parent.Utilities.Gesture)
local UtilityAccessibleInit      = require(script.Parent.Parent.Utilities.Accessible)

return function(Scope)
    local bindings = {
        BatchFn         = UtilityBatchInit(Scope, Signal),
        SelectorFn      = UtilitySelectorInit(Scope, Signal, Value, Mixins),
        CombineFn       = UtilityCombineInit(Scope, Signal, Computed),
        PreviousFn      = UtilityPreviousInit(Scope, Signal, Value),
        TimerFn         = UtilityTimerInit(Scope, Signal, Value),
        ObserveFn       = UtilityObserveInit(Scope, Signal),
        DeferFn         = UtilityDeferInit(Scope, Signal),
        FromEventFn     = UtilityFromEventInit(Scope, Signal, Value),
        WatchFn         = UtilityWatchInit(Scope, Signal),
        AnimateFn       = UtilityAnimateInit(Scope, Signal, TweenLib),
        BindActionFn    = UtilityBindActionInit(Scope, Signal, Value),
        ObserveNetFn    = UtilityObserveNetInit(Scope, Signal, Value),
        GateFn          = UtilityGateInit(Scope, Signal, Value),
        FormFn          = UtilityFormInit(Scope, Signal, Value),
        AnimateLayoutFn = UtilityAnimateLayoutInit(Scope, Signal, TweenLib),
        HistoryFn       = UtilityHistoryInit(Scope, Signal, Value, Computed),
        MediaQueryFn    = UtilityMediaQueryInit(Scope, Signal, Value),
        DragFn          = UtilityDragInit(Scope, Signal, Value),
        StoreFn         = UtilityStoreInit(Scope, Signal, Value, Computed),
        ResourceFn      = UtilityResourceInit(Scope, Signal, Value, Computed),
        QueueFn         = UtilityQueueInit(Scope, Signal, Value, Computed),
        FloatFn         = UtilityFloatInit(Scope, Signal),
        ParallaxFn      = UtilityParallaxInit(Scope, Signal),
    }

    local snapFns = UtilitySnapshotInit(Scope, Signal)
    bindings.SnapshotFn = snapFns.Snapshot
    bindings.RestoreFn = snapFns.Restore
    
    bindings.GestureFn = UtilityGestureInit(Scope, Signal)
    local accessFns = UtilityAccessibleInit(Scope, Signal)
    bindings.AccessibleFn = accessFns.Accessible
    bindings.FocusGroupFn = accessFns.FocusGroup
    
    return bindings
end
