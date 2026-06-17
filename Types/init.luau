--[=[
	@module Types
	@within Weave.Types

	Shared Luau type definitions for Weave APIs.
]=]

local Base = require(script.Base)
local GuiProps = require(script.GuiProps)
local Scope = require(script.Scope)

export type Value<T> = Base.Value<T>
export type Computed<T> = Base.Computed<T>
export type Spring<T> = Base.Spring<T>
export type Tween<T> = Base.Tween<T>
export type Derived<T> = Base.Derived<T>
export type WState<T> = Base.WState<T>

export type BaseGUIProps = GuiProps.BaseGUIProps
export type ScreenGuiProps = GuiProps.ScreenGuiProps
export type FrameProps = GuiProps.FrameProps
export type ScrollingFrameProps = GuiProps.ScrollingFrameProps
export type TextButtonProps = GuiProps.TextButtonProps
export type TextLabelProps = GuiProps.TextLabelProps
export type TextBoxProps = GuiProps.TextBoxProps
export type ImageButtonProps = GuiProps.ImageButtonProps
export type ImageLabelProps = GuiProps.ImageLabelProps
export type ViewportFrameProps = GuiProps.ViewportFrameProps
export type CanvasGroupProps = GuiProps.CanvasGroupProps
export type VideoFrameProps = GuiProps.VideoFrameProps
export type UIListLayoutProps = GuiProps.UIListLayoutProps
export type UIAspectRatioConstraintProps = GuiProps.UIAspectRatioConstraintProps
export type UIPaddingProps = GuiProps.UIPaddingProps
export type UICornerProps = GuiProps.UICornerProps
export type UIStrokeProps = GuiProps.UIStrokeProps
export type UIGridLayoutProps = GuiProps.UIGridLayoutProps
export type UIScaleProps = GuiProps.UIScaleProps
export type UIGradientProps = GuiProps.UIGradientProps
export type UISizeConstraintProps = GuiProps.UISizeConstraintProps
export type UITextSizeConstraintProps = GuiProps.UITextSizeConstraintProps
export type UIFlexItemProps = GuiProps.UIFlexItemProps
export type BillboardGuiProps = GuiProps.BillboardGuiProps
export type SurfaceGuiProps = GuiProps.SurfaceGuiProps
export type UIPageLayoutProps = GuiProps.UIPageLayoutProps
export type UITableLayoutProps = GuiProps.UITableLayoutProps
export type SelectionBoxProps = GuiProps.SelectionBoxProps
export type SelectionSphereProps = GuiProps.SelectionSphereProps
export type HighlightProps = GuiProps.HighlightProps

export type Scope = Scope.Scope

local Symbol = require(script.Parent.Parent.Symbol)

