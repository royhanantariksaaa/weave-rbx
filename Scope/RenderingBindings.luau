local Signal = require(game:GetService("ReplicatedStorage").Libraries.Echo)
local Reconciler = require(script.Parent.Parent.Core.Reconciler)

local RenderingShowInit          = require(script.Parent.Parent.Rendering.Show)
local RenderingSwitchInit        = require(script.Parent.Parent.Rendering.Switch)
local RenderingTransitionInit    = require(script.Parent.Parent.Rendering.Transition)
local RenderingForCollectionInit = require(script.Parent.Parent.Rendering.ForCollection)
local RenderingPortalInit        = require(script.Parent.Parent.Rendering.Portal)
local RenderingErrorBoundaryInit = require(script.Parent.Parent.Rendering.ErrorBoundary)
local RenderingLazyInit          = require(script.Parent.Parent.Rendering.Lazy)
local RenderingProviderInit      = require(script.Parent.Parent.Rendering.Provider)
local RenderingSuspenseInit      = require(script.Parent.Parent.Rendering.Suspense)
local RenderingPreloadInit       = require(script.Parent.Parent.Rendering.Preload)
local RenderingStaggerInit       = require(script.Parent.Parent.Rendering.Stagger)
local RenderingAnimatePresenceInit= require(script.Parent.Parent.Rendering.AnimatePresence)
local RenderingProfilerInit      = require(script.Parent.Parent.Rendering.Profiler)

return function(Scope)
    local forCollection = RenderingForCollectionInit(Scope, Signal)

    return {
        ShowFn          = RenderingShowInit(Scope, Signal),
        SwitchFn        = RenderingSwitchInit(Scope, Signal),
        TransitionFn    = RenderingTransitionInit(Scope, Signal),
        ForValuesFn     = function(self, sourceState, renderFunc)
            return forCollection(self, sourceState, true, renderFunc)
        end,
        ForKeysFn       = function(self, sourceState, renderFunc)
            return forCollection(self, sourceState, false, renderFunc)
        end,
        PortalFn        = RenderingPortalInit(Scope, Signal, Reconciler),
        ErrorBoundaryFn = RenderingErrorBoundaryInit(Scope, Signal),
        LazyFn          = RenderingLazyInit(Scope, Signal),
        ProviderFn      = RenderingProviderInit(Scope, Signal),
        SuspenseFn      = RenderingSuspenseInit(Scope, Signal),
        PreloadFn       = RenderingPreloadInit(Scope, Signal),
        StaggerFn       = RenderingStaggerInit(Scope, Signal),
        AnimatePresenceFn= RenderingAnimatePresenceInit(Scope, Signal),
        ProfilerFn      = RenderingProfilerInit(Scope, Signal),
    }
end
