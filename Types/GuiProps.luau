local Base = require(script.Parent.Base)
type WState<T> = Base.WState<T>
type UniqueId = string
type ContentId = string
type SecurityCapabilities = any
type Font = any

export type BaseGUIProps = {
    Active: WState<boolean>?,
    AnchorPoint: WState<Vector2>?,
    AutoLocalize: WState<boolean>?,
    AutomaticSize: WState<Enum.AutomaticSize>?,
    BackgroundColor3: WState<Color3>?,
    BackgroundTransparency: WState<number>?,
    BorderColor3: WState<Color3>?,
    BorderMode: WState<Enum.BorderMode>?,
    BorderSizePixel: WState<number>?,
    ClipsDescendants: WState<boolean>?,
    Interactable: WState<boolean>?,
    LayoutOrder: WState<number>?,
    NextSelectionDown: WState<Instance>?,
    NextSelectionLeft: WState<Instance>?,
    NextSelectionRight: WState<Instance>?,
    NextSelectionUp: WState<Instance>?,
    Position: WState<UDim2>?,
    RootLocalizationTable: WState<Instance>?,
    Rotation: WState<number>?,
    Selectable: WState<boolean>?,
    SelectionBehaviorDown: WState<Enum.SelectionBehavior>?,
    SelectionBehaviorLeft: WState<Enum.SelectionBehavior>?,
    SelectionBehaviorRight: WState<Enum.SelectionBehavior>?,
    SelectionBehaviorUp: WState<Enum.SelectionBehavior>?,
    SelectionGroup: WState<boolean>?,
    SelectionImageObject: WState<Instance>?,
    SelectionOrder: WState<number>?,
    Size: WState<UDim2>?,
    SizeConstraint: WState<Enum.SizeConstraint>?,
    Visible: WState<boolean>?,
    ZIndex: WState<number>?,

    -- Implicit Events
    OnInputBegan: ((InputObject) -> ())?,
    OnInputEnded: ((InputObject) -> ())?,
    OnInputChanged: ((InputObject) -> ())?,
    OnMouseEnter: ((number, number) -> ())?,
    OnMouseLeave: ((number, number) -> ())?,
    OnMouseMoved: ((number, number) -> ())?,
    OnMouseWheelForward: ((number, number) -> ())?,
    OnMouseWheelBackward: ((number, number) -> ())?,
    OnSelectionGained: (() -> ())?,
    OnSelectionLost: (() -> ())?,
    OnTouchTap: ((Vector2, boolean) -> ())?,
    OnTouchMoved: ((InputObject) -> ())?,
    OnTouchSwipe: ((Enum.SwipeDirection, number) -> ())?,
    OnTouchLongPress: ((Vector2, Enum.UserInputState) -> ())?,
}

export type InstanceProps = {
    Archivable: WState<boolean>?,
    Capabilities: WState<SecurityCapabilities>?,
    Name: WState<string>?,
    Parent: WState<Instance>?,
    Sandboxed: WState<boolean>?,
    UniqueId: WState<UniqueId>?,
}

export type TextProps = {
    FontFace: WState<Font>?,
    LineHeight: WState<number>?,
    MaxVisibleGraphemes: WState<number>?,
    OpenTypeFeatures: WState<string>?,
    RichText: WState<boolean>?,
    Text: WState<string>?,
    TextColor3: WState<Color3>?,
    TextDirection: WState<Enum.TextDirection>?,
    TextScaled: WState<boolean>?,
    TextSize: WState<number>?,
    TextStrokeColor3: WState<Color3>?,
    TextStrokeTransparency: WState<number>?,
    TextTransparency: WState<number>?,
    TextTruncate: WState<Enum.TextTruncate>?,
    TextWrapped: WState<boolean>?,
    TextXAlignment: WState<Enum.TextXAlignment>?,
    TextYAlignment: WState<Enum.TextYAlignment>?,
}

export type ImageProps = {
    Image: WState<ContentId>?,
    ImageColor3: WState<Color3>?,
    ImageContent: WState<string>?,
    ImageRectOffset: WState<Vector2>?,
    ImageRectSize: WState<Vector2>?,
    ImageTransparency: WState<number>?,
    ResampleMode: WState<Enum.ResamplerMode>?,
    ScaleType: WState<Enum.ScaleType>?,
    SliceCenter: WState<Rect>?,
    SliceScale: WState<number>?,
    TileSize: WState<UDim2>?,
}

