//! Process entry point for Zig Notes.
//!
//! The executable stays intentionally thin: platform gating happens here, and
//! all application setup is delegated to `app.zig`.

const app = @import("app.zig");

/// Starts the native macOS application using Zig's process initialization data.
pub fn main(init: @import("std").process.Init) !void {
    comptime if (!@import("builtin").target.os.tag.isDarwin()) {
        @compileError("Zig Notes uses AppKit and only builds for macOS.");
    };

    try app.run(init);
}
