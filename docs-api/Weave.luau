--!strict

-- This documentation facade is parsed by Moonwave through `--code docs-api`.
-- It describes public runtime shapes without adding stubs to the shipped module.

--[=[
	@class Weave

	Root module for scope creation, mounting, unscoped reactive state, rendering
	symbols, context, styles, lazy loading, components, and debug controls.
]=]
local Weave = {}

--[=[
	@class Scope

	Primary UI owner. State constructors, rendering primitives, utilities,
	Instances, connections, tasks, and child render branches created through a
	scope are released by `Destroy`. Canonical methods below use PascalCase;
	state, rendering, and utility methods also expose lower-camel aliases.
]=]
local Scope = {}

--[=[
	@class State

	Callable scope-owned reactive state wrapper. Read-only families ignore
	`Set` and `Update`; mutable Value, Derived, and Reducer wrappers implement
	them.
]=]
local State = {}

--[=[
	@class AnimationState

	Callable Spring or Tween projection that follows another reactive state.
]=]
local AnimationState = {}

--[=[
	@class AsyncResult

	Status record read from an Async state.
]=]
local AsyncResult = {}

--[=[
	@class Context

	Opaque context handle created by `Weave.createContext`.
]=]
local Context = {}

--[=[
	@class Ref

	Mutable Instance holder accepted by the `Weave.ref` rendering symbol.
]=]
local Ref = {}

--[=[
	@class LazyRef

	One-shot lazy module handle created by `Weave.lazy`.
]=]
local LazyRef = {}

--[=[
	@class Components

	Built-in component constructors. Each receives the owning Scope first and
	returns ordinary Roblox Instances or rendering nodes.
]=]
local Components = {}

--[=[
	@class Form

	Reactive form controller returned by `Scope:Form`.
]=]
local Form = {}

--[=[
	@class Store

	Redux-style state, dispatch, and selector controller returned by
	`Scope:Store`.
]=]
local Store = {}

--[=[
	@class Resource

	Key-driven cached request controller returned by `Scope:Resource`.
]=]
local Resource = {}

--[=[
	@class History

	Undo and redo controller returned by `Scope:History`.
]=]
local History = {}

--[=[
	@class Queue

	Reactive bounded FIFO controller returned by `Scope:Queue`.
]=]
local Queue = {}

--[=[
	@class DragState

	Reactive pointer-drag state returned by `Scope:Drag`.
]=]
local DragState = {}

--[=[
	@class GestureState

	Reactive gesture recognition state returned by `Scope:Gesture`.
]=]
local GestureState = {}

--[=[
	@class FloatState

	Reactive placement and ref bundle returned by `Scope:Float`.
]=]
local FloatState = {}

--[=[
	@class AnimationController

	Cancelable finite sequence returned by `Scope:Animate`.
]=]
local AnimationController = {}

--[=[
	@class LayoutController

	FLIP layout controller returned by `Scope:AnimateLayout`.
]=]
local LayoutController = {}

-- Root properties and rendering symbols

--[=[
	@prop children any
	@within Weave
	@readonly

	Symbol key for an explicit children array. PascalCase alias: `Children`.
]=]
Weave.children = nil :: any

--[=[
	@prop ref any
	@within Weave
	@readonly

	Symbol key that writes a constructed Instance into a mutable State or Ref.
	PascalCase alias: `Ref`.
]=]
Weave.ref = nil :: any

--[=[
	@prop Components Components
	@within Weave
	@readonly

	Built-in `Button`, `Flex`, `TextInput`, `Tooltip`, and `VirtualList` table.
]=]
Weave.Components = Components

--[=[
	@prop Debug boolean|string?
	@within Weave

	Set `true` to collect counters, `"overlay"` to mount the client profiler,
	or `nil`/`false` to disable debug tracking.
]=]
Weave.Debug = nil :: any

--[=[
	Returns a collision-proof symbol key for an Instance event. PascalCase
	alias: `OnEvent`.
]=]
function Weave.onEvent(eventName: string): any return nil end