export type ButtonProps = {
    AutoButtonColor: WState<boolean>?,
    HoverHapticEffect: WState<Instance>?,
    Modal: WState<boolean>?,
    PressHapticEffect: WState<Instance>?,
    Selected: WState<boolean>?,
    Style: WState<Enum.ButtonStyle>?,
    
    -- Specific Events
    OnActivated: ((InputObject, number) -> ())?,
    OnMouseButton1Click: (() -> ())?,
    OnMouseButton1Down: ((number, number) -> ())?,
    OnMouseButton1Up: ((number, number) -> ())?,
    OnMouseButton2Click: (() -> ())?,
    OnMouseButton2Down: ((number, number) -> ())?,
    OnMouseButton2Up: ((number, number) -> ())?,
}

export type ScreenGuiProps = InstanceProps & {
    AutoLocalize: WState<boolean>?,
    ClipToDeviceSafeArea: WState<boolean>?,
    DisplayOrder: WState<number>?,
    Enabled: WState<boolean>?,
    IgnoreGuiInset: WState<boolean>?,
    ResetOnSpawn: WState<boolean>?,
    RootLocalizationTable: WState<Instance>?,
    SafeAreaCompatibility: WState<Enum.SafeAreaCompatibility>?,
    ScreenInsets: WState<Enum.ScreenInsets>?,
    SelectionBehaviorDown: WState<Enum.SelectionBehavior>?,
    SelectionBehaviorLeft: WState<Enum.SelectionBehavior>?,
    SelectionBehaviorRight: WState<Enum.SelectionBehavior>?,
    SelectionBehaviorUp: WState<Enum.SelectionBehavior>?,
    SelectionGroup: WState<boolean>?,
    ZIndexBehavior: WState<Enum.ZIndexBehavior>?,
}

export type FrameProps = BaseGUIProps & {
    Style: WState<Enum.FrameStyle>?,
}

export type ScrollingFrameProps = BaseGUIProps & {
    AutomaticCanvasSize: WState<Enum.AutomaticSize>?,
    BottomImage: WState<ContentId>?,
    BottomImageContent: WState<string>?,
    CanvasPosition: WState<Vector2>?,
    CanvasSize: WState<UDim2>?,
    ElasticBehavior: WState<Enum.ElasticBehavior>?,
    HorizontalScrollBarInset: WState<Enum.ScrollBarInset>?,
    MidImage: WState<ContentId>?,
    MidImageContent: WState<string>?,
    ScrollBarImageColor3: WState<Color3>?,
    ScrollBarImageTransparency: WState<number>?,
    ScrollBarThickness: WState<number>?,
    ScrollingDirection: WState<Enum.ScrollingDirection>?,
    ScrollingEnabled: WState<boolean>?,
    TopImage: WState<ContentId>?,
    TopImageContent: WState<string>?,
    VerticalScrollBarInset: WState<Enum.ScrollBarInset>?,
    VerticalScrollBarPosition: WState<Enum.VerticalScrollBarPosition>?,
    
    -- Specific Events
    OnChangeCanvasPosition: ((Vector2) -> ())?,
}

export type TextButtonProps = BaseGUIProps & TextProps & ButtonProps
export type TextLabelProps = BaseGUIProps & TextProps
export type TextBoxProps = BaseGUIProps & TextProps & {
    ClearTextOnFocus: WState<boolean>?,
    CursorPosition: WState<number>?,
    MultiLine: WState<boolean>?,
    PlaceholderColor3: WState<Color3>?,
    PlaceholderText: WState<string>?,
    SelectionStart: WState<number>?,
    ShowNativeInput: WState<boolean>?,
    TextEditable: WState<boolean>?,
    
    -- Specific Events
    OnFocusLost: ((boolean, InputObject) -> ())?,
    OnFocused: (() -> ())?,
}

export type ImageButtonProps = BaseGUIProps & ImageProps & ButtonProps & {
    HoverImage: WState<ContentId>?,
    HoverImageContent: WState<string>?,
    PressedImage: WState<ContentId>?,
    PressedImageContent: WState<string>?,
}

export type ImageLabelProps = BaseGUIProps & ImageProps