export type WeaveModule = {
    -- core api
    scope: () -> Scope.Scope,
    children: any,
    onEvent: (string) -> any,
    onChange: (string) -> any,
    bind: any,
    ref: any,
    defineStyle: any,
    createContext: (any) -> any,
    memo: (any) -> any,
    lazy: (factory: () -> any) -> any,
    mount: ((parent: Instance, builderFunc: () -> any) -> (() -> ())) & 
           ((parent: Instance, name: string, builderFunc: () -> any) -> (() -> ())) & 
           ((parent: Instance, props: GuiProps.ScreenGuiProps, builderFunc: () -> any) -> (() -> ())),
           
    value: <T>(initial: T) -> ( () -> T, (T) -> () ),
    computed: <T>(computeFunc: () -> T) -> () -> T,
    derived: <T>(computeFunc: () -> T) -> () -> T,
    spring: <T>(target: () -> T, damping: number?, speed: number?) -> () -> T,
    tween: <T>(target: () -> T, tweenInfo: TweenInfo?) -> () -> T,
    effect: (callback: () -> ()) -> () -> any,
    
    peek: (stateNode: any) -> any,
    destroy: (stateNode: any) -> (),
    isState: (stateNode: any) -> boolean,

    -- legacy pascal case
    Scope: () -> Scope.Scope,
    Children: any,
    OnEvent: (string) -> any,
    OnChange: (string) -> any,
    Bind: any,
    Ref: any,
    DefineStyle: any,
    CreateContext: (any) -> any,
    Memo: (any) -> any,
    Mount: ((parent: Instance, builderFunc: () -> any) -> (() -> ())) & 
           ((parent: Instance, name: string, builderFunc: () -> any) -> (() -> ())) & 
           ((parent: Instance, props: GuiProps.ScreenGuiProps, builderFunc: () -> any) -> (() -> ())),

    Value: any,
    Computed: any,
    Derived: any,
    Spring: any,
    Tween: any,
    Peek: any,
    Destroy: any,
    IsState: any,

    Components: any,
    Debug: boolean,

    -- Helpers
    color3: (r: number, g: number, b: number) -> Color3,
    numberSequence: (keypoints: { { time: number, value: number, envelope: number? } }) -> NumberSequence,
    colorSequence: (keypoints: { { time: number, color: { number } } }) -> ColorSequence,

    -- UI Elements
    ScreenGui: (scope: Scope.Scope, props: GuiProps.ScreenGuiProps) -> ScreenGui,
    Frame: (scope: Scope.Scope, props: GuiProps.FrameProps) -> Frame,
    ScrollingFrame: (scope: Scope.Scope, props: GuiProps.ScrollingFrameProps) -> ScrollingFrame,
    TextButton: (scope: Scope.Scope, props: GuiProps.TextButtonProps) -> TextButton,
    TextLabel: (scope: Scope.Scope, props: GuiProps.TextLabelProps) -> TextLabel,
    TextBox: (scope: Scope.Scope, props: GuiProps.TextBoxProps) -> TextBox,
    ImageButton: (scope: Scope.Scope, props: GuiProps.ImageButtonProps) -> ImageButton,
    ImageLabel: (scope: Scope.Scope, props: GuiProps.ImageLabelProps) -> ImageLabel,
    ViewportFrame: (scope: Scope.Scope, props: GuiProps.ViewportFrameProps) -> ViewportFrame,
    CanvasGroup: (scope: Scope.Scope, props: GuiProps.CanvasGroupProps) -> CanvasGroup,
    VideoFrame: (scope: Scope.Scope, props: GuiProps.VideoFrameProps) -> VideoFrame,

    -- Layouts
    ListLayout: (scope: Scope.Scope, props: GuiProps.UIListLayoutProps) -> UIListLayout,
    GridLayout: (scope: Scope.Scope, props: GuiProps.UIGridLayoutProps) -> UIGridLayout,
    PageLayout: (scope: Scope.Scope, props: GuiProps.UIPageLayoutProps) -> UIPageLayout,
    TableLayout: (scope: Scope.Scope, props: GuiProps.UITableLayoutProps) -> UITableLayout,

    -- Constraints & Modifiers
    AspectRatio: (scope: Scope.Scope, props: GuiProps.UIAspectRatioConstraintProps) -> UIAspectRatioConstraint,
    SizeConstraint: (scope: Scope.Scope, props: GuiProps.UISizeConstraintProps) -> UISizeConstraint,
    TextSizeConstraint: (scope: Scope.Scope, props: GuiProps.UITextSizeConstraintProps) -> UITextSizeConstraint,
    FlexItem: (scope: Scope.Scope, props: GuiProps.UIFlexItemProps) -> UIFlexItem,

    -- Decorators
    Padding: (scope: Scope.Scope, props: GuiProps.UIPaddingProps) -> UIPadding,
    Corner: (scope: Scope.Scope, props: GuiProps.UICornerProps) -> UICorner,
    Stroke: (scope: Scope.Scope, props: GuiProps.UIStrokeProps) -> UIStroke,
    Gradient: (scope: Scope.Scope, props: GuiProps.UIGradientProps) -> UIGradient,
    Scale: (scope: Scope.Scope, props: UIScaleProps) -> UIScale,

    -- 3D/World UI
    Billboard: (scope: Scope.Scope, props: GuiProps.BillboardGuiProps) -> BillboardGui,
    Surface: (scope: Scope.Scope, props: GuiProps.SurfaceGuiProps) -> SurfaceGui,

    -- Selection Visuals
    SelectionBox: (scope: Scope.Scope, props: GuiProps.SelectionBoxProps) -> SelectionBox,
    SelectionSphere: (scope: Scope.Scope, props: GuiProps.SelectionSphereProps) -> SelectionSphere,
    Highlight: (scope: Scope.Scope, props: GuiProps.HighlightProps) -> Highlight,
}

local NodeType = {
    State = Symbol("WeaveState"),
    Rendering = Symbol("WeaveRendering"),
    Component = Symbol("WeaveComponent"),
}

return {
    NodeType = NodeType
}
