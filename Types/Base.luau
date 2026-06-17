--[=[
	@module Base
	@within Weave.Types

	Shared Luau type definitions for Weave APIs.
]=]

type UniqueId = string
type ContentId = string
type SecurityCapabilities = any
type Font = any

export type Value<T> = {
    Type: string,
    Set: (self: Value<T>, newValue: T) -> (),
    Update: (self: Value<T>, updater: (T) -> T) -> (),
    Get: (self: Value<T>) -> T,
    Map: (self: Value<T>, transformer: (T) -> any) -> any,
    Throttle: (self: Value<T>, seconds: number) -> any,
    Debounce: (self: Value<T>, seconds: number) -> any,
    Destroy: (self: Value<T>) -> ()
}

export type Computed<T> = {
    Type: string,
    Get: (self: Computed<T>) -> T,
    Map: (self: Computed<T>, transformer: (T) -> any) -> any,
    Throttle: (self: Computed<T>, seconds: number) -> any,
    Debounce: (self: Computed<T>, seconds: number) -> any,
    Destroy: (self: Computed<T>) -> ()
}

export type Spring<T> = {
    Type: string,
    Get: (self: Spring<T>) -> T,
    Map: (self: Spring<T>, transformer: (T) -> any) -> any,
    Awake: (self: Spring<T>) -> (),
    Destroy: (self: Spring<T>) -> ()
}

export type Tween<T> = {
    Type: string,
    Get: (self: Tween<T>) -> T,
    Map: (self: Tween<T>, transformer: (T) -> any) -> any,
    Set: (self: Tween<T>, newValue: T) -> (),
    Awake: (self: Tween<T>) -> (),
    Destroy: (self: Tween<T>) -> ()
}

export type Derived<T> = {
    Type: string,
    Get: (self: Derived<T>) -> T,
    Set: (self: Derived<T>, newValue: T) -> (),
    Map: (self: Derived<T>, transformer: (T) -> any) -> any,
    Destroy: (self: Derived<T>) -> ()
}

export type StateObject<T> = {
    Get: (self: any) -> T,
    [any]: any
}

export type WState<T> = StateObject<T> | T

return {}