export type ViewportFrameProps = BaseGUIProps & {
    Ambient: WState<Color3>?,
    CurrentCamera: WState<Instance>?,
    ImageColor3: WState<Color3>?,
    ImageTransparency: WState<number>?,
    LightColor: WState<Color3>?,
    LightDirection: WState<Vector3>?,
}

export type CanvasGroupProps = BaseGUIProps & {
    GroupColor3: WState<Color3>?,
    GroupTransparency: WState<number>?,
}

export type VideoFrameProps = BaseGUIProps & {
    Looped: WState<boolean>?,
    Playing: WState<boolean>?,
    TimePosition: WState<number>?,
    Video: WState<ContentId>?,
    VideoContent: WState<string>?,
    Volume: WState<number>?,
}

export type UIListLayoutProps = InstanceProps & {
    FillDirection: WState<Enum.FillDirection>?,
    HorizontalAlignment: WState<Enum.HorizontalAlignment>?,
    HorizontalFlex: WState<Enum.UIFlexAlignment>?,
    ItemLineAlignment: WState<Enum.ItemLineAlignment>?,
    Padding: WState<UDim>?,
    Spacing: WState<UDim>?,
    SortOrder: WState<Enum.SortOrder>?,
    VerticalAlignment: WState<Enum.VerticalAlignment>?,
    VerticalFlex: WState<Enum.UIFlexAlignment>?,
    Wraps: WState<boolean>?,
}

export type UIAspectRatioConstraintProps = InstanceProps & {
    AspectRatio: WState<number>?,
    AspectType: WState<Enum.AspectType>?,
    DominantAxis: WState<Enum.DominantAxis>?,
}

export type UIPaddingProps = InstanceProps & {
    PaddingBottom: WState<UDim>?,
    PaddingLeft: WState<UDim>?,
    PaddingRight: WState<UDim>?,
    PaddingTop: WState<UDim>?,
    offset: {number}?,
    scale: {number}?,
}

export type UICornerProps = InstanceProps & {
    CornerRadius: WState<UDim>?,
    Radius: WState<UDim>?,
}

export type UIStrokeProps = InstanceProps & {
    ApplyStrokeMode: WState<Enum.ApplyStrokeMode>?,
    BorderOffset: WState<UDim>?,
    BorderStrokePosition: WState<Enum.BorderStrokePosition>?,
    Color: WState<Color3>?,
    Enabled: WState<boolean>?,
    LineJoinMode: WState<Enum.LineJoinMode>?,
    StrokeSizingMode: WState<Enum.StrokeSizingMode>?,
    Thickness: WState<number>?,
    Transparency: WState<number>?,
    ZIndex: WState<number>?,
}

export type UIGridLayoutProps = InstanceProps & {
    CellPadding: WState<UDim2>?,
    Spacing: WState<UDim2>?,
    CellSize: WState<UDim2>?,
    FillDirection: WState<Enum.FillDirection>?,
    FillDirectionMaxCells: WState<number>?,
    HorizontalAlignment: WState<Enum.HorizontalAlignment>?,
    SortOrder: WState<Enum.SortOrder>?,
    StartCorner: WState<Enum.StartCorner>?,
    VerticalAlignment: WState<Enum.VerticalAlignment>?,
}

export type UIScaleProps = InstanceProps & {
    Scale: WState<number>?,
}

export type UIGradientProps = InstanceProps & {
    Color: WState<ColorSequence>?,
    Enabled: WState<boolean>?,
    Offset: WState<Vector2>?,
    Rotation: WState<number>?,
    Transparency: WState<NumberSequence>?,
}

export type UISizeConstraintProps = InstanceProps & {
    MaxSize: WState<Vector2>?,
    MinSize: WState<Vector2>?,
}

export type UITextSizeConstraintProps = InstanceProps & {
    MaxTextSize: WState<number>?,
    MinTextSize: WState<number>?,
}

export type UIFlexItemProps = InstanceProps & {
    FlexMode: WState<Enum.UIFlexMode>?,
    GrowRatio: WState<number>?,
    ItemLineAlignment: WState<Enum.ItemLineAlignment>?,
    ShrinkRatio: WState<number>?,
}