--[=[
	Returns a symbol key for `GetPropertyChangedSignal`. The callback receives
	no property value. PascalCase alias: `OnChange`.
]=]
function Weave.onChange(propertyName: string): any return nil end

--[=[
	Returns a two-way property binding symbol. The supplied state must be
	mutable to accept Instance-to-state writes. PascalCase alias: `Bind`.
]=]
function Weave.bind(propertyName: string): any return nil end

-- Root lifecycle and state

--[=[
	Creates a manual Scope. `parentScope` supplies inherited context and
	component lookup; destroy a manually created child explicitly.
]=]
function Weave.scope(parentScope: Scope?): Scope return Scope end

--[=[
	Creates a root Scope, runs a builder, parents its result, and returns the
	unmount function. Supplying props or a name wraps output in a ScreenGui.
]=]
function Weave.mount(parent: Instance, propsOrBuilder: any, builder: ((Scope) -> any)?): () -> ()
	return function() end
end

--[=[
	Creates unscoped mutable state and returns getter/setter closures. Destroy
	the getter manually. PascalCase alias: `Value`.
]=]
function Weave.value(initialValue: any, options: { validate: ((any) -> any)? }?): (() -> any, (any) -> ())
	return function() return nil end, function() end
end

--[=[
	Creates an unscoped cached computation with dynamic dependencies. PascalCase
	alias: `Computed`.
]=]
function Weave.computed(callback: () -> any, options: { equals: ((any, any) -> boolean)? }?): () -> any
	return function() return nil end
end

--[=[
	Creates an unscoped computed default with a temporary setter override.
	PascalCase alias: `Derived`.
]=]
function Weave.derived(callback: () -> any, options: { equals: ((any, any) -> boolean)? }?): (() -> any, (any) -> ())
	return function() return nil end, function() end
end

--[=[
	Creates an unscoped action reducer and returns getter/dispatch closures.
	PascalCase alias: `Reducer`.
]=]
function Weave.reducer(reducer: (any, any) -> any, initialState: any): (() -> any, (any) -> ())
	return function() return nil end, function() end
end

--[=[
	Runs a producer immediately in a task and returns an AsyncResult getter.
	PascalCase alias: `Async`.
]=]
function Weave.async(producer: () -> any): () -> AsyncResult
	return function() return AsyncResult end
end

--[=[
	Creates an unscoped Spring following a state accessor. PascalCase alias:
	`Spring`.
]=]
function Weave.spring(target: any, speed: number?, damping: number?): AnimationState return AnimationState end

--[=[
	Creates an unscoped Tween following a state accessor. PascalCase alias:
	`Tween`.
]=]
function Weave.tween(target: any, tweenInfo: TweenInfo?): AnimationState return AnimationState end

--[=[
	Creates an unscoped tracked side-effect computation. Destroy the returned
	getter with `Weave.destroy`.
]=]
function Weave.effect(callback: () -> ()): () -> any return function() return nil end end

--[=[
	Defers propagation until the outermost synchronous batch closes and
	preserves callback return values. PascalCase alias: `Batch`.
]=]
function Weave.batch(callback: () -> ...any): ...any return callback() end

--[=[
	Reads a state without dependency tracking or forcing a pending Computed.
	PascalCase alias: `Peek`.
]=]
function Weave.peek(state: any): any return nil end

--[=[
	Releases an unscoped state or animation object. Repeated destruction is
	ignored. PascalCase alias: `Destroy`.
]=]
function Weave.destroy(state: any) end

--[=[
	Returns whether a live getter, wrapper, or animation object belongs to the
	Weave engine. PascalCase alias: `IsState`.
]=]
function Weave.isState(value: any): boolean return false end

-- Composition helpers

--[=[
	Creates a unique context handle with a default value. PascalCase alias:
	`CreateContext`.
]=]
function Weave.createContext(defaultValue: any): Context return Context end

--[=[
	Stores a process-wide named props table for future element construction.
	PascalCase alias: `DefineStyle`.
]=]
function Weave.defineStyle(name: string, props: { [any]: any }) end

