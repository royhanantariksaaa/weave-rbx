--!optimize 2
--!nocheck
--[=[
	@module Scope
	@within Weave.Types

	Shared Luau type definitions for Weave APIs.
]=]

local Base = require(script.Parent.Base)
local GuiProps = require(script.Parent.GuiProps)

type WState<T> = Base.WState<T>
type Value<T> = Base.Value<T>
type Computed<T> = Base.Computed<T>
type Spring<T> = Base.Spring<T>
type Tween<T> = Base.Tween<T>
type Derived<T> = Base.Derived<T>

type ScreenGuiProps = GuiProps.ScreenGuiProps
type FrameProps = GuiProps.FrameProps
type ScrollingFrameProps = GuiProps.ScrollingFrameProps
type TextButtonProps = GuiProps.TextButtonProps
type TextLabelProps = GuiProps.TextLabelProps
type TextBoxProps = GuiProps.TextBoxProps
type ImageButtonProps = GuiProps.ImageButtonProps
type ImageLabelProps = GuiProps.ImageLabelProps
type ViewportFrameProps = GuiProps.ViewportFrameProps
type CanvasGroupProps = GuiProps.CanvasGroupProps
type VideoFrameProps = GuiProps.VideoFrameProps
type UIListLayoutProps = GuiProps.UIListLayoutProps
type UIAspectRatioConstraintProps = GuiProps.UIAspectRatioConstraintProps
type UIPaddingProps = GuiProps.UIPaddingProps
type UICornerProps = GuiProps.UICornerProps
type UIStrokeProps = GuiProps.UIStrokeProps
type UIGridLayoutProps = GuiProps.UIGridLayoutProps
type UIScaleProps = GuiProps.UIScaleProps
type UIGradientProps = GuiProps.UIGradientProps
type UISizeConstraintProps = GuiProps.UISizeConstraintProps
type UITextSizeConstraintProps = GuiProps.UITextSizeConstraintProps
type UIFlexItemProps = GuiProps.UIFlexItemProps
type UIPageLayoutProps = GuiProps.UIPageLayoutProps
type UITableLayoutProps = GuiProps.UITableLayoutProps
type BillboardGuiProps = GuiProps.BillboardGuiProps
type SurfaceGuiProps = GuiProps.SurfaceGuiProps
type SelectionBoxProps = GuiProps.SelectionBoxProps
type SelectionSphereProps = GuiProps.SelectionSphereProps
type HighlightProps = GuiProps.HighlightProps
export type Scope = {
    Value: <T>(initialValue: T, options: {validate: ((T) -> T)?}?) -> Value<T>,
    Computed: <T>(callback: (use: <U>(state: Value<U> | Computed<U> | Spring<U> | Tween<U> | U) -> U) -> T) -> Computed<T>,
    Spring: <T>(targetState: Value<T> | Computed<T>, speed: number?, damping: number?) -> Spring<T>,
    Tween: <T>(targetState: Value<T> | Computed<T>, tweenInfo: TweenInfo?) -> Tween<T>,
    Derived: <T>(callback: (use: <U>(state: any) -> U) -> T) -> Derived<T>,
    Show: <T>(conditionState: Value<boolean> | Computed<boolean>, builderFunc: (scope: Scope) -> any) -> any,
    Switch: <T>(state: Value<T> | Computed<T>, cases: {[T | string]: (scope: Scope, value: T) -> any}) -> any,
    ErrorBoundary: (builderFunc: (scope: Scope) -> any, fallbackFunc: ((scope: Scope, err: string) -> any)?) -> any,
    OnDestroy: (callback: () -> ()) -> (),
    Portal: (props: {Target: Instance | WState<Instance>, [any]: any}) -> any,
    
    Effect: (callback: (use: <U>(state: any) -> U) -> ()) -> any,
    ForValues: <T>(sourceState: any, renderFunc: (scope: Scope, value: T, index: number) -> Instance) -> any,
    Transition: (conditionState: Value<boolean> | Computed<boolean>, buildFunc: (scope: Scope) -> any, transitionProps: {Enter: ((instances: {Instance}) -> ())?, Exit: ((instances: {Instance}, done: () -> ()) -> ())?}?) -> any,
    
    Ref: () -> { Get: (self: any) -> Instance?, Set: (self: any, v: Instance) -> () },
    Watch: <T>(state: WState<T>, callback: (new: T, old: T) -> ()) -> any,
    Fragment: (children: {any}) -> any,
    Lazy: (factory: () -> any) -> any,
    
    -- SolidJS Aliases
    createSignal: <T>(initial: T) -> (Value<T>, (T) -> ()),
    createMemo: <T>(callback: (use: <U>(state: Value<U> | Computed<U> | Spring<U> | Tween<U> | U) -> U) -> T) -> Computed<T>,
    createEffect: (callback: (use: <U>(state: any) -> U) -> ()) -> Computed<any>,
    onCleanup: (callback: () -> ()) -> (),
    Animate: (target: Instance, steps: {{Property: string, To: any, Duration: number?, Delay: number?, EasingStyle: Enum.EasingStyle?, EasingDirection: Enum.EasingDirection?}}) -> { Cancel: () -> () },
    AnimateLayout: (target: Instance, options: {Duration: number?, EasingStyle: Enum.EasingStyle?, EasingDirection: Enum.EasingDirection?}?) -> { Refresh: () -> () },
    AnimatePresence: <T>(sourceState: any, renderFunc: (scope: Scope, value: T, index: number) -> Instance, options: {Exit: (scope: Scope, value: T, finish: () -> ()) -> ()}) -> any,
 
	-- Utilities
    Store: <S, A>(initial: S, config: { actions: A, middleware: any? }) -> { State: Value<S>, Dispatch: any, Select: (fn: (S) -> any) -> Computed<any> },
    Resource: <T>(keyState: WState<string>, fetcher: () -> T, config: any?) -> { Data: Value<T?>, Error: Value<string?>, Status: Value<string>, Refetch: () -> (), Invalidate: () -> () },
    Queue: <T>(options: { maxSize: number? }) -> { Push: (T) -> (), Pop: () -> T?, PeekFront: () -> T?, Items: Value<{T}>, Count: Value<number> },
    Float: (anchorRef: { Get: (self: any) -> Instance? }, options: any) -> { Position: Value<UDim2>, Visible: Value<boolean> },
    Parallax: (scrollState: WState<number|Vector2>, layers: {{instance: Instance, speed: number}}) -> (),
    Snapshot: (stateMap: {[string]: WState<any>}) -> {[string]: any},
    Restore: (stateMap: {[string]: WState<any>}, data: {[string]: any}) -> (),
    Gesture: (instance: Instance, options: { swipe: boolean?, longPress: number?, doubleTap: number? }?) -> { SwipeDirection: Value<Enum.SwipeDirection?>, IsLongPressing: Value<boolean>, GesturePhase: Value<string>, TapCount: Value<number> },
    Accessible: (instance: Instance, options: { role: string?, selectionOrder: number?, focusTrap: boolean? }?) -> Instance,
    FocusGroup: (instances: {Instance}) -> {Instance},
    
    Batch: (callback: () -> ()) -> (),
    Selector: <T, U>(state: WState<T>, selectorFn: (T) -> U, equalsFn: ((U, U) -> boolean)?) -> Computed<U>,
    Combine: <T>(...any) -> Computed<T>,
    Previous: <T>(state: WState<T>) -> Value<T?>,
    Timer: (interval: number) -> Value<number>,
    Observe: <T>(state: WState<T>, callback: (new: T, old: T?) -> ()) -> any,
    Defer: (callback: () -> ()) -> any,
    FromEvent: <T>(signal: RBXScriptSignal, mapper: (...any) -> T) -> Value<T>,
    BindAction: (actionName: string, keyCode: Enum.KeyCode | Enum.UserInputType) -> Value<boolean>,
    Gate: <T>(state: WState<T>, predicate: (T) -> boolean) -> Value<T>,
    History: <T>(state: Value<T>, options: { maxDepth: number? }?) -> { State: Value<T>, Undo: () -> (), Redo: () -> (), CanUndo: Value<boolean>, CanRedo: Value<boolean> },
    MediaQuery: (breakpoints: {[string]: number}) -> Value<string>,
    Drag: (instance: Instance, options: { axis: string? }?) -> { IsDragging: Value<boolean>, Position: Value<UDim2>, Delta: Value<Vector2> },
    Stagger: <T>(sourceState: any, renderFunc: (scope: Scope, value: T, index: number, alphaState: Value<number>) -> Instance, options: { delay: number? }?) -> any,
    
    Provide: ((key: string, value: any) -> ()) & ((context: {[string]: any}) -> ()),
    Consume: (key: string) -> any,
    
    RegisterComponent: (name: string, componentFunc: (scope: Scope, props: {[any]: any}) -> any) -> (),
    Hydrate: (instance: Instance, props: {[any]: any}) -> Instance,
    Destroy: (self: Scope) -> (),

    ScreenGui: (self: Scope, props: ScreenGuiProps) -> ScreenGui,
    Frame: (self: Scope, props: FrameProps) -> Frame,
    ScrollingFrame: (self: Scope, props: ScrollingFrameProps) -> ScrollingFrame,
    TextButton: (self: Scope, props: TextButtonProps) -> TextButton,
    TextLabel: (self: Scope, props: TextLabelProps) -> TextLabel,
    TextBox: (self: Scope, props: TextBoxProps) -> TextBox,
    ImageButton: (self: Scope, props: ImageButtonProps) -> ImageButton,
    ImageLabel: (self: Scope, props: ImageLabelProps) -> ImageLabel,
    ViewportFrame: (self: Scope, props: ViewportFrameProps) -> ViewportFrame,
    CanvasGroup: (self: Scope, props: CanvasGroupProps) -> CanvasGroup,
    VideoFrame: (self: Scope, props: VideoFrameProps) -> VideoFrame,
    ListLayout: (self: Scope, props: UIListLayoutProps) -> UIListLayout,
    AspectRatio: (self: Scope, props: UIAspectRatioConstraintProps) -> UIAspectRatioConstraint,
    Padding: (self: Scope, props: UIPaddingProps) -> UIPadding,
    Corner: (self: Scope, props: UICornerProps) -> UICorner,
    Stroke: (self: Scope, props: UIStrokeProps) -> UIStroke,
    GridLayout: (self: Scope, props: UIGridLayoutProps) -> UIGridLayout,
    Scale: (self: Scope, props: UIScaleProps) -> UIScale,
    Gradient: (self: Scope, props: UIGradientProps) -> UIGradient,
    SizeConstraint: (self: Scope, props: UISizeConstraintProps) -> UISizeConstraint,
    TextSizeConstraint: (self: Scope, props: UITextSizeConstraintProps) -> UITextSizeConstraint,
    FlexItem: (self: Scope, props: UIFlexItemProps) -> UIFlexItem,
    PageLayout: (self: Scope, props: UIPageLayoutProps) -> UIPageLayout,
    TableLayout: (self: Scope, props: UITableLayoutProps) -> UITableLayout,

    -- 3D / World UI
    BillboardGui: (self: Scope, props: BillboardGuiProps) -> BillboardGui,
    SurfaceGui: (self: Scope, props: SurfaceGuiProps) -> SurfaceGui,
    Billboard: (self: Scope, props: BillboardGuiProps) -> BillboardGui,
    Surface: (self: Scope, props: SurfaceGuiProps) -> SurfaceGui,

    -- Selection & Highlight
    SelectionBox: (self: Scope, props: SelectionBoxProps) -> SelectionBox,
    SelectionSphere: (self: Scope, props: SelectionSphereProps) -> SelectionSphere,
    Highlight: (self: Scope, props: HighlightProps) -> Highlight,

    [string]: (self: Scope, props: {[any]: any} | any) -> any
}

return {}
