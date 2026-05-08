//! File-backed note storage.
//!
//! Notes are stored as plain `.txt` files in `~/Documents/Zig Notes`. This
//! module owns all filesystem access so UI code can work in terms of `Note`
//! values and text buffers instead of paths and directory handles.

const std = @import("std");
const Io = std.Io;

const Note = @import("note.zig").Note;
const note_title = @import("note_title.zig");

/// Owns the open notes directory and provides CRUD-style file operations.
pub const NoteStore = struct {
    allocator: std.mem.Allocator,
    io: Io,
    dir: Io.Dir,
    path: []u8,

    /// Opens or creates `~/Documents/Zig Notes` and returns a store for it.
    pub fn openDocuments(allocator: std.mem.Allocator, io: Io) !NoteStore {
        const home_z = std.c.getenv("HOME") orelse return error.HomeNotFound;
        const home = std.mem.span(home_z);
        const path = try std.mem.concat(allocator, u8, &.{ home, "/Documents/Zig Notes" });
        errdefer allocator.free(path);

        try Io.Dir.createDirPath(.cwd(), io, path);
        const dir = try Io.Dir.openDirAbsolute(io, path, .{ .iterate = true });

        return .{ .allocator = allocator, .io = io, .dir = dir, .path = path };
    }

    /// Closes the directory handle and releases the owned path buffer.
    pub fn deinit(self: *NoteStore) void {
        self.dir.close(self.io);
        self.allocator.free(self.path);
    }

    /// Appends every `.txt` note found in the store directory to `notes`.
    pub fn load(self: *NoteStore, allocator: std.mem.Allocator, notes: *std.ArrayList(Note)) !void {
        var it = self.dir.iterate();
        while (try it.next(self.io)) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.name, ".txt")) continue;

            const filename = try allocator.dupe(u8, entry.name);
            errdefer allocator.free(filename);
            const title = try note_title.titleFromTextFilename(allocator, entry.name);
            errdefer allocator.free(title);

            try notes.append(allocator, .{ .title = title, .filename = filename });
        }
    }

    /// Creates an empty note file for a filename that should already be unique.
    pub fn createEmpty(self: *NoteStore, filename: []const u8) !void {
        try Io.Dir.writeFile(self.dir, self.io, .{ .sub_path = filename, .data = "" });
    }

    /// Deletes the file for a note, ignoring missing files to keep UI actions simple.
    pub fn delete(self: *NoteStore, note: Note) void {
        Io.Dir.deleteFile(self.dir, self.io, note.filename) catch {};
    }

    /// Reads a note's full text into an allocator-owned buffer.
    pub fn readAlloc(self: *NoteStore, allocator: std.mem.Allocator, note: Note) ![]u8 {
        return Io.Dir.readFileAlloc(self.dir, self.io, note.filename, allocator, .limited(1024 * 1024));
    }

    /// Replaces a note file with the provided plain-text content.
    pub fn save(self: *NoteStore, note: Note, text: []const u8) !void {
        try Io.Dir.writeFile(self.dir, self.io, .{ .sub_path = note.filename, .data = text });
    }

    /// Renames a note file on disk.
    pub fn rename(self: *NoteStore, old_filename: []const u8, new_filename: []const u8) !void {
        try Io.Dir.rename(self.dir, old_filename, self.dir, new_filename, self.io);
    }
};

test "NoteStore CRUD operations" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup(io);

    var store = NoteStore{
        .allocator = allocator,
        .io = io,
        .dir = tmp.dir,
        .path = try allocator.dupe(u8, "tmp_path"),
    };
    defer allocator.free(store.path);
    // We don't call store.deinit() because it would close tmp.dir, which tmp.cleanup() needs.

    // 1. Create empty
    try store.createEmpty("test.txt");

    // 2. Save and Read
    try store.save(.{ .title = undefined, .filename = "test.txt" }, "Hello Zig!");
    const content = try store.readAlloc(allocator, .{ .title = undefined, .filename = "test.txt" });
    defer allocator.free(content);
    try std.testing.expectEqualStrings("Hello Zig!", content);

    // 3. Rename
    try store.rename("test.txt", "renamed.txt");
    const renamed_content = try store.readAlloc(allocator, .{ .title = undefined, .filename = "renamed.txt" });
    defer allocator.free(renamed_content);
    try std.testing.expectEqualStrings("Hello Zig!", renamed_content);

    // 4. Load
    var notes = std.ArrayList(Note).init(allocator);
    defer {
        for (notes.items) |n| n.deinit(allocator);
        notes.deinit();
    }
    try store.load(allocator, &notes);
    try std.testing.expectEqual(@as(usize, 1), notes.items.len);
    try std.testing.expectEqualStrings("renamed", notes.items[0].title);

    // 5. Delete
    store.delete(.{ .title = undefined, .filename = "renamed.txt" });
    try std.testing.expectError(error.FileNotFound, store.readAlloc(allocator, .{ .title = undefined, .filename = "renamed.txt" }));
}