--[=[
	Wraps a component in a one-entry cache using scope identity and shallow prop
	equality. PascalCase alias: `Memo`.
]=]
function Weave.memo(component: (Scope, any) -> any): (Scope, any) -> any return component end

--[=[
	Creates a one-shot lazy handle. The factory runs on the first `Preload`.
]=]
function Weave.lazy(factory: () -> any): LazyRef return LazyRef end

--[=[
	Creates a Color3 from normalized 0-1 channels.
]=]
function Weave.color3(r: number, g: number, b: number): Color3 return Color3.new(r, g, b) end

--[=[
	Creates a NumberSequence from lowercase `time`, `value`, and optional
	`envelope` fields.
]=]
function Weave.numberSequence(keypoints: { any }): NumberSequence return nil :: any end

--[=[
	Creates a ColorSequence from lowercase `time` and normalized `color` array
	fields.
]=]
function Weave.colorSequence(keypoints: { any }): ColorSequence return nil :: any end

-- Scope state construction

--[=[
	Creates an owned mutable State and a setter convenience. Lowercase alias:
	`value`; Solid alias: `createSignal`.
]=]
function Scope:Value(initialValue: any, options: { validate: ((any) -> any)? }?): (State, (any) -> ())
	return State, function() end
end

--[=[
	Creates an owned read-only State with dynamic dependencies and optional
	equality. Lowercase alias: `computed`; Solid alias: `createMemo`.
]=]
function Scope:Computed(callback: ((any) -> any), options: { equals: ((any, any) -> boolean)? }?): State return State end

--[=[
	Creates an owned computed default with a temporary writable override.
	Lowercase alias: `derived`.
]=]
function Scope:Derived(callback: ((any) -> any), options: { equals: ((any, any) -> boolean)? }?): (State, (any) -> ())
	return State, function() end
end

--[=[
	Creates an owned reducer State and action dispatcher. Lowercase alias:
	`reducer`.
]=]
function Scope:Reducer(reducer: (any, any) -> any, initialState: any): (State, (any) -> ())
	return State, function() end
end

--[=[
	Creates an owned Async State whose value is an AsyncResult. Lowercase alias:
	`async`.
]=]
function Scope:Async(producer: () -> any): State return State end

--[=[
	Creates an owned Spring following a State. Lowercase alias: `spring`.
]=]
function Scope:Spring(target: any, speed: number?, damping: number?): AnimationState return AnimationState end

--[=[
	Creates an owned Tween following a State. Lowercase alias: `tween`.
]=]
function Scope:Tween(target: any, tweenInfo: TweenInfo?): AnimationState return AnimationState end

--[=[
	Runs immediately and reruns after tracked dependencies change. Returns the
	destroyable owned computation. Lowercase alias: `effect`; Solid alias:
	`createEffect`.
]=]
function Scope:Effect(callback: (any) -> ()): State return State end

--[=[
	Returns children as a fragment without adding an Instance. Lowercase alias:
	`fragment`.
]=]
function Scope:Fragment(children: any): { any } return {} end

--[=[
	Runs synchronous writes in one propagation boundary. Lowercase alias:
	`batch`.
]=]
function Scope:Batch(callback: () -> ...any): ...any return callback() end

-- Scope rendering

--[=[
	Renders a child-scope branch while a condition is truthy. Lowercase alias:
	`show`.
]=]
function Scope:Show(condition: any, builder: (Scope) -> any): any return nil end

--[=[
	Renders the builder matching a state value, or `cases.default`. Lowercase
	alias: `switch`.
]=]
function Scope:Switch(state: any, cases: { [any]: (Scope, any) -> any }): any return nil end

--[=[
	Renders a boolean branch with optional Enter and asynchronous Exit hooks.
	Exit must call its `done` callback. Lowercase alias: `transition`.
]=]
function Scope:Transition(condition: any, builder: (Scope) -> any, options: any?): any return nil end

--[=[
	Renders array entries keyed by each unique value identity. Lowercase alias:
	`forValues`.
]=]
function Scope:ForValues(source: any, render: (Scope, any, number) -> any): any return nil end

