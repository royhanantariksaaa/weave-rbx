--!optimize 2
--[=[
	@module Base
	@within Weave.Types

	Shared Luau type definitions for Weave APIs.
]=]

type UniqueId = string
type ContentId = string
type SecurityCapabilities = any
type Font = any

type StateMetatable<T> = {
    __call: (self: any) -> T,
}

type ReadableFields<T> = {
    Type: string,
    Get: (self: any) -> T,
    Peek: (self: any) -> T,
    Map: (self: any, transformer: (T) -> any) -> any,
    Throttle: (self: any, seconds: number) -> any,
    Debounce: (self: any, seconds: number) -> any,
    Destroy: (self: any) -> (),
}

type WritableFields<T> = ReadableFields<T> & {
    Set: (self: any, newValue: T) -> (),
    Update: (self: any, updater: (T) -> T) -> (),
}

export type Value<T> = typeof(setmetatable({} :: WritableFields<T>, {} :: StateMetatable<T>))
export type Computed<T> = typeof(setmetatable({} :: ReadableFields<T>, {} :: StateMetatable<T>))

type SpringFields<T> = ReadableFields<T> & {
    Awake: (self: any) -> (),
    SetSpeed: (self: any, speed: number) -> (),
    SetDamping: (self: any, damping: number) -> (),
}

type TweenFields<T> = ReadableFields<T> & {
    Set: (self: any, newValue: T) -> (),
    Awake: (self: any) -> (),
}

export type Spring<T> = typeof(setmetatable({} :: SpringFields<T>, {} :: StateMetatable<T>))
export type Tween<T> = typeof(setmetatable({} :: TweenFields<T>, {} :: StateMetatable<T>))
export type Derived<T> = typeof(setmetatable({} :: WritableFields<T>, {} :: StateMetatable<T>))

export type AsyncStatus<T> = {
    Status: "Pending" | "Resolved" | "Rejected",
    Value: T?,
    Error: any?,
}

export type Async<T> = Computed<AsyncStatus<T>>
export type Reducer<T> = Value<T>

export type StateObject<T> = {
    Get: (self: any) -> T,
    [any]: any
}

export type WState<T> = (() -> T) | StateObject<T> | T

return {}
