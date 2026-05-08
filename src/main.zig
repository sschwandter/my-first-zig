const app = @import("app.zig");

pub fn main(init: @import("std").process.Init) !void {
    comptime if (!@import("builtin").target.os.tag.isDarwin()) {
        @compileError("Zig Notes uses AppKit and only builds for macOS.");
    };

    try app.run(init);
}