--[=[
	Renders map entries keyed by map key. Retained keys retain their row scope.
	Lowercase alias: `forKeys`.
]=]
function Scope:ForKeys(source: any, render: (Scope, any, any) -> any): any return nil end

--[=[
	Renders owned children under another target Instance. Lowercase alias:
	`portal`.
]=]
function Scope:Portal(props: { [any]: any }): any return nil end

--[=[
	Catches synchronous subtree-construction errors and optionally builds a
	fallback. Lowercase alias: `errorBoundary`.
]=]
function Scope:ErrorBoundary(builder: (Scope) -> any, fallback: ((Scope, any) -> any)?): any return nil end

--[=[
	Loads a LazyRef through Async and renders an optional fallback. Lowercase
	alias: `lazy`.
]=]
function Scope:Lazy(reference: LazyRef | (() -> any), fallback: ((Scope) -> any)?): any return nil end

--[=[
	Provides one context value to an owned child subtree. Lowercase alias:
	`provider`.
]=]
function Scope:Provider(context: Context, value: any, builder: (Scope) -> any): any return nil end

--[=[
	Renders Fallback while one or several Async states are pending and Children
	after all resolve. Lowercase alias: `suspense`.
]=]
function Scope:Suspense(props: { [string]: any }): any return nil end

--[=[
	Preloads Instances with ContentProvider before rendering Children. Lowercase
	alias: `preload`.
]=]
function Scope:Preload(props: { [string]: any }): any return nil end

--[=[
	Renders rows with a per-index State that changes from 0 to 1 after a delay.
	Lowercase alias: `stagger`.
]=]
function Scope:Stagger(source: any, render: (Scope, any, number, State) -> any, options: any?): any return nil end

--[=[
	Retains removed value-keyed rows until their Exit callback returns. Lowercase
	alias: `animatePresence`.
]=]
function Scope:AnimatePresence(source: any, render: (Scope, any, number) -> any, options: any): any return nil end

--[=[
	Mounts the client debug-counter overlay through a portal. Lowercase alias:
	`profiler`.
]=]
function Scope:Profiler(): any return nil end

-- Scope observation and derivation utilities

--[=[
	Projects one source through a selector and optional equality function.
	Lowercase alias: `selector`.
]=]
function Scope:Selector(state: any, selector: (any) -> any, equals: ((any, any) -> boolean)?): State return State end

--[=[
	Combines all leading state arguments with the final callback. Lowercase
	alias: `combine`.
]=]
function Scope:Combine(...: any): State return State end

--[=[
	Returns a State holding the source's prior value, initially nil. Lowercase
	alias: `previous`.
]=]
function Scope:Previous(state: any): State return State end

--[=[
	Creates a tick-count State incremented every positive interval in seconds.
	Lowercase alias: `timer`.
]=]
function Scope:Timer(interval: number): State return State end

--[=[
	Runs after each source change, skipping the initial value, and returns the
	destroyable watcher State. Lowercase alias: `watch`.
]=]
function Scope:Watch(state: any, callback: (any, any) -> ()): State return State end

--[=[
	Invokes immediately with `(current, nil)`, then watches subsequent changes.
	Returns the destroyable watcher State. Lowercase alias: `observe`.
]=]
function Scope:Observe(state: any, callback: (any, any?) -> ()): State return State end

--[=[
	Runs a callback on the next shared frame turn unless the scope is destroyed.
	Lowercase alias: `defer`.
]=]
function Scope:Defer(callback: () -> ()) end

--[=[
	Bridges an RBXScriptSignal into a latest-value State. Lowercase alias:
	`fromEvent`.
]=]
function Scope:FromEvent(signal: RBXScriptSignal, mapper: ((...any) -> any)?): State return State end

--[=[
	Bridges a RemoteEvent or Connect-compatible signal into State. Lowercase
	alias: `observeNet`.
]=]
function Scope:ObserveNet(source: any, ...: any): State return State end

--[=[
	Binds one ContextActionService action and returns held-state boolean State.
	Additional key codes or input types are accepted. Lowercase alias:
	`bindAction`.
]=]
function Scope:BindAction(actionName: string, ...: EnumItem): State return State end

