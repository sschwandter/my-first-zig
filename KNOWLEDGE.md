# Zig Notes Project Knowledge

This file documents the engineering standards, idioms, and version-specific knowledge discovered during the development of Zig Notes.

## Zig Environment (0.16.0)

This project uses Zig **0.16.0**. Note the following version-specific standard library patterns:

### Testing Filesystem Logic
Use the following utilities for robust, isolated filesystem tests:
- **`std.testing.tmpDir(.{})`**: Creates a unique temporary directory in `.zig-cache/tmp`. Always call `defer tmp.cleanup(io)` to ensure resources are released.
- **`std.testing.io`**: The standard threaded I/O instance for tests. Pass this to any function requiring a `std.Io` parameter.

### Version Management
- **Single Source of Truth**: The application version is defined in `build.zig.zon`.
- **Release Automation**: This project uses `release-please`. For version bumping to work, the version line in `build.zig.zon` must include the marker: `.version = "x.y.z", // x-release-please-version`.
- **Build Extraction**: Extract the version at compile time in `build.zig` using `@embedFile("build.zig.zon")` and a slice-based parser to avoid complex ZON parsing logic during the build.

## macOS / Cocoa Bridge Conventions

### Objective-C Message Shims (`src/cocoa/runtime.zig`)
Naming follow a strict `msg[Return][Arg1][Arg2]...` convention to maintain type safety:
- `msgVoidIdBool`: Sends one `Id` and one `bool`, returns `void`.
- `msgIdId`: Sends one `Id`, returns an `Id` (object).
- `msgDoubleDouble`: Sends two `f64`, returns an `Id` (object).

### View-Based Tables
Prefer **view-based** `NSTableView` over cell-based.
- Register `tableView:viewForTableColumn:row:` in `delegate.zig`.
- Implement cell creation logic in `app_controller.zig` using `makeViewWithIdentifier:owner:`.
- Manually handle vertical centering for `NSTextField` within `NSTableCellView` by using precise `y` offsets (e.g., `10.5` for a 42pt row) to account for visual baseline perception.

## Build System Patterns
- **Dynamic Assets**: Generate macOS system files like `Info.plist` at build time.
- **Templates**: Store XML/Plist structures in `resources/*.in` files. Use `@embedFile` and `b.fmt` in `build.zig` to populate them.
