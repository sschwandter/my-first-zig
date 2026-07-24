# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Zig Notes: a native macOS AppKit notes app written in Zig 0.16.0 (no Objective-C source — the ObjC runtime is called directly from Zig). macOS-only; the build fails on other platforms by design.

Also read [AGENTS.md](./AGENTS.md) (contributor guidelines and mandates) and [KNOWLEDGE.md](./KNOWLEDGE.md) (Zig 0.16.0 idioms and Cocoa bridge patterns) — both are binding.

## Commands

- `zig build` — build and install `zig-out/Zig Notes.app`
- `zig build run` — build and launch the app
- `zig build test` — run all tests (required before committing)
- `zig test src/notes/note_title.zig` — run a single file's tests (works for pure-Zig files in `src/notes/`)
- `zig fmt build.zig src/**/*.zig` — format before committing
- `git config core.hooksPath .githooks` — enable the commit-msg hook (enforces Conventional Commits)

## Architecture

Dependency direction (enforced by convention): `main -> app -> ui -> cocoa`, plus `app -> notes`.

- `src/main.zig` — thin entry point; comptime-gates to Darwin, delegates to `app.zig`.
- `src/app.zig` — composition root: opens the `NoteStore`, creates the `AppController`, registers the Objective-C delegate class, builds menu/window, enters the AppKit run loop.
- `src/cocoa/` — the only layer allowed to touch Objective-C. `runtime.zig` holds typed `objc_msgSend` shims named `msg[Return][Arg1][Arg2]...` (e.g. `msgVoidIdBool`). `delegate.zig` registers one NSObject subclass at runtime and maps its selectors to Zig `callconv(.c)` callbacks.
- `src/ui/` — AppKit view construction plus `app_controller.zig`, the boundary between AppKit callbacks and domain logic. ObjC trampolines stay thin and delegate all behavior to `AppController`.
- `src/notes/` — pure Zig, platform-independent, and the only layer with real unit tests. Never import Cocoa modules here. Notes are `.txt` files in `~/Documents/Zig Notes`.

## Key conventions

- **Never commit without asking the user for confirmation immediately before** (AGENTS.md mandate).
- Conventional Commits required; release-please automates releases. The version lives only in `build.zig.zon` and its line must keep the `// x-release-please-version` marker; `build.zig` extracts it via `@embedFile` string slicing.
- `Info.plist` is generated at build time from `resources/Info.plist.in` via `b.fmt`.
- Filesystem tests use `std.testing.tmpDir(.{})` with `defer tmp.cleanup(io)` and `std.testing.io` for `std.Io` parameters (Zig 0.16.0).
- UI behavior is verified by build/launch smoke testing, not AppKit unit tests.