--[=[
	Publishes source values accepted by a `(new, old) -> boolean` predicate.
	Lowercase alias: `gate`.
]=]
function Scope:Gate(state: any, predicate: (any, any?) -> boolean): State return State end

-- Scope application utilities

--[=[
	Creates a reactive form Values, Errors, Touched, and command controller.
	Lowercase alias: `form`.
]=]
function Scope:Form(initialValues: { [string]: any }?): Form return Form end

--[=[
	Creates Redux-style State, Dispatch, and Select operations. Lowercase alias:
	`store`.
]=]
function Scope:Store(initialState: any, options: any?): Store return Store end

--[=[
	Creates a cached, deduplicated key-driven request controller. Policy values
	are seconds. Lowercase alias: `resource`.
]=]
function Scope:Resource(key: any, fetcher: (any) -> any, options: any?): Resource return Resource end

--[=[
	Adds undo/redo history to a mutable State. Lowercase alias: `history`.
]=]
function Scope:History(state: State, options: { maxDepth: number? }?): History return History end

--[=[
	Creates a bounded reactive FIFO queue. Lowercase alias: `queue`.
]=]
function Scope:Queue(options: { maxSize: number? }?): Queue return Queue end

--[=[
	Creates a responsive breakpoint-name State from minimum widths. Lowercase
	alias: `mediaQuery`.
]=]
function Scope:MediaQuery(breakpoints: { [string]: number }): State return State end

--[=[
	Tracks pointer drag state for a GuiObject. Lowercase alias: `drag`.
]=]
function Scope:Drag(instance: GuiObject, options: { axis: string? }?): DragState return DragState end

--[=[
	Recognizes swipe, long-press, and tap state on a GuiObject. Lowercase alias:
	`gesture`.
]=]
function Scope:Gesture(instance: GuiObject, options: any?): GestureState return GestureState end

--[=[
	Applies selection and focus metadata through the reconciler. Lowercase alias:
	`accessible`.
]=]
function Scope:Accessible(instance: GuiObject, options: any?): GuiObject return instance end

--[=[
	Links GuiObjects into circular directional selection and clears links on
	teardown. Lowercase alias: `focusGroup`.
]=]
function Scope:FocusGroup(instances: { GuiObject }): { GuiObject } return instances end

--[=[
	Creates reactive floating-element placement plus the ref for the floating
	GuiObject. Lowercase alias: `float`.
]=]
function Scope:Float(anchor: any, options: any?): FloatState return FloatState end

--[=[
	Applies per-layer offsets from a number or Vector2 scroll State each frame.
	Lowercase alias: `parallax`.
]=]
function Scope:Parallax(scroll: any, layers: { any }) end

--[=[
	Captures named state values without adding dependency edges. Lowercase
	alias: `snapshot`.
]=]
function Scope:Snapshot(states: { [string]: any }): { [string]: any } return {} end

--[=[
	Writes snapshot values back to mutable named states. Lowercase alias:
	`restore`.
]=]
function Scope:Restore(states: { [string]: any }, data: { [string]: any }) end

-- Scope animation utilities

--[=[
	Schedules sequential one-property Tween steps. The returned controller and
	pending work are scope-owned. Lowercase alias: `animate`.
]=]
function Scope:Animate(instance: Instance, steps: { any }): AnimationController return AnimationController end

--[=[
	Tracks child layout changes and animates positional deltas with FLIP.
	Lowercase alias: `animateLayout`.
]=]
function Scope:AnimateLayout(container: GuiObject, options: any?): LayoutController return LayoutController end

-- Scope composition and lifecycle

--[=[
	Creates a mutable Instance Ref.
]=]
function Scope:Ref(): Ref return Ref end

--[=[
	Applies reactive props and children to an existing Instance and transfers
	its lifetime to the scope.
]=]
function Scope:Hydrate(instance: Instance, props: { [any]: any }): Instance return instance end

--[=[
	Registers a named component inherited by child scopes.
]=]
function Scope:RegisterComponent(name: string, component: (Scope, any) -> any) end

