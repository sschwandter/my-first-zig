# Repository Guidelines

## Project Structure & Module Organization

This repository contains a native macOS AppKit notes app written in Zig.

- `src/main.zig`: thin process entry point and macOS platform gate.
- `src/app.zig`: application composition root and AppKit lifecycle wiring.
- `src/cocoa/`: Objective-C runtime, Foundation, AppKit, and delegate bridge helpers.
- `src/notes/`: pure Zig note model, title/filename rules, and file-backed storage.
- `src/ui/`: AppKit UI construction and `AppController` behavior.
- `src/root.zig`: small reusable/testable package module.
- `resources/Info.plist`: macOS app bundle metadata.
- `build.zig`: build graph, framework linking, run/test steps, and `.app` bundle install.

Generated outputs such as `.zig-cache/`, `zig-out/`, `.DS_Store`, and `/test` are ignored.

## Build, Test, and Development Commands

- `zig build`: builds the executable and installs `zig-out/Zig Notes.app`.
- `zig build run`: runs the app executable through Zig’s build graph.
- `open "zig-out/Zig Notes.app"`: launches the generated app bundle like Finder would.
- `zig build test`: runs configured package and executable tests.
- `zig test src/notes/note_title.zig`: runs focused pure-Zig note-title tests.
- `zig fmt build.zig src/**/*.zig`: formats Zig sources before committing.
- `plutil -lint resources/Info.plist "zig-out/Zig Notes.app/Contents/Info.plist"`: validates plist files.

## Coding Style & Naming Conventions

Use `zig fmt` formatting. Prefer concise module-level `//!` comments and `///` docs for public APIs. Keep AppKit/Objective-C interop in `src/cocoa/`; do not import Cocoa modules from `src/notes/`. Use `snake_case` for Zig functions, fields, and files. Use descriptive module names such as `note_store.zig` and `app_controller.zig`.

## Testing Guidelines

Favor pure Zig tests for domain logic in `src/notes/`. UI behavior is currently verified with build and launch smoke tests rather than unit tests against AppKit. Add focused `test "..."` blocks near the logic being tested. Always run `zig build test` before committing.

## Commit & Pull Request Guidelines

History uses short imperative commit subjects, for example `Build native Zig Notes app` and `Document Zig Notes modules`. Keep commits focused: one behavior change, refactor, or documentation pass per commit. Pull requests should include a short summary, verification commands run, and screenshots or screen recordings for visible UI changes.

## Architecture Notes

Maintain the dependency direction: `main -> app -> ui -> cocoa`, and `app -> notes`. The `notes` layer should remain platform-independent and testable. Objective-C callback trampolines should stay thin and delegate behavior to `AppController`.
