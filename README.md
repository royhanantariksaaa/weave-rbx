# Weave

A UI library for Roblox inspired by SolidJS and Flutter that is somewhat lightweight.

This is the core reactive/UI primitives framework. WeaveKit (the component library
built on top) and Flite (the game framework) both consume it.

## Runtime sibling requirements

Weave uses **absolute requires** to sibling modules in `ReplicatedStorage.Libraries`.
At runtime, the following must be present as siblings of `Weave`:

- `WeaveSignal` — `ReplicatedStorage.Libraries.WeaveSignal` (fast pure-Luau signal)
- `Symbol` — `ReplicatedStorage.Libraries.Symbol` (unique keys)
- `Tween` — `ReplicatedStorage.Libraries.Tween` (SoA tween scheduler)

These are leaf single-file utilities and are intentionally **not** vendored here.
See your consuming project's quickstart below for how to obtain them.

## Consume as a git submodule

From your game repo root (assuming `src/Shared` maps to `ReplicatedStorage`):

```sh
git submodule add https://github.com/royhanantariksaaa/weave-rbx.git src/Shared/Libraries/Weave
```

This lands Weave at `ReplicatedStorage.Libraries.Weave`, matching what its own
requires (and WeaveKit/Flite) expect. Then provide the three sibling utilities
above at `ReplicatedStorage.Libraries/<Name>`.

## Standalone dev

Open the project in [Rojo](https://rojo.space):

```sh
rojo serve default.project.json
```

This serves Weave at `ReplicatedStorage.Libraries.Weave` so it can be developed
in isolation. The sibling utilities still need to be present for it to run.

## Tests

Reference specs live under `src/tests/` and are written for [TestEZ](https://github.com/roblox/testez).

> **Known issue:** these specs reference the library under the legacy name
> `ReplicatedStorage.Libraries.WeaveEcs`. That alias is stale — the library is
> now named `Weave`. Either rename the requires in the specs or alias Weave to
> `WeaveEcs` in your test harness before running them.

## License

[MIT](./LICENSE).
