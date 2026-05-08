const std = @import("std");
const Io = std.Io;

const Note = @import("note.zig").Note;
const note_title = @import("note_title.zig");

pub const NoteStore = struct {
    allocator: std.mem.Allocator,
    io: Io,
    dir: Io.Dir,
    path: []u8,

    pub fn openDocuments(allocator: std.mem.Allocator, io: Io) !NoteStore {
        const home_z = std.c.getenv("HOME") orelse return error.HomeNotFound;
        const home = std.mem.span(home_z);
        const path = try std.mem.concat(allocator, u8, &.{ home, "/Documents/Zig Notes" });
        errdefer allocator.free(path);

        try Io.Dir.createDirPath(.cwd(), io, path);
        const dir = try Io.Dir.openDirAbsolute(io, path, .{ .iterate = true });

        return .{ .allocator = allocator, .io = io, .dir = dir, .path = path };
    }

    pub fn deinit(self: *NoteStore) void {
        self.dir.close(self.io);
        self.allocator.free(self.path);
    }

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

    pub fn createEmpty(self: *NoteStore, filename: []const u8) !void {
        try Io.Dir.writeFile(self.dir, self.io, .{ .sub_path = filename, .data = "" });
    }

    pub fn delete(self: *NoteStore, note: Note) void {
        Io.Dir.deleteFile(self.dir, self.io, note.filename) catch {};
    }

    pub fn readAlloc(self: *NoteStore, allocator: std.mem.Allocator, note: Note) ![]u8 {
        return Io.Dir.readFileAlloc(self.dir, self.io, note.filename, allocator, .limited(1024 * 1024));
    }

    pub fn save(self: *NoteStore, note: Note, text: []const u8) !void {
        try Io.Dir.writeFile(self.dir, self.io, .{ .sub_path = note.filename, .data = text });
    }
};