--[=[
	Provides one context handle/key or a map of values on this scope.
]=]
function Scope:Provide(keyOrValues: any, value: any?) end

--[=[
	Reads one raw context key without default handling.
]=]
function Scope:Consume(key: any): any return nil end

--[=[
	Reads a Context value, falling back to its default when nil.
]=]
function Scope:UseContext(context: Context): any return nil end

--[=[
	Defers a callback to the next mount turn unless the scope is destroyed.
]=]
function Scope:OnMount(callback: () -> ()) end

--[=[
	Registers deterministic scope cleanup.
]=]
function Scope:OnDestroy(callback: () -> ()) end

--[=[
	Lowercase cleanup alias for `OnDestroy`.
]=]
function Scope:onCleanup(callback: () -> ()) end

--[=[
	Releases all resources owned by this scope. Repeated destruction is safe.
]=]
function Scope:Destroy() end

-- Representative dynamic Instance factories

--[=[
	Creates and owns a Frame. Any valid Roblox class name resolves by the same
	dynamic factory mechanism.
]=]
function Scope:Frame(props: { [any]: any }): Frame return nil :: any end

--[=[
	Creates and owns a TextLabel.
]=]
function Scope:TextLabel(props: { [any]: any }): TextLabel return nil :: any end

--[=[
	Creates and owns a TextButton.
]=]
function Scope:TextButton(props: { [any]: any }): TextButton return nil :: any end

--[=[
	Creates and owns a TextBox.
]=]
function Scope:TextBox(props: { [any]: any }): TextBox return nil :: any end

--[=[
	Creates and owns a ScrollingFrame.
]=]
function Scope:ScrollingFrame(props: { [any]: any }): ScrollingFrame return nil :: any end

--[=[
	Creates and owns a CanvasGroup.
]=]
function Scope:CanvasGroup(props: { [any]: any }): CanvasGroup return nil :: any end

--[=[
	Creates and owns a UICorner through the `Corner` alias.
]=]
function Scope:Corner(props: { [any]: any }): UICorner return nil :: any end

--[=[
	Creates and owns a UIPadding through the `Padding` alias.
]=]
function Scope:Padding(props: { [any]: any }): UIPadding return nil :: any end

--[=[
	Creates and owns a UIListLayout through the `ListLayout` alias.
]=]
function Scope:ListLayout(props: { [any]: any }): UIListLayout return nil :: any end

-- State

--[=[
	@prop Type string
	@within State
	@readonly

	Wrapper family such as Value, Computed, Derived, Async, or Reducer.
]=]
State.Type = ""

--[=[
	Reads and tracks the state inside a Computed or Effect.
]=]
function State:Get(): any return nil end

--[=[
	Reads without adding a dependency edge.
]=]
function State:Peek(): any return nil end

--[=[
	Replaces mutable state. Read-only wrappers ignore this call.
]=]
function State:Set(value: any) end

--[=[
	Updates mutable state from its current value. Read-only wrappers ignore it.
]=]
function State:Update(updater: (any) -> any) end

--[=[
	Creates an owned transformed Computed State.
]=]
function State:Map(transformer: (any) -> any): State return State end

--[=[
	Creates an owned rate-limited Computed view.
]=]
function State:Throttle(seconds: number): State return State end

--[=[
	Creates an owned settled Computed view.
]=]
function State:Debounce(seconds: number): State return State end

--[=[
	Releases this graph node before normal scope teardown. Repeated calls are
	ignored.
]=]
function State:Destroy() end

-- AnimationState

--[=[
	@prop Type string
	@within AnimationState
	@readonly

	`WeaveSpring` or `WeaveTween`.
]=]
AnimationState.Type = ""

--[=[
	Tracked read of the current animated value.
]=]
function AnimationState:Get(): any return nil end

--[=[
	Untracked read of the current animated value.
]=]
function AnimationState:Peek(): any return nil end

--[=[
	Creates a mapped Computed state from the animation.
]=]
function AnimationState:Map(transformer: (any) -> any): State return State end

