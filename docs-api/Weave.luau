--!strict

--[=[
	@class Weave

	Scoped reactive UI runtime for Roblox.
]=]
local Weave = {}

--[=[
	@class State

	Common readable state surface. Mutable state types additionally expose
	`Set` and `Update`.
]=]
local State = {}

--- Returns the current value and tracks the read when inside a computation.
function State:Get(): any return nil end

--- Replaces a mutable state's value.
function State:Set(value: any) end

--- Updates a mutable state from its current value.
function State:Update(updater: (any) -> any) end

--- Reads the value without dependency tracking.
function State:Peek(): any return nil end

--- Releases the state. Destruction is idempotent.
function State:Destroy() end

--[=[
	@class Scope

	Owns state, Instances, connections, effects, tasks, and nested scopes.
]=]
local Scope = {}

--- Creates mutable state.
function Scope:Value(initial: any, options: any?): any return nil end

--- Creates read-only derived state.
function Scope:Computed(callback: () -> any, options: any?): any return nil end

--- Creates computed state that can be temporarily overridden.
function Scope:Derived(callback: () -> any, options: any?): any return nil end

--- Creates a physics-driven animation state.
function Scope:Spring(target: any, speed: number?, damping: number?): any return nil end

--- Creates a TweenService-driven animation state.
function Scope:Tween(target: any, tweenInfo: TweenInfo?): any return nil end

--- Creates asynchronous status state from a producer.
function Scope:Async(producer: () -> any): any return nil end

--- Creates reducer-backed state.
function Scope:Reducer(reducer: (any, any) -> any, initial: any): ...any return end

--- Runs an effect and tracks every state read made by its callback.
function Scope:Effect(callback: () -> ()): any return nil end

--- Batches writes and flushes dependent work once the outer batch closes.
function Scope:Batch(callback: () -> ...any): ...any return callback() end

--- Creates an Instance, applies reactive props, and owns it.
function Scope:New(className: string, props: { [any]: any }): Instance return nil :: any end

--- Applies reactive props and children to an existing Instance.
function Scope:Hydrate(instance: Instance, props: { [any]: any }): Instance return instance end

--- Registers a component constructor on this scope.
function Scope:RegisterComponent(name: string, component: (...any) -> any) end

--- Provides a raw context value.
function Scope:Provide(key: any, value: any) end

--- Reads a raw context value.
function Scope:Consume(key: any): any return nil end

--- Reads a typed context value or its default.
function Scope:UseContext(context: any): any return nil end

--- Registers work for the next mount turn.
function Scope:OnMount(callback: () -> ()) end

--- Registers deterministic cleanup.
function Scope:OnDestroy(callback: () -> ()) end

--- Lowercase cleanup alias.
function Scope:onCleanup(callback: () -> ()) end

--- Destroys everything owned by the scope.
function Scope:Destroy() end

--- Creates a scope, optionally inheriting context from a parent.
function Weave.scope(parentScope: any?): any return nil end

--- Mounts a scoped UI tree under a parent and returns its cleanup function.
function Weave.mount(parent: Instance, propsOrBuilder: any, builder: any?): () -> () return function() end end

--- Creates mutable state outside a scope. Prefer scoped state for UI.
function Weave.value(initial: any, options: any?): ...any return end

--- Creates computed state outside a scope.
function Weave.computed(callback: () -> any, options: any?): any return nil end

--- Creates overrideable derived state outside a scope.
function Weave.derived(callback: () -> any, options: any?): ...any return end

--- Creates a spring animation state.
function Weave.spring(target: any, speed: number?, damping: number?): any return nil end

--- Creates a tween animation state.
function Weave.tween(target: any, tweenInfo: TweenInfo?): any return nil end

--- Creates async status state.
function Weave.async(producer: () -> any): any return nil end

--- Creates reducer-backed state.
function Weave.reducer(reducer: (any, any) -> any, initial: any): ...any return end

--- Runs a tracked effect.
function Weave.effect(callback: () -> ()): any return nil end

--- Batches state writes.
function Weave.batch(callback: () -> ...any): ...any return callback() end

--- Reads state without dependency tracking.
function Weave.peek(state: any): any return nil end

--- Destroys a state.
function Weave.destroy(state: any) end

--- Returns whether a value is a Weave state accessor or wrapper.
function Weave.isState(value: any): boolean return false end

--- Creates a context handle with a default value.
function Weave.createContext(defaultValue: any): any return nil end

--- Registers a named style.
function Weave.defineStyle(name: string, props: { [any]: any }) end

--- Wraps a component with shallow-prop memoization.
function Weave.memo(component: (...any) -> any): (...any) -> any return component end

--- Creates a lazily resolved module reference.
function Weave.lazy(factory: () -> any): any return nil end

return Weave
