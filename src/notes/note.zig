const std = @import("std");

pub const Note = struct {
    title: [:0]u8,
    filename: []u8,

    pub fn deinit(self: Note, allocator: std.mem.Allocator) void {
        allocator.free(self.title);
        allocator.free(self.filename);
    }
};

pub fn sortByTitle(notes: []Note) void {
    std.mem.sort(Note, notes, {}, struct {
        fn lessThan(_: void, a: Note, b: Note) bool {
            return std.ascii.lessThanIgnoreCase(a.title, b.title);
        }
    }.lessThan);
}