--[=[
	Creates a throttled Computed view.
]=]
function AnimationState:Throttle(seconds: number): State return State end

--[=[
	Creates a debounced Computed view.
]=]
function AnimationState:Debounce(seconds: number): State return State end

--[=[
	Resumes or forces target processing.
]=]
function AnimationState:Awake() end

--[=[
	Changes Spring speed and wakes it. Available on Springs.
]=]
function AnimationState:SetSpeed(speed: number) end

--[=[
	Changes Spring damping and wakes it. Available on Springs.
]=]
function AnimationState:SetDamping(damping: number) end

--[=[
	Writes Tween's current interpolation value. Normally changed internally;
	application code should write the target State.
]=]
function AnimationState:Set(value: any) end

--[=[
	Stops animation work, disconnects the target, and releases the graph node.
]=]
function AnimationState:Destroy() end

-- AsyncResult

--[=[
	@prop Status string
	@within AsyncResult
	@readonly

	`Pending`, `Resolved`, or `Rejected`.
]=]
AsyncResult.Status = "Pending"

--[=[
	@prop Value any
	@within AsyncResult
	@readonly

	Producer result when resolved.
]=]
AsyncResult.Value = nil :: any

--[=[
	@prop Error any
	@within AsyncResult
	@readonly

	Thrown producer value when rejected.
]=]
AsyncResult.Error = nil :: any

-- Context and refs

--[=[
	@prop DefaultValue any
	@within Context
	@readonly

	Fallback returned when no non-nil value is provided.
]=]
Context.DefaultValue = nil :: any

--[=[
	Returns the held Instance or nil.
]=]
function Ref:Get(): Instance? return nil end

--[=[
	Replaces the held value. Reconciler ref bindings call this automatically.
]=]
function Ref:Set(value: Instance?) end

--[=[
	Runs the lazy factory at most once and returns the cached result.
]=]
function LazyRef:Preload(): any return nil end

-- Built-in components

--[=[
	Creates a TextButton with owned hovering and pressed state. Optional props
	include HoverState, PressState, and ordinary TextButton props.
]=]
function Components.Button(scope: Scope, props: { [any]: any }): TextButton return nil :: any end

--[=[
	Creates a Frame with UIListLayout. Component props include Direction, Wrap,
	Justify, Align, Gap, and Children.
]=]
function Components.Flex(scope: Scope, props: { [any]: any }): Frame return nil :: any end

--[=[
	Creates a TextBox with optional TextState, OnChange, and OnSubmit behavior.
]=]
function Components.TextInput(scope: Scope, props: { [any]: any }): TextBox return nil :: any end

--[=[
	Creates hover content through a Portal. Target and PortalTarget Instances are
	required; Content or Children supplies the tooltip body.
]=]
function Components.Tooltip(scope: Scope, props: { [any]: any }): any return nil end

--[=[
	Creates a fixed-row-height ScrollingFrame that renders only the visible
	range. Required props: Items and RenderItem; ItemHeight defaults to 50.
]=]
function Components.VirtualList(scope: Scope, props: { [any]: any }): ScrollingFrame return nil :: any end

-- Utility return controllers

--[=[
	@prop Values State
	@within Form
	@readonly
	Current field dictionary.
]=]
Form.Values = State
--[=[
	@prop Errors State
	@within Form
	@readonly
	Current field-error dictionary.
]=]
Form.Errors = State
--[=[
	@prop Touched State
	@within Form
	@readonly
	Current touched-field dictionary.
]=]
Form.Touched = State
--[=[
	Writes a field value and marks it touched.
]=]
function Form.Update(key: string, value: any) end
--[=[
	Writes one field error.
]=]
function Form.SetError(key: string, errorValue: any) end
--[=[
	Returns a command that invokes the callback with current values.
]=]
function Form.Submit(callback: ({ [string]: any }) -> ()): () -> () return function() end end