export type BillboardGuiProps = InstanceProps & {
    Active: WState<boolean>?,
    Adornee: WState<Instance>?,
    AlwaysOnTop: WState<boolean>?,
    Brightness: WState<number>?,
    ClipsDescendants: WState<boolean>?,
    CurrentDistance: WState<number>?,
    DistanceLowerLimit: WState<number>?,
    DistanceStep: WState<number>?,
    DistanceUpperLimit: WState<number>?,
    Enabled: WState<boolean>?,
    ExtentsOffset: WState<Vector3>?,
    ExtentsOffsetWorldSpace: WState<Vector3>?,
    LightInfluence: WState<number>?,
    MaxDistance: WState<number>?,
    PlayerToHideFrom: WState<Instance>?,
    ResetOnSpawn: WState<boolean>?,
    Size: WState<UDim2>?,
    SizeOffset: WState<Vector2>?,
    StudsOffset: WState<Vector3>?,
    StudsOffsetWorldSpace: WState<Vector3>?,
    ZIndexBehavior: WState<Enum.ZIndexBehavior>?,
}

export type SurfaceGuiProps = InstanceProps & {
    Active: WState<boolean>?,
    Adornee: WState<Instance>?,
    AlwaysOnTop: WState<boolean>?,
    Brightness: WState<number>?,
    CanvasSize: WState<Vector2>?,
    ClipsDescendants: WState<boolean>?,
    Enabled: WState<boolean>?,
    Face: WState<Enum.NormalId>?,
    LightInfluence: WState<number>?,
    MaxDistance: WState<number>?,
    PixelsPerStud: WState<number>?,
    ResetOnSpawn: WState<boolean>?,
    SizingMode: WState<Enum.SurfaceGuiSizingMode>?,
    ToolPunchThroughDistance: WState<number>?,
    ZIndexBehavior: WState<Enum.ZIndexBehavior>?,
    ZOffset: WState<number>?,
}

export type UIPageLayoutProps = InstanceProps & {
    AnimationDirection: WState<any>?,
    Animated: WState<boolean>?,
    CircularEnabled: WState<boolean>?,
    EasingDirection: WState<Enum.EasingDirection>?,
    EasingStyle: WState<Enum.EasingStyle>?,
    FillDirection: WState<Enum.FillDirection>?,
    GamepadInputEnabled: WState<boolean>?,
    HorizontalAlignment: WState<Enum.HorizontalAlignment>?,
    Infinite: WState<boolean>?,
    Padding: WState<UDim>?,
    ScrollWheelInputEnabled: WState<boolean>?,
    SortOrder: WState<Enum.SortOrder>?,
    TouchInputEnabled: WState<boolean>?,
    TweenTime: WState<number>?,
    VerticalAlignment: WState<Enum.VerticalAlignment>?,
}

export type UITableLayoutProps = InstanceProps & {
    FillDirection: WState<Enum.FillDirection>?,
    FillEmptySpaceColumns: WState<boolean>?,
    FillEmptySpaceRows: WState<boolean>?,
    HorizontalAlignment: WState<Enum.HorizontalAlignment>?,
    MajorAxis: WState<Enum.TableMajorAxis>?,
    Padding: WState<UDim2>?,
    SortOrder: WState<Enum.SortOrder>?,
    VerticalAlignment: WState<Enum.VerticalAlignment>?,
}

export type SelectionBoxProps = InstanceProps & {
    Adornee: WState<Instance>?,
    Color3: WState<Color3>?,
    Enabled: WState<boolean>?,
    LineThickness: WState<number>?,
    SurfaceColor3: WState<Color3>?,
    SurfaceTransparency: WState<number>?,
    Transparency: WState<number>?,
    Visible: WState<boolean>?,
}

export type SelectionSphereProps = InstanceProps & {
    Adornee: WState<Instance>?,
    Color3: WState<Color3>?,
    Enabled: WState<boolean>?,
    SurfaceColor3: WState<Color3>?,
    SurfaceTransparency: WState<number>?,
    Transparency: WState<number>?,
    Visible: WState<boolean>?,
}

export type HighlightProps = InstanceProps & {
    Adornee: WState<Instance>?,
    DepthMode: WState<Enum.HighlightDepthMode>?,
    Enabled: WState<boolean>?,
    FillColor: WState<Color3>?,
    FillTransparency: WState<number>?,
    OutlineColor: WState<Color3>?,
    OutlineTransparency: WState<number>?,
}

return {}