--[=[
	@prop State State
	@within Store
	@readonly
	Complete store state.
]=]
Store.State = State
--[=[
	Dispatches a named action through middleware.
]=]
function Store.Dispatch(actionName: string, ...: any) end
--[=[
	Creates an equality-gated Computed slice.
]=]
function Store.Select(selector: (any) -> any, equals: ((any, any) -> boolean)?): State return State end

--[=[
	@prop data State
	@within Resource
	@readonly
	Latest cached or fetched data.
]=]
Resource.data = State
--[=[
	@prop error State
	@within Resource
	@readonly
	Latest fetch error.
]=]
Resource.error = State
--[=[
	@prop status State
	@within Resource
	@readonly
	`idle`, `loading`, `success`, or `error`.
]=]
Resource.status = State
--[=[
	Fetches the current key while respecting a fresh cache entry.
]=]
function Resource.refetch() end
--[=[
	Clears the current cache entry and fetches again.
]=]
function Resource.invalidate() end

--[=[
	@prop State State
	@within History
	@readonly
	Original tracked mutable state.
]=]
History.State = State
--[=[
	@prop CanUndo State
	@within History
	@readonly
	Whether an undo entry exists.
]=]
History.CanUndo = State
--[=[
	@prop CanRedo State
	@within History
	@readonly
	Whether a redo entry exists.
]=]
History.CanRedo = State
--[=[
	@prop UndoCount State
	@within History
	@readonly
	Reactive undo stack depth.
]=]
History.UndoCount = State
--[=[
	@prop RedoCount State
	@within History
	@readonly
	Reactive redo stack depth.
]=]
History.RedoCount = State
--[=[
	Applies the latest undo entry.
]=]
function History.Undo() end
--[=[
	Applies the latest redo entry.
]=]
function History.Redo() end

--[=[
	@prop Items State
	@within Queue
	@readonly
	Reactive array of retained items.
]=]
Queue.Items = State
--[=[
	@prop Count State
	@within Queue
	@readonly
	Reactive item count.
]=]
Queue.Count = State
--[=[
	Appends an item and removes oldest entries above maxSize.
]=]
function Queue.Push(item: any) end
--[=[
	Removes and returns the oldest item.
]=]
function Queue.Pop(): any return nil end
--[=[
	Returns the oldest item without removal.
]=]
function Queue.PeekFront(): any return nil end
--[=[
	Removes all items.
]=]
function Queue.Clear() end

--[=[
	@prop IsDragging State
	@within DragState
	@readonly
	Boolean held state.
]=]
DragState.IsDragging = State
--[=[
	@prop Position State
	@within DragState
	@readonly
	Accumulated pointer position as Vector2.
]=]
DragState.Position = State
--[=[
	@prop Delta State
	@within DragState
	@readonly
	Current drag delta as Vector2.
]=]
DragState.Delta = State

--[=[
	@prop SwipeDirection State
	@within GestureState
	@readonly
	Last recognized Enum.SwipeDirection.
]=]
GestureState.SwipeDirection = State
--[=[
	@prop IsLongPressing State
	@within GestureState
	@readonly
	Long-press held state.
]=]
GestureState.IsLongPressing = State
--[=[
	@prop GesturePhase State
	@within GestureState
	@readonly
	Current gesture phase string.
]=]
GestureState.GesturePhase = State
--[=[
	@prop TapCount State
	@within GestureState
	@readonly
	Current tap sequence count.
]=]
GestureState.TapCount = State

--[=[
	@prop Position State
	@within FloatState
	@readonly
	Screen-space UDim2 placement for the floating GuiObject.
]=]
FloatState.Position = State
--[=[
	@prop Visible State
	@within FloatState
	@readonly
	Whether both anchor and floating GuiObjects are live.
]=]
FloatState.Visible = State
--[=[
	@prop FloatRef Ref
	@within FloatState
	@readonly
	Pass through `[Weave.ref]` on the floating GuiObject.
]=]
FloatState.FloatRef = Ref

--[=[
	Cancels pending steps and active tweens. Repeated calls are ignored.
]=]
function AnimationController.Cancel() end

--[=[
	Schedules a fresh FLIP measurement and transition.
]=]
function LayoutController.Refresh() end

return Weave
